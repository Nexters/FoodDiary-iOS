//
//  DetailViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class DetailViewModel<RecordRepo: FoodRecordRepository> {

    // MARK: - Output

    public var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public private(set) var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    // MARK: - Input

    public let input = PassthroughSubject<Input, Never>()

    // MARK: - Private

    private let calendar: Calendar
    private let stateSubject: CurrentValueSubject<State, Never>
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let fetchRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>

    // MARK: - Init

    public init(
        initialDate: Date,
        fetchRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    ) {
        self.fetchRecordsUseCase = fetchRecordsUseCase
        self.calendar = Calendar.current

        let startOfDay = calendar.startOfDay(for: initialDate)
        self.stateSubject = CurrentValueSubject(State(currentDate: startOfDay))

        updateDateText()
        updateNextDayAvailability()
        setupBindings()
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
            let records = try await fetchRecordsUseCase.execute(for: date)
            state.recordsByMealType = groupRecordsByMealType(records)
            updateDateText()
        } catch {
            print("Failed to load records: \(error)")
        }
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
}

// MARK: - State & Input

extension DetailViewModel {
    public struct State: Equatable {
        public var currentDate: Date
        public var recordsByMealType: [MealType: FoodRecord] = [:]
        public var dateText: String = ""
        public var isLoading: Bool = false
        public var isNextDayAvailable: Bool = true

        public static func == (lhs: Self, rhs: Self) -> Bool {
            Calendar.current.isDate(lhs.currentDate, inSameDayAs: rhs.currentDate)
                && lhs.recordsByMealType == rhs.recordsByMealType
                && lhs.dateText == rhs.dateText
                && lhs.isLoading == rhs.isLoading
                && lhs.isNextDayAvailable == rhs.isNextDayAvailable
        }
    }

    public enum Input {
        case loadRecords
        case goToPreviousDay
        case goToNextDay
    }
}
