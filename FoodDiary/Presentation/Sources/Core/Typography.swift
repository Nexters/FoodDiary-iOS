//
//  Typography.swift
//  Presentation
//

import UIKit
import DesignSystem

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
    // MARK: - Headline (Bold, 130% line height)
    /// 페이지 헤드라인 - 24pt Bold
    case hd24
    /// 페이지 타이틀 - 20pt Bold
    case hd20
    /// 페이지 서브 타이틀 - 18pt Bold
    case hd18
    /// 페이지 서브 타이틀 2nd - 16pt Bold
    case hd16

    // MARK: - Paragraph (Regular, 100% line height)
    /// 본문 - 18pt Regular
    case p18
    /// 캡션 - 15pt Regular
    case p15
    /// 플래그명 (예: 중식, 한식, 양식 등) - 14pt Regular
    case p14
    /// 아이콘 + - 12pt Regular
    case p12

    /// 직접사용 금지: line spacing 적용된 NSAttributedString 사용할 것
    private var font: UIFont {
        switch self {
        case .hd24:
            return DesignSystemFontFamily.Pretendard.bold.font(size: 24)
        case .hd20:
            return DesignSystemFontFamily.Pretendard.bold.font(size: 20)
        case .hd18:
            return DesignSystemFontFamily.Pretendard.bold.font(size: 18)
        case .hd16:
            return DesignSystemFontFamily.Pretendard.bold.font(size: 16)
        case .p18:
            return DesignSystemFontFamily.Pretendard.regular.font(size: 18)
        case .p15:
            return DesignSystemFontFamily.Pretendard.regular.font(size: 15)
        case .p14:
            return DesignSystemFontFamily.Pretendard.regular.font(size: 14)
        case .p12:
            return DesignSystemFontFamily.Pretendard.regular.font(size: 12)
        }
    }

    private var lineHeightMultiple: CGFloat {
        switch self {
        case .hd24, .hd20, .hd18, .hd16:
            return 1.3
        case .p18, .p15, .p14, .p12:
            return 1.0
        }
    }

    private var letterSpacing: CGFloat {
        -0.015 * font.pointSize
    }

    public func styled(_ text: String, color: UIColor = .white) -> NSAttributedString {
        let paragraphStyle = NSMutableParagraphStyle()
        paragraphStyle.lineHeightMultiple = lineHeightMultiple

        return NSAttributedString(string: text, attributes: [
            .font: font,
            .kern: letterSpacing,
            .foregroundColor: color,
            .paragraphStyle: paragraphStyle
        ])
    }
}

public extension UILabel {
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
