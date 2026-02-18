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

    private let addressFieldContainer: UIControl = {
        let control = UIControl()
        return control
    }()

    private let addressField = SearchTextField(placeholder: "주소 검색", showSearchIcon: true, isEditable: false)

    private let detailAddressTextField: SearchTextField = {
        let tf = SearchTextField(placeholder: "상세 주소 입력")
        tf.isHidden = true
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

        addressFieldContainer.addSubview(addressField)

        stackView.addArrangedSubview(addressFieldContainer)
        stackView.addArrangedSubview(detailAddressTextField)

        configure(address: nil, detailAddress: "")
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        addressFieldContainer.snp.makeConstraints {
            $0.height.equalTo(Constants.height)
        }

        addressField.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        detailAddressTextField.snp.makeConstraints {
            $0.height.equalTo(Constants.height)
        }
    }

    private func setupActions() {
        addressFieldContainer.addTarget(self, action: #selector(addressButtonTapped), for: .touchUpInside)
        detailAddressTextField.addTarget(self, action: #selector(detailAddressChanged), for: .editingChanged)
    }

    // MARK: - Public Methods

    func configure(address: String?, detailAddress: String) {
        if let address, !address.isEmpty {
            addressField.text = address
            addressField.textColor = .white
            detailAddressTextField.isHidden = false
            detailAddressTextField.text = detailAddress
        } else {
            addressField.text = nil
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
