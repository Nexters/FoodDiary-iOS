//
//  AddressSearchViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

// MARK: - Constants

/// Cannot use `static let`` inside the class due to generic type constraints, so we define it outside.
enum AddressSearchConstants {
    static let horizontalInset: CGFloat = 20
    static let textFieldHeight: CGFloat = 48
    static let cornerRadius: CGFloat = 10
    static let closeButtonSize: CGFloat = 44
    static let closeButtonTopInset: CGFloat = 20
    static let searchFieldTopSpacing: CGFloat = 16
    static let guideLabelTopSpacing: CGFloat = 24
    static let resultsTopSpacing: CGFloat = 24
    static let resultCellHeight: CGFloat = 72
}

public final class AddressSearchViewController<
    AddressRepo: AddressSearchRepository
>: UIViewController, UITextFieldDelegate {

    // MARK: - Callback

    public var onAddressSelected: ((AddressSearchResult) -> Void)?

    // MARK: - Dependencies

    private let viewModel: AddressSearchViewModel<AddressRepo>
    private var cancellables = Set<AnyCancellable>()
    private var containerHeightConstraint: Constraint?

    // MARK: - TableView Handler

    private lazy var tableViewHandler: AddressSearchTableViewHandler = {
        let handler = AddressSearchTableViewHandler()
        handler.onSelectAddress = { [weak self] result in
            self?.viewModel.input.send(.selectAddress(result))
        }
        return handler
    }()

    // MARK: - UI Components

    private lazy var closeButton: UIButton = {
        let button = UIButton(type: .system)
        button.setImage(UIImage(systemName: "xmark"), for: .normal)
        button.tintColor = .white
        button.addTarget(self, action: #selector(closeButtonTapped), for: .touchUpInside)
        return button
    }()

    private lazy var searchTextField: UITextField = {
        let tf = UITextField()
        tf.backgroundColor = .sd900
        tf.layer.cornerRadius = AddressSearchConstants.cornerRadius
        tf.textColor = .white
        tf.attributedPlaceholder = Typography.p14.styled("검색어를 입력해주세요.", color: .gray600)
        tf.font = DesignSystemFontFamily.Pretendard.regular.font(size: 14)
        tf.returnKeyType = .search
        tf.delegate = self

        let searchIcon = UIImageView(image: UIImage(systemName: "magnifyingglass"))
        searchIcon.tintColor = .gray400
        searchIcon.contentMode = .center
        searchIcon.isUserInteractionEnabled = true

        let searchButton = UIButton(type: .system)
        searchButton.setImage(UIImage(systemName: "magnifyingglass"), for: .normal)
        searchButton.tintColor = .gray400
        searchButton.frame = CGRect(x: 0, y: 0, width: 40, height: 20)
        searchButton.addTarget(self, action: #selector(searchButtonTapped), for: .touchUpInside)
        tf.rightView = searchButton
        tf.rightViewMode = .always

        let leftPadding = UIView(frame: CGRect(x: 0, y: 0, width: 16, height: 0))
        tf.leftView = leftPadding
        tf.leftViewMode = .always
        return tf
    }()

    private let guideLabel: UILabel = {
        let label = UILabel()
        label.setText("이 식당을 찾고 계신가요?", style: .hd16)
        return label
    }()

    private let resultsContainerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.borderColor = UIColor.sd800.cgColor
        view.layer.borderWidth = 1

        view.layer.cornerRadius = AddressSearchConstants.cornerRadius
        view.clipsToBounds = true
        view.isHidden = true
        return view
    }()

    private let emptyResultLabel: UILabel = {
        let label = UILabel()
        label.setText("검색 결과가 없습니다.", style: .p14, color: .gray400)
        label.textAlignment = .center
        label.isHidden = true
        return label
    }()

    private lazy var resultsTableView: UITableView = {
        let tv = UITableView()
        tv.backgroundColor = .clear
        tv.separatorColor = .sd600
        tv.separatorInset = UIEdgeInsets(top: 0, left: 16, bottom: 0, right: 16)
        tv.delegate = tableViewHandler
        tv.dataSource = tableViewHandler
        tv.register(
            AddressSearchResultCell.self,
            forCellReuseIdentifier: AddressSearchResultCell.reuseIdentifier)
        tv.rowHeight = UITableView.automaticDimension
        tv.estimatedRowHeight = AddressSearchConstants.resultCellHeight
        tv.showsVerticalScrollIndicator = false
        tv.tableFooterView = UIView()
        return tv
    }()

    // MARK: - Init

    public init(viewModel: AddressSearchViewModel<AddressRepo>) {
        self.viewModel = viewModel
        super.init(nibName: nil, bundle: nil)
        modalPresentationStyle = .fullScreen
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupUI()
        setupConstraints()
        setupBindings()
    }

    public override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        searchTextField.becomeFirstResponder()
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        let contentHeight = resultsTableView.contentSize.height
        resultsTableView.isScrollEnabled = contentHeight > resultsContainerView.bounds.height
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(closeButton)
        view.addSubview(searchTextField)
        view.addSubview(guideLabel)
        view.addSubview(emptyResultLabel)
        view.addSubview(resultsContainerView)
        resultsContainerView.addSubview(resultsTableView)
    }

    private func setupConstraints() {
        closeButton.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(
                AddressSearchConstants.closeButtonTopInset)
            $0.trailing.equalToSuperview().offset(-AddressSearchConstants.horizontalInset)
            $0.size.equalTo(AddressSearchConstants.closeButtonSize)
        }

        searchTextField.snp.makeConstraints {
            $0.top.equalTo(closeButton.snp.bottom).offset(
                AddressSearchConstants.searchFieldTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(AddressSearchConstants.horizontalInset)
            $0.height.equalTo(AddressSearchConstants.textFieldHeight)
        }

        guideLabel.snp.makeConstraints {
            $0.top.equalTo(searchTextField.snp.bottom).offset(
                AddressSearchConstants.guideLabelTopSpacing)
            $0.leading.equalToSuperview().offset(AddressSearchConstants.horizontalInset)
        }

        emptyResultLabel.snp.makeConstraints {
            $0.top.equalTo(guideLabel.snp.bottom).offset(
                AddressSearchConstants.resultsTopSpacing + 24)
            $0.leading.trailing.equalToSuperview().inset(AddressSearchConstants.horizontalInset)
        }

        resultsContainerView.snp.makeConstraints {
            $0.top.equalTo(guideLabel.snp.bottom).offset(AddressSearchConstants.resultsTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(AddressSearchConstants.horizontalInset)
            containerHeightConstraint = $0.height.equalTo(0).priority(.high).constraint
            $0.bottom.lessThanOrEqualTo(view.safeAreaLayoutGuide)
        }

        resultsTableView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }
    }

    private func setupBindings() {
        searchTextField.addTarget(self, action: #selector(searchTextChanged), for: .editingChanged)

        viewModel.statePublisher
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateUI(with: state)
            }
            .store(in: &cancellables)

        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)

    }

    // MARK: - Private Methods

    private func updateUI(with state: AddressSearchViewModel<AddressRepo>.State) {
        let displayResults: [AddressSearchResult]

        switch state.mode {
        case .suggestions:
            guideLabel.setText("이 식당을 찾고 계신가요?", style: .hd16)
            displayResults = state.suggestions
        case .searchResults:
            guideLabel.setText("검색 결과", style: .hd16)
            displayResults = state.searchResults
        }

        tableViewHandler.searchResults = displayResults
        resultsTableView.reloadData()
        resultsContainerView.isHidden = displayResults.isEmpty

        emptyResultLabel.isHidden = !(state.mode == .searchResults && displayResults.isEmpty)

        Task { @MainActor [weak self] in
            guard let self else { return }
            self.view.layoutIfNeeded()
            let contentHeight = self.resultsTableView.contentSize.height
            self.containerHeightConstraint?.update(offset: contentHeight)
        }
    }

    private func handleEvent(_ event: AddressSearchViewModel<AddressRepo>.Event) {
        switch event {
        case .addressSelected(let result):
            onAddressSelected?(result)
            dismiss(animated: true)

        case .dismissed:
            dismiss(animated: true)
        }
    }

    // MARK: - Actions

    @objc private func searchTextChanged() {
        let text = searchTextField.text ?? ""
        viewModel.input.send(.updateSearchKeyword(text))
    }

    @objc private func searchButtonTapped() {
        viewModel.input.send(.search)
        searchTextField.resignFirstResponder()
    }

    @objc private func closeButtonTapped() {
        dismiss(animated: true)
    }

    // MARK: - UITextFieldDelegate

    public func textFieldShouldReturn(_ textField: UITextField) -> Bool {
        viewModel.input.send(.search)
        textField.resignFirstResponder()
        return true
    }
}

// MARK: - TableView Handler

final class AddressSearchTableViewHandler: NSObject, UITableViewDataSource, UITableViewDelegate {

    var searchResults: [AddressSearchResult] = []
    var onSelectAddress: ((AddressSearchResult) -> Void)?

    func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        searchResults.count
    }

    func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        guard
            let cell = tableView.dequeueReusableCell(
                withIdentifier: AddressSearchResultCell.reuseIdentifier,
                for: indexPath
            ) as? AddressSearchResultCell
        else {
            return UITableViewCell()
        }

        let result = searchResults[indexPath.row]
        cell.configure(with: result)
        cell.onSelectTapped = { [weak self] in
            self?.onSelectAddress?(result)
        }

        return cell
    }

    func tableView(_ tableView: UITableView, heightForRowAt indexPath: IndexPath) -> CGFloat {
        UITableView.automaticDimension
    }

    func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        let result = searchResults[indexPath.row]
        onSelectAddress?(result)
    }
}
