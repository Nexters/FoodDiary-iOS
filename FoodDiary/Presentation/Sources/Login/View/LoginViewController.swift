//
//  LoginViewController.swift
//  Presentation
//
//  Created by 강대훈 on 1/23/26.
//

import AuthenticationServices
import UIKit
import SnapKit

public protocol LoginViewControllerDelegate: AnyObject {
    func loginViewControllerDidLogin()
}

final public class LoginViewController: UIViewController {
    public weak var delegate: LoginViewControllerDelegate?
    
    let viewModel: LoginViewModel
    
    public init(viewModel: LoginViewModel = LoginViewModel()) {
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
        appleLoginBtn.cornerRadius = 10
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
        let reqeust = provider.createRequest()
        reqeust.requestedScopes = [.fullName, .email]
        
        let controller = ASAuthorizationController(authorizationRequests: [reqeust])
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
                    await viewModel.sendIdentityToken(token)
                    delegate?.loginViewControllerDidLogin()
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
        return view.window!
    }
}
