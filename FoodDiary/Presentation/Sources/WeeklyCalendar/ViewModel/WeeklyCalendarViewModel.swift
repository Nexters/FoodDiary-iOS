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
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    private let loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, ImageProvider>

    // MARK: - Init

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, ImageProvider>
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.loadWeeklyCalendarDataUseCase = loadWeeklyCalendarDataUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase

        self.calendar = Calendar.current

        let today = calendar.startOfDay(for: Date())
        self.currentWeekBaseDate = today
        self.stateSubject = CurrentValueSubject(State(selectedDate: today))

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
            async let weekLoad: Void = loadWeekData(for: currentWeekBaseDate)
            async let dateLoad: Void = loadDateData(of: state.selectedDate, forceReload: true)
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
            async let weekLoad: Void = loadWeekData(for: currentWeekBaseDate)
            async let dateLoad: Void = loadDateData(of: state.selectedDate)
            _ = await (weekLoad, dateLoad)

        case .goToNextWeek:
            let nextWeek = calendar.nextWeek(from: currentWeekBaseDate)
            let today = calendar.startOfDay(for: Date())
            guard nextWeek <= today else { return }

            currentWeekBaseDate = nextWeek
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            async let weekLoad: Void = loadWeekData(for: currentWeekBaseDate)
            async let dateLoad: Void = loadDateData(of: state.selectedDate)
            _ = await (weekLoad, dateLoad)

        case .selectDate(let date):
            if !calendar.isDate(state.selectedDate, inSameDayAs: date) {
                state.selectedDate = date
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
            state.monthText = weekData.monthText
        } catch {
            eventSubject.send(.loadFailed(error))
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
            state.selectedDateRecords = dateData.records
            lastLoadedDate = dateData.startOfDay
        } catch {
            eventSubject.send(.loadFailed(error))
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
            let dateKey = calendar.startOfDay(for: pendingRecord.date)
            state.pendingRecordsByDate[dateKey, default: []].insert(pendingRecord, at: 0)
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

// MARK: - State
extension WeeklyCalendarViewModel {
    public struct State: Equatable {
        fileprivate static var foodProbabilityThreshold: Float { 0.6 }

        public internal(set) var weekDays: [WeeklyCalendarDay] = []
        public internal(set) var selectedDate: Date = Date()
        public internal(set) var monthText: String = ""
        public internal(set) var selectedDateRecords: [FoodRecord] = []
        public internal(set) var pendingRecordsByDate: [Date: [PendingFoodRecord]] = [:]
        public internal(set) var selectedDatePhotos: [FoodImageAsset<AssetRepo.Asset>] = []
        public internal(set) var isLoading: Bool = false

        public static func == (lhs: Self, rhs: Self) -> Bool {
            lhs.weekDays == rhs.weekDays
                && Calendar.current.isDate(lhs.selectedDate, inSameDayAs: rhs.selectedDate)
                && lhs.monthText == rhs.monthText
                && lhs.selectedDateRecords == rhs.selectedDateRecords
                && lhs.pendingRecordsByDate == rhs.pendingRecordsByDate
                && lhs.isLoading == rhs.isLoading
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
        case loadFailed(Error)
    }
}

// MARK: - Public Methods

extension WeeklyCalendarViewModel {
    /// 특정 사진 배열의 음식 사진 개수
    public func foodPhotoCount(for photos: [FoodImageAsset<AssetRepo.Asset>]) -> Int {
        photos.filter { $0.foodProbability >= State.foodProbabilityThreshold }.count
    }

    /// 특정 날짜의 대기 중인 기록
    public func pendingRecords(for date: Date) -> [PendingFoodRecord] {
        let dateKey = Calendar.current.startOfDay(for: date)
        return state.pendingRecordsByDate[dateKey] ?? []
    }

    /// 다음 주로 이동 가능 여부
    public func canGoToNextWeek(from date: Date) -> Bool {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        let today = calendar.startOfDay(for: Date())
        return calendar.startOfDay(for: nextWeek) <= today
    }
}
