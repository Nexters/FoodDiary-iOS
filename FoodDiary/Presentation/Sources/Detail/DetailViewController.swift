//
//  DetailViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import Kingfisher
import SnapKit
import UIKit

public final class DetailViewController<RecordRepo: FoodRecordRepository>: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static var dateNavigatorHeight: CGFloat { 64 }
        static var dateNavigatorTopPadding: CGFloat { 32 }
        static var dateNavigatorBottomSpacing: CGFloat { 16 }
        static var bottomPadding: CGFloat { 32 }
        static var toastCornerRadius: CGFloat { 16 }
        static var toastHeight: CGFloat { 32 }
        static var toastMinWidth: CGFloat { 150 }
        static var toastBottomOffset: CGFloat { 32 }
    }

    // MARK: - Dependencies

    private let viewModel: DetailViewModel<RecordRepo>

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        return sv
    }()

    private let contentView = UIView()

    private let dateNavigatorView = DetailDateNavigatorView()

    private let mealSectionsStackView: UIStackView = {
        let stack = UIStackView()
        stack.axis = .vertical
        stack.spacing = 0
        return stack
    }()

    private let breakfastSection = MealSectionView(mealType: .breakfast)
    private let lunchSection = MealSectionView(mealType: .lunch)
    private let dinnerSection = MealSectionView(mealType: .dinner)

    // MARK: - State

    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(
        initialRecord: FoodRecord,
        viewModel: DetailViewModel<RecordRepo>
    ) {
        self.viewModel = viewModel
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
        setupBindings()

        viewModel.input.send(.loadRecords)
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(false, animated: animated)
    }

    // MARK: - Setup

    private func setupNavigation() {
        title = "상세보기"

        // Navigation bar appearance
        let appearance = UINavigationBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = .sdBase
        appearance.titleTextAttributes = [.foregroundColor: UIColor.white]
        navigationController?.navigationBar.standardAppearance = appearance
        navigationController?.navigationBar.scrollEdgeAppearance = appearance
        navigationController?.navigationBar.tintColor = .white

        // Back button
        navigationItem.leftBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "chevron.left"),
            style: .plain,
            target: self,
            action: #selector(backButtonTapped)
        )

        // More button
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            image: UIImage(systemName: "ellipsis"),
            style: .plain,
            target: self,
            action: #selector(moreButtonTapped)
        )
    }

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentView)
        contentView.addSubview(mealSectionsStackView)
        view.addSubview(dateNavigatorView)

        mealSectionsStackView.addArrangedSubview(breakfastSection)
        mealSectionsStackView.addArrangedSubview(lunchSection)
        mealSectionsStackView.addArrangedSubview(dinnerSection)
    }

    private func setupConstraints() {
        dateNavigatorView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.dateNavigatorTopPadding)
            $0.leading.trailing.equalToSuperview()
            $0.height.equalTo(Constants.dateNavigatorHeight)
        }

        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }
        let topInset = Constants.dateNavigatorTopPadding + Constants.dateNavigatorHeight + Constants.dateNavigatorBottomSpacing
        scrollView.contentInset.top = topInset
        scrollView.verticalScrollIndicatorInsets.top = topInset

        contentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalToSuperview()
        }

        mealSectionsStackView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.equalToSuperview()
            $0.bottom.equalToSuperview().offset(-Constants.bottomPadding)
        }
    }

    private func setupBindings() {
        // Input: View → ViewModel
        dateNavigatorView.previousTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToPreviousDay)
            }
            .store(in: &cancellables)

        dateNavigatorView.nextTapPublisher
            .sink { [weak self] in
                self?.viewModel.input.send(.goToNextDay)
            }
            .store(in: &cancellables)

        // Output: ViewModel → View
        viewModel.statePublisher
            .map(\.dateText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] dateText in
                self?.dateNavigatorView.setDateText(dateText)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.isLoading)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] isLoading in
                self?.dateNavigatorView.setPending(isLoading)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.recordsByMealType)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] recordsByMealType in
                self?.updateMealSections(recordsByMealType)
            }
            .store(in: &cancellables)

        // Card events
        setupCardEventBindings()
    }

    private func setupCardEventBindings() {
        // Breakfast section
        breakfastSection.copyTapPublisher
            .sink { [weak self] record in
                self?.handleCopy(record: record)
            }
            .store(in: &cancellables)

        breakfastSection.shareTapPublisher
            .sink { [weak self] record in
                self?.handleShare(record: record)
            }
            .store(in: &cancellables)

        // Lunch section
        lunchSection.copyTapPublisher
            .sink { [weak self] record in
                self?.handleCopy(record: record)
            }
            .store(in: &cancellables)

        lunchSection.shareTapPublisher
            .sink { [weak self] record in
                self?.handleShare(record: record)
            }
            .store(in: &cancellables)

        // Dinner section
        dinnerSection.copyTapPublisher
            .sink { [weak self] record in
                self?.handleCopy(record: record)
            }
            .store(in: &cancellables)

        dinnerSection.shareTapPublisher
            .sink { [weak self] record in
                self?.handleShare(record: record)
            }
            .store(in: &cancellables)

        // Edit buttons
        breakfastSection.editTapPublisher
            .sink { [weak self] mealType in
                self?.handleEdit(mealType: mealType)
            }
            .store(in: &cancellables)

        lunchSection.editTapPublisher
            .sink { [weak self] mealType in
                self?.handleEdit(mealType: mealType)
            }
            .store(in: &cancellables)

        dinnerSection.editTapPublisher
            .sink { [weak self] mealType in
                self?.handleEdit(mealType: mealType)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func updateMealSections(_ recordsByMealType: [MealType: [FoodRecord]]) {
        breakfastSection.configure(records: recordsByMealType[.breakfast] ?? [])
        lunchSection.configure(records: recordsByMealType[.lunch] ?? [])
        dinnerSection.configure(records: recordsByMealType[.dinner] ?? [])
    }

    private func formatRecordForCopy(_ record: FoodRecord) -> String {
        var lines: [String] = []
        if let name = record.restaurantName {
            lines.append(name)
        }
        lines.append(record.genre.rawValue)
        if !record.hashtags.isEmpty {
            lines.append(record.hashtags.map { "#\($0)" }.joined(separator: " "))
        }
        return lines.joined(separator: "\n")
    }

    private func handleCopy(record: FoodRecord) {
        let text = formatRecordForCopy(record)
        UIPasteboard.general.string = text

        // Show toast
        showToast(message: "클립보드에 복사되었습니다")
    }

    private func handleShare(record: FoodRecord) {
        let text = formatRecordForCopy(record)

        // Image from Kingfisher cache
        if let imageURL = record.imageURLs.first {
            ImageCache.default.retrieveImage(forKey: imageURL.absoluteString) { [weak self] result in
                guard let self else { return }
                DispatchQueue.main.async {
                    var items: [Any] = [text]
                    if case .success(let cacheResult) = result, let image = cacheResult.image {
                        items.insert(image, at: 0)
                    }
                    self.presentShareSheet(items: items)
                }
            }
        } else {
            presentShareSheet(items: [text])
        }
    }

    private func presentShareSheet(items: [Any]) {
        let activityVC = UIActivityViewController(
            activityItems: items,
            applicationActivities: nil
        )
        present(activityVC, animated: true)
    }

    private func showToast(message: String) {
        let toastLabel = UILabel()
        toastLabel.backgroundColor = UIColor.black.withAlphaComponent(0.7)
        toastLabel.textColor = .white
        toastLabel.textAlignment = .center
        toastLabel.font = .systemFont(ofSize: 14)
        toastLabel.text = message
        toastLabel.alpha = 0
        toastLabel.layer.cornerRadius = Constants.toastCornerRadius
        toastLabel.clipsToBounds = true

        view.addSubview(toastLabel)
        toastLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.bottom.equalTo(view.safeAreaLayoutGuide).offset(-Constants.toastBottomOffset)
            $0.height.equalTo(Constants.toastHeight)
            $0.width.greaterThanOrEqualTo(Constants.toastMinWidth)
        }

        UIView.animate(withDuration: 0.3, animations: {
            toastLabel.alpha = 1
        }) { _ in
            UIView.animate(withDuration: 0.3, delay: 1.5, options: [], animations: {
                toastLabel.alpha = 0
            }) { _ in
                toastLabel.removeFromSuperview()
            }
        }
    }

    // MARK: - Actions

    @objc private func backButtonTapped() {
        navigationController?.popViewController(animated: true)
    }

    @objc private func moreButtonTapped() {
        // TODO: Show more options menu
    }

    private func handleEdit(mealType: MealType) {
        // TODO: Navigate to edit screen
    }
}
