//
//  Typography.swift
//  Presentation
//

import DesignSystem
import UIKit

/// 앱 전체 타이포그래피 스타일 정의
///
/// Usage:
/// ```swift
/// // UILabel extension 사용
/// label.setText("뭐먹었지", style: .hd24)
///
/// // NSAttributedString 직접 사용
/// label.attributedText = Typography.hd24.styled("뭐먹었지")
/// ```
public enum Typography {
    /// Headline 24pt - Semibold, 130% line height
    case hd24
    /// Headline 20pt - Semibold, 130% line height
    case hd20
    /// Headline 18pt - Semibold, 130% line height
    case hd18
    /// Paragraph 12pt - Regular, 100% line height
    case p12

    /// 직접사용 금지: line spacing 적용된 NSAttributedString 사용할 것
    private var font: UIFont {
        switch self {
        case .hd24:
            return DesignSystemFontFamily.Pretendard.semiBold.font(size: 24)
        case .hd20:
            return DesignSystemFontFamily.Pretendard.semiBold.font(size: 20)
        case .hd18:
            return DesignSystemFontFamily.Pretendard.semiBold.font(size: 18)
        case .p12:
            return DesignSystemFontFamily.Pretendard.regular.font(size: 12)
        }
    }

    private var letterSpacing: CGFloat {
        -0.015 * font.pointSize
    }

    public func styled(_ text: String, color: UIColor = .white) -> NSAttributedString {
        NSAttributedString(string: text, attributes: [
            .font: font,
            .kern: letterSpacing,
            .foregroundColor: color
        ])
    }
}

extension UILabel {
    /// Typography 스타일이 적용된 텍스트 설정
    ///
    /// - Parameters:
    ///   - text: 표시할 텍스트
    ///   - style: 적용할 Typography 스타일
    ///   - color: 텍스트 컬러 (기본값: .white)
    ///
    /// ```swift
    /// label.setText("뭐먹었지", style: .hd24)
    /// label.setText("뭐먹었지", style: .hd24, color: .black)
    /// ```
    func setText(_ text: String, style: Typography, color: UIColor = .white) {
        self.attributedText = style.styled(text, color: color)
    }
}
