//
//  CalendarSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public protocol CalendarSceneProducing {
    func makeScene() -> CalendarViewController
}

public final class CalendarSceneFactory: CalendarSceneProducing {
    public typealias WeeklyVM = WeeklyCalendarViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
        FoodImageAssetFetcher<TFLiteFoodClassifier, UIImageLoader>,
        PhotoAuthorizationFetcher,
        PushNotificationObserver
    >
    public typealias MonthlyVM = MonthlyCalendarViewModel<
        FoodRecordRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>,
        PhotoAuthorizationFetcher
    >

    private let weeklyVM: WeeklyVM
    private let monthlyVM: MonthlyVM

    public init(weeklyVM: WeeklyVM, monthlyVM: MonthlyVM) {
        self.weeklyVM = weeklyVM
        self.monthlyVM = monthlyVM
    }

    public func makeScene() -> CalendarViewController {
        let weeklyVC = WeeklyCalendarViewController(viewModel: weeklyVM)
        let monthlyVC = MonthlyCalendarViewController(viewModel: monthlyVM)
        return CalendarViewController(weeklyVC: weeklyVC, monthlyVC: monthlyVC)
    }
}
