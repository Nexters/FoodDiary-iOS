//
//  DesignSystem.swift
//  DesignSystem
//
//  Created by 강대훈 on 1/12/26.
//

import UIKit

/// DesignSystem 모듈의 이미지 에셋 접근
public enum MumukImage {
    /// 체크마크 선택됨 이미지
    public static var checkmarkSelected: UIImage? {
        UIImage(named: "image_checked", in: Bundle.module, compatibleWith: nil)
    }

    /// 체크마크 미선택 이미지
    public static var checkmarkUnselected: UIImage? {
        UIImage(named: "image_unchecked", in: Bundle.module, compatibleWith: nil)
    }
}
