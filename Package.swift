// swift-tools-version: 6.1
import PackageDescription

let package = Package(
    name: "CroatianGroceryPriceTracker",
    platforms: [ .macOS(.v13), .iOS(.v16), .watchOS(.v9), .tvOS(.v16) ],
    products: [
        .library( name: "CroatianGroceryCore",
                  targets: [ "CroatianGroceryCore"] ),
        .library( name: "CroatianGroceryUI",
                  targets: ["CroatianGroceryUI"] ),
        .executable( name: "grocery-price-cli",
                     targets: ["GroceryPriceCLI"] ) ],
    dependencies: [
        .package(url: "https://github.com/apple/swift-argument-parser", from: "1.2.0"),
        .package(url: "https://github.com/SwiftyJSON/SwiftyJSON.git", from: "4.0.0")
    ],
    targets: [
        .target( name: "CroatianGroceryCore",
                 dependencies: ["SwiftyJSON"], path: "Sources/CroatianGroceryCore" ),
        .target( name: "CroatianGroceryUI",
                 dependencies: ["CroatianGroceryCore"], path: "Sources/CroatianGroceryUI" ),
        .executableTarget( name: "GroceryPriceCLI",
                           dependencies: [ "CroatianGroceryCore",
                                           .product(name: "ArgumentParser", package: "swift-argument-parser") ], path: "Sources/GroceryPriceCLI" ),
        .testTarget( name: "CroatianGrocerTests", dependencies: ["CroatianGroceryCore"], path: "Tests" )
    ]
)
