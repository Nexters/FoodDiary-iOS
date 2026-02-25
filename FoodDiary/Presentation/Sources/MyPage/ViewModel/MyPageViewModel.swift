//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by 강대훈 on 2/20/26.
//

import Combine
import Domain
import Foundation
import UIKit

public final class MyPageViewModel {

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

    private let stateSubject: CurrentValueSubject<State, Never>
    private let eventSubject = PassthroughSubject<Event, Never>()
    private var cancellables = Set<AnyCancellable>()
    private let updateDeviceNotificationSettingUseCase: UpdateDeviceNotificationSettingUseCase
    private let notificationAuthorizationProvider: NotificationAuthorizationProviding
    private let logoutUseCase: LogoutUseCase
    private let withdrawUserUseCase: WithdrawUserUseCase
    private let getNicknameUseCase: GetNicknameUseCase

    // MARK: - Init

    public init(
        updateDeviceNotificationSettingUseCase: UpdateDeviceNotificationSettingUseCase,
        notificationAuthorizationProvider: NotificationAuthorizationProviding,
        logoutUseCase: LogoutUseCase,
        withdrawUserUseCase: WithdrawUserUseCase,
        getNicknameUseCase: GetNicknameUseCase,
        getAppVersionUseCase: GetAppVersionUseCase
    ) {
        self.stateSubject = CurrentValueSubject(State(appVersion: getAppVersionUseCase.execute()))
        self.updateDeviceNotificationSettingUseCase = updateDeviceNotificationSettingUseCase
        self.notificationAuthorizationProvider = notificationAuthorizationProvider
        self.logoutUseCase = logoutUseCase
        self.withdrawUserUseCase = withdrawUserUseCase
        self.getNicknameUseCase = getNicknameUseCase
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
        case .viewDidLoad:
            state.nickname = getNicknameUseCase.execute()
            await fetchNotificationStatus()
        case .updateNotificationSetting:
            await updateNotificationSetting()
        case .logout:
            logout()
        case .withdraw:
            await withdraw()
        }
    }

    @MainActor
    private func fetchNotificationStatus() async {
        let isEnabled = await notificationAuthorizationProvider.isNotificationEnabled()
        state.isNotificationEnabled = isEnabled
    }

    @MainActor
    private func updateNotificationSetting() async {
        let isEnabled = await notificationAuthorizationProvider.isNotificationEnabled()
        state.isNotificationEnabled = isEnabled
        do {
            try await updateDeviceNotificationSettingUseCase.execute()
        } catch {
            print("디바이스 알림 설정 업데이트 실패: \(error)")
        }
    }

    @MainActor
    private func logout() {
        do {
            try logoutUseCase.execute()
            eventSubject.send(.didLogout)
        } catch {
            print("로그아웃 실패: \(error)")
        }
    }

    @MainActor
    private func withdraw() async {
        do {
            try await withdrawUserUseCase.execute()
            eventSubject.send(.didWithdraw)
        } catch {
            print("회원탈퇴 실패: \(error)")
        }
    }
}

// MARK: - State, Input & Event

extension MyPageViewModel {
    public struct State: Equatable {
        public var isNotificationEnabled: Bool = true
        public var nickname: String? = nil
        public var appVersion: String = ""
    }

    public enum Input {
        case viewDidLoad
        case updateNotificationSetting
        case logout
        case withdraw
    }

    public enum Event {
        case didLogout
        case didWithdraw
    }
}
