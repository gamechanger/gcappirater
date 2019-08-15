// swift-tools-version:5.0
import PackageDescription

let package = Package(
    name: "podspec-renderer",
    dependencies: [
        .package(url: "git@github.com:gamechanger/inline-template-renderer.git", from: "0.0.3"),
    ]
)
