//
//  WeeklyCalendarViewModel.swift
//  Presentation
//

import Combine
import Data
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
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Dependencies

    private let fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>
    private let fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    private let imageProvider: ImageProvider

    // MARK: - Init

    public init(
        fetchWeeklyCalendarUseCase: FetchWeeklyCalendarUseCase<RecordRepo>,
        fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase<AssetRepo>,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>,
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        imageProvider: ImageProvider
    ) {
        self.fetchWeeklyCalendarUseCase = fetchWeeklyCalendarUseCase
        self.fetchFoodImageAssetUseCase = fetchFoodImageAssetUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.imageProvider = imageProvider

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
            await loadWeekData(for: currentWeekBaseDate)
            await loadDateData(of: state.selectedDate)

        case .requestPhotoAuthorization:
            let status = await requestPhotoAuthorizationUseCase.execute()
            if status == .denied || status == .restricted {
                eventSubject.send(.photoAuthorizationDenied)
            } else {
                await loadDateData(of: state.selectedDate)
            }

        case .goToPreviousWeek:
            currentWeekBaseDate = calendar.previousWeek(from: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            await loadDateData(of: state.selectedDate)

        case .goToNextWeek:
            currentWeekBaseDate = calendar.nextWeek(from: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            await loadDateData(of: state.selectedDate)

        case .selectDate(let date):
            state.selectedDate = date
            await loadDateData(of: state.selectedDate)

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)
        }
    }

    // MARK: - Private Methods

    @MainActor
    private func loadWeekData(for date: Date) async {
        state.isLoading = true
        defer { state.isLoading = false }

        // 주간 사진 캐시 워밍
        fetchFoodImageAssetUseCase.prefetch(for: date)

        do {
            let weekDays = try await fetchWeeklyCalendarUseCase.execute(for: date)
            state.weekDays = weekDays
            state.monthText = date.formatMonthText()
        } catch {
            print("Failed to load week data: \(error)")
        }
    }

    @MainActor
    private func loadDateData(of selectedDate: Date) async {
        let startOfDay = calendar.startOfDay(for: selectedDate)
        let endOfDay = calendar.date(byAdding: .day, value: 1, to: startOfDay)

        do {
            let photosByDate = try await fetchFoodImageAssetUseCase.execute(
                from: startOfDay,
                to: endOfDay
            )
            state.selectedDatePhotos = photosByDate[startOfDay] ?? []

            let records = try await fetchFoodRecordsUseCase.execute(for: selectedDate)
            state.selectedDateRecords = records
        } catch {
            print("Failed to load selected date data: \(error)")
        }
    }

    private func savePhotosAsRecord(_ assets: [AssetRepo.Asset]) async {
        guard !assets.isEmpty else { return }

        // 1. 백그라운드에서 모든 이미지 로드
        let images: [UIImage]
        do {
            images = try await loadImages(from: assets)
        } catch {
            eventSubject.send(.saveFailed(error))
            return
        }

        // 2. 대표 이미지로 PendingFoodRecord 생성
        let pendingRecord = PendingFoodRecord(
            date: state.selectedDate,
            representativeImage: images[0]
        )
        state.pendingRecords.insert(pendingRecord, at: 0)

        // 3. 백그라운드에서 서버 저장
        let request = CreateFoodRecordRequest(
            date: state.selectedDate,
            images: images
        )

        do {
            let savedRecord = try await BackgroundTaskManager.shared.performBackgroundTask(
                named: "SaveFoodRecord"
            ) { [saveFoodRecordUseCase] in
                try await saveFoodRecordUseCase.execute(request)
            }

            state.selectedDateRecords.insert(savedRecord, at: 0)
            eventSubject.send(.saveCompleted(savedRecord))

            // 백그라운드 상태면 푸시 알림 발송
            if UIApplication.shared.applicationState != .active {
                LocalNotificationService().sendRecordSavedNotification(
                    restaurantName: savedRecord.restaurantName
                )
            }
        } catch {
            // 5. 실패: pending 제거, 에러 이벤트
            state.pendingRecords.removeAll { $0.id == pendingRecord.id }
            eventSubject.send(.saveFailed(error))

            // 백그라운드 상태면 실패 푸시 알림
            if UIApplication.shared.applicationState != .active {
                LocalNotificationService().sendRecordFailedNotification()
            }
        }
    }

    /// 여러 asset을 병렬로 로드하여 UIImage 배열로 반환
    private func loadImages(from assets: [AssetRepo.Asset]) async throws -> [UIImage] {
        try await withThrowingTaskGroup(of: (Int, UIImage).self) { group in
            for (index, asset) in assets.enumerated() {
                group.addTask {
                    let image = try await self.imageProvider.loadImage(
                        for: asset,
                        targetSize: CGSize(width: 1200, height: 1200)
                    )
                    return (index, image)
                }
            }

            var results: [(Int, UIImage)] = []
            for try await result in group {
                results.append(result)
            }
            return results.sorted(by: { $0.0 < $1.0 }).map { $0.1 }
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
        private static var foodProbabilityThreshold: Float { 0.6 }

        public internal(set) var weekDays: [WeeklyCalendarDay] = []
        public internal(set) var selectedDate: Date = Date()
        public internal(set) var monthText: String = ""
        public internal(set) var selectedDateRecords: [FoodRecord] = []
        public internal(set) var pendingRecords: [PendingFoodRecord] = []
        public internal(set) var selectedDatePhotos: [FoodImageAsset<AssetRepo.Asset>] = []
        public internal(set) var isLoading: Bool = false
        public internal(set) var isSaving: Bool = false

        /// 음식으로 판별된 사진 개수
        public var foodPhotoCount: Int {
            selectedDatePhotos.filter { $0.foodProbability >= Self.foodProbabilityThreshold }.count
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
        case saveCompleted(FoodRecord)
        case saveFailed(Error)
    }
}
