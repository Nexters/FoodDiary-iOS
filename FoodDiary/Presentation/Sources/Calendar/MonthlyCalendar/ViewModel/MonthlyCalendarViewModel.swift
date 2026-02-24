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

    // MARK: - Dependencies

    private let fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase<RecordRepo>
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    private let getNicknameUseCase: GetNicknameUseCase

    // MARK: - Init

    public init(
        fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase<RecordRepo>,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>,
        getNicknameUseCase: GetNicknameUseCase
    ) {
        self.fetchMonthlyCalendarDaysUseCase = fetchMonthlyCalendarDaysUseCase
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
        self.getNicknameUseCase = getNicknameUseCase

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
            state.nickname = getNicknameUseCase.execute()
            await requestPhotoAuthorizationIfNeeded()
            await loadMonth(for: state.currentDisplayDate)

        case .selectMonth(let date):
            state.currentDisplayDate = date
            await loadMonth(for: state.currentDisplayDate)

        case .selectDay(let date):
            do {
                let records = try await fetchFoodRecordsUseCase.execute(for: date)
                eventSubject.send(.navigateToDetail(date: date, records: records))
            } catch {
                eventSubject.send(.showError(error))
            }
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadMonth(for date: Date) async {
        state.currentDisplayDate = date
        state.monthYearText = date.formatMonthText()

        let period = Calendar.current.monthlyCalendarPeriod(for: date)

        do {
            let monthDays = try await fetchMonthlyCalendarDaysUseCase.execute(for: period, currentMonth: date)
            state.monthDays = monthDays
            state.numberOfWeeks = monthDays.count / 7
        } catch {
            print("Failed to load monthly calendar: \(error)")
        }
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
        case loadInitialData
        case selectMonth(Date)
        case selectDay(Date)
    }

    public enum Event {
        case navigateToDetail(date: Date, records: [FoodRecord])
        case showError(Error)
    }
}
