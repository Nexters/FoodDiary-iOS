//
//  UIView+Gradient.swift
//  DesignSystem
//

import UIKit

extension UIView {

    private enum GradientLayerKey {
        static let name = "designSystem.backgroundGradient"
    }

    /// 배경 그라디언트를 적용합니다.
    /// - Parameters:
    ///   - colors: 그라디언트에 사용할 색상 배열
    ///   - startPoint: 그라디언트 시작점 (기본값: 좌측 상단)
    ///   - endPoint: 그라디언트 끝점 (기본값: 우측 하단)
    ///   - cornerRadius: 코너 반경 (기본값: 0)
    public func applyGradient(
        colors: [UIColor],
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1),
        cornerRadius: CGFloat = 0
    ) {
        removeGradient()

        let gradientLayer = CAGradientLayer()
        gradientLayer.name = GradientLayerKey.name
        gradientLayer.colors = colors.map(\.cgColor)
        gradientLayer.startPoint = startPoint
        gradientLayer.endPoint = endPoint
        gradientLayer.cornerRadius = cornerRadius
        gradientLayer.frame = bounds
        layer.insertSublayer(gradientLayer, at: 0)
    }

    /// Primary 그라디언트(#FE670E → #FF853D)를 배경에 적용합니다.
    /// - Parameters:
    ///   - startPoint: 그라디언트 시작점 (기본값: 좌측 상단)
    ///   - endPoint: 그라디언트 끝점 (기본값: 우측 하단)
    ///   - cornerRadius: 코너 반경 (기본값: 0)
    public func applyPrimaryGradient(
        startPoint: CGPoint = CGPoint(x: 0, y: 0),
        endPoint: CGPoint = CGPoint(x: 1, y: 1),
        cornerRadius: CGFloat = 0
    ) {
        applyGradient(
            colors: [
                DesignSystemAsset.primary.color,
                DesignSystemAsset.primaryLight.color,
            ],
            startPoint: startPoint,
            endPoint: endPoint,
            cornerRadius: cornerRadius
        )
    }

    /// 적용된 배경 그라디언트를 제거합니다.
    public func removeGradient() {
        layer.sublayers?
            .filter { $0.name == GradientLayerKey.name }
            .forEach { $0.removeFromSuperlayer() }
    }

    /// 레이아웃 변경 시 그라디언트 프레임을 업데이트합니다.
    /// `layoutSubviews()`에서 호출하세요.
    public func updateGradientFrame() {
        layer.sublayers?
            .filter { $0.name == GradientLayerKey.name }
            .forEach { $0.frame = bounds }
    }
}
