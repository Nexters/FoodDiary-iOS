//
//  PendingFoodRecordCardView.swift
//  Presentation
//

import DesignSystem
import Domain
import SnapKit
import UIKit

/// 분석 대기 중인 음식 기록 카드 뷰
public final class PendingFoodRecordCardView: UIView {

    // MARK: - Constants

    private enum Constants {
        static let cornerRadius: CGFloat = 20
        static let pendingIconSize: CGFloat = 140
        static let pendingLabelTopSpacing: CGFloat = 27
    }

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .clear
        view.layer.cornerRadius = Constants.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let pendingIconView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.pending.image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let pendingLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        return label
    }()

    // MARK: - Init

    public init(record: PendingFoodRecord) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        pendingLabel.setText(
            "귀찮은 입력은 AI가 대신하고 있어요..",
            style: .p14,
            color: .gray050
        )
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Layout

    public override func layoutSubviews() {
        super.layoutSubviews()
        containerView.updateGradientFrame()
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(pendingIconView)
        containerView.addSubview(pendingLabel)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        pendingIconView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-20)
            $0.size.equalTo(Constants.pendingIconSize)
        }

        pendingLabel.snp.makeConstraints {
            $0.top.equalTo(pendingIconView.snp.bottom).offset(Constants.pendingLabelTopSpacing)
            $0.centerX.equalToSuperview()
        }
    }

}
