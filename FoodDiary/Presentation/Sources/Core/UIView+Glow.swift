//
//  UIView+Glow.swift
//  Presentation
//

import UIKit

// MARK: - UIView Extension

extension UIView {
    /// 네온/글로우 효과 + 그라디언트 보더 적용
    /// - Parameters:
    ///   - glowColor: 글로우 색상
    ///   - borderColor: 보더 색상
    ///   - cornerRadius: 코너 반경
    ///   - glowRadius: 글로우 퍼짐 정도 (기본값: 8)
    ///   - glowOpacity: 글로우 불투명도 (기본값: 0.6)
    ///   - borderWidth: 보더 두께 (기본값: 0.5)
    ///   - borderInside: true면 보더가 뷰 안쪽으로 (기본값: true)
    public func applyGlow(
        glowColor: UIColor,
        borderColor: UIColor,
        cornerRadius: CGFloat,
        glowRadius: CGFloat = 5,
        glowOpacity: Float = 0.5,
        borderWidth: CGFloat = 1,
        borderInside: Bool = true
    ) {
        // 글로우 효과
        layer.shadowColor = glowColor.cgColor
        layer.shadowRadius = glowRadius
        layer.shadowOpacity = glowOpacity
        layer.shadowOffset = .zero
        layer.masksToBounds = false

        // 그라디언트 보더
        removeGradientBorder()
        let borderView = GradientBorderView(
            color: borderColor,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            inside: borderInside
        )
        addSubview(borderView)
        borderView.frame = bounds
        borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    /// 글로우 + 그라디언트 보더 제거
    public func removeGlow() {
        layer.shadowColor = nil
        layer.shadowRadius = 0
        layer.shadowOpacity = 0
        removeGradientBorder()
    }

    private func removeGradientBorder() {
        subviews.compactMap { $0 as? GradientBorderView }.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - GradientBorderView

/// 위에서 아래로 페이드되는 그라디언트 보더 뷰
fileprivate final class GradientBorderView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    private let borderColor: UIColor
    private let borderWidth: CGFloat
    private let cornerRadius: CGFloat
    private let inside: Bool

    public init(color: UIColor, borderWidth: CGFloat, cornerRadius: CGFloat, inside: Bool = true) {
        self.borderColor = color
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.inside = inside
        super.init(frame: .zero)
        setupLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.colors = [
            borderColor.cgColor,
            borderColor.withAlphaComponent(0).cgColor,
        ]
        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = borderWidth

        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }

    public override func layoutSubviews() {
        super.layoutSubviews()
        gradientLayer.frame = bounds

        let inset = inside ? borderWidth / 2 : -borderWidth / 2
        let path = UIBezierPath(
            roundedRect: bounds.insetBy(dx: inset, dy: inset),
            cornerRadius: cornerRadius
        )
        shapeLayer.path = path.cgPath
    }
}
