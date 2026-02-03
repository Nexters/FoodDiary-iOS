//
//  ShimmerView.swift
//  DesignSystem
//

import UIKit

/// 로딩 중임을 나타내는 시머 애니메이션 뷰
public final class ShimmerView: UIView {

    // MARK: - Properties

    private let gradientLayer = CAGradientLayer()

    // MARK: - Init

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupGradient()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds
    }

    // MARK: - Setup

    private func setupGradient() {
        gradientLayer.startPoint = CGPoint(x: 0, y: 0.5)
        gradientLayer.endPoint = CGPoint(x: 1, y: 0.5)

        let baseColor = DesignSystemAsset.gray300.color.cgColor
        let highlightColor = DesignSystemAsset.gray200.color.cgColor

        gradientLayer.colors = [
            baseColor,
            highlightColor,
            baseColor
        ]

        gradientLayer.locations = [0, 0.5, 1]
        layer.addSublayer(gradientLayer)
    }

    // MARK: - Animation

    /// 시머 애니메이션 시작
    public func startAnimating() {
        gradientLayer.locations = [-1.0, -0.5, 0.0]

        let animation = CABasicAnimation(keyPath: "locations")
        animation.fromValue = [-1.0, -0.5, 0.0]
        animation.toValue = [1.0, 1.5, 2.0]
        animation.duration = 1.0
        animation.beginTime = 1.0

        let group = CAAnimationGroup()
        group.animations = [animation]
        group.duration = animation.duration + animation.beginTime
        group.repeatCount = .infinity

        gradientLayer.add(group, forKey: "shimmer")
    }

    /// 시머 애니메이션 중지
    public func stopAnimating() {
        gradientLayer.removeAnimation(forKey: "shimmer")
    }
}
