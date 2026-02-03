//
//  FoodSlotView.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 점선 테두리 사각형 뷰
final class FoodSlotView: UIView {

    // MARK: - Properties

    private let dashedBorderLayer: CAShapeLayer = {
        let layer = CAShapeLayer()
        layer.strokeColor = DesignSystemAsset.gray600.color.cgColor
        layer.fillColor = UIColor.clear.cgColor
        layer.lineDashPattern = [4, 3]
        layer.lineWidth = 1
        return layer
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateDashedBorder()
    }

    // MARK: - Setup

    private func setupUI() {
        layer.addSublayer(dashedBorderLayer)
    }

    private func updateDashedBorder() {
        let cornerRadius = min(bounds.width, bounds.height) * 0.2
        let path = UIBezierPath(roundedRect: bounds, cornerRadius: cornerRadius)
        dashedBorderLayer.path = path.cgPath
        dashedBorderLayer.frame = bounds
    }
}
