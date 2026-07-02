//
//  MonthlyCalendarViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class MonthlyCalendarViewModel {
    // MARK: - Output

    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public private(set) var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    // MARK: - Input

    public let input = PassthroughSubject<Input, Never>()

    // MARK: - Output (Event)

    public var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    // MARK: - Private

    private let stateSubject: CurrentValueSubject<State, Never>
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()
    @MainActor private var currentLoadTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase
    private let getNicknameUseCase: GetNicknameUseCase
    private let fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase
    private let pushNotificationObserver: any PushNotificationObserving
    private let checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase

    // MARK: - Init

    public init(
        fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase,
        getNicknameUseCase: GetNicknameUseCase,
        fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase,
        saveFoodRecordUseCase: SaveFoodRecordUseCase,
        pushNotificationObserver: any PushNotificationObserving,
        checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase
    ) {
        self.fetchMonthlyCalendarDaysUseCase = fetchMonthlyCalendarDaysUseCase
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
        self.getNicknameUseCase = getNicknameUseCase
        self.fetchFoodImageAssetUseCase = fetchFoodImageAssetUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
        self.checkAppReviewEligibilityUseCase = checkAppReviewEligibilityUseCase

        let today = Date()
        let calendar = Calendar.seoul
        let period = calendar.monthlyCalendarPeriod(for: today)
        let placeholderDays = Self.generatePlaceholderDays(
            for: period, currentMonth: today, calendar: calendar
        )

        self.stateSubject = CurrentValueSubject(State(currentDisplayDate: today))
        state.monthDays = placeholderDays
        state.numberOfWeeks = placeholderDays.count / 7
        state.monthYearText = today.formatMonthText()
        state.selectedDate = calendar.startOfDay(for: today)

        setupBindings()
        input.send(.loadNickname)
    }

    // MARK: - Setup

    private func setupBindings() {
        input
            .sink { [weak self] action in
                guard let self else { return }
                Task {
                    await self.handleInput(action)
                }
            }
            .store(in: &cancellables)

        pushNotificationObserver.analysisResultPublisher
            .sink { [weak self] notification in
                self?.input.send(.handlePushNotification(notification))
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func handleInput(_ action: Input) async {
        switch action {
        case .loadNickname:
            state.nickname = getNicknameUseCase.execute()

        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
            startLoadMonth(for: state.currentDisplayDate)
            await updateSelectedDateContent()

        case .selectMonth(let date):
            let calendar = Calendar.current
            let newComponents = calendar.dateComponents([.year, .month], from: date)
            let todayComponents = calendar.dateComponents([.year, .month], from: Date())
            guard let newYearMonth = calendar.date(from: newComponents),
                  let todayYearMonth = calendar.date(from: todayComponents),
                  newYearMonth <= todayYearMonth else { return }
            state.currentDisplayDate = date
            state.selectedDate = selectedDate(for: date)
            startLoadMonth(for: state.currentDisplayDate)
            await updateSelectedDateContent()

        case .selectDay(let date):
            state.selectedDate = Calendar.current.startOfDay(for: date)
            await updateSelectedDateContent()

        case .refreshCurrentMonth:
            startLoadMonth(for: state.currentDisplayDate)
            await updateSelectedDateContent()

        case .updateMonth(let date):
            let calendar = Calendar.current
            if calendar.component(.year, from: date) != calendar.component(.year, from: state.currentDisplayDate)
                || calendar.component(.month, from: date) != calendar.component(.month, from: state.currentDisplayDate) {
                startLoadMonth(for: date)
            } else {
                startLoadMonth(for: state.currentDisplayDate)
            }
            state.selectedDate = calendar.startOfDay(for: date)
            await updateSelectedDateContent()

        case .requestPhotoAuthorization:
            let status = await requestPhotoAuthorizationUseCase.execute()
            if status == .denied || status == .restricted {
                eventSubject.send(.photoAuthorizationDenied)
            }

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)

        case .handlePushNotification(let notification):
            await handlePushNotification(notification)

        case .navigateToSelectedDateDetail:
            eventSubject.send(.navigateToDetail(date: state.selectedDate, records: state.selectedRecords))
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func startLoadMonth(for date: Date) {
        currentLoadTask?.cancel()
        currentLoadTask = nil
        currentLoadTask = Task {
            await loadMonth(for: date)
        }
    }

    @MainActor
    private func loadMonth(for date: Date) async {
        state.currentDisplayDate = date
        state.monthYearText = date.formatMonthText()

        let period = Calendar.current.monthlyCalendarPeriod(for: date)
        
        do {
            for try await monthDays in fetchMonthlyCalendarDaysUseCase.execute(for: period, currentMonth: date) {
                state.monthDays = monthDays
                state.numberOfWeeks = monthDays.count / 7
                updateMonthlyProgress()
            }
        } catch is CancellationError {
            print("Task Cancelled")
        } catch {
            print("Failed to load monthly calendar: \(error)")
        }
    }

    private static func generatePlaceholderDays(
        for period: DateInterval,
        currentMonth: Date,
        calendar: Calendar
    ) -> [MonthlyCalendarDay] {
        let today = calendar.startOfDay(for: Date())
        let currentMonthComponents = calendar.dateComponents([.year, .month], from: currentMonth)

        var days: [MonthlyCalendarDay] = []
        var currentDate = period.start

        while currentDate < period.end {
            let dateComponents = calendar.dateComponents([.year, .month], from: currentDate)
            let isCurrentMonth = dateComponents.year == currentMonthComponents.year &&
                                 dateComponents.month == currentMonthComponents.month

            days.append(MonthlyCalendarDay(
                date: currentDate,
                dayNumber: calendar.component(.day, from: currentDate),
                isCurrentMonth: isCurrentMonth,
                isToday: calendar.isDate(currentDate, inSameDayAs: today),
                imageURLs: []
            ))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }

        return days
    }

    private func requestPhotoAuthorizationIfNeeded() async {
        let status = requestPhotoAuthorizationUseCase.currentStatus()
        if status == .notDetermined {
            _ = await requestPhotoAuthorizationUseCase.execute()
        }
    }

    @MainActor
    private func updateSelectedDateContent() async {
        do {
            let records = try await fetchFoodRecordsUseCase.execute(for: state.selectedDate)
            let completedRecords = records.filter { !$0.isProcessing }
            let processingRecords = records.filter { $0.isProcessing }

            var hasFoodPhotos = false
            if completedRecords.isEmpty && processingRecords.isEmpty {
                hasFoodPhotos = await checkFoodPhotosExist(for: state.selectedDate)
            }

            state.selectedRecords = completedRecords
            state.processingRecords = processingRecords
            state.hasFoodPhotos = hasFoodPhotos
        } catch {
            eventSubject.send(.showError(error))
        }
    }

    private func checkFoodPhotosExist(for date: Date) async -> Bool {
        guard requestPhotoAuthorizationUseCase.isAuthorized() else {
            return false
        }
        do {
            let calendar = Calendar.current
            let startOfDay = calendar.startOfDay(for: date)
            let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)
            let photosByDate = try await fetchFoodImageAssetUseCase.execute(
                from: startOfDay,
                to: endOfDay
            )
            let photos = photosByDate[startOfDay] ?? []
            return !photos.isEmpty
        } catch {
            return false
        }
    }

    @MainActor
    private func savePhotosAsRecord(_ assets: [any ImageAssetable]) async {
        guard !assets.isEmpty else { return }

        do {
            let results = try await saveFoodRecordUseCase.execute(
                from: assets,
                date: state.selectedDate
            )
            let mealType = results.first?.mealType ?? .breakfast
            eventSubject.send(.uploadCompleted(date: state.selectedDate, mealType: mealType))
            startLoadMonth(for: state.currentDisplayDate)
            await updateSelectedDateContent()
        } catch {
            eventSubject.send(.saveFailed(error))
        }
    }

    private func handlePushNotification(_ notification: AnalysisResultNotification) async {
        let calendar = Calendar.current
        let notificationDate = calendar.startOfDay(for: notification.diaryDate)
        let selectedDate = calendar.startOfDay(for: state.selectedDate)

        if calendar.isDate(notificationDate, equalTo: state.currentDisplayDate, toGranularity: .month) {
            await startLoadMonth(for: state.currentDisplayDate)
        }

        if notificationDate == selectedDate {
            await updateSelectedDateContent()
        }

        if checkAppReviewEligibilityUseCase.execute() {
            eventSubject.send(.requestAppReview)
        }
    }

    @MainActor
    private func updateMonthlyProgress() {
        let calendar = Calendar.current
        let currentComponents = calendar.dateComponents([.year, .month], from: state.currentDisplayDate)
        let currentMonthDays = state.monthDays.filter { day in
            let components = calendar.dateComponents([.year, .month], from: day.date)
            return components.year == currentComponents.year && components.month == currentComponents.month
        }
        state.monthRecordCount = currentMonthDays.filter { !$0.imageURLs.isEmpty }.count
        state.monthDayCount = currentMonthDays.count
    }

    private func selectedDate(for monthDate: Date) -> Date {
        let calendar = Calendar.current
        let today = calendar.startOfDay(for: Date())
        if calendar.isDate(monthDate, equalTo: today, toGranularity: .month) {
            return today
        }
        return calendar.date(
            from: calendar.dateComponents([.year, .month], from: monthDate)
        ) ?? monthDate
    }
}

// MARK: - State & Input

extension MonthlyCalendarViewModel {
    public struct State: Equatable {
        public internal(set) var currentDisplayDate: Date
        public internal(set) var selectedDate: Date = Date()
        var monthDays: [MonthlyCalendarDay] = []
        var numberOfWeeks: Int = 5
        var monthYearText: String = ""
        var nickname: String? = nil
        var selectedRecords: [FoodRecord] = []
        var processingRecords: [FoodRecord] = []
        var hasFoodPhotos: Bool = false
        var monthRecordCount: Int = 0
        var monthDayCount: Int = 0

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.monthDays == rhs.monthDays
                && lhs.numberOfWeeks == rhs.numberOfWeeks
                && lhs.monthYearText == rhs.monthYearText
                && lhs.nickname == rhs.nickname
                && lhs.selectedDate == rhs.selectedDate
                && lhs.selectedRecords == rhs.selectedRecords
                && lhs.processingRecords == rhs.processingRecords
                && lhs.hasFoodPhotos == rhs.hasFoodPhotos
                && lhs.monthRecordCount == rhs.monthRecordCount
                && lhs.monthDayCount == rhs.monthDayCount
        }
    }

    public enum Input {
        case loadNickname
        case loadInitialData
        case selectMonth(Date)
        case selectDay(Date)
        case refreshCurrentMonth
        case updateMonth(Date)
        case requestPhotoAuthorization
        case saveSelectedPhotos([any ImageAssetable])
        case handlePushNotification(AnalysisResultNotification)
        case navigateToSelectedDateDetail
    }

    public enum Event {
        case navigateToDetail(date: Date, records: [FoodRecord])
        case showError(Error)
        case photoAuthorizationDenied
        case uploadCompleted(date: Date, mealType: MealType)
        case saveFailed(Error)
        case requestAppReview
    }
}
