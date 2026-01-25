//
//  FoodImagePickerResult.swift
//  Presentation
//
//  Created by Kai Lee on 1/25/26.
//

import Domain

/// 이미지 피커 결과
public enum ImagePickerResult<Asset: ImageAssetable> {
    /// 사진 선택 완료
    case selected([FoodPhoto<Asset>])
    /// 취소
    case cancelled
}
