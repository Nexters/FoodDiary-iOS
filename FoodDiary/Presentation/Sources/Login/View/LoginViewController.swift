//
//  LoginViewController.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import AuthenticationServices
import Combine
import UIKit
import SnapKit
import DesignSystem
import Domain
import UserNotifications

final public class LoginViewController: UIViewController {
    private let didLoginSubject = PassthroughSubject<LoginResult, Never>()

    public var didLoginPublisher: AnyPublisher<LoginResult, Never> {
        didLoginSubject.eraseToAnyPublisher()
    }
    
    private let viewModel: LoginViewModel
    
    public init(viewModel: LoginViewModel) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
    }
    
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
    
    override public func viewDidLoad() {
        super.viewDidLoad()
        configureUI()
    }
    
    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        Task { await requestNotificationPermission() }
    }
}

private extension LoginViewController {
    /// 알림 권한 요청
    func requestNotificationPermission() async {
        do {
            let granted = try await UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound])
            if granted {
                await MainActor.run {
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
        } catch {
            // TODO: 추후 처리
            print(error.localizedDescription)
        }
    }
    
    func configureUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        
        let logoImageView = UIImageView(image: DesignSystemAsset.logo.image)
        logoImageView.contentMode = .scaleAspectFill
        
        let characterImageView = UIImageView(image: DesignSystemAsset.character.image)
        characterImageView.contentMode = .scaleAspectFit
        
        let appleLoginBtn = ASAuthorizationAppleIDButton(authorizationButtonType: .signIn, authorizationButtonStyle: .black)
        appleLoginBtn.clipsToBounds = true
        appleLoginBtn.layer.cornerRadius = 10
        appleLoginBtn.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        view.addSubview(logoImageView)
        view.addSubview(characterImageView)
        view.addSubview(appleLoginBtn)
        
        logoImageView.snp.makeConstraints {
            $0.centerX.equalTo(view.snp.centerX)
            $0.width.equalTo(215)
            $0.height.equalTo(58)
            $0.bottom.equalTo(characterImageView.snp.top).inset(-27)
        }
        
        characterImageView.snp.makeConstraints {
            $0.width.equalTo(175)
            $0.height.equalTo(145)
            $0.center.equalTo(view.center)
        }
        
        appleLoginBtn.snp.makeConstraints {
            $0.leading.trailing.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(52)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(32)
        }
    }
    
    @objc func loginButtonTapped() {
        let provider = ASAuthorizationAppleIDProvider()
        let request = provider.createRequest()
        request.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [request])
        controller.delegate = self
        controller.presentationContextProvider = self
        controller.performRequests()
    }
}

extension LoginViewController: ASAuthorizationControllerDelegate {
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithAuthorization authorization: ASAuthorization) {
        if case let appleIDCredential as ASAuthorizationAppleIDCredential = authorization.credential {
            if let token = appleIDCredential.identityToken,
               let tokenString = String(data: token, encoding: .utf8) {
                Task {
                    do {
                        let result = try await viewModel.sendIdentityToken(tokenString)
                        didLoginSubject.send(result)
                    } catch {
                        print(error.localizedDescription)
                    }
                }
            } else {
                // TODO: identityToken 변환 실패 처리
                print("identityToken 변환 실패")
            }
        }
    }
    
    public func authorizationController(controller: ASAuthorizationController, didCompleteWithError error: any Error) {
        // TODO: 구체적인 Alert
        print("에러 발생")
    }
}

extension LoginViewController: ASAuthorizationControllerPresentationContextProviding {
    public func presentationAnchor(for controller: ASAuthorizationController) -> ASPresentationAnchor {
        guard let window = view.window else {
            fatalError("View controller's view must be in a window hierarchy")
        }
        return window
    }
}
