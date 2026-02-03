//
//  MonthlyCalendarViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class MonthlyCalendarViewModel<
    RecordRepo: FoodRecordRepository,
    AuthRepo: PhotoAuthorizationRepository
> {
    // MARK: - Output

    var statePublisher: AnyPublisher<State, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    private(set) var state: State {
        get { stateSubject.value }
        set { stateSubject.value = newValue }
    }

    // MARK: - Input

    let input = PassthroughSubject<Input, Never>()

    // MARK: - Private

    private let stateSubject: CurrentValueSubject<State, Never>
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let fetchMonthlyCalendarUseCase: FetchMonthlyCalendarUseCase<RecordRepo>
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>

    // MARK: - Init

    public init(
        fetchMonthlyCalendarUseCase: FetchMonthlyCalendarUseCase<RecordRepo>,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    ) {
        self.fetchMonthlyCalendarUseCase = fetchMonthlyCalendarUseCase
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase

        let today = Date()
        self.stateSubject = CurrentValueSubject(State(currentDisplayDate: today))

        setupBindings()
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
        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
            await loadMonth(for: state.currentDisplayDate)

        case .selectMonth(let date):
            state.currentDisplayDate = date
            await loadMonth(for: state.currentDisplayDate)
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadMonth(for date: Date) async {
        var calendar = Calendar.current
        calendar.firstWeekday = 2

        let monthDays = generateMonthDays(for: date, calendar: calendar)
        let numberOfWeeks = monthDays.count / 7

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "ko_KR")
        formatter.dateFormat = "yyyy년 M월"

        state.currentDisplayDate = date
        state.monthDays = monthDays
        state.numberOfWeeks = numberOfWeeks
        state.monthYearText = formatter.string(from: date)

        // 음식 기록 데이터 로드
        await loadFoodRecords(for: monthDays)
    }

    @MainActor
    private func loadFoodRecords(for monthDays: [MonthlyCalendarDay]) async {
        do {
            state.monthDays = try await fetchMonthlyCalendarUseCase.execute(for: monthDays)
        } catch {
            print("Failed to load food records: \(error)")
        }
    }

    private func requestPhotoAuthorizationIfNeeded() async {
        let status = requestPhotoAuthorizationUseCase.currentStatus()
        if status == .notDetermined {
            _ = await requestPhotoAuthorizationUseCase.execute()
        }
    }

    // 달력을 만드는 메소드
    private func generateMonthDays(for date: Date, calendar: Calendar) -> [MonthlyCalendarDay] {
        guard let monthInterval = calendar.dateInterval(of: .month, for: date),
              let firstWeekday = calendar.dateComponents([.weekday], from: monthInterval.start).weekday
        else {
            return []
        }

        let today = calendar.startOfDay(for: Date())
        let leadingCount = (firstWeekday - calendar.firstWeekday + 7) % 7

        var days: [MonthlyCalendarDay] = []
        days += generateLeadingDays(before: monthInterval.start, count: leadingCount, today: today, calendar: calendar)
        days += generateCurrentMonthDays(in: monthInterval, today: today, calendar: calendar)
        days += generateTrailingDays(after: monthInterval.end, currentCount: days.count, today: today, calendar: calendar)
        return days
    }

    // 이전 달
    private func generateLeadingDays(
        before monthStart: Date,
        count: Int,
        today: Date,
        calendar: Calendar
    ) -> [MonthlyCalendarDay] {
        guard count > 0 else { return [] }
        return (0..<count).reversed().compactMap { i in
            calendar.date(byAdding: .day, value: -(i + 1), to: monthStart).map {
                makeDay(date: $0, isCurrentMonth: false, today: today, calendar: calendar)
            }
        }
    }

    // 이번 달
    private func generateCurrentMonthDays(
        in interval: DateInterval,
        today: Date,
        calendar: Calendar
    ) -> [MonthlyCalendarDay] {
        var days: [MonthlyCalendarDay] = []
        var currentDate = interval.start
        while currentDate < interval.end {
            days.append(makeDay(date: currentDate, isCurrentMonth: true, today: today, calendar: calendar))
            guard let next = calendar.date(byAdding: .day, value: 1, to: currentDate) else { break }
            currentDate = next
        }
        return days
    }

    // 다음 달
    private func generateTrailingDays(
        after monthEnd: Date,
        currentCount: Int,
        today: Date,
        calendar: Calendar
    ) -> [MonthlyCalendarDay] {
        let remainder = currentCount % 7
        guard remainder > 0 else { return [] }
        let trailingCount = 7 - remainder
        return (0..<trailingCount).compactMap { i in
            calendar.date(byAdding: .day, value: i, to: monthEnd).map {
                makeDay(date: $0, isCurrentMonth: false, today: today, calendar: calendar)
            }
        }
    }

    private func makeDay(
        date: Date,
        isCurrentMonth: Bool,
        today: Date,
        calendar: Calendar
    ) -> MonthlyCalendarDay {
        MonthlyCalendarDay(
            date: date,
            dayNumber: String(format: "%02d", calendar.component(.day, from: date)),
            isCurrentMonth: isCurrentMonth,
            isToday: calendar.isDate(date, inSameDayAs: today),
            records: []
        )
    }
}

// MARK: - State & Input

extension MonthlyCalendarViewModel {
    struct State: Equatable {
        var currentDisplayDate: Date
        var monthDays: [MonthlyCalendarDay] = []
        var numberOfWeeks: Int = 5
        var monthYearText: String = ""

        static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.monthDays == rhs.monthDays
                && lhs.numberOfWeeks == rhs.numberOfWeeks
                && lhs.monthYearText == rhs.monthYearText
        }
    }

    enum Input {
        case loadInitialData
        case selectMonth(Date)
    }
}
