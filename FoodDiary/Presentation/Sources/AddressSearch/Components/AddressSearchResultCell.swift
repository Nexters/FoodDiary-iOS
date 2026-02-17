//
//  AddressSearchResultCell.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

private enum Constants {
    static let horizontalPadding: CGFloat = 20
    static let verticalPadding: CGFloat = 24
    static let textStackSpacing: CGFloat = 8
    static let buttonSpacing: CGFloat = 24
}

final class AddressSearchResultCell: UITableViewCell {

    static let reuseIdentifier = "AddressSearchResultCell"

    // MARK: - Callback

    var onSelectTapped: (() -> Void)?

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

    private lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        var config = UIButton.Configuration.plain()
        config.attributedTitle = underlined("선택", style: .p14, color: .white)
        button.configuration = config
        button.addTarget(self, action: #selector(selectButtonTapped), for: .touchUpInside)
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
        onSelectTapped = nil
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

    // MARK: - Private Methods

    private func underlined(
        _ text: String,
        style: Typography,
        color: UIColor
    ) -> AttributedString {
        var attributed = AttributedString(style.styled(text, color: color))
        attributed.underlineStyle = .single
        return attributed
    }

    // MARK: - Actions

    @objc private func selectButtonTapped() {
        onSelectTapped?()
    }
}
