//
//  PermissionViewController.swift
//  Presentation
//

import DesignSystem
import SnapKit
import UIKit

/// 권한이 거부된 상태에서 표시되는 전체화면 안내 뷰
public final class PermissionViewController: UIViewController {

    // MARK: - UI

    private let titleLabel: UILabel = {
        let label = UILabel()
        label.text = "앱 사용을 위해\n접근 권한을 허용해주세요"
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 24, weight: .bold)
        label.textColor = DesignSystemAsset.gray050.color
        return label
    }()

    private let descriptionLabel: UILabel = {
        let label = UILabel()
        label.text = "일부 권한이 거부되어 서비스 이용이\n제한될 수 있습니다."
        label.numberOfLines = 0
        label.textAlignment = .center
        label.font = .systemFont(ofSize: 14, weight: .regular)
        label.textColor = DesignSystemAsset.gray400.color
        return label
    }()

    private let settingsButton: MumukPrimaryButton = {
        let button = MumukPrimaryButton()
        button.configure(title: "설정으로 이동")
        return button
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
        setupAction()
    }
}

// MARK: - Setup

private extension PermissionViewController {
    func setupUI() {
        view.backgroundColor = DesignSystemAsset.sdBase.color

        view.addSubview(titleLabel)
        view.addSubview(descriptionLabel)
        view.addSubview(settingsButton)

        titleLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.centerY.equalToSuperview().offset(-60)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        descriptionLabel.snp.makeConstraints {
            $0.centerX.equalToSuperview()
            $0.top.equalTo(titleLabel.snp.bottom).offset(16)
            $0.leading.trailing.equalToSuperview().inset(24)
        }

        settingsButton.snp.makeConstraints {
            $0.leading.trailing.equalToSuperview().inset(24)
            $0.bottom.equalTo(view.safeAreaLayoutGuide).inset(16)
            $0.height.equalTo(50)
        }
    }

    func setupAction() {
        settingsButton.addTarget(self, action: #selector(didTapSettings), for: .touchUpInside)
    }

    @objc func didTapSettings() {
        guard let url = URL(string: UIApplication.openSettingsURLString) else { return }
        UIApplication.shared.open(url)
    }
}
