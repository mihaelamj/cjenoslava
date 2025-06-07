// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CroatianGroceryPriceTracker",
    platforms: [
        .macOS(.v14),
        .iOS(.v17),
        .watchOS(.v9),
        .tvOS(.v17)
    ],
    products: [
        .singleTargetLibrary("CroatianGroceryCore"),
        .singleTargetLibrary("CroatianGroceryUI"),
        .singleTargetLibrary("SharedGroceryProduct"),
        .executable(name: "grocery-price-cli", targets: ["GroceryPriceCLI"]),
    ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0"),
        .package(url: "https://github.com/realm/SwiftLint", exact: "0.54.0"),
    ],
    targets: {
        
        let sharedProductTarget = Target.target(
            name: "SharedGroceryProduct",
            dependencies: [
                "SwiftyJSON"
            ],
            path: "Sources/SharedGroceryProduct"
        )
        
        let coreTarget = Target.target(
            name: "CroatianGroceryCore",
            dependencies: [
                "SwiftyJSON"
            ],
            path: "Sources/CroatianGroceryCore"
        )
        
        let uiTarget = Target.target(
            name: "CroatianGroceryUI",
            dependencies: [
                "CroatianGroceryCore"
            ],
            path: "Sources/CroatianGroceryUI"
        )
        
        let cliTarget = Target.executableTarget(
            name: "GroceryPriceCLI",
            dependencies: [
                "CroatianGroceryCore",
                .product(name: "ArgumentParser", package: "swift-argument-parser")
            ],
            path: "Sources/GroceryPriceCLI"
        )
        
        let testsTarget = Target.testTarget(
            name: "CroatianGrocerTests",
            dependencies: [
                "CroatianGroceryCore"
            ],
            path: "Tests"
        )
        
        var targets: [Target] = [
            sharedProductTarget,
            coreTarget,
            uiTarget,
            cliTarget,
            testsTarget,
        ]
        
        return targets
    }()
)

// Inject SwiftLint plugin into each target
package.targets = package.targets.map { target in
    var plugins = target.plugins ?? []
//    plugins.append(.plugin(name: "SwiftLintPlugin", package: "SwiftLint"))
    target.plugins = plugins
    return target
}

extension Product {
    static func singleTargetLibrary(_ name: String) -> Product {
        .library(name: name, targets: [name])
    }
}
