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
        static let imageInset: CGFloat = 5
        static let imageAspectRatio: CGFloat = 0.90
        static let infoHorizontalPadding: CGFloat = 18
        static let infoVerticalPadding: CGFloat = 16
        static let titleShimmerHeight: CGFloat = 20
        static let subtitleShimmerHeight: CGFloat = 16
        static let titleShimmerWidth: CGFloat = 100
        static let subtitleShimmerWidth: CGFloat = 80
        static let shimmerSpacing: CGFloat = 8
    }

    // MARK: - UI Components

    private let containerView: UIView = {
        let view = UIView()
        view.backgroundColor = .white
        view.layer.cornerRadius = Constants.cornerRadius
        view.clipsToBounds = true
        return view
    }()

    private let foodImageView: UIImageView = {
        let iv = UIImageView()
        iv.contentMode = .scaleAspectFill
        iv.clipsToBounds = true
        iv.layer.cornerRadius = Constants.cornerRadius
        iv.layer.maskedCorners = [.layerMinXMinYCorner, .layerMaxXMinYCorner]
        iv.backgroundColor = .gray300
        return iv
    }()

    private let titleShimmerView: ShimmerView = {
        let view = ShimmerView()
        view.backgroundColor = .gray200
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    private let subtitleShimmerView: ShimmerView = {
        let view = ShimmerView()
        view.backgroundColor = .gray200
        view.layer.cornerRadius = 4
        view.clipsToBounds = true
        return view
    }()

    // MARK: - Init

    public init(record: PendingFoodRecord) {
        super.init(frame: .zero)
        setupUI()
        setupConstraints()
        foodImageView.image = record.representativeImage
        titleShimmerView.startAnimating()
        subtitleShimmerView.startAnimating()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        addSubview(containerView)
        containerView.addSubview(foodImageView)
        containerView.addSubview(titleShimmerView)
        containerView.addSubview(subtitleShimmerView)
    }

    private func setupConstraints() {
        containerView.snp.makeConstraints {
            $0.edges.equalToSuperview()
        }

        foodImageView.snp.makeConstraints {
            $0.top.leading.trailing.equalToSuperview().inset(Constants.imageInset)
            $0.height.equalTo(foodImageView.snp.width).multipliedBy(Constants.imageAspectRatio).priority(.high)
        }

        titleShimmerView.snp.makeConstraints {
            $0.top.equalTo(foodImageView.snp.bottom).offset(Constants.infoVerticalPadding)
            $0.leading.equalToSuperview().inset(Constants.infoHorizontalPadding)
            $0.width.equalTo(Constants.titleShimmerWidth)
            $0.height.equalTo(Constants.titleShimmerHeight)
        }

        subtitleShimmerView.snp.makeConstraints {
            $0.top.equalTo(titleShimmerView.snp.bottom).offset(Constants.shimmerSpacing)
            $0.leading.equalToSuperview().inset(Constants.infoHorizontalPadding)
            $0.bottom.equalToSuperview().inset(Constants.infoVerticalPadding)
            $0.width.equalTo(Constants.subtitleShimmerWidth)
            $0.height.equalTo(Constants.subtitleShimmerHeight)
        }
    }

}
