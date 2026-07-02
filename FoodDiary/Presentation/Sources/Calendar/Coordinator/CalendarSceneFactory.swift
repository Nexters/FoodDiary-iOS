//
//  CalendarSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public final class CalendarSceneFactory {
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase
    private let fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase
    private let pushNotificationObserver: PushNotificationObserver
    private let getNicknameUseCase: GetNicknameUseCase
    private let coachmarkStorage: any CoachmarkStoring
    private let checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase
    private let fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase,
        fetchFoodImageAssetUseCase: FetchFoodImageAssetUseCase,
        saveFoodRecordUseCase: SaveFoodRecordUseCase,
        pushNotificationObserver: PushNotificationObserver,
        getNicknameUseCase: GetNicknameUseCase,
        coachmarkStorage: any CoachmarkStoring,
        checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase,
        fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase
    ) {
        self.requestPhotoAuthorizationUseCase = requestPhotoAuthorizationUseCase
        self.fetchFoodImageAssetUseCase = fetchFoodImageAssetUseCase
        self.saveFoodRecordUseCase = saveFoodRecordUseCase
        self.pushNotificationObserver = pushNotificationObserver
        self.getNicknameUseCase = getNicknameUseCase
        self.coachmarkStorage = coachmarkStorage
        self.checkAppReviewEligibilityUseCase = checkAppReviewEligibilityUseCase
        self.fetchMonthlyCalendarDaysUseCase = fetchMonthlyCalendarDaysUseCase
        self.fetchFoodRecordsUseCase = fetchFoodRecordsUseCase
    }

    public func makeScene() -> MonthlyCalendarViewController {
        let monthlyVM = MonthlyCalendarViewModel(
            fetchMonthlyCalendarDaysUseCase: fetchMonthlyCalendarDaysUseCase,
            requestPhotoAuthorizationUseCase: requestPhotoAuthorizationUseCase,
            fetchFoodRecordsUseCase: fetchFoodRecordsUseCase,
            getNicknameUseCase: getNicknameUseCase,
            fetchFoodImageAssetUseCase: fetchFoodImageAssetUseCase,
            saveFoodRecordUseCase: saveFoodRecordUseCase,
            pushNotificationObserver: pushNotificationObserver,
            checkAppReviewEligibilityUseCase: checkAppReviewEligibilityUseCase
        )
        return MonthlyCalendarViewController(viewModel: monthlyVM)
    }
}
