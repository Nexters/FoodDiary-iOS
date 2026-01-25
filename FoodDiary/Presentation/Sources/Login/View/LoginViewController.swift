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

final public class LoginViewController: UIViewController {
    public let didLogin = PassthroughSubject<Void, Never>()
    
    private let viewModel: LoginViewModel
    
    public init(viewModel: LoginViewModel = .init()) {
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
}

private extension LoginViewController {
    func configureUI() {
        view.backgroundColor = .gray
        
        let appleLoginBtn = ASAuthorizationAppleIDButton(authorizationButtonType: .continue, authorizationButtonStyle: .black)
        appleLoginBtn.clipsToBounds = true
        appleLoginBtn.layer.cornerRadius = 10
        appleLoginBtn.addTarget(self, action: #selector(loginButtonTapped), for: .touchUpInside)
        
        view.addSubview(appleLoginBtn)
        
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
            if let token = appleIDCredential.identityToken {
                Task { @MainActor in
                    do {
                        try await viewModel.sendIdentityToken(token)
                        didLogin.send()
                    } catch {
                        // TODO: 추후에 에러 처리 필요
                        print(error.localizedDescription)
                    }
                }
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
