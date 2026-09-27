// swift-tools-version: 5.10
import PackageDescription

let package = Package(
    name: "TypingPetMac",
    platforms: [.macOS(.v13)],
    targets: [
        .executableTarget(
            name: "TypingPetMac",
            resources: [
                .copy("Resources/images")
            ]
        )
    ]
)
