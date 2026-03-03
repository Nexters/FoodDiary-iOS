//
//  SearchTextField.swift
//  DesignSystem
//

import UIKit

public final class SearchTextField: UITextField {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let iconSize: CGFloat = 16
    }

    // MARK: - Properties

    public var onSearchIconTapped: (() -> Void)?

    // MARK: - Initialization

    /// - Parameters:
    ///   - placeholder: 플레이스홀더 텍스트
    ///   - showSearchIcon: 돋보기 아이콘 표시 여부
    ///   - isEditable: true면 텍스트 입력 가능, false면 탭 전용 (입력 불가)
    public init(placeholder: String, showSearchIcon: Bool = false, isEditable: Bool = true) {
        super.init(frame: .zero)
        setupStyle(placeholder: placeholder, showSearchIcon: showSearchIcon, isEditable: isEditable)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout Overrides

    override public func leftViewRect(forBounds bounds: CGRect) -> CGRect {
        CGRect(x: 0, y: 0, width: Constants.horizontalInset, height: bounds.height)
    }

    override public func rightViewRect(forBounds bounds: CGRect) -> CGRect {
        let iconWidth = rightView?.frame.width ?? 0
        let totalWidth = iconWidth + Constants.horizontalInset
        let y = (bounds.height - (rightView?.frame.height ?? 0)) / 2
        return CGRect(x: bounds.width - totalWidth, y: y, width: iconWidth, height: rightView?.frame.height ?? 0)
    }

    // MARK: - Private

    private func setupStyle(placeholder: String, showSearchIcon: Bool, isEditable: Bool) {
        backgroundColor = DesignSystemAsset.sd900.color
        layer.cornerRadius = Constants.cornerRadius
        textColor = .white
        font = DesignSystemFontFamily.Pretendard.regular.font(size: 14)

        attributedPlaceholder = NSAttributedString(
            string: placeholder,
            attributes: [
                .font: DesignSystemFontFamily.Pretendard.regular.font(size: 14),
                .foregroundColor: DesignSystemAsset.gray600.color
            ]
        )

        leftView = UIView()
        leftViewMode = .always

        if showSearchIcon {
            let iconButton = UIButton(type: .system)
            iconButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
            iconButton.tintColor = DesignSystemAsset.gray400.color
            iconButton.frame = CGRect(x: 0, y: 0, width: Constants.iconSize, height: Constants.iconSize)
            iconButton.addTarget(self, action: #selector(searchIconTapped), for: .touchUpInside)
            rightView = iconButton
            rightViewMode = .always
        }

        if !isEditable {
            isUserInteractionEnabled = false
        }
    }

    @objc private func searchIconTapped() {
        onSearchIconTapped?()
    }
}
