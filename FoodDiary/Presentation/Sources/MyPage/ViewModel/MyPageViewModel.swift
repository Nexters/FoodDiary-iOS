//
//  MyPageViewModel.swift
//  Presentation
//
//  Created by 강대훈 on 2/20/26.
//

import Combine
import Data
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
    private let updateDeviceNotificationSettingUseCase: UpdateDeviceNotificationSettingUseCase<DeviceRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>
    private let logoutUseCase: LogoutUseCase
    private let withdrawUserUseCase: WithdrawUserUseCase

    // MARK: - Init

    public init(
        updateDeviceNotificationSettingUseCase: UpdateDeviceNotificationSettingUseCase<DeviceRepositoryImpl<HTTPClient, AuthTokenStorage<KeychainService>>>,
        logoutUseCase: LogoutUseCase,
        withdrawUserUseCase: WithdrawUserUseCase
    ) {
        self.stateSubject = CurrentValueSubject(State())
        self.updateDeviceNotificationSettingUseCase = updateDeviceNotificationSettingUseCase
        self.logoutUseCase = logoutUseCase
        self.withdrawUserUseCase = withdrawUserUseCase
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
        case .updateNotificationSetting:
            await updateNotificationSetting()
        case .logout:
            logout()
        case .withdraw:
            await withdraw()
        }
    }

    @MainActor
    private func updateNotificationSetting() async {
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
    }

    public enum Input {
        case updateNotificationSetting
        case logout
        case withdraw
    }

    public enum Event {
        case didLogout
        case didWithdraw
    }
}
