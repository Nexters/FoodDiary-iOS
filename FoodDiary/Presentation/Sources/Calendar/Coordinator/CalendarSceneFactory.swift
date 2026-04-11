//
//  CalendarSceneFactory.swift
//  Presentation
//

import DI
import Data
import UIKit

public protocol CalendarSceneProducing {
    func makeWeeklyCalendarVC() -> UIViewController
    func makeMonthlyCalendarVC() -> UIViewController
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
    private let imageProvider: UIImageLoader
    // WeeklyCalendarVC / MonthlyCalendarVC 의 하위 화면 생성에 전달 — Factory 내부에서 resolve 하지 않음
    private let container: DIContainer

    public init(
        weeklyVM: WeeklyVM,
        monthlyVM: MonthlyVM,
        imageProvider: UIImageLoader,
        container: DIContainer
    ) {
        self.weeklyVM = weeklyVM
        self.monthlyVM = monthlyVM
        self.imageProvider = imageProvider
        self.container = container
    }

    public func makeWeeklyCalendarVC() -> UIViewController {
        WeeklyCalendarViewController(
            viewModel: weeklyVM,
            imageProvider: imageProvider,
            container: container
        )
    }

    public func makeMonthlyCalendarVC() -> UIViewController {
        MonthlyCalendarViewController(
            viewModel: monthlyVM,
            container: container
        )
    }
}
