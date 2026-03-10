//
//  InsightTopMenuView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

final class InsightTopMenuView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let maxBarHeight: CGFloat = 160
        static let lineCount: Int = 6
        static let barWidth: CGFloat = 60
    }

    // MARK: - UI Components

    private let titleLabel = UILabel()
    private let separatorView = UIView()
    private let chartContainerView = UIView()
    private let linesStackView = UIStackView()
    private let barView: GradientBarView
    private let countLabel = UILabel()
    private let nameLabel = UILabel()

    // MARK: - Init

    init(topMenu: TopMenu) {
        barView = GradientBarView(colors: [.primaryGradientStart, .primaryGradientEnd])
        super.init(frame: .zero)
        setupUI(topMenu: topMenu)
        setupConstraints()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI(topMenu: TopMenu) {
        backgroundColor = .sd900
        layer.cornerRadius = 16
        clipsToBounds = true

        setupTitle(name: topMenu.name)
        setupSeparator()
        setupChart(count: topMenu.count)
    }

    private func setupTitle(name: String) {
        let attributed = NSMutableAttributedString()
        attributed.append(Typography.hd15.styled("가장 자주 먹은\n음식은 ", color: .white, lineSpacing: 6))
        attributed.append(Typography.hd15.styled(name, color: .primary))

        titleLabel.attributedText = attributed
        titleLabel.numberOfLines = 0
        addSubview(titleLabel)
    }

    private func setupSeparator() {
        separatorView.backgroundColor = .sd800
        addSubview(separatorView)
    }

    private func setupChart(count: Int) {
        addSubview(chartContainerView)

        // Grid lines
        linesStackView.axis = .vertical
        linesStackView.distribution = .equalSpacing
        chartContainerView.addSubview(linesStackView)

        for _ in 0..<Constants.lineCount {
            let line = UIView()
            line.backgroundColor = .sd800
            line.translatesAutoresizingMaskIntoConstraints = false
            line.heightAnchor.constraint(equalToConstant: 0.5).isActive = true
            linesStackView.addArrangedSubview(line)
        }

        // Bar
        chartContainerView.addSubview(barView)

        countLabel.setText("\(count)회", style: .p12, color: .white)
        countLabel.textAlignment = .center
        barView.addSubview(countLabel)

        // Name label below bar
        nameLabel.setText("총 기록", style: .p10, color: .gray200)
        nameLabel.textAlignment = .center
        addSubview(nameLabel)
    }

    private func setupConstraints() {
        titleLabel.snp.makeConstraints {
            $0.top.leading.equalToSuperview().inset(20)
            $0.trailing.lessThanOrEqualToSuperview().inset(20)
        }

        separatorView.snp.makeConstraints {
            $0.top.equalTo(titleLabel.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(0.5)
        }

        chartContainerView.snp.makeConstraints {
            $0.top.equalTo(separatorView.snp.bottom).offset(20)
            $0.leading.trailing.equalToSuperview().inset(20)
            $0.height.equalTo(Constants.maxBarHeight)
        }

        linesStackView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        barView.snp.makeConstraints {
            $0.centerX.bottom.equalToSuperview()
            $0.width.equalTo(Constants.barWidth)
            $0.height.equalTo(Constants.maxBarHeight)
        }

        countLabel.snp.makeConstraints {
            $0.top.equalToSuperview().inset(6)
            $0.centerX.equalToSuperview()
        }

        nameLabel.snp.makeConstraints {
            $0.top.equalTo(chartContainerView.snp.bottom).offset(8)
            $0.centerX.equalTo(barView)
            $0.bottom.equalToSuperview().inset(20)
        }
    }
}
