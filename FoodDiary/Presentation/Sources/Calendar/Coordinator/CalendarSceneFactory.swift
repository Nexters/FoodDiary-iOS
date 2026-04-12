//
//  CalendarSceneFactory.swift
//  Presentation
//

import Data
import Domain
import UIKit

public protocol CalendarSceneProducing {
    func makeCalendarViewController(
        delegate: any CalendarViewControllerDelegate,
        imagePickerDelegate: (any ImagePickerDelegate)?
    ) -> CalendarViewController
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

    public func makeCalendarViewController(
        delegate: any CalendarViewControllerDelegate,
        imagePickerDelegate: (any ImagePickerDelegate)?
    ) -> CalendarViewController {
        let weeklyVC = WeeklyCalendarViewController(
            viewModel: weeklyVM,
            imagePickerDelegate: imagePickerDelegate,
            delegate: delegate
        )
        let monthlyVC = MonthlyCalendarViewController(
            viewModel: monthlyVM,
            delegate: delegate
        )
        let calendarVC = CalendarViewController(weeklyVC: weeklyVC, monthlyVC: monthlyVC)
        calendarVC.delegate = delegate
        return calendarVC
    }
}
