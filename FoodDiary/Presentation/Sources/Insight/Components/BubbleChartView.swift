//
//  BubbleChartView.swift
//  Presentation
//

import DesignSystem
import UIKit

final class BubbleChartView: UIView {

    struct BubbleData {
        let label: String
        let count: Int
        let color: UIColor
        var textColor: UIColor = .white
    }

    var data: [BubbleData] = []
    var animationDuration: CFTimeInterval = 0.6

    private var didLayoutBubbles = false
    private let padding: CGFloat = 4

    // MARK: - Layout

    override func layoutSubviews() {
        super.layoutSubviews()
        guard bounds.width > 0, !data.isEmpty, !didLayoutBubbles else { return }
        didLayoutBubbles = true
        drawBubbles()
    }

    // MARK: - Drawing

    private func drawBubbles() {
        layer.sublayers?.forEach { $0.removeFromSuperlayer() }

        let sortedData = data.sorted { $0.count > $1.count }
        let topData = Array(sortedData.prefix(3))

        guard let maxCount = topData.first?.count, maxCount > 0 else { return }

        let maxDiameter = min(bounds.width, bounds.height) * 0.65
        let minDiameter: CGFloat = 50

        // 순위별 고정 비율: 1등 100%, 2등 65%, 3등 45%
        let rankRatios: [CGFloat] = [1.0, 0.65, 0.45]
        let diameters = topData.enumerated().map { index, _ -> CGFloat in
            max(rankRatios[index] * maxDiameter, minDiameter)
        }

        let centers = calculateNonOverlappingCenters(diameters: diameters)

        for (index, item) in topData.enumerated() {
            let bubbleLayer = makeBubbleLayer(
                center: centers[index],
                diameter: diameters[index],
                color: item.color,
                textColor: item.textColor,
                label: item.label,
                count: item.count
            )
            layer.addSublayer(bubbleLayer)

            animateBubble(bubbleLayer, delay: Double(index) * 0.15)
        }
    }

    // MARK: - 겹치지 않는 배치 계산

    private func calculateNonOverlappingCenters(diameters: [CGFloat]) -> [CGPoint] {
        let radii = diameters.map { $0 / 2 }

        switch diameters.count {
        case 1:
            return [CGPoint(x: bounds.midX, y: bounds.midY)]

        case 2:
            let totalWidth = diameters[0] + padding + diameters[1]
            let startX = (bounds.width - totalWidth) / 2 + radii[0]
            return [
                CGPoint(x: startX, y: bounds.midY),
                CGPoint(x: startX + radii[0] + padding + radii[1], y: bounds.midY)
            ]

        default:
            // 1번(큼): 왼쪽, 2번(중간): 오른쪽 위, 3번(작음): 오른쪽 아래
            let r0 = radii[0]
            let r1 = radii[1]
            let r2 = radii[2]

            // 원점(0,0) 기준으로 배치 후 중앙 정렬
            let c0 = CGPoint.zero

            // 2번 버블: 1번의 오른쪽 위
            let dist01 = r0 + r1 + padding
            let angle01: CGFloat = -.pi / 3  // 60도 위
            let c1 = CGPoint(
                x: c0.x + dist01 * cos(angle01),
                y: c0.y + dist01 * sin(angle01)
            )

            // 3번 버블: 1번의 오른쪽
            let dist02 = r0 + r2 + padding
            let angle02: CGFloat = -.pi / 8  // 살짝 위
            var c2 = CGPoint(
                x: c0.x + dist02 * cos(angle02),
                y: c0.y + dist02 * sin(angle02)
            )

            // 2번과 겹치면 밀어냄
            let dist12 = hypot(c2.x - c1.x, c2.y - c1.y)
            let minDist12 = r1 + r2 + padding
            if dist12 < minDist12 {
                let pushAngle = atan2(c2.y - c1.y, c2.x - c1.x)
                c2 = CGPoint(
                    x: c1.x + minDist12 * cos(pushAngle),
                    y: c1.y + minDist12 * sin(pushAngle)
                )
            }

            // 전체 바운딩 박스 계산 후 중앙 정렬
            var centers = [c0, c1, c2]
            let allLeft = zip(centers, radii).map { $0.0.x - $0.1 }.min()!
            let allRight = zip(centers, radii).map { $0.0.x + $0.1 }.max()!
            let allTop = zip(centers, radii).map { $0.0.y - $0.1 }.min()!
            let allBottom = zip(centers, radii).map { $0.0.y + $0.1 }.max()!

            let groupWidth = allRight - allLeft
            let groupHeight = allBottom - allTop
            let offsetX = (bounds.width - groupWidth) / 2 - allLeft
            let offsetY = (bounds.height - groupHeight) / 2 - allTop

            for i in 0..<centers.count {
                centers[i].x += offsetX
                centers[i].y += offsetY
            }

            return centers
        }
    }

