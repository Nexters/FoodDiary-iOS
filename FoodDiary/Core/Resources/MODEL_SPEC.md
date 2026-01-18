# Food Classifier Model Specification

## 모델 정보

| 항목 | 값 |
|------|-----|
| **모델명** | food_classifier.tflite |
| **기반 아키텍처** | EfficientNet-Lite0 |
| **출처** | [mrdbourke/food-not-food](https://github.com/mrdbourke/food-not-food) |
| **용도** | 이미지가 음식인지 아닌지 이진 분류 |

## 입력 스펙

| 항목 | 값 |
|------|-----|
| **Shape** | `[1, 224, 224, 3]` |
| **해상도** | 224 × 224 pixels |
| **채널** | RGB (3 channels) |
| **데이터 타입** | `UInt8` |
| **값 범위** | 0 ~ 255 |
| **총 크기** | 150,528 bytes (224 × 224 × 3 × 1) |

### 전처리 과정

1. 입력 이미지를 224×224 크기로 리사이즈
2. RGBA → RGB 변환 (알파 채널 제거)
3. `UInt8` 형식 유지 (정규화 없음)

```swift
// 전처리 예시
let rgbData = [UInt8]()  // 크기: 150,528
for pixel in image {
    rgbData.append(pixel.red)    // 0-255
    rgbData.append(pixel.green)  // 0-255
    rgbData.append(pixel.blue)   // 0-255
}
```

## 출력 스펙

| 항목 | 값 |
|------|-----|
| **Shape** | `[1, 2]` |
| **데이터 타입** | `UInt8` |
| **값 범위** | 0 ~ 255 |
| **출력 순서** | `[food, not_food]` |
| **총 크기** | 2 bytes |

### 출력 해석

```swift
let results: [UInt8] = [food_raw, not_food_raw]

// UInt8 → Float 변환 (0-1 범위로 정규화)
let foodConfidence = Float(results[0]) / 255.0
let notFoodConfidence = Float(results[1]) / 255.0

// 예시: results = [243, 13]
// food: 243 / 255 = 0.953
// not_food: 13 / 255 = 0.051
```

## 분류 기준

- `results[0] > results[1]` → **음식 (food)**
- `results[1] >= results[0]` → **음식 아님 (not_food)**

## 참고 사항

- 모델은 양자화(quantized)되어 있어 입력이 `UInt8` 형식
- EfficientNet-Lite는 모바일 환경에 최적화된 경량 모델
- ReLU6 활성화 함수 사용 (Swish 대체)
