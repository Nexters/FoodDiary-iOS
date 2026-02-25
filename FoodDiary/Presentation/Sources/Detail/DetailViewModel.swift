//
//  DetailViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class DetailViewModel<
    RecordRepo: FoodRecordRepository,
    PendingRepo: PendingFoodRecordRepository,
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
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, PendingRepo>
    private let loadPendingRecordsUseCase: LoadPendingRecordsUseCase<PendingRepo>
    private let deletePendingRecordUseCase: DeletePendingRecordUseCase<PendingRepo>
    private let deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>
    private let cleanUpExpiredPendingRecordsUseCase: CleanUpExpiredPendingRecordsUseCase<PendingRepo>
    private let pushNotificationObserver: PushObserver

    // MARK: - Init

    public init(
        initialDate: Date,
        initialRecords: [FoodRecord],
        fetchRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, PendingRepo>,
        loadPendingRecordsUseCase: LoadPendingRecordsUseCase<PendingRepo>,
        deletePendingRecordUseCase: DeletePendingRecordUseCase<PendingRepo>,
        deleteFoodRecordUseCase: DeleteFoodRecordUseCase<RecordRepo>,
        cleanUpExpiredPendingRecordsUseCase: CleanUpExpiredPendingRecordsUseCase<PendingRepo>,
        pushNotificationObserver: PushObserver
    ) {
        self.fetchRecordsUseCase = fetchRecordsUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.loadPendingRecordsUseCase = loadPendingRecordsUseCase
        self.deletePendingRecordUseCase = deletePendingRecordUseCase
        self.deleteFoodRecordUseCase = deleteFoodRecordUseCase
        self.cleanUpExpiredPendingRecordsUseCase = cleanUpExpiredPendingRecordsUseCase
        self.pushNotificationObserver = pushNotificationObserver
        self.calendar = Calendar.current

        let startOfDay = calendar.startOfDay(for: initialDate)
        self.stateSubject = CurrentValueSubject(State(currentDate: startOfDay))
        stateSubject.value.recordsByMealType = groupRecordsByMealType(initialRecords)

        updateDateText()
        updateNextDayAvailability()
        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        input
            .sink { [weak self] action in
                guard let self else { return }
                self.loadRecordsTask?.cancel()
                self.loadRecordsTask = Task(priority: .userInitiated) {
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

        do {
            let records = try await fetchRecordsUseCase.execute(for: date)
            guard !Task.isCancelled else { return }

            state.recordsByMealType = groupRecordsByMealType(records)

            let pendingRecords = try await loadPendingRecords(for: date)
            guard !Task.isCancelled else { return }

            state.pendingRecords = try await cleanUpExpiredPendingRecordsUseCase.execute(
                serverRecords: records,
                pendingRecords: pendingRecords
            )

            updateDateText()
        } catch {
            if !Task.isCancelled {
                print("Failed to load records: \(error)")
            }
        }

        state.isLoading = false
    }

    private func groupRecordsByMealType(_ records: [FoodRecord]) -> [MealType: FoodRecord] {
        Dictionary(uniqueKeysWithValues: records.map { ($0.mealType, $0) })
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
            let pendingRecords = try await saveFoodRecordUseCase.execute(
                from: assets,
                date: state.currentDate
            )
            state.pendingRecords.append(contentsOf: pendingRecords)
            eventSubject.send(.uploadCompleted)
        } catch {
            eventSubject.send(.saveFailed(error))
        }
    }

    // MARK: - Pending Records

    @MainActor
    private func handlePushNotification(_ notification: AnalysisResultNotification) async {
        do {
            try await deletePendingRecordUseCase.execute(byDate: notification.diaryDate)

            let notificationDate = calendar.startOfDay(for: notification.diaryDate)
            let currentDate = calendar.startOfDay(for: state.currentDate)

            if notificationDate == currentDate {
                await loadRecords(for: state.currentDate)
            }
        } catch {
            // Push 처리 실패는 무시
        }
    }

    @MainActor
    private func performDeleteAllRecords() async {
        guard !state.recordsByMealType.isEmpty || !state.pendingRecords.isEmpty else { return }

        state.isLoading = true
        defer { state.isLoading = false }

        do {
            for (_, record) in state.recordsByMealType {
                try await deleteFoodRecordUseCase.execute(id: record.id)
            }

            try await deletePendingRecordUseCase.execute(byDate: state.currentDate)

            state.recordsByMealType = [:]
            state.pendingRecords = []
            eventSubject.send(.deleteAllCompleted)
        } catch {
            eventSubject.send(.deleteAllFailed(error))
        }
    }

    private func loadPendingRecords(for date: Date) async throws -> [PendingFoodRecord] {
        let allRecords = try await loadPendingRecordsUseCase.execute()
        let dateKey = calendar.startOfDay(for: date)
        return allRecords.filter { calendar.startOfDay(for: $0.date) == dateKey }
    }
}

// MARK: - State & Input

extension DetailViewModel {
    public struct State: Equatable {
        public var currentDate: Date
        public var recordsByMealType: [MealType: FoodRecord] = [:]
        public var pendingRecords: [PendingFoodRecord] = []
        public var dateText: String = ""
        public var isLoading: Bool = false
        public var isNextDayAvailable: Bool = true

        public static func == (lhs: Self, rhs: Self) -> Bool {
            Calendar.current.isDate(lhs.currentDate, inSameDayAs: rhs.currentDate)
                && lhs.recordsByMealType == rhs.recordsByMealType
                && lhs.pendingRecords == rhs.pendingRecords
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
