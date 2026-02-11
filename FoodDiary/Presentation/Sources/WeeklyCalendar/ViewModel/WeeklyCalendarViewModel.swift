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
    ImageProvider: RenderableImageRepository,
    PendingRepo: PendingFoodRecordRepository,
    AnalysisRepo: AnalysisResultRepository
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

    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>
    private let loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, ImageProvider, PendingRepo>
    private let restorePendingRecordsUseCase: RestorePendingRecordsUseCase<PendingRepo>
    private let checkPendingAnalysisUseCase: CheckPendingAnalysisUseCase<PendingRepo, AnalysisRepo>
    private let pushNotificationObserver: PushNotificationObserving

    // MARK: - Init

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, ImageProvider, PendingRepo>,
        restorePendingRecordsUseCase: RestorePendingRecordsUseCase<PendingRepo>,
        checkPendingAnalysisUseCase: CheckPendingAnalysisUseCase<PendingRepo, AnalysisRepo>,
        pushNotificationObserver: PushNotificationObserving
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.loadWeeklyCalendarDataUseCase = loadWeeklyCalendarDataUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.restorePendingRecordsUseCase = restorePendingRecordsUseCase
        self.checkPendingAnalysisUseCase = checkPendingAnalysisUseCase
        self.pushNotificationObserver = pushNotificationObserver

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

        pushNotificationObserver.analysisResultPublisher
            .sink { [weak self] uploadId in
                self?.input.send(.handlePushNotification(uploadId: uploadId))
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func handleInput(_ action: Input) async {
        switch action {
        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
            await restorePendingRecords()
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)
            await checkPendingAnalysisStatus()

        case .requestPhotoAuthorization:
            let status = await requestPhotoAuthorizationUseCase.execute()
            if status == .denied || status == .restricted {
                eventSubject.send(.photoAuthorizationDenied)
            }

        case .goToPreviousWeek:
            currentWeekBaseDate = calendar.previousWeek(from: currentWeekBaseDate)
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)

        case .goToNextWeek:
            let nextWeek = calendar.nextWeek(from: currentWeekBaseDate)
            let today = calendar.startOfDay(for: Date())
            guard nextWeek <= today else { return }

            currentWeekBaseDate = nextWeek
            updateSelectedDateToSameWeekday(in: currentWeekBaseDate)
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)

        case .selectDate(let date):
            if !calendar.isDate(state.selectedDate, inSameDayAs: date) {
                state.selectedDate = date
                await updateDateContent(for: date)
            }

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)

        case .checkPendingAnalysisStatus:
            await checkPendingAnalysisStatus()

        case .handlePushNotification(let uploadId):
            await handlePushNotification(uploadId: uploadId)
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
    private func updateDateContent(for date: Date) async {
        do {
            let dateData = try await loadWeeklyCalendarDataUseCase.loadDateData(for: date)
            state.dateContent = DateContent(
                records: dateData.records,
                pendingRecords: pendingRecords(for: date),
                foodPhotoCount: countFoodPhotos(in: dateData.photos)
            )
        } catch {
            eventSubject.send(.loadFailed(error))
        }
    }


    @MainActor
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
            await updateDateContent(for: state.selectedDate)
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

    // MARK: - Pending Records

    @MainActor
    private func restorePendingRecords() async {
        do {
            let pendingRecords = try await restorePendingRecordsUseCase.execute()
            for record in pendingRecords {
                let dateKey = calendar.startOfDay(for: record.date)
                state.pendingRecordsByDate[dateKey, default: []].append(record)
            }
        } catch {
            // 복원 실패는 치명적이지 않음
        }
    }

    @MainActor
    private func checkPendingAnalysisStatus() async {
        let allPendingUploadIds = state.pendingRecordsByDate.values
            .flatMap { $0 }
            .map { $0.uploadId }

        guard !allPendingUploadIds.isEmpty else { return }

        do {
            let result = try await checkPendingAnalysisUseCase.execute(for: allPendingUploadIds)

            for (uploadId, _) in result.completedRecords {
                removePendingRecord(uploadId: uploadId)
            }

            for (uploadId, reason) in result.failedUploadIds {
                removePendingRecord(uploadId: uploadId)
                eventSubject.send(.analysisFailed(uploadId: uploadId, reason: reason))
            }
        } catch {
            // 폴링 실패는 무시 (다음에 다시 시도)
        }
    }

    @MainActor
    private func handlePushNotification(uploadId: String) async {
        do {
            let result = try await checkPendingAnalysisUseCase.execute(for: [uploadId])

            if let completed = result.completedRecords.first {
                removePendingRecord(uploadId: completed.uploadId)
            } else if let failed = result.failedUploadIds.first {
                removePendingRecord(uploadId: failed.uploadId)
                eventSubject.send(.analysisFailed(uploadId: failed.uploadId, reason: failed.reason))
            }
        } catch {
            // Push 처리 실패는 무시
        }
    }

    @MainActor
    private func removePendingRecord(uploadId: String) {
        for (date, records) in state.pendingRecordsByDate {
            state.pendingRecordsByDate[date] = records.filter { $0.uploadId != uploadId }
        }
        updatePendingRecordsInDateContent()
    }

    @MainActor
    private func updatePendingRecordsInDateContent() {
        guard let currentContent = state.dateContent else { return }
        let updatedPendingRecords = pendingRecords(for: state.selectedDate)
        state.dateContent = DateContent(
            records: currentContent.records,
            pendingRecords: updatedPendingRecords,
            foodPhotoCount: currentContent.foodPhotoCount
        )
    }
}

