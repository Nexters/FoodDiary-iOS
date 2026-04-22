//
//  GradientBackgroundView.swift
//  Presentation
//

import DesignSystem
import UIKit

final class GradientBackgroundView: UIView {

    private let gradientLayer = CAGradientLayer()

    init(cornerRadius: CGFloat) {
        super.init(frame: .zero)
        gradientLayer.colors = [
            DesignSystemAsset.primary.color.cgColor,
            DesignSystemAsset.primaryLight.color.cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        gradientLayer.cornerRadius = cornerRadius
        layer.insertSublayer(gradientLayer, at: 0)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }
}
