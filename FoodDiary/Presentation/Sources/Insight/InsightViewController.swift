//
//  InsightViewController.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

public final class InsightViewController: UIViewController {

    // MARK: - Constants

    private enum Constants {
        static let imageSize: CGFloat = 240
        static let textTopSpacing: CGFloat = 32
    }

    // MARK: - UI Components

    private let emptyImageView: UIImageView = {
        let iv = UIImageView()
        iv.image = DesignSystemAsset.emptyInsight.image
        iv.contentMode = .scaleAspectFit
        return iv
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.textAlignment = .center
        label.numberOfLines = 0
        return label
    }()

    // MARK: - Init

    public init() {
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
    }

    // MARK: - Setup

    private func setupUI() {
        view.backgroundColor = .sdBase

        view.addSubview(emptyImageView)
        view.addSubview(descriptionLabel)

        descriptionLabel.setText(
            "인사이트를 제공하기 위해\n최소 1주일간의 데이터가 필요해요.",
            style: .p14,
            color: .gray050
        )
    }

    private func setupConstraints() {
        emptyImageView.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-40)
            $0.size.equalTo(Constants.imageSize)
        }

        descriptionLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(emptyImageView.snp.bottom).offset(Constants.textTopSpacing)
        }
    }
}
