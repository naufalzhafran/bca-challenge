// swift-tools-version:5.9
import PackageDescription

let package = Package(
    name: "LabBankCore",
    platforms: [.macOS(.v13), .iOS(.v16)],
    products: [
        .library(name: "LabBankCore", targets: ["LabBankCore"]),
    ],
    targets: [
        .target(name: "LabBankCore"),
        .testTarget(name: "LabBankCoreTests", dependencies: ["LabBankCore"]),
    ]
)
