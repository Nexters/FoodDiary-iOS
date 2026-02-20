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
    AnalysisRepo: AnalysisResultRepository,
    PushObserver: PushNotificationObserving
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
    private let loadPendingRecordsUseCase: LoadPendingRecordsUseCase<PendingRepo>
    private let syncPendingAnalysisUseCase: SyncPendingAnalysisUseCase<PendingRepo, AnalysisRepo>
    private let pushNotificationObserver: PushObserver

    // MARK: - Init

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<AuthRepo>,
        loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetRepo>,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo, ImageProvider, PendingRepo>,
        loadPendingRecordsUseCase: LoadPendingRecordsUseCase<PendingRepo>,
        syncPendingAnalysisUseCase: SyncPendingAnalysisUseCase<PendingRepo, AnalysisRepo>,
        pushNotificationObserver: PushObserver
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.loadWeeklyCalendarDataUseCase = loadWeeklyCalendarDataUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.loadPendingRecordsUseCase = loadPendingRecordsUseCase
        self.syncPendingAnalysisUseCase = syncPendingAnalysisUseCase
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
            .sink { [weak self] notification in
                self?.input.send(.handlePushNotification(notification))
            }
            .store(in: &cancellables)
    }

    @MainActor
    private func handleInput(_ action: Input) async {
        switch action {
        case .loadInitialData:
            await requestPhotoAuthorizationIfNeeded()
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
                await moveToWeekIfNeeded(for: date)
                await updateDateContent(for: date)
            }

        case .saveSelectedPhotos(let assets):
            await savePhotosAsRecord(assets)

        case .checkPendingAnalysisStatus:
            await checkPendingAnalysisStatus()

        case .handlePushNotification(let notification):
            await handlePushNotification(notification)

        case .refreshData:
            await loadWeekData(for: currentWeekBaseDate)
            await updateDateContent(for: state.selectedDate)
            await checkPendingAnalysisStatus()
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
            let startOfDay = calendar.startOfDay(for: date)
            let records = state.weekDays
                .first { calendar.isDate($0.date, inSameDayAs: startOfDay) }?
                .records ?? []

            let pendingRecords = try await loadPendingRecords(for: date)

            state.dateContent = DateContent(
                records: records,
                pendingRecords: pendingRecords
            )
        } catch {
            eventSubject.send(.loadFailed(error))
        }
    }

    @MainActor
    private func savePhotosAsRecord(_ assets: [AssetRepo.Asset]) async {
        guard !assets.isEmpty else { return }

        do {
            // 이미지 로드 → 서버 업로드 → PendingRecord 저장 (Repository)
            let pendingRecord = try await saveFoodRecordUseCase.execute(
                from: assets,
                date: state.selectedDate
            )
            await updateDateContent(for: state.selectedDate)
            eventSubject.send(.uploadCompleted(pendingRecord))
        } catch {
            eventSubject.send(.saveFailed(error))
        }
    }

    /// 선택된 날짜가 현재 표시 중인 주 범위 밖이면 해당 주로 이동
    private func moveToWeekIfNeeded(for date: Date) async {
        let (weekStart, weekEnd) = calendar.weekRange(for: currentWeekBaseDate)
        let dateStart = calendar.startOfDay(for: date)
        if !(weekStart...weekEnd).contains(dateStart) {
            currentWeekBaseDate = date
            await loadWeekData(for: currentWeekBaseDate)
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

    private func checkPendingAnalysisStatus() async {
        do {
            let result = try await syncPendingAnalysisUseCase.execute()
            processSyncResult(result)
        } catch {
            // 폴링 실패는 무시 (다음에 다시 시도)
        }
    }

    private func handlePushNotification(_ notification: AnalysisResultNotification) async {
        do {
            let syncResult = try await syncPendingAnalysisUseCase.execute(for: [
                notification.uploadId
            ])

            // 실패 이벤트는 항상 발행
            for (uploadId, reason) in syncResult.failedUploadIds {
                eventSubject.send(.analysisFailed(uploadId: uploadId, reason: reason))
            }

            let notificationDate = calendar.startOfDay(for: notification.date)
            let selectedDate = calendar.startOfDay(for: state.selectedDate)
            let (weekStart, weekEnd) = calendar.weekRange(for: currentWeekBaseDate)
            let currentWeekRange = weekStart...weekEnd

            // 완료된 레코드가 있으면 해당 날짜/주차 데이터 갱신
            if currentWeekRange.contains(notificationDate) {
                await loadWeekData(for: currentWeekBaseDate)
            }

            // selectedDate에 해당하는 변경사항이 있으면 dateContent 업데이트
            if notificationDate == selectedDate {
                await updateDateContent(for: state.selectedDate)
            }
        } catch {
            // Push 처리 실패는 무시
        }
    }

    private func processSyncResult(
        _ result: SyncPendingAnalysisUseCase<PendingRepo, AnalysisRepo>.Result
    ) {
        for (uploadId, reason) in result.failedUploadIds {
            eventSubject.send(.analysisFailed(uploadId: uploadId, reason: reason))
        }

        let selectedDateStart = calendar.startOfDay(for: state.selectedDate)

        let hasChangesForSelectedDate =
            result.completedRecords.contains { _, record in
                calendar.startOfDay(for: record.date) == selectedDateStart
            } || !result.failedUploadIds.isEmpty

        Task {
            await loadWeekData(for: currentWeekBaseDate)
            if hasChangesForSelectedDate {
                await updateDateContent(for: state.selectedDate)
            }
        }
    }

    private func loadPendingRecords(for date: Date) async throws -> [PendingFoodRecord] {
        let allRecords = try await loadPendingRecordsUseCase.execute()
        let dateKey = calendar.startOfDay(for: date)
        return allRecords.filter { calendar.startOfDay(for: $0.date) == dateKey }
    }
}

// MARK: - State
extension WeeklyCalendarViewModel {
    public struct State: Equatable {
        fileprivate static var foodProbabilityThreshold: Float { 0.6 }

        public internal(set) var weekDays: [WeeklyCalendarDay] = []
        public internal(set) var selectedDate: Date = Date()
        public internal(set) var monthText: String = ""
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
        case handlePushNotification(AnalysisResultNotification)
        case refreshData
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
}