// MARK: - State
extension WeeklyCalendarViewModel {
    public struct State: Equatable {
        fileprivate static var foodProbabilityThreshold: Float { 0.6 }

        public internal(set) var weekDays: [WeeklyCalendarDay] = []
        public internal(set) var selectedDate: Date = Date()
        public internal(set) var monthText: String = ""
        public internal(set) var pendingRecordsByDate: [Date: [PendingFoodRecord]] = [:]
        public internal(set) var isLoading: Bool = false
        public internal(set) var dateContent: DateContent?
    }

    public enum Input {
        case loadInitialData
        case requestPhotoAuthorization
        case goToPreviousWeek
        case goToNextWeek
        case selectDate(Date)
        case saveSelectedPhotos([AssetRepo.Asset])
        case checkPendingAnalysisStatus
        case handlePushNotification(uploadId: String)
    }

    public enum Event {
        case photoAuthorizationDenied
        case uploadCompleted(PendingFoodRecord)
        case saveFailed(Error)
        case loadFailed(Error)
        case analysisFailed(uploadId: String, reason: String)
    }
}

// MARK: - DateContent

extension WeeklyCalendarViewModel {
    public struct DateContent: Equatable {
        public let records: [FoodRecord]
        public let pendingRecords: [PendingFoodRecord]
        public let foodPhotoCount: Int
    }
}

// MARK: - Public Methods

extension WeeklyCalendarViewModel {
    /// 다음 주로 이동 가능 여부
    public func canGoToNextWeek(from date: Date) -> Bool {
        let calendar = Calendar.current
        let nextWeek = calendar.date(byAdding: .weekOfYear, value: 1, to: date) ?? date
        let today = calendar.startOfDay(for: Date())
        return calendar.startOfDay(for: nextWeek) <= today
    }

    /// 특정 날짜의 사진 로드
    public func photos(for date: Date) async throws -> [FoodImageAsset<AssetRepo.Asset>] {
        let dateData = try await loadWeeklyCalendarDataUseCase.loadDateData(for: date)
        return dateData.photos
    }

    // MARK: - Private Helpers

    /// 특정 날짜의 대기 중인 기록
    private func pendingRecords(for date: Date) -> [PendingFoodRecord] {
        let dateKey = Calendar.current.startOfDay(for: date)
        return state.pendingRecordsByDate[dateKey] ?? []
    }

    /// 특정 사진 배열의 음식 사진 개수
    private func countFoodPhotos(in photos: [FoodImageAsset<AssetRepo.Asset>]) -> Int {
        photos.filter { $0.foodProbability >= State.foodProbabilityThreshold }.count
    }
}
