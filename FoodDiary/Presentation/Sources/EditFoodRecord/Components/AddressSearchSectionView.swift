//
//  AddressSearchSectionView.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

/// 주소 검색 섹션 (검색 텍스트필드 + 결과 목록 + 도로명주소 + 상세주소)
final class AddressSearchSectionView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let textFieldHeight: CGFloat = 48
        static let cornerRadius: CGFloat = 12
        static let horizontalInset: CGFloat = 16
        static let spacing: CGFloat = 8
        static let resultCellHeight: CGFloat = 44
        static let maxVisibleResults: Int = 5
    }

    // MARK: - Publishers

    var searchTextPublisher: AnyPublisher<String, Never> {
        searchTextSubject
            .debounce(for: .milliseconds(500), scheduler: RunLoop.main)
            .removeDuplicates()
            .eraseToAnyPublisher()
    }

    var addressSelectedPublisher: AnyPublisher<AddressSearchResult, Never> {
        addressSelectedSubject.eraseToAnyPublisher()
    }

    var detailAddressPublisher: AnyPublisher<String, Never> {
        detailAddressSubject.eraseToAnyPublisher()
    }

    private let searchTextSubject = PassthroughSubject<String, Never>()
    private let addressSelectedSubject = PassthroughSubject<AddressSearchResult, Never>()
    private let detailAddressSubject = PassthroughSubject<String, Never>()

    // MARK: - State

    private var searchResults: [AddressSearchResult] = []

    // MARK: - UI Components

    private let searchTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .sd900
        tf.layer.cornerRadius = Constants.cornerRadius
        tf.textColor = .white
        tf.attributedPlaceholder = Typography.p14.styled("주소 검색", color: .gray600)
        tf.font = .systemFont(ofSize: 14)
        tf.returnKeyType = .search

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .gray400
        searchIcon.contentMode = .center
        searchIcon.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        tf.rightView = searchIcon
        tf.rightViewMode = .always

        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Constants.horizontalInset, height: 0))
        tf.leftViewMode = .always
        return tf
    }()

    private lazy var resultsTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .sd900
        tv.layer.cornerRadius = Constants.cornerRadius
        tv.separatorColor = .sd600
        tv.isHidden = true
        tv.delegate = self
        tv.dataSource = self
        tv.register(UITableViewCell.self, forCellReuseIdentifier: "ResultCell")
        return tv
    }()

    private let roadAddressLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let detailAddressTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .sd900
        tf.layer.cornerRadius = Constants.cornerRadius
        tf.textColor = .white
        tf.attributedPlaceholder = Typography.p14.styled("상세 주소 입력", color: .gray600)
        tf.font = .systemFont(ofSize: 14)
        tf.isHidden = true

        tf.leftView = UIView(frame: CGRect(x: 0, y: 0, width: Constants.horizontalInset, height: 0))
        tf.leftViewMode = .always
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
        stackView.addArrangedSubview(searchTextField)
        stackView.addArrangedSubview(resultsTableView)
        stackView.addArrangedSubview(roadAddressLabel)
        stackView.addArrangedSubview(detailAddressTextField)
    }

    private func setupConstraints() {
        stackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        searchTextField.snp.makeConstraints {
            $0.height.equalTo(Constants.textFieldHeight)
        }

        detailAddressTextField.snp.makeConstraints {
            $0.height.equalTo(Constants.textFieldHeight)
        }
    }

    private func setupActions() {
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)
        detailAddressTextField.addTarget(self, action: #selector(detailAddressChanged), for: .editingChanged)
    }

    // MARK: - Public Methods

    func configure(address: String?, detailAddress: String) {
        if let address, !address.isEmpty {
            roadAddressLabel.setText(address, style: .p14, color: .gray400)
            roadAddressLabel.isHidden = false
            detailAddressTextField.isHidden = false
            detailAddressTextField.text = detailAddress
        } else {
            roadAddressLabel.isHidden = true
            detailAddressTextField.isHidden = true
        }
    }

    func updateSearchResults(_ results: [AddressSearchResult]) {
        searchResults = results
        resultsTableView.reloadData()
        resultsTableView.isHidden = results.isEmpty

        let height = min(results.count, Constants.maxVisibleResults) * Int(Constants.resultCellHeight)
        resultsTableView.snp.remakeConstraints {
            $0.height.equalTo(height)
        }
    }

    // MARK: - Actions

    @objc private func searchTextChanged() {
        searchTextSubject.send(searchTextField.text ?? "")
    }

    @objc private func detailAddressChanged() {
        detailAddressSubject.send(detailAddressTextField.text ?? "")
    }
}

// MARK: - UITableViewDataSource

extension AddressSearchSectionView: UITableViewDataSource {
    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = tableView.dequeueReusableCell(withIdentifier: "ResultCell", for: indexPath)
        let result = searchResults[indexPath.row]
        cell.backgroundColor = .sd900
        cell.textLabel?.setText("\(result.placeName) - \(result.roadAddress)", style: .p14, color: .white)
        cell.selectionStyle = .none
        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        Constants.resultCellHeight
    }
}

// MARK: - UITableViewDelegate

extension AddressSearchSectionView: UITableViewDelegate {
    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        addressSelectedSubject.send(result)
        searchTextField.text = result.placeName
        searchResults = []
        resultsTableView.isHidden = true
        resultsTableView.reloadData()
        searchTextField.resignFirstResponder()
    }
}
