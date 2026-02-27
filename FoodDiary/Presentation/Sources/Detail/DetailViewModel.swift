//
//  DetailViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class DetailViewModel<
    RecordRepo: FoodRecordRepository,
    PushObserver: PushNotificationObserving
> {

    // MARK: - Output

    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public private(set) var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    public var eventPublisher: AnyPublisher<Event, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    // MARK: - Input

    public let input = PassthroughSubject<Input, Never>()

    // MARK: - Private

    private let calendar: Calendar
    private let stateSubject: CurrentValueSubject<State, Never>
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()
    private var loadRecordsTask: Task<Void, Never>?

    // MARK: - Dependencies

    private let fetchRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>
    private let pushNotificationObserver: PushObserver

    // MARK: - Init

    public init(
        initialDate: Date,
        initialRecords: [FoodRecord],
        fetchRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>,
        pushNotificationObserver: PushObserver
    ) {
        self.fetchRecordsUseCase = fetchRecordsUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
        self.calendar = Calendar.current

        let startOfDay = calendar.startOfDay(for: initialDate)
        self.stateSubject = CurrentValueSubject(State(currentDate: startOfDay))

        let (completed, processing) = Self.partitionRecords(initialRecords)
        stateSubject.value.recordsByMealType = Self.groupRecordsByMealType(completed)
        stateSubject.value.processingRecordsByMealType = Self.groupRecordsByMealType(processing)

        updateDateText()
        updateNextDayAvailability()
        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        input
            .sink { [weak self] action in
                guard let self else { return }
                switch action {
                case .loadRecords, .goToPreviousDay, .goToNextDay:
                    self.loadRecordsTask?.cancel()
                    self.loadRecordsTask = Task(priority: .userInitiated) {
                        await self.handleInput(action)
                    }
                default:
                    Task(priority: .userInitiated) {
                        await self.handleInput(action)
                    }
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
        case .loadRecords:
            await loadRecords(for: state.currentDate)

        case .goToPreviousDay:
            await navigateDay(by: -1)

        case .goToNextDay:
            await navigateDay(by: 1)

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)

        case .handlePushNotification(let notification):
            await handlePushNotification(notification)

        case .deleteAllRecords:
            await performDeleteAllRecords()
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func navigateDay(by offset: Int) async {
        if let newDate = calendar.date(byAdding: .day, value: offset, to: state.currentDate) {
            if offset > 0 {
                let today = calendar.startOfDay(for: Date())
                guard newDate <= today else { return }
            }
            state.currentDate = newDate
            updateDateText()
            updateNextDayAvailability()
            await loadRecords(for: newDate)
        }
    }

    @MainActor
    private func loadRecords(for date: Date) async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let allRecords = try await fetchRecordsUseCase.execute(for: date)
            guard !Task.isCancelled else { return }

            let (completed, processing) = Self.partitionRecords(allRecords)
            state.recordsByMealType = Self.groupRecordsByMealType(completed)
            state.processingRecordsByMealType = Self.groupRecordsByMealType(processing)

            updateDateText()
        } catch {
            if !Task.isCancelled {
                print("Failed to load records: \(error)")
            }
        }
    }

    private static func groupRecordsByMealType(_ records: [FoodRecord]) -> [MealType: FoodRecord] {
        Dictionary(uniqueKeysWithValues: records.map { ($0.mealType, $0) })
    }

    private static func partitionRecords(_ records: [FoodRecord]) -> (completed: [FoodRecord], processing: [FoodRecord]) {
        var completed: [FoodRecord] = []
        var processing: [FoodRecord] = []
        for record in records {
            if record.isProcessing {
                processing.append(record)
            } else {
                completed.append(record)
            }
        }
        return (completed, processing)
    }

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        return formatter
    }()

    private func updateDateText() {
        state.dateText = dateFormatter.string(from: state.currentDate)
    }

    private func updateNextDayAvailability() {
        let today = calendar.startOfDay(for: Date())
        state.isNextDayAvailable = state.currentDate < today
    }

    @MainActor
    private func savePhotosAsRecord(_ assets: [any ImageAssetable]) async {
        guard !assets.isEmpty else { return }

        do {
            try await saveFoodRecordUseCase.execute(
                from: assets,
                date: state.currentDate
            )
            eventSubject.send(.uploadCompleted)
            await loadRecords(for: state.currentDate)
        } catch {
            eventSubject.send(.saveFailed(error))
        }
    }

    // MARK: - Push Notification

    @MainActor
    private func handlePushNotification(_ notification: AnalysisResultNotification) async {
        let notificationDate = calendar.startOfDay(for: notification.diaryDate)
        let currentDate = calendar.startOfDay(for: state.currentDate)

        if notificationDate == currentDate {
            await loadRecords(for: state.currentDate)
        }
    }

    @MainActor
    private func performDeleteAllRecords() async {
        guard !state.recordsByMealType.isEmpty || !state.processingRecordsByMealType.isEmpty else { return }

        state.isLoading = true

        do {
            for (_, record) in state.recordsByMealType {
                try await deleteFoodRecordUseCase.execute(id: record.id)
            }

            for (_, record) in state.processingRecordsByMealType {
                try await deleteFoodRecordUseCase.execute(id: record.id)
            }

            state.recordsByMealType = [:]
            state.processingRecordsByMealType = [:]
            eventSubject.send(.deleteAllCompleted)
        } catch {
            state.isLoading = false
            eventSubject.send(.deleteAllFailed(error))
        }
    }
}

// MARK: - State & Input

extension DetailViewModel {
    public struct State: Equatable {
        public var currentDate: Date
        public var recordsByMealType: [MealType: FoodRecord] = [:]
        public var processingRecordsByMealType: [MealType: FoodRecord] = [:]
        public var dateText: String = ""
        public var isLoading: Bool = false
        public var isNextDayAvailable: Bool = true

        public static func == (lhs: Self, rhs: Self) -> Bool {
            Calendar.current.isDate(lhs.currentDate, inSameDayAs: rhs.currentDate)
                && lhs.recordsByMealType == rhs.recordsByMealType
                && lhs.processingRecordsByMealType == rhs.processingRecordsByMealType
                && lhs.dateText == rhs.dateText
                && lhs.isLoading == rhs.isLoading
                && lhs.isNextDayAvailable == rhs.isNextDayAvailable
        }
    }

    public enum Input {
        case loadRecords
        case goToPreviousDay
        case goToNextDay
        case saveSelectedPhotos([any ImageAssetable])
        case handlePushNotification(AnalysisResultNotification)
        case deleteAllRecords
    }

    public enum Event {
        case uploadCompleted
        case saveFailed(Error)
        case deleteAllCompleted
        case deleteAllFailed(Error)
    }
}
