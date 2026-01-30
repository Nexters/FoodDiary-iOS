//
//  Typography.swift
//  Presentation
//

import UIKit
import DesignSystem

public enum Typography {
    case hd24
    case hd20
    case p12

    public var font: UIFont {
        switch self {
        case .hd24:
            return DesignSystemFontFamily.Pretendard.semiBold.font(size: 24)
        case .hd20:
            return DesignSystemFontFamily.Pretendard.semiBold.font(size: 20)
        case .p12:
            return DesignSystemFontFamily.Pretendard.regular.font(size: 12)
        }
    }

    private var letterSpacing: CGFloat {
        -0.015 * font.pointSize
    }

    public func styled(_ text: String) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: font,
            .kern: letterSpacing
        ])
    }
}

public extension UILabel {
    func setText(_ text: String, style: Typography) {
        self.attributedText = style.styled(text)
    }
}
