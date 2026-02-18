//
//  AddressSearchResultCell.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

final class AddressSearchResultCell: UITableViewCell {
    private enum Constants {
        static let horizontalPadding: CGFloat = 20
        static let verticalPadding: CGFloat = 24
        static let textStackSpacing: CGFloat = 8
        static let buttonSpacing: CGFloat = 24
    }

    static let reuseIdentifier = "AddressSearchResultCell"

    // MARK: - UI Components

    private let placeNameLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private let roadAddressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private let textStack: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = Constants.textStackSpacing
        return sv
    }()

    private let selectButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = {
            var attributed = AttributedString(Typography.p14.styled("선택", color: .white))
            attributed.underlineStyle = .single
            return attributed
        }()
        button.configuration = config
        button.isUserInteractionEnabled = false
        return button
    }()

    // MARK: - Init

    override init(style: UITableViewCell.CellStyle, reuseIdentifier: String?) {
        super.init(style: style, reuseIdentifier: reuseIdentifier)
        setupUI()
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    override func prepareForReuse() {
        super.prepareForReuse()
        placeNameLabel.text = nil
        roadAddressLabel.text = nil
    }

    // MARK: - Setup

    private func setupUI() {
        backgroundColor = .clear
        contentView.backgroundColor = .clear
        selectionStyle = .none

        contentView.addSubview(textStack)
        textStack.addArrangedSubview(placeNameLabel)
        textStack.addArrangedSubview(roadAddressLabel)

        contentView.addSubview(selectButton)
    }

    private func setupConstraints() {
        textStack.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.horizontalPadding)
            $0.top.equalToSuperview().offset(Constants.verticalPadding)
            $0.bottom.equalToSuperview().offset(-Constants.verticalPadding)
            $0.trailing.lessThanOrEqualTo(selectButton.snp.leading).offset(-Constants.buttonSpacing)
        }

        selectButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.horizontalPadding)
            $0.top.equalToSuperview().offset(Constants.verticalPadding)
        }
        selectButton.setContentHuggingPriority(.required, for: .horizontal)
        selectButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Configure

    func configure(with result: AddressSearchResult) {
        placeNameLabel.setText(result.placeName, style: .hd16)
        roadAddressLabel.setText(result.roadAddress, style: .p14, color: .gray400)
    }

}
