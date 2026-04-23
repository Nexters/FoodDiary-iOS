//
//  CalendarSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public final class CalendarSceneFactory {
    private typealias RecordRepo = FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>
    private typealias AssetFetcher = FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>

    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>
    private let loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<RecordRepo, AssetFetcher>
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase<RecordRepo>
    private let pushNotificationObserver: PushNotificationObserver
    private let getNicknameUseCase: GetNicknameUseCase
    private let coachmarkStorage: any CoachmarkStoring
    private let checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase
    private let fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase<RecordRepo>
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<RecordRepo>

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase<PhotoAuthorizationFetcher>,
        loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase<
            FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
            FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>
        >,
        saveFoodRecordUseCase: SaveFoodRecordUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        pushNotificationObserver: PushNotificationObserver,
        getNicknameUseCase: GetNicknameUseCase,
        coachmarkStorage: any CoachmarkStoring,
        checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase,
        fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase<FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.loadWeeklyCalendarDataUseCase = loadWeeklyCalendarDataUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
        self.getNicknameUseCase = getNicknameUseCase
        self.coachmarkStorage = coachmarkStorage
        self.checkAppReviewEligibilityUseCase = checkAppReviewEligibilityUseCase
        self.fetchMonthlyCalendarDaysUseCase = fetchMonthlyCalendarDaysUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
    }

    public func makeScene() -> CalendarViewController {
        let weeklyVM = WeeklyCalendarViewModel(
            requestPhotoAuthorizationUseCase: requestPhotoAuthorizationUseCase,
            loadWeeklyCalendarDataUseCase: loadWeeklyCalendarDataUseCase,
            saveFoodRecordUseCase: saveFoodRecordUseCase,
            pushNotificationObserver: pushNotificationObserver,
            getNicknameUseCase: getNicknameUseCase,
            coachmarkStorage: coachmarkStorage,
            checkAppReviewEligibilityUseCase: checkAppReviewEligibilityUseCase
        )
        let monthlyVM = MonthlyCalendarViewModel(
            fetchMonthlyCalendarDaysUseCase: fetchMonthlyCalendarDaysUseCase,
            requestPhotoAuthorizationUseCase: requestPhotoAuthorizationUseCase,
            fetchFoodRecordsUseCase: fetchFoodRecordsUseCase,
            getNicknameUseCase: getNicknameUseCase
        )
        let weeklyVC = WeeklyCalendarViewController(viewModel: weeklyVM)
        let monthlyVC = MonthlyCalendarViewController(viewModel: monthlyVM)
        return CalendarViewController(
            weeklyVC: weeklyVC,
            monthlyVC: monthlyVC,
            weeklyFlowPublisher: weeklyVC.flowPublisher,
            monthlyFlowPublisher: monthlyVC.flowPublisher
        )
    }
}
