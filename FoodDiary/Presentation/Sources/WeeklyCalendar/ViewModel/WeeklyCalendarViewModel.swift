//
//  WeeklyCalendarViewModel.swift
//  Presentation
//

import Combine
import Domain
import Foundation

public final class WeeklyCalendarViewModel<
    RecordRepo: FoodRecordRepository,
    AssetRepo: FoodImageAssetRepository
> {
    // MARK: - Output (Publishers)

    public var weekDaysPublisher: AnyPublisher<[WeeklyCalendarDay], Never> {
        weekDaysSubject.eraseToAnyPublisher()
    }

    public var selectedDatePublisher: AnyPublisher<Date, Never> {
        selectedDateSubject.eraseToAnyPublisher()
    }

    public var monthTextPublisher: AnyPublisher<String, Never> {
        monthTextSubject.eraseToAnyPublisher()
    }

    public var selectedDateRecordsPublisher: AnyPublisher<[FoodRecord], Never> {
        selectedDateRecordsSubject.eraseToAnyPublisher()
    }

    public var selectedDatePhotosPublisher: AnyPublisher<[FoodImageAsset<AssetRepo.Asset>], Never> {
        selectedDatePhotosSubject.eraseToAnyPublisher()
    }

    public var isLoadingPublisher: AnyPublisher<Bool, Never> {
        isLoadingSubject.eraseToAnyPublisher()
    }

    // MARK: - Input (Subjects)

    public let loadInitialData = PassthroughSubject<Void, Never>()
    public let goToPreviousWeek = PassthroughSubject<Void, Never>()
    public let goToNextWeek = PassthroughSubject<Void, Never>()
    public let selectDate = PassthroughSubject<Date, Never>()

    // MARK: - Private Subjects

    private let weekDaysSubject = CurrentValueSubject<[WeeklyCalendarDay], Never>([])
    private let selectedDateSubject: CurrentValueSubject<Date, Never>
    private let monthTextSubject = CurrentValueSubject<String, Never>("")
    private let selectedDateRecordsSubject = CurrentValueSubject<[FoodRecord], Never>([])
    private let selectedDatePhotosSubject = CurrentValueSubject<[FoodImageAsset<AssetRepo.Asset>], Never>([])
    private let isLoadingSubject = CurrentValueSubject<Bool, Never>(false)

    // MARK: - Dependencies

    private let fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>
    private let foodImageAssetFetchUseCase: FoodImageAssetFetchUseCase<AssetRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>

    // MARK: - Private State

    private var currentWeekBaseDate: Date
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>,
        foodImageAssetFetchUseCase: FoodImageAssetFetchUseCase<AssetRepo>,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    ) {
        self.fetchWeeklyCalendarUseCase = fetchWeeklyCalendarUseCase
        self.foodImageAssetFetchUseCase = foodImageAssetFetchUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase

        let today = Date()
        self.currentWeekBaseDate = today
        self.selectedDateSubject = CurrentValueSubject(today)

        setupBindings()
    }

    // MARK: - Setup

    private func setupBindings() {
        loadInitialData
            .sink { [weak self] in
                guard let self else { return }
                Task {
                    await self.loadWeekData(for: self.currentWeekBaseDate)
                    await self.loadSelectedDateData()
                }
            }
            .store(in: &cancellables)

        goToPreviousWeek
            .sink { [weak self] in
                guard let self else { return }
                Task {
                    self.currentWeekBaseDate = self.fetchWeeklyCalendarUseCase.previousWeek(
                        from: self.currentWeekBaseDate
                    )
                    await self.loadWeekData(for: self.currentWeekBaseDate)
                }
            }
            .store(in: &cancellables)

        goToNextWeek
            .sink { [weak self] in
                guard let self else { return }
                Task {
                    self.currentWeekBaseDate = self.fetchWeeklyCalendarUseCase.nextWeek(
                        from: self.currentWeekBaseDate
                    )
                    await self.loadWeekData(for: self.currentWeekBaseDate)
                }
            }
            .store(in: &cancellables)

        selectDate
            .sink { [weak self] date in
                guard let self else { return }
                self.selectedDateSubject.send(date)
                Task {
                    await self.loadSelectedDateData()
                }
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func loadWeekData(for date: Date) async {
        isLoadingSubject.send(true)
        defer { isLoadingSubject.send(false) }

        do {
            let weekDays = try await fetchWeeklyCalendarUseCase.execute(for: date)
            weekDaysSubject.send(weekDays)
            monthTextSubject.send(fetchWeeklyCalendarUseCase.formatMonthText(for: date))
        } catch {
            // 에러 처리 (추후 에러 상태 추가 가능)
            print("Failed to load week data: \(error)")
        }
    }

    private func loadSelectedDateData() async {
        let selectedDate = selectedDateSubject.value
        let calendar = Calendar.current
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)

        do {
            // 로컬 갤러리에서 해당 날짜 사진 조회
            let photosByDate = try await foodImageAssetFetchUseCase.execute(
                from: startOfDay,
                to: endOfDay
            )
            selectedDatePhotosSubject.send(photosByDate[startOfDay] ?? [])

            // 서버 기록 조회
            let records = try await fetchFoodRecordsUseCase.execute(for: selectedDate)
            selectedDateRecordsSubject.send(records)
        } catch {
            print("Failed to load selected date data: \(error)")
        }
    }
}
