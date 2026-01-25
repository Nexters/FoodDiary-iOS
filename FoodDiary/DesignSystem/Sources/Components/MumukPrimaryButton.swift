//
//  MumukPrimaryButton.swift
//  DesignSystem
//

import UIKit

/// Primary 스타일 버튼
public final class MumukPrimaryButton: UIButton {
    // MARK: - Properties

    private var colorConfiguration: ImagePickerColorConfiguration = .default

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
    ///   - colorConfiguration: 색상 설정
    public func configure(
        title: String,
        colorConfiguration: ImagePickerColorConfiguration = .default
    ) {
        self.colorConfiguration = colorConfiguration
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
            backgroundColor = colorConfiguration.primaryColor
            setTitleColor(colorConfiguration.buttonTextColor, for: .normal)
        } else {
            backgroundColor = colorConfiguration.buttonDisabledColor
            setTitleColor(colorConfiguration.buttonTextColor.withAlphaComponent(0.5), for: .normal)
        }
    }
}
