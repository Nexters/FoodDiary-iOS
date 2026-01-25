//
//  ImagePickerConfiguration.swift
//  Presentation
//

import UIKit
import DesignSystem

/// 이미지 피커 설정
public struct ImagePickerConfiguration: Sendable {
    // MARK: - Color Properties

    /// 선택 테두리 및 버튼 배경 색상
    public let primaryColor: UIColor

    /// 버튼 텍스트 색상
    public let buttonTextColor: UIColor

    /// 버튼 비활성화 색상
    public let buttonDisabledColor: UIColor

    // MARK: - Picker Properties

    /// 최대 선택 가능 수 (nil이면 무제한)
    public let maxSelectionCount: Int?

    /// 확인 버튼 타이틀
    public let confirmButtonTitle: String

    /// 음식 확률 라벨 표시 여부
    /// - Note: 디버그 목적으로 임시 구현된 기능입니다. 추후 제거될 수 있습니다.
    public let showsFoodProbability: Bool

    /// 기본 설정
    public static let `default` = ImagePickerConfiguration(
        primaryColor: DesignSystemAsset.primary.color,
        buttonTextColor: .white,
        buttonDisabledColor: DesignSystemAsset.disabled.color,
        maxSelectionCount: nil,
        confirmButtonTitle: "추가하기",
        showsFoodProbability: false
    )
    
    /// 디버그 설정
    public static let debug = ImagePickerConfiguration(
        primaryColor: DesignSystemAsset.primary.color,
        buttonTextColor: .white,
        buttonDisabledColor: DesignSystemAsset.disabled.color,
        maxSelectionCount: nil,
        confirmButtonTitle: "추가하기",
        showsFoodProbability: true
    )

    public init(
        primaryColor: UIColor,
        buttonTextColor: UIColor,
        buttonDisabledColor: UIColor,
        maxSelectionCount: Int?,
        confirmButtonTitle: String,
        showsFoodProbability: Bool = false
    ) {
        self.primaryColor = primaryColor
        self.buttonTextColor = buttonTextColor
        self.buttonDisabledColor = buttonDisabledColor
        self.maxSelectionCount = maxSelectionCount
        self.confirmButtonTitle = confirmButtonTitle
        self.showsFoodProbability = showsFoodProbability
    }
}
