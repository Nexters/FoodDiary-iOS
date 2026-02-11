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
            if let previousDay = calendar.date(byAdding: .day, value: -1, to: state.currentDate) {
                state.currentDate = previousDay
                updateDateText()
                await loadRecords(for: previousDay)
            }

        case .goToNextDay:
            if let nextDay = calendar.date(byAdding: .day, value: 1, to: state.currentDate) {
                state.currentDate = nextDay
                updateDateText()
                await loadRecords(for: nextDay)
            }
        }
    }

    // MARK: - Private Methods

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

    private func groupRecordsByMealType(_ records: [FoodRecord]) -> [MealType: [FoodRecord]] {
        var grouped: [MealType: [FoodRecord]] = [:]
        for record in records {
            grouped[record.mealType, default: []].append(record)
        }
        return grouped
    }

    private func updateDateText() {
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월 d일 (E)"
        state.dateText = formatter.string(from: state.currentDate)
    }
}

// MARK: - State & Input

extension DetailViewModel {
    public struct State: Equatable {
        public var currentDate: Date
        public var recordsByMealType: [MealType: [FoodRecord]] = [:]
        public var dateText: String = ""
        public var isLoading: Bool = false

        public static func == (lhs: Self, rhs: Self) -> Bool {
            Calendar.current.isDate(lhs.currentDate, inSameDayAs: rhs.currentDate)
                && lhs.recordsByMealType == rhs.recordsByMealType
                && lhs.dateText == rhs.dateText
                && lhs.isLoading == rhs.isLoading
        }
    }

    public enum Input {
        case loadRecords
        case goToPreviousDay
        case goToNextDay
    }
}
