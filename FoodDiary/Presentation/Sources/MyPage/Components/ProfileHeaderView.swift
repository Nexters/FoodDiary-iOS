//
//  ProfileHeaderView.swift
//  Presentation
//
//  Created by 강대훈 on 2/21/26.
//

import UIKit
import DesignSystem
import SnapKit

final class ProfileHeaderView: UIView {

    private let characterImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.mypageCharacter.image
        iv.contentMode = .scaleAspectFit
        iv.layer.cornerRadius = 36
        iv.clipsToBounds = true
        iv.layer.borderWidth = 3
        iv.layer.borderColor = UIColor.sd800.cgColor

        return iv
    }()

    private let greetingLabel: UILabel = {
        let label = UILabel()
        label.setText("안녕하세요,", style: .p12, color: .gray050)
        label.textAlignment = .center
        return label
    }()

    private let nameLabel: UILabel = {
        let label = UILabel()
        label.setText("홍길동님", style: .hd18, color: .white)
        label.textAlignment = .center
        return label
    }()

    private lazy var labelStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [greetingLabel, nameLabel])
        sv.axis = .vertical
        sv.spacing = 3
        sv.alignment = .center
        return sv
    }()

    private lazy var contentStackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [characterImageView, labelStackView])
        sv.axis = .vertical
        sv.spacing = 15
        sv.alignment = .center
        return sv
    }()

    private let separatorView: UIView = {
        let view = UIView()
        view.backgroundColor = .sd800
        return view
    }()

    func configure(nickname: String) {
        nameLabel.setText("\(nickname)님", style: .hd18, color: .white)
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func setupUI() {
        backgroundColor = .sd700
        [contentStackView, separatorView].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        self.snp.makeConstraints {
            $0.height.equalTo(280)
        }

        characterImageView.snp.makeConstraints {
            $0.size.equalTo(72)
        }

        contentStackView.snp.makeConstraints {
            $0.centerY.equalToSuperview().offset(40)
            $0.centerX.equalToSuperview()
        }

        separatorView.snp.makeConstraints {
            $0.leading.trailing.bottom.equalToSuperview()
            $0.height.equalTo(1)
        }
    }
}
