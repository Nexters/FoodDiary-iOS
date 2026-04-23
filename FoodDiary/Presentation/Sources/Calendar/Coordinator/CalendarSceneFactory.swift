//
//  CalendarSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public final class CalendarSceneFactory {
    private let requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase
    private let loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase
    private let saveFoodRecordUseCase: SaveFoodRecordUseCase
    private let pushNotificationObserver: PushNotificationObserver
    private let getNicknameUseCase: GetNicknameUseCase
    private let coachmarkStorage: any CoachmarkStoring
    private let checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase
    private let fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase
    private let fetchFoodRecordsUseCase: FetchFoodRecordsUseCase

    public init(
        requestPhotoAuthorizationUseCase: RequestPhotoAuthorizationUseCase,
        loadWeeklyCalendarDataUseCase: LoadWeeklyRecordUseCase,
        saveFoodRecordUseCase: SaveFoodRecordUseCase,
        pushNotificationObserver: PushNotificationObserver,
        getNicknameUseCase: GetNicknameUseCase,
        coachmarkStorage: any CoachmarkStoring,
        checkAppReviewEligibilityUseCase: CheckAppReviewEligibilityUseCase,
        fetchMonthlyCalendarDaysUseCase: FetchMonthlyCalendarDaysUseCase,
        fetchFoodRecordsUseCase: FetchFoodRecordsUseCase
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
