//
//  GradientBarView.swift
//  Presentation
//

import UIKit

final class GradientBarView: UIView {

    private let gradientLayer = CAGradientLayer()

    init(colors: [UIColor]) {
        super.init(frame: .zero)
        clipsToBounds = true
        layer.cornerRadius = 4
        layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]

        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
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
