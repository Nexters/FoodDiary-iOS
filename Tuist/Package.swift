// swift-tools-version: 6.0
import PackageDescription

#if TUIST
    import struct ProjectDescription.PackageSettings

    let packageSettings = PackageSettings(
        productTypes: [:]
    )
#endif

let package = Package(
    name: "FoodDiary",
    dependencies: [
        .package(url: "https://github.com/SnapKit/SnapKit.git", from: "5.7.0")
    ]
)
