//
//  WeeklyCalendarViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation
import UIKit

// MARK: - ViewModel

public final class WeeklyCalendarViewModel<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository,
    AuthRepo: PhotoAuthorizationRepository,
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
    private var currentWeekBaseDate: Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    private let loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>
    private let pushNotificationObserver: PushObserver
    private let getNicknameUseCase: GetNicknameUseCase

    // MARK: - Init

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>,
        pushNotificationObserver: PushObserver,
        getNicknameUseCase: GetNicknameUseCase
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.loadWeeklyCalendarDataUseCase = loadWeeklyCalendarDataUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
        self.getNicknameUseCase = getNicknameUseCase

        self.calendar = Calendar.current

        let today = calendar.startOfDay(for: Date())
        self.currentWeekBaseDate = today
        self.stateSubject = CurrentValueSubject(State(selectedDate: today))

        setupBindings()
        input.send(.loadNickname)
    }

    // MARK: - Setup

    private func setupBindings() {
        input
            .sink { [weak self] action in
                guard let self else { return }
                Task(priority: .userInitiated) {
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
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)

        case .requestPhotoAuthorization:
            let status = await requestPhotoAuthorizationUseCase.execute()
            if status == .denied || status == .restricted {
                eventSubject.send(.photoAuthorizationDenied)
            }

        case .goToPreviousWeek:
            currentWeekBaseDate = calendar.previousWeek(from: currentWeekBaseDate)
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)

        case .goToNextWeek:
            let nextWeek = calendar.nextWeek(from: currentWeekBaseDate)
            let today = calendar.startOfDay(for: Date())
            let (nextWeekStart, _) = calendar.weekRange(for: nextWeek)
            guard nextWeekStart <= today else { return }

            currentWeekBaseDate = nextWeek
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)

        case .selectDate(let date):
            if !calendar.isDate(state.selectedDate, inSameDayAs: date) {
                state.selectedDate = date
                await moveToWeekIfNeeded(for: date)
                await updateDateContent(for: date)
            }

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)

        case .handlePushNotification(let notification):
            await handlePushNotification(notification)

        case .refreshData(let date):
            if let date {
                state.selectedDate = date
                await moveToWeekIfNeeded(for: date)
            }
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadWeekData(for date: Date) async {
        state.isLoading = true
        defer { state.isLoading = false }

        do {
            let weekData = try await loadWeeklyCalendarDataUseCase.loadWeekData(for: date)
            state.weekDays = weekData.weekDays
            state.monthText = weekData.monthText
            state.canGoToNextWeek = canGoToNextWeek(from: currentWeekBaseDate)
        } catch {
            eventSubject.send(.loadFailed(error))
        }
    }

    @MainActor
    private func updateDateContent(for date: Date) async {
        let startOfDay = calendar.startOfDay(for: date)
        let allRecords = state.weekDays.records(for: startOfDay, calendar: calendar)

        let completedRecords = allRecords.filter { !$0.isProcessing }
        let processingRecords = allRecords.filter { $0.isProcessing }

        state.dateContent = DateContent(
            records: completedRecords,
            processingRecords: processingRecords
        )
    }

    @MainActor
    private func savePhotosAsRecord(_ assets: [AssetRepo.Asset]) async {
        guard !assets.isEmpty else { return }

        do {
            try await saveFoodRecordUseCase.execute(
                from: assets,
                date: state.selectedDate
            )
            eventSubject.send(.uploadCompleted)
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)
        } catch {
            eventSubject.send(.saveFailed(error))
        }
    }

    /// 선택된 날짜가 현재 표시 중인 주 범위 밖이면 해당 주로 이동
    private func moveToWeekIfNeeded(for date: Date) async {
        let (weekStart, weekEnd) = calendar.weekRange(for: currentWeekBaseDate)
        let dateStart = calendar.startOfDay(for: date)
        if !(weekStart...weekEnd).contains(dateStart) {
            currentWeekBaseDate = date
            await loadWeekData(for: currentWeekBaseDate)
        }
    }

    /// 주간 이동 시 같은 요일로 선택 날짜 업데이트
    private func updateSelectedDateToSameWeekday(in weekBaseDate: Date) {
        let currentWeekday = calendar.component(.weekday, from: state.selectedDate)

        // 새 주의 시작일(일요일) 찾기
        let weekStart =
            calendar.date(
                from: calendar.dateComponents(
                    [.yearForWeekOfYear, .weekOfYear], from: weekBaseDate)
            ) ?? weekBaseDate

        // 같은 요일로 이동 (weekday: 1=일, 2=월, ...)
        if let newSelectedDate = calendar.date(
            byAdding: .day, value: currentWeekday - 1, to: weekStart)
        {
            let today = calendar.startOfDay(for: Date())
            state.selectedDate = newSelectedDate > today ? today : newSelectedDate
        }
    }

    private func requestPhotoAuthorizationIfNeeded() async {
        let status = requestPhotoAuthorizationUseCase.currentStatus()
        if status == .notDetermined {
            _ = await requestPhotoAuthorizationUseCase.execute()
        }
    }

    /// 사진 추가 전 권한 체크
    public func checkPhotoAuthorizationForAddingPhoto() -> Bool {
        requestPhotoAuthorizationUseCase.isAuthorized()
    }

    // MARK: - Push Notification

    private func handlePushNotification(_ notification: AnalysisResultNotification) async {
        let notificationDate = calendar.startOfDay(for: notification.diaryDate)
        let selectedDate = calendar.startOfDay(for: state.selectedDate)
        let (weekStart, weekEnd) = calendar.weekRange(for: currentWeekBaseDate)
        let currentWeekRange = weekStart...weekEnd

        if currentWeekRange.contains(notificationDate) {
            await loadWeekData(for: currentWeekBaseDate)
        }

        if notificationDate == selectedDate {
            await updateDateContent(for: state.selectedDate)
        }
    }
}

