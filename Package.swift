// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "StudyBar",
    platforms: [.macOS(.v14)],
    targets: [
        .executableTarget(
            name: "StudyBar",
            path: "Sources/StudyBar",
            exclude: ["Info.plist"]
        )
    ]
)
