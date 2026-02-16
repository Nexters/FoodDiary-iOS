//
//  AddressDisplayView.swift
//  Presentation
//

import Combine
import DesignSystem
import SnapKit
import UIKit

final class AddressDisplayView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let height: CGFloat = 48
        static let cornerRadius: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let spacing: CGFloat = 8
    }

    // MARK: - Publishers

    var addressTapPublisher: AnyPublisher<Void, Never> {
        addressTapSubject.eraseToAnyPublisher()
    }

    var detailAddressPublisher: AnyPublisher<String, Never> {
        detailAddressSubject.eraseToAnyPublisher()
    }

    private let addressTapSubject = PassthroughSubject<Void, Never>()
    private let detailAddressSubject = PassthroughSubject<String, Never>()

    // MARK: - UI Components

    private let addressButton: UIControl = {
        let control = UIControl()
        control.backgroundColor = .sd900
        control.layer.cornerRadius = Constants.cornerRadius
        return control
    }()

    private let addressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 1
        return label
    }()

    private let searchIcon: UIImageView = {
        let iv = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        iv.tintColor = .gray400
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let detailAddressTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .sd900
        tf.layer.cornerRadius = Constants.cornerRadius
        tf.textColor = .white
        tf.attributedPlaceholder = Typography.p14.styled("상세 주소 입력", color: .gray600)
        tf.font = DesignSystemFontFamily.Pretendard.regular.font(size: 14)
        tf.isHidden = true

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: Constants.horizontalInset, height: 0))
        tf.leftView = leftPadding
        tf.leftViewMode = .always

        let rightPadding = UIView(frame: CGRect(x: 0, y: 0, width: Constants.horizontalInset, height: 0))
        tf.rightView = rightPadding
        tf.rightViewMode = .always
        return tf
    }()

    private let stackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = Constants.spacing
        return sv
    }()

    // MARK: - Init

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
        setupConstraints()
        setupActions()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(stackView)

        addressButton.addSubview(addressLabel)
        addressButton.addSubview(searchIcon)

        stackView.addArrangedSubview(addressButton)
        stackView.addArrangedSubview(detailAddressTextField)

        configure(address: nil, detailAddress: "")
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        addressButton.snp.makeConstraints {
            $0.height.equalTo(Constants.height)
        }

        addressLabel.snp.makeConstraints {
            $0.leading.equalToSuperview().offset(Constants.horizontalInset)
            $0.centerY.equalToSuperview()
            $0.trailing.lessThanOrEqualTo(searchIcon.snp.leading).offset(-8)
        }

        searchIcon.snp.makeConstraints {
            $0.trailing.equalToSuperview().offset(-Constants.horizontalInset)
            $0.centerY.equalToSuperview()
            $0.size.equalTo(16)
        }

        detailAddressTextField.snp.makeConstraints {
            $0.height.equalTo(Constants.height)
        }
    }

    private func setupActions() {
        addressButton.addTarget(self, action: #selector(addressButtonTapped), for: .touchUpInside)
        detailAddressTextField.addTarget(self, action: #selector(detailAddressChanged), for: .editingChanged)
    }

    // MARK: - Public Methods

    func configure(address: String?, detailAddress: String) {
        if let address, !address.isEmpty {
            addressLabel.setText(address, style: .p14, color: .white)
            detailAddressTextField.isHidden = false
            detailAddressTextField.text = detailAddress
        } else {
            addressLabel.setText("주소 검색", style: .p14, color: .gray600)
            detailAddressTextField.isHidden = true
        }
    }

    // MARK: - Actions

    @objc private func addressButtonTapped() {
        addressTapSubject.send()
    }

    @objc private func detailAddressChanged() {
        detailAddressSubject.send(detailAddressTextField.text ?? "")
    }
}