// MARK: - State
extension WeeklyCalendarViewModel {
    public struct State: Equatable {
        fileprivate static var foodProbabilityThreshold: Float { 0.6 }

        public internal(set) var weekDays: [WeeklyCalendarDay] = []
        public internal(set) var selectedDate: Date = Date()
        public internal(set) var monthText: String = ""
        public internal(set) var isLoading: Bool = false
        public internal(set) var dateContent: DateContent?
        public internal(set) var nickname: String? = nil
        public internal(set) var canGoToNextWeek: Bool = false
    }

    public enum Input {
        case loadNickname
        case loadInitialData
        case requestPhotoAuthorization
        case goToPreviousWeek
        case goToNextWeek
        case selectDate(Date)
        case saveSelectedPhotos([AssetRepo.Asset])
        case handlePushNotification(AnalysisResultNotification)
        case refreshData(Date? = nil)
    }

    public enum Event {
        case photoAuthorizationDenied
        case uploadCompleted
        case saveFailed(Error)
        case loadFailed(Error)
    }
}

// MARK: - DateContent

extension WeeklyCalendarViewModel {
    public struct DateContent: Equatable {
        public let records: [FoodRecord]
        public let processingRecords: [FoodRecord]
    }
}

// MARK: - Public Methods

extension WeeklyCalendarViewModel {
    /// 다음 주로 이동 가능 여부
    public func canGoToNextWeek(from date: Date) -> Bool {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        let today = calendar.startOfDay(for: Date())
        let (nextWeekStart, _) = calendar.weekRange(for: nextWeek)
        return nextWeekStart <= today
    }

    /// 특정 날짜의 사진 로드
    public func photos(for date: Date) async throws -> [FoodImageAsset<AssetRepo.Asset>] {
        try await loadWeeklyCalendarDataUseCase.loadPhotos(for: date)
    }
}
