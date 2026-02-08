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
    ImageProvider: RenderableImageRepository
> where ImageProvider.Asset == AssetRepo.Asset {
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
    private var lastLoadedDate: Date?
    private var weekDayIndexByDate: [Date: Int] = [:]
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    private let loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, ImageProvider>

    // MARK: - Init

    public init(
        fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>,
        foodRecordRepository: RecordRepo,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        imageProvider: ImageProvider
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase

        self.calendar = Calendar.current

        let today = calendar.startOfDay(for: Date())
        self.currentWeekBaseDate = today
        self.stateSubject = CurrentValueSubject(State(selectedDate: today))
        self.loadWeeklyCalendarDataUseCase = LoadWeeklyRecordUseCase(
            calendar: calendar,
            recordRepository: foodRecordRepository,
            fetchFoodImageAssetUseCase: fetchFoodImageAssetUseCase
        )
        self.saveFoodRecordUseCase = SaveFoodRecordUseCase(
            repository: foodRecordRepository,
            imageProvider: imageProvider
        )

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
        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
            async let weekLoad = loadWeekData(for: currentWeekBaseDate)
            async let dateLoad = loadDateData(of: state.selectedDate, forceReload: true)
            _ = await (weekLoad, dateLoad)

        case .requestPhotoAuthorization:
            let status = await requestPhotoAuthorizationUseCase.execute()
            if status == .denied || status == .restricted {
                eventSubject.send(.photoAuthorizationDenied)
            } else {
                await loadDateData(of: state.selectedDate, forceReload: true)
            }

        case .goToPreviousWeek:
            currentWeekBaseDate = calendar.previousWeek(from: currentWeekBaseDate)
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            async let weekLoad = loadWeekData(for: currentWeekBaseDate)
            async let dateLoad = loadDateData(of: state.selectedDate)
            _ = await (weekLoad, dateLoad)

        case .goToNextWeek:
            currentWeekBaseDate = calendar.nextWeek(from: currentWeekBaseDate)
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            async let weekLoad = loadWeekData(for: currentWeekBaseDate)
            async let dateLoad = loadDateData(of: state.selectedDate)
            _ = await (weekLoad, dateLoad)

        case .selectDate(let date):
            if !calendar.isDate(state.selectedDate, inSameDayAs: date) {
                state.selectedDate = date
                refreshDerivedState()
                await loadDateData(of: state.selectedDate)
            }

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)
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
            rebuildWeekDayIndex()
            state.monthText = weekData.monthText
        } catch {
            print("Failed to load week data: \(error)")
        }
    }

    @MainActor
    private func loadDateData(of selectedDate: Date, forceReload: Bool = false) async {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        if !forceReload, let lastLoadedDate,
            calendar.isDate(lastLoadedDate, inSameDayAs: startOfDay)
        {
            return
        }
        do {
            let dateData = try await loadWeeklyCalendarDataUseCase.loadDateData(for: selectedDate)
            state.selectedDatePhotos = dateData.photos
            refreshDerivedState()

            state.selectedDateRecords = dateData.records
            lastLoadedDate = dateData.startOfDay
        } catch {
            print("Failed to load selected date data: \(error)")
        }
    }

    private func savePhotosAsRecord(_ assets: [AssetRepo.Asset]) async {
        guard !assets.isEmpty else { return }

        do {
            // 이미지 로드 → 서버 업로드 → PendingRecord 반환
            let pendingRecord = try await saveFoodRecordUseCase.execute(
                from: assets,
                date: state.selectedDate
            )
            state.pendingRecords.insert(pendingRecord, at: 0)
            refreshDerivedState()
            eventSubject.send(.uploadCompleted(pendingRecord))
        } catch {
            eventSubject.send(.saveFailed(error))
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
            state.selectedDate = newSelectedDate
            refreshDerivedState()
        }
    }

    private func requestPhotoAuthorizationIfNeeded() async {
        let status = requestPhotoAuthorizationUseCase.currentStatus()
        if status == .notDetermined {
            _ = await requestPhotoAuthorizationUseCase.execute()
        }
    }

    /// weekDays 내 특정 날짜의 records를 업데이트
    private func updateWeekDayRecords(for date: Date, records: [FoodRecord]) {
        let normalizedDate = calendar.startOfDay(for: date)
        guard let index = weekDayIndexByDate[normalizedDate] else { return }

        let existingDay = state.weekDays[index]
        state.weekDays[index] = WeeklyCalendarDay(
            date: existingDay.date,
            dayOfWeek: existingDay.dayOfWeek,
            dayNumber: existingDay.dayNumber,
            isToday: existingDay.isToday,
            isFuture: existingDay.isFuture,
            records: records
        )
    }

    private func rebuildWeekDayIndex() {
        weekDayIndexByDate = Dictionary(
            uniqueKeysWithValues: state.weekDays.enumerated().map { index, day in
                (calendar.startOfDay(for: day.date), index)
            }
        )
    }

    private func refreshDerivedState() {
        state.foodPhotoCountCache =
            state.selectedDatePhotos.filter {
                $0.foodProbability >= State.foodProbabilityThreshold
            }.count
        state.selectedDatePendingRecordsCache = state.pendingRecords.filter {
            calendar.isDate($0.date, inSameDayAs: state.selectedDate)
        }
    }

    /// 사진 추가 전 권한 체크
    public func checkPhotoAuthorizationForAddingPhoto() -> Bool {
        requestPhotoAuthorizationUseCase.isAuthorized()
    }
}

// MARK: - State

extension WeeklyCalendarViewModel {
    public struct State: Equatable {
        fileprivate static var foodProbabilityThreshold: Float { 0.6 }

        public internal(set) var weekDays: [WeeklyCalendarDay] = []
        public internal(set) var selectedDate: Date = Date()
        public internal(set) var monthText: String = ""
        public internal(set) var selectedDateRecords: [FoodRecord] = []
        public internal(set) var pendingRecords: [PendingFoodRecord] = []
        public internal(set) var selectedDatePhotos: [FoodImageAsset<AssetRepo.Asset>] = []
        public internal(set) var isLoading: Bool = false
        public internal(set) var isSaving: Bool = false
        public internal(set) var foodPhotoCountCache: Int = 0
        public internal(set) var selectedDatePendingRecordsCache: [PendingFoodRecord] = []

        /// 음식으로 판별된 사진 개수
        public var foodPhotoCount: Int {
            foodPhotoCountCache
        }

        /// 선택된 날짜의 대기 중인 기록
        public var selectedDatePendingRecords: [PendingFoodRecord] {
            selectedDatePendingRecordsCache
        }

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.weekDays == rhs.weekDays
                && Calendar.current.isDate(lhs.selectedDate, inSameDayAs: rhs.selectedDate)
                && lhs.monthText == rhs.monthText
                && lhs.selectedDateRecords == rhs.selectedDateRecords
                && lhs.pendingRecords == rhs.pendingRecords
                && lhs.isLoading == rhs.isLoading
                && lhs.isSaving == rhs.isSaving
        }
    }

    public enum Input {
        case loadInitialData
        case requestPhotoAuthorization
        case goToPreviousWeek
        case goToNextWeek
        case selectDate(Date)
        case saveSelectedPhotos([AssetRepo.Asset])
    }

    public enum Event {
        case photoAuthorizationDenied
        case uploadCompleted(PendingFoodRecord)
        case saveFailed(Error)
    }
}
