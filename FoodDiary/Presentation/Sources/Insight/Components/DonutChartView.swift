//
//  DonutChartView.swift
//  Presentation
//

import UIKit

final class DonutChartView: UIView {
    struct SliceData {
        let value: Double
        let colors: [UIColor]
        let label: String
    }

    var data: [SliceData] = []
    var innerRadiusRatio: CGFloat = 0.5
    var animationDuration: CFTimeInterval = 1.2
    var separatorColor: UIColor = .black

    private var total: Double { data.reduce(0) { $0 + $1.value } }
    private let sliceContainer = CALayer()
    private var labelLayers: [CATextLayer] = []

    override init(frame: CGRect) {
        super.init(frame: frame)
        layer.addSublayer(sliceContainer)
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        layer.addSublayer(sliceContainer)
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        sliceContainer.frame = bounds
        setup()
    }

    // MARK: - Setup

    private func setup() {
        guard bounds.width > 0, total > 0 else { return }

        sliceContainer.sublayers?.forEach { $0.removeFromSuperlayer() }
        labelLayers.forEach { $0.removeFromSuperlayer() }
        labelLayers.removeAll()
        sliceContainer.mask = nil

        let center = CGPoint(x: bounds.midX, y: bounds.midY)
        let outerRadius = min(bounds.width, bounds.height) / 2
        let innerRadius = outerRadius * innerRadiusRatio
        let midRadius = (outerRadius + innerRadius) / 2
        let startOffset = -CGFloat.pi / 2
        var currentAngle = startOffset
        var boundaryAngles: [CGFloat] = []

        for item in data {
            let sweep = CGFloat(item.value / total) * 2 * .pi

            let path = UIBezierPath()
            path.move(to: CGPoint(
                x: center.x + outerRadius * cos(currentAngle),
                y: center.y + outerRadius * sin(currentAngle)
            ))
            path.addArc(withCenter: center, radius: outerRadius,
                        startAngle: currentAngle, endAngle: currentAngle + sweep, clockwise: true)
            path.addArc(withCenter: center, radius: innerRadius,
                        startAngle: currentAngle + sweep, endAngle: currentAngle, clockwise: false)
            path.close()

            let shapeMask = CAShapeLayer()
            shapeMask.path = path.cgPath

            let gradientLayer = CAGradientLayer()
            gradientLayer.frame = bounds
            gradientLayer.colors = item.colors.map(\.cgColor)
            gradientLayer.startPoint = CGPoint(x: 0.5, y: 0)
            gradientLayer.endPoint = CGPoint(x: 0.5, y: 1)
            gradientLayer.mask = shapeMask
            sliceContainer.addSublayer(gradientLayer)

            let midAngle = currentAngle + sweep / 2
            let labelPoint = CGPoint(
                x: center.x + midRadius * cos(midAngle),
                y: center.y + midRadius * sin(midAngle)
            )
            let textLayer = makeTextLayer(item.label, at: labelPoint)
            textLayer.opacity = 0
            layer.addSublayer(textLayer)
            labelLayers.append(textLayer)

            boundaryAngles.append(currentAngle)
            currentAngle += sweep
        }

        // 슬라이스 경계에 배경색 선을 덧그려 균일한 간격 효과 적용
        for angle in boundaryAngles {
            let separatorLayer = CAShapeLayer()
            let separatorPath = UIBezierPath()
            separatorPath.move(to: CGPoint(
                x: center.x + innerRadius * cos(angle),
                y: center.y + innerRadius * sin(angle)
            ))
            separatorPath.addLine(to: CGPoint(
                x: center.x + outerRadius * cos(angle),
                y: center.y + outerRadius * sin(angle)
            ))
            separatorLayer.path = separatorPath.cgPath
            separatorLayer.strokeColor = separatorColor.cgColor
            separatorLayer.lineWidth = 3
            separatorLayer.lineCap = .square
            sliceContainer.addSublayer(separatorLayer)
        }

        let ringWidth = outerRadius - innerRadius
        let animMask = CAShapeLayer()
        let circlePath = UIBezierPath(
            arcCenter: center,
            radius: midRadius,
            startAngle: startOffset,
            endAngle: startOffset + 2 * .pi,
            clockwise: true
        )
        animMask.path = circlePath.cgPath
        animMask.fillColor = UIColor.clear.cgColor
        animMask.strokeColor = UIColor.black.cgColor
        animMask.lineWidth = ringWidth + 2
        animMask.strokeEnd = 0
        sliceContainer.mask = animMask

        animateMask(animMask)
    }

    // MARK: - Animation

    private func animateMask(_ maskLayer: CAShapeLayer) {
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        maskLayer.strokeEnd = 1
        CATransaction.commit()

        let anim = CABasicAnimation(keyPath: "strokeEnd")
        anim.fromValue = 0
        anim.toValue = 1
        anim.duration = animationDuration
        anim.timingFunction = CAMediaTimingFunction(name: .easeInEaseOut)
        maskLayer.add(anim, forKey: "drawDonut")

        Task {
            try? await Task.sleep(for: .seconds(animationDuration))
            fadeInLabels()
        }
    }

    private func fadeInLabels() {
        for label in labelLayers {
            let anim = CABasicAnimation(keyPath: "opacity")
            anim.fromValue = 0
            anim.toValue = 1
            anim.duration = 0.3
            label.opacity = 1
            label.add(anim, forKey: "fadeIn")
        }
    }

    // MARK: - Helper

    private func makeTextLayer(_ text: String, at point: CGPoint) -> CATextLayer {
        let attributed = Typography.p12.styled(text, color: .white)
        let size = attributed.boundingRect(
            with: CGSize(width: CGFloat.greatestFiniteMagnitude, height: CGFloat.greatestFiniteMagnitude),
            options: .usesLineFragmentOrigin,
            context: nil
        ).size

        let textLayer = CATextLayer()
        textLayer.string = attributed
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.frame = CGRect(
            x: point.x - size.width / 2,
            y: point.y - size.height / 2,
            width: size.width,
            height: size.height
        )
        return textLayer
    }
}
