//
//  MumukImagePickerConfiguration.swift
//  DesignSystem
//

import UIKit

/// 이미지 피커의 색상 설정
public struct ImagePickerColorConfiguration: Sendable {
    /// 선택 테두리 및 버튼 배경 색상
    public let primaryColor: UIColor

    /// 선택된 체크마크 배경 색상
    public let checkmarkBackgroundSelected: UIColor

    /// 미선택 체크마크 배경 색상
    public let checkmarkBackgroundUnselected: UIColor

    /// 선택된 체크마크 틴트 색상
    public let checkmarkTintSelected: UIColor

    /// 미선택 체크마크 틴트 색상
    public let checkmarkTintUnselected: UIColor

    /// 버튼 텍스트 색상
    public let buttonTextColor: UIColor

    /// 버튼 비활성화 색상
    public let buttonDisabledColor: UIColor

    /// 셀 배경 색상
    public let cellBackgroundColor: UIColor

    /// 배경 색상
    public let backgroundColor: UIColor

    /// 기본 설정
    public static let `default` = ImagePickerColorConfiguration(
        primaryColor: MumukColor.primary,
        checkmarkBackgroundSelected: MumukColor.primary,
        checkmarkBackgroundUnselected: MumukColor.checkmarkUnselected,
        checkmarkTintSelected: .white,
        checkmarkTintUnselected: UIColor.systemGray4,
        buttonTextColor: .white,
        buttonDisabledColor: MumukColor.disabled,
        cellBackgroundColor: UIColor(hex: "#2C2C2E"),
        backgroundColor: UIColor(hex: "#1C1C1E")
    )

    public init(
        primaryColor: UIColor,
        checkmarkBackgroundSelected: UIColor,
        checkmarkBackgroundUnselected: UIColor,
        checkmarkTintSelected: UIColor,
        checkmarkTintUnselected: UIColor,
        buttonTextColor: UIColor,
        buttonDisabledColor: UIColor,
        cellBackgroundColor: UIColor,
        backgroundColor: UIColor
    ) {
        self.primaryColor = primaryColor
        self.checkmarkBackgroundSelected = checkmarkBackgroundSelected
        self.checkmarkBackgroundUnselected = checkmarkBackgroundUnselected
        self.checkmarkTintSelected = checkmarkTintSelected
        self.checkmarkTintUnselected = checkmarkTintUnselected
        self.buttonTextColor = buttonTextColor
        self.buttonDisabledColor = buttonDisabledColor
        self.cellBackgroundColor = cellBackgroundColor
        self.backgroundColor = backgroundColor
    }
}

/// 이미지 피커 설정
public struct ImagePickerConfiguration: Sendable {
    /// 최대 선택 가능 수 (nil이면 무제한)
    public let maxSelectionCount: Int?

    /// 색상 설정
    public let colorConfiguration: ImagePickerColorConfiguration

    /// 확인 버튼 타이틀
    public let confirmButtonTitle: String

    /// 음식 확률 라벨 표시 여부
    /// - Note: 디버그 목적으로 임시 구현된 기능입니다. 추후 제거될 수 있습니다.
    public let showsFoodProbability: Bool

    /// 기본 설정
    public static let `default` = ImagePickerConfiguration(
        maxSelectionCount: nil,
        colorConfiguration: .default,
        confirmButtonTitle: "추가하기",
        showsFoodProbability: false
    )

    public init(
        maxSelectionCount: Int?,
        colorConfiguration: ImagePickerColorConfiguration,
        confirmButtonTitle: String,
        showsFoodProbability: Bool = false
    ) {
        self.maxSelectionCount = maxSelectionCount
        self.colorConfiguration = colorConfiguration
        self.confirmButtonTitle = confirmButtonTitle
        self.showsFoodProbability = showsFoodProbability
    }
}
