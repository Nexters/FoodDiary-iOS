//
//  FoodImagePickerResult.swift
//  Presentation
//
//  Created by Kai Lee on 1/25/26.
//

/// 이미지 피커 결과
public enum ImagePickerResult<Asset: ImageAssetable> {
    /// 사진 선택 완료
    case selected([Asset])
    /// 취소
    case cancelled
}
