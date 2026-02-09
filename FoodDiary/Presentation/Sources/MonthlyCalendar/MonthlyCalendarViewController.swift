//
//  MonthlyCalendarViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

public final class MonthlyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AuthRepo: PhotoAuthorizationRepository
>: UIViewController, UIAdaptivePresentationControllerDelegate, UICollectionViewDelegate {

    private enum Section: Hashable {
        case calendar
    }

    // MARK: - Dependencies

    private let viewModel: MonthlyCalendarViewModel<RecordRepo, AuthRepo>

    // MARK: - UI Components

    private let recordPromptHeaderView = RecordPromptHeaderView()
    private let monthYearHeaderView = MonthlyCalendarHeaderView()
    private let weekdayHeaderView = WeekdayHeaderView()
    
    private lazy var containerView: UIView = {
        let v = UIView()
        v.layer.borderColor = DesignSystemAsset.sd800.color.cgColor
        v.backgroundColor = DesignSystemAsset.sd900.color
        v.layer.borderWidth = Constants.containerBorderWidth
        v.layer.cornerRadius = Constants.containerCornerRadius
        return v
    }()

    private lazy var stackView: UIStackView = {
        let sv = UIStackView(arrangedSubviews: [weekdayHeaderView, collectionView])
        sv.axis = .vertical
        sv.distribution = .fill
        sv.spacing = 16
        return sv
    }()

    private lazy var collectionView: UICollectionView = {
        let cv = UICollectionView(frame: .zero, collectionViewLayout: createLayout())
        cv.backgroundColor = .clear
        cv.isScrollEnabled = false
        cv.register(
            MonthlyCalendarDayCell.self,
            forCellWithReuseIdentifier: MonthlyCalendarDayCell.reuseIdentifier
        )
        return cv
    }()

    // MARK: - State

    private var dataSource: UICollectionViewDiffableDataSource<Section, MonthlyCalendarDay>?
    private var cancellables = Set<AnyCancellable>()
    private var monthPickerCancellable: AnyCancellable?
    private var numberOfWeeks: Int = 5
    private var collectionViewHeightConstraint: Constraint?

    // MARK: - Init

    public init(viewModel: MonthlyCalendarViewModel<RecordRepo, AuthRepo>) {
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
        setupUI()
        setupConstraints()
        setupDataSource()
        setupBindings()

        collectionView.delegate = self

        viewModel.input.send(.loadInitialData)
    }

    public override func viewDidLayoutSubviews() {
        super.viewDidLayoutSubviews()
        updateCollectionViewHeight()
    }

    public override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        navigationController?.setNavigationBarHidden(true, animated: animated)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color
        view.addSubview(recordPromptHeaderView)
        view.addSubview(monthYearHeaderView)
        view.addSubview(containerView)
        containerView.addSubview(stackView)
    }

    private func setupConstraints() {
        recordPromptHeaderView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Constants.recordPromptHorizontalInset)
            $0.bottom.equalTo(monthYearHeaderView.snp.top).offset(Constants.recordPromptBottomOffset)
        }

        monthYearHeaderView.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(Constants.headerHorizontalInset)
            $0.bottom.equalTo(containerView.snp.top).offset(Constants.headerBottomOffset)
            $0.height.equalTo(32)
        }

        containerView.snp.makeConstraints {
            $0.top.equalTo(view.safeAreaLayoutGuide).offset(Constants.containerTopOffset)
            $0.leading.trailing.equalToSuperview().inset(Constants.containerHorizontalInset)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(Constants.containerBottomInset)
        }

        stackView.snp.makeConstraints {
            $0.top.equalToSuperview().inset(Constants.stackTopInset)
            $0.leading.trailing.equalToSuperview().inset(Constants.stackHorizontalInset)
            $0.bottom.equalToSuperview().inset(Constants.stackBottomInset)
        }

        collectionView.snp.makeConstraints {
            collectionViewHeightConstraint = $0.height.equalTo(0).constraint
        }
    }

    private func createLayout() -> UICollectionViewLayout {
        UICollectionViewCompositionalLayout { [weak self] _, _ in
            guard let self else { return nil }

            let itemSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0 / 7.0),
                heightDimension: .fractionalHeight(1.0)
            )
            let item = NSCollectionLayoutItem(layoutSize: itemSize)
            item.contentInsets = NSDirectionalEdgeInsets(top: 0, leading: 1.5, bottom: 0, trailing: 1.5)

            let groupSize = NSCollectionLayoutSize(
                widthDimension: .fractionalWidth(1.0),
                heightDimension: .fractionalHeight(1.0 / CGFloat(self.numberOfWeeks))
            )
            let group = NSCollectionLayoutGroup.horizontal(layoutSize: groupSize, subitems: [item])

            let section = NSCollectionLayoutSection(group: group)

            return section
        }
    }

    private func setupDataSource() {
        dataSource = UICollectionViewDiffableDataSource<Section, MonthlyCalendarDay>(collectionView: collectionView) { collectionView, indexPath, day in
            guard let cell = collectionView.dequeueReusableCell(
                withReuseIdentifier: MonthlyCalendarDayCell.reuseIdentifier,
                for: indexPath
            ) as? MonthlyCalendarDayCell else {
                return UICollectionViewCell()
            }

            cell.configure(with: day, isSelected: false)
            return cell
        }
    }

    private func setupBindings() {
        // Input: View → ViewModel
        monthYearHeaderView.monthPickerTapPublisher
            .sink { [weak self] in
                self?.presentMonthPicker()
            }
            .store(in: &cancellables)

        // Output: ViewModel → View
        viewModel.statePublisher
            .map(\.monthYearText)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] text in
                self?.monthYearHeaderView.setMonthYearText(text)
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] state in
                self?.updateCalendar(days: state.monthDays, numberOfWeeks: state.numberOfWeeks)
            }
            .store(in: &cancellables)
    }

    // MARK: - Private Methods

    private func updateCalendar(days: [MonthlyCalendarDay], numberOfWeeks: Int) {
        self.numberOfWeeks = numberOfWeeks
        updateCollectionViewHeight()
        collectionView.collectionViewLayout.invalidateLayout()
        applySnapshot(days: days)
    }

    private func updateCollectionViewHeight() {
        let availableWidth = view.bounds.width - Constants.containerHorizontalInset * 2 - Constants.stackHorizontalInset * 2
        let cellWidth = availableWidth / 7

        let rowHeight = cellWidth + 28
        let totalHeight = rowHeight * CGFloat(numberOfWeeks)
        collectionViewHeightConstraint?.update(offset: totalHeight)
    }

    private func applySnapshot(days: [MonthlyCalendarDay]) {
        var snapshot = NSDiffableDataSourceSnapshot<Section, MonthlyCalendarDay>()
        snapshot.appendSections([.calendar])
        snapshot.appendItems(days, toSection: .calendar)
        dataSource?.apply(snapshot, animatingDifferences: false)
    }

    private func presentMonthPicker() {
        let picker = MonthPickerBottomSheetViewController(
            currentMonth: viewModel.state.currentDisplayDate
        )

        if let sheet = picker.sheetPresentationController {
            sheet.detents = [.custom { context in context.maximumDetentValue * 0.45 }]
        }

        picker.presentationController?.delegate = self

        monthPickerCancellable = picker.selectedMonthPublisher
            .sink { [weak self] date in
                self?.viewModel.input.send(.selectMonth(date))
                self?.monthPickerCancellable = nil
            }

        present(picker, animated: true)
    }

    // MARK: - UIAdaptivePresentationControllerDelegate

    public func presentationControllerWillDismiss(_ presentationController: UIPresentationController) {
        monthYearHeaderView.resetChevron()
    }

    // MARK: - UICollectionViewDelegate

    public func collectionView(_ collectionView: UICollectionView, didSelectItemAt indexPath: IndexPath) {
        guard let day = dataSource?.itemIdentifier(for: indexPath) else { return }

        let detailVC = FoodRecordDetailViewController(records: day.records, date: day.date)
        detailVC.modalPresentationStyle = .pageSheet
        present(detailVC, animated: true)
    }
}

// MARK: - Constants

extension MonthlyCalendarViewController {
    enum Constants {
        static var containerCornerRadius: CGFloat { 16 }
        static var containerBorderWidth: CGFloat { 1 }
        static var recordPromptHorizontalInset: CGFloat { 16 }
        static var recordPromptBottomOffset: CGFloat { -18 }
        static var headerBottomOffset: CGFloat { -18 }
        static var headerHorizontalInset: CGFloat { 20 }
        static var containerTopOffset: CGFloat { 260 }
        static var containerHorizontalInset: CGFloat { 20 }
        static var containerBottomInset: CGFloat { 100 }
        static var stackTopInset: CGFloat { 24 }
        static var stackHorizontalInset: CGFloat { 14 }
        static var stackBottomInset: CGFloat { 18 }
    }
}
