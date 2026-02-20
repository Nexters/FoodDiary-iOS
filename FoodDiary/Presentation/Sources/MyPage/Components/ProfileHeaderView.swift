//
//  ProfileHeaderView.swift
//  Presentation
//
//  Created by 강대훈 on 2/21/26.
//

import UIKit
import DesignSystem

final class ProfileHeaderView: UIView {

    private let characterImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.character.image
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
        [characterImageView, greetingLabel, nameLabel].forEach { addSubview($0) }
    }

    private func setupConstraints() {
        self.snp.makeConstraints {
            $0.height.equalTo(200)
        }

        characterImageView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(38)
            $0.centerX.equalToSuperview()
            $0.size.equalTo(72)
        }

        greetingLabel.snp.makeConstraints {
            $0.top.equalTo(characterImageView.snp.bottom).offset(15)
            $0.centerX.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(greetingLabel.snp.bottom).offset(3)
            $0.centerX.equalToSuperview()
        }
    }
}
