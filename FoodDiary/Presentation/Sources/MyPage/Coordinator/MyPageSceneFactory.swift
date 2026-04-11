//
//  MyPageSceneFactory.swift
//  Presentation
//

import Domain

public protocol MyPageSceneProducing {
    func makeMyPageScene() -> MyPageViewController
}

public final class MyPageSceneFactory: MyPageSceneProducing {
    private let updateDeviceUseCase: UpdateDeviceNotificationSettingUseCase
    private let notificationAuthProvider: NotificationAuthorizationProviding
    private let logoutUseCase: LogoutUseCase
    private let withdrawUserUseCase: WithdrawUserUseCase
    private let getNicknameUseCase: GetNicknameUseCase
    private let getAppVersionUseCase: GetAppVersionUseCase

    public init(
        updateDeviceUseCase: UpdateDeviceNotificationSettingUseCase,
        notificationAuthProvider: NotificationAuthorizationProviding,
        logoutUseCase: LogoutUseCase,
        withdrawUserUseCase: WithdrawUserUseCase,
        getNicknameUseCase: GetNicknameUseCase,
        getAppVersionUseCase: GetAppVersionUseCase
    ) {
        self.updateDeviceUseCase = updateDeviceUseCase
        self.notificationAuthProvider = notificationAuthProvider
        self.logoutUseCase = logoutUseCase
        self.withdrawUserUseCase = withdrawUserUseCase
        self.getNicknameUseCase = getNicknameUseCase
        self.getAppVersionUseCase = getAppVersionUseCase
    }

    public func makeMyPageScene() -> MyPageViewController {
        MyPageViewController(viewModel: MyPageViewModel(
            updateDeviceNotificationSettingUseCase: updateDeviceUseCase,
            notificationAuthorizationProvider: notificationAuthProvider,
            logoutUseCase: logoutUseCase,
            withdrawUserUseCase: withdrawUserUseCase,
            getNicknameUseCase: getNicknameUseCase,
            getAppVersionUseCase: getAppVersionUseCase
        ))
    }
}
