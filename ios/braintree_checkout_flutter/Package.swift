// swift-tools-version: 5.9
import PackageDescription

let package = Package(
    name: "braintree_checkout_flutter",
    platforms: [.iOS(.v14)],
    products: [
        .library(name: "braintree-checkout-flutter", targets: ["braintree_checkout_flutter"])
    ],
    // Flutter 3.38 supplies the engine framework through the host build.
    // Keep this manifest compatible with that integration rather than requiring
    // the generated engine package introduced by newer Flutter versions.
    dependencies: [
        .package(url: "https://github.com/braintree/braintree_ios.git", exact: "6.30.0")
    ],
    targets: [
        .target(
            name: "braintree_checkout_flutter",
            dependencies: [
                .product(name: "BraintreeCore", package: "braintree_ios"),
                .product(name: "BraintreeCard", package: "braintree_ios"),
                .product(name: "BraintreeDataCollector", package: "braintree_ios"),
                .product(name: "BraintreePayPal", package: "braintree_ios"),
                .product(name: "BraintreeVenmo", package: "braintree_ios"),
                .product(name: "BraintreeThreeDSecure", package: "braintree_ios")
            ],
            resources: [.process("PrivacyInfo.xcprivacy")]
        )
    ]
)
