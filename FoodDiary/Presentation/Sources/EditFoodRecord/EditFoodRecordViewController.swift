//
//  EditFoodRecordViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

// MARK: - Constants

private enum EditFoodRecordConstants {
    static let horizontalInset: CGFloat = 20
    static let sectionSpacing: CGFloat = 28
    static let titleTopSpacing: CGFloat = 16
    static let contentTopSpacing: CGFloat = 12
    static let bottomBarHeight: CGFloat = 50
    static let bottomBarSpacing: CGFloat = 12
    static let bottomBarInset: CGFloat = 20
    static let buttonCornerRadius: CGFloat = 25
}

public final class EditFoodRecordViewController<
    RecordRepo: FoodRecordRepository
>: UIViewController {

    // MARK: - Types

    public enum EditResult {
        case updated(FoodRecord)
        case deleted
        case cancelled
    }

    // MARK: - Dependencies

    private let viewModel: EditFoodRecordViewModel<RecordRepo>
    private let onDismissWithResult: ((EditResult) -> Void)?
    private let onPresentAddressSearch: ((@escaping (AddressSearchResult) -> Void) -> Void)?

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.keyboardDismissMode = .onDrag
        return sv
    }()

    private let contentView = UIView()

    private let imageSectionView = EditImageSectionView()

    private let categoryTitleLabel: UILabel = {
        let label = UILabel()
        label.setText("카테고리", style: .hd18)
        return label
    }()

    private let categoryStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .horizontal
        sv.spacing = 8
        return sv
    }()

    private var categoryChips: [CategoryChipView] = []

    private let addressTitleLabel: UILabel = {
        let label = UILabel()
        label.setText("주소", style: .hd18)
        return label
    }()

    private let addressDisplayView = AddressDisplayView()

    private let tagTitleLabel: UILabel = {
        let label = UILabel()
        label.setText("태그", style: .hd18)
        return label
    }()

    private let tagSectionView = TagSectionView()

    private let bottomBarView = UIView()

    private lazy var deleteButton: UIButton = {
        let button = UIButton()
        button.setAttributedTitle(
            Typography.hd16.styled("삭제", color: .white),
            for: .normal
        )
        button.layer.cornerRadius = EditFoodRecordConstants.buttonCornerRadius
        button.layer.borderWidth = 1
        button.layer.borderColor = UIColor.gray600.cgColor
        button.backgroundColor = .clear
        return button
    }()

    private let saveButton: MumukPrimaryButton = {
        let button = MumukPrimaryButton()
        button.configure(title: "저장")
        return button
    }()

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        viewModel: EditFoodRecordViewModel<RecordRepo>,
        onDismissWithResult: ((EditResult) -> Void)? = nil,
        onPresentAddressSearch: ((@escaping (AddressSearchResult) -> Void) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.onDismissWithResult = onDismissWithResult
        self.onPresentAddressSearch = onPresentAddressSearch
        super.init(nibName: nil, bundle: nil)
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Lifecycle

    public override func viewDidLoad() {
        super.viewDidLoad()
        setupNavigation()
        setupUI()
        setupConstraints()
        setupCategoryChips()
        setupBindings()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "수정"
    }

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(imageSectionView)
        contentView.addSubview(categoryTitleLabel)
        contentView.addSubview(categoryStackView)
        contentView.addSubview(addressTitleLabel)
        contentView.addSubview(addressDisplayView)
        contentView.addSubview(tagTitleLabel)
        contentView.addSubview(tagSectionView)

        view.addSubview(bottomBarView)
        bottomBarView.backgroundColor = .sdBase

        let buttonStack = UIStackView(arrangedSubviews: [deleteButton, saveButton])
        buttonStack.axis = .horizontal
        buttonStack.spacing = EditFoodRecordConstants.bottomBarSpacing
        buttonStack.distribution = .fillProportionally
        bottomBarView.addSubview(buttonStack)

        buttonStack.snp.makeConstraints {
            $0.top.equalToSuperview().offset(8)
            $0.leading.trailing.equalToSuperview().inset(EditFoodRecordConstants.bottomBarInset)
            $0.height.equalTo(EditFoodRecordConstants.bottomBarHeight)
        }

        deleteButton.snp.makeConstraints {
            $0.width.equalTo(saveButton).multipliedBy(0.55)
        }
    }

    private func setupConstraints() {
        bottomBarView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide)
            $0.height.equalTo(EditFoodRecordConstants.bottomBarHeight + 24)
        }

        scrollView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview()
            $0.bottom.equalTo(bottomBarView.snp.top)
        }

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        imageSectionView.snp.makeConstraints {
            $0.top.equalToSuperview().offset(EditFoodRecordConstants.sectionSpacing)
            $0.leading.trailing.equalToSuperview()
        }

        categoryTitleLabel.snp.makeConstraints {
            $0.top.equalTo(imageSectionView.snp.bottom).offset(EditFoodRecordConstants.sectionSpacing)
            $0.leading.equalToSuperview().offset(EditFoodRecordConstants.horizontalInset)
        }

        categoryStackView.snp.makeConstraints {
            $0.top.equalTo(categoryTitleLabel.snp.bottom).offset(EditFoodRecordConstants.contentTopSpacing)
            $0.leading.equalToSuperview().offset(EditFoodRecordConstants.horizontalInset)
        }

        addressTitleLabel.snp.makeConstraints {
            $0.top.equalTo(categoryStackView.snp.bottom).offset(EditFoodRecordConstants.sectionSpacing)
            $0.leading.equalToSuperview().offset(EditFoodRecordConstants.horizontalInset)
        }

        addressDisplayView.snp.makeConstraints {
            $0.top.equalTo(addressTitleLabel.snp.bottom).offset(EditFoodRecordConstants.contentTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(EditFoodRecordConstants.horizontalInset)
        }

        tagTitleLabel.snp.makeConstraints {
            $0.top.equalTo(addressDisplayView.snp.bottom).offset(EditFoodRecordConstants.sectionSpacing)
            $0.leading.equalToSuperview().offset(EditFoodRecordConstants.horizontalInset)
        }

        tagSectionView.snp.makeConstraints {
            $0.top.equalTo(tagTitleLabel.snp.bottom).offset(EditFoodRecordConstants.contentTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(EditFoodRecordConstants.horizontalInset)
            $0.bottom.equalToSuperview().offset(-EditFoodRecordConstants.sectionSpacing)
        }
    }

    private func setupCategoryChips() {
        for genre in FoodGenre.allCases {
            let chip = CategoryChipView(genre: genre)
            categoryChips.append(chip)
            categoryStackView.addArrangedSubview(chip)

            chip.tapPublisher
                .sink { [weak self] genre in
                    self?.viewModel.input.send(.selectGenre(genre))
                }
                .store(in: &cancellables)
        }
    }

    private func setupBindings() {
        // Output: ViewModel → View

        viewModel.statePublisher
            .map(\.selectedGenre)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] genre in
                self?.updateCategoryChips(genre)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map { ($0.imageURLs, $0.newImages) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urls, newImages in
                self?.imageSectionView.configure(existingImageURLs: urls, newImages: newImages)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map { ($0.address, $0.detailAddress) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] address, detailAddress in
                self?.addressDisplayView.configure(address: address, detailAddress: detailAddress)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.hashtags)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] tags in
                self?.tagSectionView.configure(tags: tags)
            }
            .store(in: &cancellables)

        // Events
        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                self?.handleEvent(event)
            }
            .store(in: &cancellables)

        // Input: View → ViewModel

        imageSectionView.addImageTapPublisher
            .sink { [weak self] in
                self?.presentImagePicker()
            }
            .store(in: &cancellables)

        imageSectionView.removeExistingImagePublisher
            .sink { [weak self] index in
                self?.viewModel.input.send(.removeExistingImage(at: index))
            }
            .store(in: &cancellables)

        imageSectionView.removeNewImagePublisher
            .sink { [weak self] index in
                self?.viewModel.input.send(.removeNewImage(at: index))
            }
            .store(in: &cancellables)

        addressDisplayView.addressTapPublisher
            .sink { [weak self] in
                self?.presentAddressSearchModal()
            }
            .store(in: &cancellables)

        addressDisplayView.detailAddressPublisher
            .sink { [weak self] text in
                self?.viewModel.input.send(.updateDetailAddress(text))
            }
            .store(in: &cancellables)

        tagSectionView.addTagTapPublisher
            .sink { [weak self] in
                self?.presentAddTagAlert()
            }
            .store(in: &cancellables)

        tagSectionView.removeTagPublisher
            .sink { [weak self] index in
                self?.viewModel.input.send(.removeHashtag(at: index))
            }
            .store(in: &cancellables)

        // Bottom buttons
        deleteButton.addTarget(self, action: #selector(deleteButtonTapped), for: .touchUpInside)
        saveButton.addTarget(self, action: #selector(saveButtonTapped), for: .touchUpInside)
    }

    // MARK: - Private Methods

    private func updateCategoryChips(_ selectedGenre: FoodGenre) {
        for chip in categoryChips {
            chip.setSelected(chip.genre == selectedGenre)
        }
    }

    private func handleEvent(_ event: EditFoodRecordViewModel<RecordRepo>.Event) {
        switch event {
        case .saveCompleted(let record):
            onDismissWithResult?(.updated(record))
            navigationController?.popViewController(animated: true)

        case .deleteCompleted:
            onDismissWithResult?(.deleted)
            navigationController?.popViewController(animated: true)

        case .error(let error):
            let alert = UIAlertController(
                title: "오류",
                message: error.localizedDescription,
                preferredStyle: .alert
            )
            alert.addAction(UIAlertAction(title: "확인", style: .default))
            present(alert, animated: true)
        }
    }

    private func presentAddressSearchModal() {
        onPresentAddressSearch? { [weak self] result in
            self?.viewModel.input.send(.selectAddress(result))
        }
    }

    private func presentImagePicker() {
        // TODO: todo
    }

    private func presentAddTagAlert() {
        let alert = UIAlertController(
            title: "태그 추가",
            message: "추가할 태그를 입력하세요",
            preferredStyle: .alert
        )
        alert.addTextField { textField in
            textField.placeholder = "태그"
        }
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "추가", style: .default) { [weak self] _ in
            guard let text = alert.textFields?.first?.text else { return }
            self?.viewModel.input.send(.addHashtag(text))
        })
        present(alert, animated: true)
    }

    // MARK: - Actions

    @objc private func deleteButtonTapped() {
        let alert = UIAlertController(
            title: "기록 삭제",
            message: "이 기록을 삭제하시겠습니까?",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "삭제", style: .destructive) { [weak self] _ in
            self?.viewModel.input.send(.delete)
        })
        present(alert, animated: true)
    }

    @objc private func saveButtonTapped() {
        viewModel.input.send(.save)
    }
}
