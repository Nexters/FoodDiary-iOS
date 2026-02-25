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
>: UIViewController, UIGestureRecognizerDelegate {

    // MARK: - Dependencies

    private let viewModel: EditFoodRecordViewModel<RecordRepo>
    private let addressSearchViewControllerFactory: ((Int, @escaping (AddressSearchResult) -> Void) -> UIViewController)?
    private let presentImagePickerHandler: (
        (_ navigationController: UINavigationController,
         _ date: Date,
         _ onSelected: @escaping ([any ImageAssetable], [UIImage]) -> Void
        ) -> Void)?

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

    private let categoryScrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsHorizontalScrollIndicator = false
        sv.showsVerticalScrollIndicator = false
        return sv
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
        addressSearchViewControllerFactory: ((Int, @escaping (AddressSearchResult) -> Void) -> UIViewController)? = nil,
        presentImagePickerHandler: ((UINavigationController, Date, @escaping ([any ImageAssetable], [UIImage]) -> Void) -> Void)? = nil
    ) {
        self.viewModel = viewModel
        self.addressSearchViewControllerFactory = addressSearchViewControllerFactory
        self.presentImagePickerHandler = presentImagePickerHandler
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
        navigationController?.interactivePopGestureRecognizer?.delegate = self
    }

    public override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "수정"

        let backButton = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )
        navigationItem.leftBarButtonItem = backButton
    }

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)

        contentView.addSubview(imageSectionView)
        contentView.addSubview(categoryTitleLabel)
        contentView.addSubview(categoryScrollView)
        categoryScrollView.addSubview(categoryStackView)
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

        categoryScrollView.snp.makeConstraints {
            $0.top.equalTo(categoryTitleLabel.snp.bottom).offset(EditFoodRecordConstants.contentTopSpacing)
            $0.leading.trailing.equalToSuperview()
        }

        categoryStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(UIEdgeInsets(
                top: 0,
                left: EditFoodRecordConstants.horizontalInset,
                bottom: 0,
                right: EditFoodRecordConstants.horizontalInset
            ))
            $0.height.equalToSuperview()
        }

        addressTitleLabel.snp.makeConstraints {
            $0.top.equalTo(categoryScrollView.snp.bottom).offset(EditFoodRecordConstants.sectionSpacing)
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

        let selectedGenrePublisher = viewModel.statePublisher
            .map(\.selectedGenre)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .share()

        selectedGenrePublisher
            .prefix(1)
            .sink { [weak self] (genre: FoodGenre) in
                self?.updateCategoryChips(genre, animated: false)
            }
            .store(in: &cancellables)

        selectedGenrePublisher
            .dropFirst()
            .sink { [weak self] (genre: FoodGenre) in
                self?.updateCategoryChips(genre, animated: true)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map { ($0.imageURLs, $0.newPreviewImages) }
            .receive(on: DispatchQueue.main)
            .sink { [weak self] urls, newPreviewImages in
                self?.imageSectionView.configure(existingImageURLs: urls, newImages: newPreviewImages)
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

    private func updateCategoryChips(_ selectedGenre: FoodGenre, animated: Bool) {
        for chip in categoryChips {
            chip.setSelected(chip.genre == selectedGenre)
            if chip.genre == selectedGenre {
                let frameInScrollView = chip.convert(chip.bounds, to: categoryScrollView)
                categoryScrollView.scrollRectToVisible(frameInScrollView, animated: animated)
            }
        }
    }

    private func handleEvent(_ event: EditFoodRecordViewModel<RecordRepo>.Event) {
        switch event {
        case .saveCompleted:
            ToastView.show(type: .infoUpdate)
            navigationController?.popViewController(animated: true)

        case .deleteCompleted:
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
        guard let diaryId = Int(viewModel.state.originalRecord.id) else { return }
        guard let addressSearchVC = addressSearchViewControllerFactory?(diaryId, { [weak self] result in
            self?.viewModel.input.send(.selectAddress(result))
        }) else { return }
        present(addressSearchVC, animated: true)
    }

    private func presentImagePicker() {
        guard let nav = navigationController else { return }
        presentImagePickerHandler?(nav, viewModel.state.originalRecord.date) { [weak self] assets, previewImages in
            self?.viewModel.input.send(.addImages(assets: assets, previewImages: previewImages))
        }
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

    private func showUnsavedChangesAlert() {
        let alert = UIAlertController(
            title: "나가시겠어요?",
            message: "저장하지 않으면 수정이 완료되지 않아요",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "취소", style: .cancel))
        alert.addAction(UIAlertAction(title: "나가기", style: .destructive) { [weak self] _ in
            self?.popWithCancelled()
        })
        present(alert, animated: true)
    }

    private func popWithCancelled() {
        navigationController?.popViewController(animated: true)
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        guard !viewModel.state.isSaving else { return }
        showUnsavedChangesAlert()
    }

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

    // MARK: - UIGestureRecognizerDelegate

    public func gestureRecognizerShouldBegin(_ gestureRecognizer: UIGestureRecognizer) -> Bool {
        guard !viewModel.state.isSaving else { return false }
        showUnsavedChangesAlert()
        return false
    }
}
