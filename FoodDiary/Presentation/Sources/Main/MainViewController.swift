//
//  MainViewController.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import Combine
import Domain
import UIKit

public final class MainViewController: UIViewController {
    private let authRepository: AuthRepository
    private let didLogoutSubject = PassthroughSubject<Void, Never>()

    public var didLogoutPublisher: AnyPublisher<Void, Never> {
        didLogoutSubject.eraseToAnyPublisher()
    }

    public init(authRepository: AuthRepository) {
        self.authRepository = authRepository
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    public override func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
}

private extension MainViewController {
    func configureUI() {
        view.backgroundColor = .systemBackground

        let label = UILabel()
        label.translatesAutoresizingMaskIntoConstraints = false
        label.textColor = .white
        label.text = "메인화면"

        let logoutButton = UIButton(type: .system)
        logoutButton.translatesAutoresizingMaskIntoConstraints = false
        logoutButton.setTitle("로그아웃", for: .normal)
        logoutButton.addTarget(self, action: #selector(logoutButtonTapped), for: .touchUpInside)

        view.addSubview(label)
        view.addSubview(logoutButton)

        NSLayoutConstraint.activate([
            label.centerYAnchor.constraint(equalTo: view.centerYAnchor),
            label.centerXAnchor.constraint(equalTo: view.centerXAnchor),

            logoutButton.topAnchor.constraint(equalTo: label.bottomAnchor, constant: 24),
            logoutButton.centerXAnchor.constraint(equalTo: view.centerXAnchor),
        ])
    }

    @objc
    func logoutButtonTapped() {
        do {
            try authRepository.logout()
            didLogoutSubject.send()
        } catch {
            // TODO: 에러 처리 전략 확정 후 구체적인 UI 처리
            print("로그아웃 실패: \(error)")
        }
    }
}

