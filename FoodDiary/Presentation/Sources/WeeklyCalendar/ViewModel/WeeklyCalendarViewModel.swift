//
//  WeeklyCalendarViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

// MARK: - State

public struct WeeklyCalendarState<Asset: ImageAssetable>: Equatable {
    public internal(set) var weekDays: [WeeklyCalendarDay] = []
    public internal(set) var selectedDate: Date = Date()
    public internal(set) var monthText: String = ""
    public internal(set) var selectedDateRecords: [FoodRecord] = []
    public internal(set) var selectedDatePhotos: [FoodImageAsset<Asset>] = []
    public internal(set) var isLoading: Bool = false

    public static func == (lhs: Self, rhs: Self) -> Bool {
        lhs.weekDays == rhs.weekDays &&
        Calendar.current.isDate(lhs.selectedDate, inSameDayAs: rhs.selectedDate) &&
        lhs.monthText == rhs.monthText &&
        lhs.selectedDateRecords == rhs.selectedDateRecords &&
        lhs.isLoading == rhs.isLoading
    }
}

// MARK: - Input

public enum WeeklyCalendarInput {
    case loadInitialData
    case requestPhotoAuthorization
    case goToPreviousWeek
    case goToNextWeek
    case selectDate(Date)
}

// MARK: - Event (one-shot)

public enum WeeklyCalendarEvent {
    case photoAuthorizationDenied
}

// MARK: - ViewModel

public final class WeeklyCalendarViewModel<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository
> {
    // MARK: - Output

    public var statePublisher: AnyPublisher<WeeklyCalendarState<AssetRepo.Asset>, Never> {
        stateSubject.eraseToAnyPublisher()
    }

    public var state: WeeklyCalendarState<AssetRepo.Asset> {
        stateSubject.value
    }

    public var eventPublisher: AnyPublisher<WeeklyCalendarEvent, Never> {
        eventSubject.eraseToAnyPublisher()
    }

    // MARK: - Input

    public let input = PassthroughSubject<WeeklyCalendarInput, Never>()

    // MARK: - Private

    private let stateSubject: CurrentValueSubject<WeeklyCalendarState<AssetRepo.Asset>, Never>
    private let eventSubject = PassthroughSubject<WeeklyCalendarEvent, Never>()
    private var currentWeekBaseDate: Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>
    private let foodImageAssetFetchUseCase: FoodImageAssetFetchUseCase<AssetRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AssetRepo>

    // MARK: - Init

    public init(
        fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>,
        foodImageAssetFetchUseCase: FoodImageAssetFetchUseCase<AssetRepo>,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AssetRepo>
    ) {
        self.fetchWeeklyCalendarUseCase = fetchWeeklyCalendarUseCase
        self.foodImageAssetFetchUseCase = foodImageAssetFetchUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase

        let today = Date()
        self.currentWeekBaseDate = today
        self.stateSubject = CurrentValueSubject(WeeklyCalendarState(selectedDate: today))

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        input
            .sink { [weak self] action in
                guard let self else { return }
                Task { await self.handleInput(action) }
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func handleInput(_ action: WeeklyCalendarInput) async {
        switch action {
        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
            await loadWeekData(for: currentWeekBaseDate)
            await loadSelectedDateData()

        case .requestPhotoAuthorization:
            let status = await requestPhotoAuthorizationUseCase.execute()
            if status == .denied || status == .restricted {
                eventSubject.send(.photoAuthorizationDenied)
            } else {
                await loadSelectedDateData()
            }

        case .goToPreviousWeek:
            currentWeekBaseDate = fetchWeeklyCalendarUseCase.previousWeek(from: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)

        case .goToNextWeek:
            currentWeekBaseDate = fetchWeeklyCalendarUseCase.nextWeek(from: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)

        case .selectDate(let date):
            stateSubject.value.selectedDate = date
            await loadSelectedDateData()
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadWeekData(for date: Date) async {
        stateSubject.value.isLoading = true
        defer { stateSubject.value.isLoading = false }

        do {
            let weekDays = try await fetchWeeklyCalendarUseCase.execute(for: date)
            stateSubject.value.weekDays = weekDays
            stateSubject.value.monthText = fetchWeeklyCalendarUseCase.formatMonthText(for: date)
        } catch {
            print("Failed to load week data: \(error)")
        }
    }

    @MainActor
    private func loadSelectedDateData() async {
        let selectedDate = stateSubject.value.selectedDate
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)

        do {
            let photosByDate = try await foodImageAssetFetchUseCase.execute(
                from: startOfDay,
                to: endOfDay
            )
            stateSubject.value.selectedDatePhotos = photosByDate[startOfDay] ?? []

            let records = try await fetchFoodRecordsUseCase.execute(for: selectedDate)
            stateSubject.value.selectedDateRecords = records
        } catch {
            print("Failed to load selected date data: \(error)")
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
}
