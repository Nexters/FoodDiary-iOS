//
//  SplashView.swift
//  App
//

import SnapKit
import UIKit

final class SplashView: UIView {
    init() {
        super.init(frame: .zero)

        backgroundColor = UIColor(
            red: 0.098, green: 0.094, blue: 0.129, alpha: 1
        )

        let logoImageView = UIImageView(image: UIImage(named: "logo"))
        logoImageView.contentMode = .scaleAspectFit

        let characterImageView = UIImageView(image: UIImage(named: "character"))
        characterImageView.contentMode = .scaleAspectFit

        addSubview(logoImageView)
        addSubview(characterImageView)

        characterImageView.snp.makeConstraints {
            $0.centerX.centerY.equalToSuperview()
            $0.width.equalTo(175)
            $0.height.equalTo(145)
        }

        logoImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(characterImageView.snp.top).offset(-27)
            $0.width.equalTo(215)
            $0.height.equalTo(64)
        }
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func animateRemoval(completion: (() -> Void)? = nil) {
        UIView.animate(withDuration: 0.3, animations: {
            self.alpha = 0
        }, completion: { _ in
            self.removeFromSuperview()
            completion?()
        })
    }
}
