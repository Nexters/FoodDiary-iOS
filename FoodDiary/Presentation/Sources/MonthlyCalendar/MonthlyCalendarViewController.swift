//
//  MonthlyCalendarViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

private enum MonthlyCalendarConstants {
    static let containerCornerRadius: CGFloat = 16
    static let containerBorderWidth: CGFloat = 1
    static let subtitleTopOffset: CGFloat = 130
    static let titleTopSpacing: CGFloat = 8
    static let horizontalInset: CGFloat = 16
    static let headerTopSpacing: CGFloat = 36
    static let headerHorizontalInset: CGFloat = 20
    static let containerTopSpacing: CGFloat = 24
    static let containerHorizontalInset: CGFloat = 20
    static let containerBottomInset: CGFloat = 100
    static let stackTopInset: CGFloat = 24
    static let stackHorizontalInset: CGFloat = 14
    static let stackBottomInset: CGFloat = 18
}

public final class MonthlyCalendarViewController<
    RecordRepo: FoodRecordRepository,
    AuthRepo: PhotoAuthorizationRepository
>: UIViewController {

    private typealias Constants = MonthlyCalendarConstants

    private enum Section: Hashable {
        case calendar
    }

    // MARK: - Dependencies

    private let viewModel: MonthlyCalendarViewModel<RecordRepo, AuthRepo>

    // MARK: - UI Components
    
    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.alwaysBounceVertical = true
        return sv
    }()

    private let scrollContentView = UIView()

    private let subtitleLabel: UILabel = {
        let label = UILabel()
        label.setText("이번주 음식을 기록해 보세요", style: .p12)
        label.textColor = .white
        return label
    }()

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 2
        label.setText("길동님의 음식 기록,\n지금 바로 쓸 수 있어요", style: .hd20)
        label.textColor = .white
        return label
    }()

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
        view.addSubview(scrollView)
        scrollView.addSubview(scrollContentView)
        scrollContentView.addSubview(subtitleLabel)
        scrollContentView.addSubview(titleLabel)
        scrollContentView.addSubview(monthYearHeaderView)
        scrollContentView.addSubview(containerView)
        containerView.addSubview(stackView)
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.top.equalToSuperview()
            $0.leading.trailing.bottom.equalToSuperview()
        }

        scrollContentView.snp.makeConstraints {
            $0.edges.equalToSuperview()
            $0.width.equalTo(scrollView.snp.width)
        }

        subtitleLabel.snp.makeConstraints {
            $0.top.equalToSuperview().offset(Constants.subtitleTopOffset)
            $0.leading.equalToSuperview().inset(Constants.horizontalInset)
        }

        titleLabel.snp.makeConstraints {
            $0.top.equalTo(subtitleLabel.snp.bottom).offset(Constants.titleTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.horizontalInset)
        }

        monthYearHeaderView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(Constants.headerTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.headerHorizontalInset)
            $0.height.equalTo(32)
        }

        containerView.snp.makeConstraints {
            $0.top.equalTo(monthYearHeaderView.snp.bottom).offset(Constants.containerTopSpacing)
            $0.leading.trailing.equalToSuperview().inset(Constants.containerHorizontalInset)
            $0.bottom.equalToSuperview().inset(Constants.containerBottomInset)
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
            sheet.detents = [.custom { context in context.maximumDetentValue * 0.4 }]
        }

        picker.selectedMonthPublisher
            .sink { [weak self] date in
                self?.viewModel.input.send(.selectMonth(date))
            }
            .store(in: &cancellables)

        present(picker, animated: true)
    }
}
