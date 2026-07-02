//
//  WithdrawalFooterView.swift
//  Presentation
//
//  Created by 강대훈 on 2/21/26.
//

import UIKit

final class WithdrawalFooterView: UIView {

    var onTap: (() -> Void)?

    private let withdrawalLabel: UILabel = {
        let label = UILabel()
        let base = Typography.p12.styled("탈퇴", color: .gray900)
        let mutable = NSMutableAttributedString(attributedString: base)
        mutable.addAttribute(.underlineStyle, value: NSUnderlineStyle.single.rawValue, range: NSRange(location: 0, length: mutable.length))
        label.attributedText = mutable
        label.isUserInteractionEnabled = true
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(withdrawalLabel)

        withdrawalLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }

        let tapGesture = UITapGestureRecognizer(target: self, action: #selector(labelTapped))
        withdrawalLabel.addGestureRecognizer(tapGesture)
    }

    @objc private func labelTapped() {
        onTap?()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
