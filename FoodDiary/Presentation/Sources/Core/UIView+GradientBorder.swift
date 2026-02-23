//
//  UIView+GradientBorder.swift
//  Presentation
//

import UIKit

// MARK: - UIView Extension

extension UIView {
    /// 다색 그라디언트 보더 적용
    /// - Parameters:
    ///   - colors: 그라디언트 색상 배열
    ///   - locations: 각 색상의 위치 (0.0 ~ 1.0)
    ///   - borderWidth: 보더 두께
    ///   - cornerRadius: 코너 반경
    ///   - inside: true면 보더가 뷰 안쪽으로 (기본값: true)
    public func applyGradientBorder(
        colors: [UIColor],
        locations: [NSNumber],
        borderWidth: CGFloat,
        cornerRadius: CGFloat,
        inside: Bool = true
    ) {
        removeGradientBorder()
        let borderView = GradientBorderView(
            colors: colors,
            locations: locations,
            borderWidth: borderWidth,
            cornerRadius: cornerRadius,
            inside: inside
        )
        addSubview(borderView)
        borderView.frame = bounds
        borderView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
    }

    func removeGradientBorder() {
        subviews.compactMap { $0 as? GradientBorderView }.forEach { $0.removeFromSuperview() }
    }
}

// MARK: - GradientBorderView

/// 위에서 아래로 페이드되는 그라디언트 보더 뷰
fileprivate final class GradientBorderView: UIView {

    private let gradientLayer = CAGradientLayer()
    private let shapeLayer = CAShapeLayer()
    private let borderWidth: CGFloat
    private let cornerRadius: CGFloat
    private let inside: Bool

    init(colors: [UIColor], locations: [NSNumber], borderWidth: CGFloat, cornerRadius: CGFloat, inside: Bool = true) {
        self.borderWidth = borderWidth
        self.cornerRadius = cornerRadius
        self.inside = inside
        super.init(frame: .zero)
        gradientLayer.colors = colors.map { $0.cgColor }
        gradientLayer.locations = locations
        setupLayers()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayers() {
        isUserInteractionEnabled = false
        backgroundColor = .clear

        gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
        gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)

        shapeLayer.fillColor = UIColor.clear.cgColor
        shapeLayer.strokeColor = UIColor.white.cgColor
        shapeLayer.lineWidth = borderWidth

        gradientLayer.mask = shapeLayer
        layer.addSublayer(gradientLayer)
    }

    override func layoutSubviews() {
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
