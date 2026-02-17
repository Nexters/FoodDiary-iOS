//
//  DashedBorderView.swift
//  Presentation
//

import DesignSystem
import UIKit

/// 점선 테두리를 가진 둥근 사각형 뷰
final class DashedBorderView: UIView {

    private let dashedBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.fillColor = UIColor.clear.cgColor
        layer.lineDashPattern = [4, 4]
        layer.lineWidth = 1
        return layer
    }()

    var cornerRadius: CGFloat = 8 {
        didSet {
            setNeedsLayout()
        }
    }

    init(strokeColor: UIColor = DesignSystemAsset.gray900.color) {
        super.init(frame: .zero)
        dashedBorderLayer.strokeColor = strokeColor.cgColor
        setupLayer()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupLayer() {
        backgroundColor = .clear
        layer.addSublayer(dashedBorderLayer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        dashedBorderLayer.frame = bounds
        dashedBorderLayer.path = UIBezierPath(
            roundedRect: bounds,
            cornerRadius: cornerRadius
        ).cgPath
    }
}
