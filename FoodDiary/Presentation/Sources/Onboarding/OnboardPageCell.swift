//
//  OnboardPageCell.swift
//  Presentation
//
//  Created by Claude Code on 2/11/26.
//

import UIKit
import SnapKit
import DesignSystem

final class OnboardPageCell: UICollectionViewCell {
    static let identifier = "OnboardPageCell"

    private let imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFit
        return imageView
    }()

    private let textLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    private lazy var stackView: UIStackView = {
        let stackView = UIStackView(arrangedSubviews: [imageView, textLabel])
        stackView.axis = .vertical
        stackView.spacing = 40
        stackView.alignment = .center
        return stackView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    func configure(image: UIImage?, text: String) {
        imageView.image = image
        textLabel.setText(text, style: .p15)
        textLabel.textAlignment = .center
    }
}

private extension OnboardPageCell {
    func setupUI() {
        contentView.addSubview(stackView)

        stackView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(130)
            $0.leading.trailing.equalToSuperview().inset(65)
        }

        imageView.snp.makeConstraints {
            $0.height.equalTo(220)
            $0.width.equalTo(imageView.snp.height)
            $0.centerX.equalToSuperview()
        }
    }
}
