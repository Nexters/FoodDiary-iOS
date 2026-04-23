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

    // MARK: - Init

    public init(
        fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase,
        getNicknameUseCase: GetNicknameUseCase
    ) {
        self.fetchMonthlyCalendarDaysUseCase = fetchMonthlyCalendarDaysUseCase
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
        self.getNicknameUseCase = getNicknameUseCase

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
    }

    @MainActor
    private func handleInput(_ action: Input) async {
        switch action {
        case .loadNickname:
            state.nickname = getNicknameUseCase.execute()

        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
            startLoadMonth(for: state.currentDisplayDate)

        case .selectMonth(let date):
            let calendar = Calendar.current
            let newComponents = calendar.dateComponents([.year, .month], from: date)
            let todayComponents = calendar.dateComponents([.year, .month], from: Date())
            guard let newYearMonth = calendar.date(from: newComponents),
                  let todayYearMonth = calendar.date(from: todayComponents),
                  newYearMonth <= todayYearMonth else { return }
            state.currentDisplayDate = date
            startLoadMonth(for: state.currentDisplayDate)

        case .selectDay(let date):
            do {
                let records = try await fetchFoodRecordsUseCase.execute(for: date)
                eventSubject.send(.navigateToDetail(date: date, records: records))
            } catch {
                eventSubject.send(.showError(error))
            }

        case .refreshCurrentMonth:
            startLoadMonth(for: state.currentDisplayDate)

        case .updateMonth(let date):
            let calendar = Calendar.current
            if calendar.component(.year, from: date) != calendar.component(.year, from: state.currentDisplayDate)
                || calendar.component(.month, from: date) != calendar.component(.month, from: state.currentDisplayDate) {
                startLoadMonth(for: date)
            } else {
                startLoadMonth(for: state.currentDisplayDate)
            }
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
}

// MARK: - State & Input

extension MonthlyCalendarViewModel {
    public struct State: Equatable {
        public internal(set) var currentDisplayDate: Date
        var monthDays: [MonthlyCalendarDay] = []
        var numberOfWeeks: Int = 5
        var monthYearText: String = ""
        var nickname: String? = nil

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.monthDays == rhs.monthDays
                && lhs.numberOfWeeks == rhs.numberOfWeeks
                && lhs.monthYearText == rhs.monthYearText
                && lhs.nickname == rhs.nickname
        }
    }

    public enum Input {
        case loadNickname
        case loadInitialData
        case selectMonth(Date)
        case selectDay(Date)
        case refreshCurrentMonth
        case updateMonth(Date)
    }

    public enum Event {
        case navigateToDetail(date: Date, records: [FoodRecord])
        case showError(Error)
    }
}
