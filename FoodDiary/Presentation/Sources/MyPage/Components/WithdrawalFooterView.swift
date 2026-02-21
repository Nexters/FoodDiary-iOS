//
//  WithdrawalFooterView.swift
//  Presentation
//
//  Created by 강대훈 on 2/21/26.
//

import UIKit

final class WithdrawalFooterView: UIView {

    private let withdrawalLabel: UILabel = {
        let label = UILabel()
        label.setText("탈퇴", style: .p12, color: .gray050)
        return label
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        backgroundColor = .clear
        addSubview(withdrawalLabel)

        withdrawalLabel.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-28)
            $0.centerY.equalToSuperview()
        }
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}