    private func makeBubbleLayer(
        center: CGPoint,
        diameter: CGFloat,
        color: UIColor,
        textColor: UIColor,
        label: String,
        count: Int
    ) -> CALayer {
        let container = CALayer()
        container.frame = CGRect(
            x: center.x - diameter / 2,
            y: center.y - diameter / 2,
            width: diameter,
            height: diameter
        )

        // 원형 배경
        let circleLayer = CAShapeLayer()
        let circlePath = UIBezierPath(
            ovalIn: CGRect(x: 0, y: 0, width: diameter, height: diameter)
        )
        circleLayer.path = circlePath.cgPath
        circleLayer.fillColor = color.cgColor
        container.addSublayer(circleLayer)

        // 라벨 텍스트
        let nameFontSize: CGFloat = diameter > 100 ? 15 : (diameter > 70 ? 13 : 11)
        let countFontSize: CGFloat = diameter > 100 ? 12 : (diameter > 70 ? 10 : 9)
        let nameFont = DesignSystemFontFamily.Pretendard.bold.font(size: nameFontSize)
        let countFont = DesignSystemFontFamily.Pretendard.regular.font(size: countFontSize)

        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.alignment = .center
        paragraphStyle.lineSpacing = 2

        let attributed = NSMutableAttributedString()
        attributed.append(NSAttributedString(
            string: label,
            attributes: [.font: nameFont, .foregroundColor: textColor, .paragraphStyle: paragraphStyle]
        ))
        attributed.append(NSAttributedString(
            string: "\n(\(count)회)",
            attributes: [.font: countFont, .foregroundColor: textColor, .paragraphStyle: paragraphStyle]
        ))

        let textSize = attributed.boundingRect(
            with: CGSize(width: diameter - 8, height: CGFloat.greatestFiniteMagnitude),
            options: [.usesLineFragmentOrigin, .usesFontLeading],
            context: nil
        ).size

        let textLayer = CATextLayer()
        textLayer.string = attributed
        textLayer.isWrapped = true
        textLayer.alignmentMode = .center
        textLayer.contentsScale = UIScreen.main.scale
        textLayer.frame = CGRect(
            x: (diameter - textSize.width) / 2,
            y: (diameter - textSize.height) / 2,
            width: textSize.width,
            height: textSize.height
        )
        container.addSublayer(textLayer)

        return container
    }

    // MARK: - Animation

    private func animateBubble(_ bubbleLayer: CALayer, delay: TimeInterval) {
        bubbleLayer.opacity = 0
        bubbleLayer.transform = CATransform3DMakeScale(0.3, 0.3, 1)

        CATransaction.begin()
        CATransaction.setDisableActions(true)
        bubbleLayer.opacity = 1
        bubbleLayer.transform = CATransform3DIdentity
        CATransaction.commit()

        let scaleAnim = CABasicAnimation(keyPath: "transform.scale")
        scaleAnim.fromValue = 0.3
        scaleAnim.toValue = 1.0

        let opacityAnim = CABasicAnimation(keyPath: "opacity")
        opacityAnim.fromValue = 0
        opacityAnim.toValue = 1

        let group = CAAnimationGroup()
        group.animations = [scaleAnim, opacityAnim]
        group.duration = animationDuration
        group.beginTime = CACurrentMediaTime() + delay
        group.timingFunction = CAMediaTimingFunction(name: .easeOut)
        group.fillMode = .backwards

        bubbleLayer.add(group, forKey: "appear")
    }
}
