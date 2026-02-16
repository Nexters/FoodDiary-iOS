//
//  AddressSearchResultCell.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

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
        sv.spacing = 4
        return sv
    }()

    private lazy var selectButton: UIButton = {
        let button = UIButton(type: .system)
        let baseAttributed = Typography.p14.styled("선택", color: .primary)
        let mutable = NSMutableAttributedString(attributedString: baseAttributed)
        mutable.addAttribute(
            .underlineStyle,
            value: NSUnderlineStyle.single.rawValue,
            range: NSRange(location: 0, length: mutable.length)
        )
        button.setAttributedTitle(mutable, for: .normal)
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
            $0.leading.equalToSuperview().offset(16)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(selectButton.snp.leading).offset(-12)
        }

        selectButton.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-16)
            $0.centerY.equalToSuperview()
        }
        selectButton.setContentHuggingPriority(.required, for: .horizontal)
        selectButton.setContentCompressionResistancePriority(.required, for: .horizontal)
    }

    // MARK: - Configure

    func configure(with result: AddressSearchResult) {
        placeNameLabel.setText(result.placeName, style: .hd16)
        roadAddressLabel.setText(result.roadAddress, style: .p14, color: .gray400)
    }

    // MARK: - Actions

    @objc private func selectButtonTapped() {
        onSelectTapped?()
    }
}
