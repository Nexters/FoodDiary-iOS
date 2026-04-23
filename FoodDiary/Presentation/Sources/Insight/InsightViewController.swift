//
//  InsightViewController.swift
//  Presentation
//

import Combine
import DesignSystem
import Domain
import SnapKit
import UIKit

private enum InsightConstants {
    static let imageSize: CGFloat = 240
    static let textTopSpacing: CGFloat = 32
    static let sectionSpacing: CGFloat = 16
    static let contentInset: CGFloat = 20
}

public final class InsightViewController: UIViewController {

    // MARK: - UI Components

    private let scrollView: UIScrollView = {
        let sv = UIScrollView()
        sv.showsVerticalScrollIndicator = false
        sv.isHidden = true
        return sv
    }()

    private let contentStackView: UIStackView = {
        let sv = UIStackView()
        sv.axis = .vertical
        sv.spacing = InsightConstants.sectionSpacing
        return sv
    }()

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.emptyInsight.image
        iv.contentMode = .scaleAspectFit
        iv.isHidden = true
        return iv
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.numberOfLines = 0
        label.isHidden = true
        return label
    }()

    private let loadingIndicator: UIActivityIndicatorView = {
        let indicator = UIActivityIndicatorView(style: .large)
        indicator.color = .gray300
        indicator.hidesWhenStopped = true
        return indicator
    }()

    // MARK: - Properties

    private let viewModel: InsightViewModel
    private var cancellables = Set<AnyCancellable>()

    // MARK: - Init

    public init(viewModel: InsightViewModel) {
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
        setupBindings()
        viewModel.input.send(.loadInsight)
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(scrollView)
        scrollView.addSubview(contentStackView)

        view.addSubview(emptyImageView)
        view.addSubview(descriptionLabel)
        view.addSubview(loadingIndicator)

        descriptionLabel.setText(
            "인사이트를 제공하기 위해\n최소 1주일간의 데이터가 필요해요.",
            style: .p14,
            color: .gray050,
            alignment: .center,
            lineSpacing: 4
        )
    }

    private func setupConstraints() {
        scrollView.snp.makeConstraints {
            $0.edges.equalTo(view.safeAreaLayoutGuide)
        }

        contentStackView.snp.makeConstraints {
            $0.edges.equalToSuperview().inset(InsightConstants.contentInset)
            $0.width.equalToSuperview().offset(-InsightConstants.contentInset * 2)
        }

        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-40)
            $0.size.equalTo(InsightConstants.imageSize)
        }

        descriptionLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emptyImageView.snp.bottom).offset(InsightConstants.textTopSpacing)
        }

        loadingIndicator.snp.makeConstraints {
            $0.center.equalToSuperview()
        }
    }

    private func setupBindings() {
        viewModel.statePublisher
            .map(\.isLoading)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (isLoading: Bool) in
                if isLoading {
                    self?.loadingIndicator.startAnimating()
                } else {
                    self?.loadingIndicator.stopAnimating()
                }
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .map(\.hasInsufficientData)
            .removeDuplicates()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (insufficientData: Bool) in
                self?.emptyImageView.isHidden = !insufficientData
                self?.descriptionLabel.isHidden = !insufficientData
                self?.scrollView.isHidden = insufficientData
            }
            .store(in: &cancellables)

        viewModel.statePublisher
            .compactMap(\.insight)
            .first()
            .receive(on: DispatchQueue.main)
            .sink { [weak self] (insight: Insight) in
                self?.buildContentSections(with: insight)
            }
            .store(in: &cancellables)

        viewModel.eventPublisher
            .receive(on: DispatchQueue.main)
            .sink { [weak self] event in
                switch event {
                case .loadFailed:
                    self?.showLoadFailedAlert()
                }
            }
            .store(in: &cancellables)
    }

    private func showLoadFailedAlert() {
        let alert = UIAlertController(
            title: "오류",
            message: "데이터를 불러오는 데 실패했습니다.\n다시 시도해 주세요.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "다시 시도", style: .default) { [weak self] _ in
            self?.viewModel.input.send(.loadInsight)
        })
        alert.addAction(UIAlertAction(title: "닫기", style: .cancel))
        present(alert, animated: true)
    }

    // MARK: - Content

    private func buildContentSections(with insight: Insight) {
        emptyImageView.isHidden = true
        descriptionLabel.isHidden = true
        scrollView.isHidden = false

        var sections: [UIView] = [
            InsightHeaderView(),
            InsightPhotoStatsView(photoStats: insight.photoStats, month: insight.month),
            InsightCategoryStatsView(categoryStats: insight.categoryStats),
            InsightTopMenuView(weeklyStats: insight.weeklyStats),
            InsightDiaryTimeStatsView(diaryTimeStats: insight.diaryTimeStats)
        ]

        if !insight.locationStats.isEmpty {
            sections.append(InsightLocationStatsView(locationStats: insight.locationStats))
        }

        sections.append(InsightKeywordsView(keywords: insight.tagStats))

        sections.forEach { contentStackView.addArrangedSubview($0) }
    }
}
