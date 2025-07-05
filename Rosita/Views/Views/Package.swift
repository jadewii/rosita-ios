// swift-tools-version:5.7
import PackageDescription

let package = Package(
    name: "Rosita",
    platforms: [
        .iOS(.v16)
    ],
    products: [
        .library(
            name: "Rosita",
            targets: ["Rosita"]),
    ],
    dependencies: [
        .package(url: "https://github.com/AudioKit/AudioKit.git", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/SoundpipeAudioKit.git", from: "5.6.0"),
        .package(url: "https://github.com/AudioKit/AudioKitEX.git", from: "5.6.0")
    ],
    targets: [
        .target(
            name: "Rosita",
            dependencies: [
                "AudioKit",
                "SoundpipeAudioKit", 
                "AudioKitEX"
            ]),
    ]
)