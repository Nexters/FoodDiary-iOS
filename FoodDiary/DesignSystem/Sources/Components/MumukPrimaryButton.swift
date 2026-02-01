//
//  MumukPrimaryButton.swift
//  DesignSystem
//

import UIKit

/// Primary 스타일 버튼
public final class MumukPrimaryButton: UIButton {
    // MARK: - Properties

    private var primaryColor: UIColor = DesignSystemAsset.primary.color
    private var buttonTextColor: UIColor = .white
    private var buttonDisabledColor: UIColor = DesignSystemAsset.gray400.color

    // MARK: - Initialization

    public override init(frame: CGRect) {
        super.init(frame: frame)
        setupUI()
    }

    @available(*, unavailable)
    required init?(coder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // MARK: - Setup

    private func setupUI() {
        layer.cornerRadius = 25
        titleLabel?.font = .systemFont(ofSize: 17, weight: .semibold)
    }

    // MARK: - Configuration

    /// 버튼 설정
    /// - Parameters:
    ///   - title: 버튼 타이틀
    ///   - primaryColor: 기본 색상
    ///   - buttonTextColor: 텍스트 색상
    ///   - buttonDisabledColor: 비활성화 색상
    public func configure(
        title: String,
        primaryColor: UIColor = DesignSystemAsset.primary.color,
        buttonTextColor: UIColor = .white,
        buttonDisabledColor: UIColor = DesignSystemAsset.gray400.color
    ) {
        self.primaryColor = primaryColor
        self.buttonTextColor = buttonTextColor
        self.buttonDisabledColor = buttonDisabledColor
        setTitle(title, for: .normal)
        updateAppearance()
    }

    // MARK: - State

    public override var isEnabled: Bool {
        didSet {
            updateAppearance()
        }
    }

    // MARK: - Private Methods

    private func updateAppearance() {
        if isEnabled {
            backgroundColor = primaryColor
            setTitleColor(buttonTextColor, for: .normal)
        } else {
            backgroundColor = buttonDisabledColor
            setTitleColor(buttonTextColor.withAlphaComponent(0.5), for: .normal)
        }
    }
}
