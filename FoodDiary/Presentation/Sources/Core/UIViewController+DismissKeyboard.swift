//
//  UIViewController+DismissKeyboard.swift
//  Presentation
//

import UIKit

extension UIViewController {
    func setupKeyboardDismissGesture() {
        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(dismissKeyboardOnTap))
        tapGesture.cancelsTouchesInView = false
        view.addGestureRecognizer(tapGesture)
    }

    @objc private func dismissKeyboardOnTap() {
        view.endEditing(true)
    }
}
