import XCTest
import Flutter
#if canImport(BraintreePayPal)
import BraintreePayPal
#else
import Braintree
#endif
@testable import braintree_checkout_flutter

final class CheckoutClientFake: PayPalCheckoutTokenizing {
    var requests: [BTPayPalCheckoutRequest] = []
    var request: BTPayPalCheckoutRequest?
    var completion: ((PayPalCheckoutAccount?, Error?) -> Void)?

    func tokenize(_ request: BTPayPalCheckoutRequest, completion: @escaping (PayPalCheckoutAccount?, Error?) -> Void) {
        requests.append(request)
        self.request = request
        self.completion = completion
    }
}

private enum CheckoutFactory {
    static func arguments(_ overrides: [String: Any] = [:]) -> [String: Any] {
        ["token": "test-token", "amount": "29.90", "currencyCode": "USD",
         "paymentIntent": "authorize", "userAction": "none"].merging(overrides) { _, new in new }
    }

    static func account(nonce: String = "test-nonce") -> PayPalCheckoutAccount {
        PayPalCheckoutAccount(nonce: nonce, isDefault: false, billingAddress: nil,
                              clientMetadataId: nil, firstName: nil, lastName: nil,
                              phone: nil, email: nil, payerId: nil)
    }
}

@MainActor
final class PayPalCheckoutHandlerTests: XCTestCase {
    func testShouldFallbackOnceAfterAppLaunchFailureAndIgnoreStaleCallback() {
        let client = CheckoutClientFake()
        let handler = PayPalCheckoutHandler(clientFactory: { _, _ in client })
        var responses: [Any?] = []
        handler.handle(arguments: CheckoutFactory.arguments([
            "universalLink": "https://merchant.example/paypal", "userAction": "payNow",
            "userAuthenticationEmail": "buyer@example.com"
        ])) { responses.append($0) }
        XCTAssertEqual(client.request?.userAuthenticationEmail, "buyer@example.com")
        let appCompletion = client.completion
        appCompletion?(nil, BTPayPalError.appSwitchFailed)
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(client.request?.userAuthenticationEmail, "buyer@example.com")
        XCTAssertTrue(responses.isEmpty)
        appCompletion?(CheckoutFactory.account(), nil)
        XCTAssertTrue(responses.isEmpty)
        client.completion?(CheckoutFactory.account(), nil)
        client.completion?(CheckoutFactory.account(), nil)
        XCTAssertEqual(responses.count, 1)
        XCTAssertTrue(responses.first is String)
    }

    func testShouldOnlyConfigureAppSwitchWhenEnabledWithUsableLink() {
        let cases: [([String: Any], String?)] = [
            (["universalLink": "https://merchant.example/paypal"], "https://merchant.example/paypal"),
            (["universalLink": "https://merchant.example/paypal", "enablePayPalAppSwitch": true], "https://merchant.example/paypal"),
            (["universalLink": "https://merchant.example/paypal", "enablePayPalAppSwitch": false], nil),
            ([:], nil), (["universalLink": ""], nil),
            (["universalLink": "http://merchant.example/paypal"], nil),
            (["universalLink": "https://merchant.example/paypal?query=1"], nil),
            (["universalLink": "https://user@merchant.example/paypal"], nil),
            (["universalLink": "https://merchant.example/paypal#fragment"], nil)
        ]
        for (options, expected) in cases {
            let client = CheckoutClientFake()
            var links: [URL?] = []
            let handler = PayPalCheckoutHandler(clientFactory: { _, url in
                links.append(url)
                return client
            })
            handler.handle(arguments: CheckoutFactory.arguments(options)) { _ in }
            XCTAssertEqual(links.count, 1)
            XCTAssertEqual(links[0]?.absoluteString, expected)
            client.completion?(nil, BTPayPalError.canceled)
        }
    }

    func testShouldNotRetryCancellationOrOtherErrorsWithAppSwitchEnabled() {
        for error: Error in [BTPayPalError.canceled, BTPayPalError.failedToCreateNonce,
                             NSError(domain: "other", code: BTPayPalError.appSwitchFailed.errorCode)] {
            let client = CheckoutClientFake()
            let handler = PayPalCheckoutHandler(clientFactory: { _, _ in client })
            var responses = 0
            handler.handle(arguments: CheckoutFactory.arguments([
                "universalLink": "https://merchant.example/paypal"
            ])) { _ in responses += 1 }
            client.completion?(nil, error)
            XCTAssertEqual(client.requests.count, 1)
            XCTAssertEqual(responses, 1)
        }
    }

    func testShouldNotRetryWebAttemptAndShouldReleaseBusyState() {
        let client = CheckoutClientFake()
        var links: [URL?] = []
        let handler = PayPalCheckoutHandler(clientFactory: { _, url in
            links.append(url)
            return client
        })
        var responses: [Any?] = []
        handler.handle(arguments: CheckoutFactory.arguments([
            "universalLink": "https://merchant.example/paypal", "paymentIntent": "sale",
            "userAction": "payNow", "displayName": "Store", "merchantAccountId": "merchant"
        ])) { responses.append($0) }
        client.completion?(nil, BTPayPalError.appSwitchFailed as NSError)
        XCTAssertEqual(links.count, 2)
        XCTAssertNotNil(links[0])
        XCTAssertNil(links[1])
        XCTAssertEqual(client.request?.amount, "29.90")
        XCTAssertEqual(client.request?.intent, .sale)
        XCTAssertEqual(client.request?.userAction, .payNow)
        XCTAssertEqual(client.request?.displayName, "Store")
        XCTAssertEqual(client.request?.merchantAccountID, "merchant")
        var busy: Any?
        handler.handle(arguments: CheckoutFactory.arguments()) { busy = $0 }
        XCTAssertEqual((busy as? FlutterError)?.code, "payment_in_progress")
        client.completion?(nil, BTPayPalError.appSwitchFailed)
        XCTAssertEqual(client.requests.count, 2)
        XCTAssertEqual(responses.count, 1)
        XCTAssertEqual((responses[0] as? FlutterError)?.code, "error")
        handler.handle(arguments: CheckoutFactory.arguments()) { _ in }
        XCTAssertEqual(client.requests.count, 3)
        client.completion?(nil, BTPayPalError.canceled)
    }

    func testShouldNotRetryWhenDisabledOrWithoutReturnLink() {
        for options: [String: Any] in [[:], ["enablePayPalAppSwitch": false,
                                      "universalLink": "https://merchant.example/paypal"]] {
            let client = CheckoutClientFake()
            let handler = PayPalCheckoutHandler(clientFactory: { _, _ in client })
            var responses = 0
            handler.handle(arguments: CheckoutFactory.arguments(options)) { _ in responses += 1 }
            client.completion?(nil, BTPayPalError.appSwitchFailed)
            XCTAssertEqual(client.requests.count, 1)
            XCTAssertEqual(responses, 1)
        }
    }

    func testShouldOnlyRouteActiveCheckoutReturnLinksAndClearOnFallback() {
        let client = CheckoutClientFake()
        var routed: [URL] = []
        let handler = PayPalCheckoutHandler(clientFactory: { _, _ in client }, returnURLHandler: {
            routed.append($0)
            return true
        })
        let valid = URL(string: "https://merchant.example/paypal/braintreeAppSwitchPayPal/success?token=test")!
        XCTAssertFalse(handler.handleReturnURL(valid))
        handler.handle(arguments: CheckoutFactory.arguments([
            "universalLink": "https://merchant.example/paypal"
        ])) { _ in }
        for invalid in ["https://other.example/paypal/braintreeAppSwitchPayPal/success",
                        "https://merchant.example/paypal-other/braintreeAppSwitchPayPal/success",
                        "https://merchant.example/paypal/braintreeAppSwitchVenmo/success",
                        "http://merchant.example/paypal/braintreeAppSwitchPayPal/success",
                        "https://merchant.example:444/paypal/braintreeAppSwitchPayPal/success"] {
            XCTAssertFalse(handler.handleReturnURL(URL(string: invalid)!))
        }
        XCTAssertTrue(handler.handleReturnURL(valid))
        XCTAssertEqual(routed, [valid])
        client.completion?(nil, BTPayPalError.appSwitchFailed)
        XCTAssertFalse(handler.handleReturnURL(valid))
        client.completion?(CheckoutFactory.account(), nil)
        XCTAssertFalse(handler.handleReturnURL(valid))
    }

    func testShouldBuildCheckoutWhenOptionsAreProvided() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        checkoutHandler.handle(arguments: CheckoutFactory.arguments([
            "paymentIntent": "sale", "userAction": "payNow", "displayName": "Store", "merchantAccountId": "merchant"
        ])) { _ in }
        XCTAssertEqual(checkoutClient.request?.amount, "29.90")
        XCTAssertEqual(checkoutClient.request?.currencyCode, "USD")
        XCTAssertEqual(checkoutClient.request?.displayName, "Store")
        XCTAssertEqual(checkoutClient.request?.merchantAccountID, "merchant")
        XCTAssertEqual(checkoutClient.request?.intent, .sale)
        XCTAssertEqual(checkoutClient.request?.userAction, .payNow)
        XCTAssertEqual(checkoutClient.request?.requestBillingAgreement, false)
        XCTAssertEqual(checkoutClient.request?.isShippingAddressRequired, false)
        checkoutClient.completion?(CheckoutFactory.account(), nil)
    }

    func testShouldMapDefaultsAndOrderWhenRequested() {
        for intent in ["authorize", "order"] {
            let checkoutClient = CheckoutClientFake()
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
            checkoutHandler.handle(arguments: CheckoutFactory.arguments(["paymentIntent": intent])) { _ in }
            XCTAssertEqual(checkoutClient.request?.intent, intent == "order" ? .order : .authorize)
            XCTAssertEqual(checkoutClient.request?.userAction, BTPayPalRequestUserAction.none)
            checkoutClient.completion?(CheckoutFactory.account(), nil)
        }
    }

    func testShouldRejectInvalidArgumentsBeforeCreatingClient() {
        let invalidArguments: [Any?] = [nil, "wrong", [:],
            CheckoutFactory.arguments(["token": " "]),
            CheckoutFactory.arguments(["token": 42]),
            CheckoutFactory.arguments(["userAuthenticationEmail": ""]),
            CheckoutFactory.arguments(["userAuthenticationEmail": "  "]),
            CheckoutFactory.arguments(["userAuthenticationEmail": 42]),
            CheckoutFactory.arguments(["amount": 29.90]),
            CheckoutFactory.arguments(["amount": "-1"]),
            CheckoutFactory.arguments(["amount": "1.0"]),
            CheckoutFactory.arguments(["amount": "1.000"]),
            CheckoutFactory.arguments(["amount": "10000000"]),
            CheckoutFactory.arguments(["amount": "1\n"]),
            CheckoutFactory.arguments(["currencyCode": "usd"]),
            CheckoutFactory.arguments(["currencyCode": "USD\n"]),
            CheckoutFactory.arguments(["displayName": " "]),
            CheckoutFactory.arguments(["merchantAccountId": false]),
            CheckoutFactory.arguments(["paymentIntent": "unknown"]),
            CheckoutFactory.arguments(["userAction": 1]),
            CheckoutFactory.arguments(["enablePayPalAppSwitch": "true"]),
            CheckoutFactory.arguments(["enablePayPalAppSwitch": 1])]
        for arguments in invalidArguments {
            var clientCreations = 0
            var responses: [Any?] = []
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in
                clientCreations += 1
                return CheckoutClientFake()
            })
            checkoutHandler.handle(arguments: arguments) { responses.append($0) }
            XCTAssertEqual(clientCreations, 0)
            XCTAssertEqual(responses.count, 1)
            XCTAssertEqual((responses.first as? FlutterError)?.code, "invalid_arguments")
        }
    }

    func testShouldAcceptAmountBoundariesWithoutCoercion() {
        for amount in ["0", "0.00", "10", "10.00", "9999999.99"] {
            let checkoutClient = CheckoutClientFake()
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
            checkoutHandler.handle(arguments: CheckoutFactory.arguments(["amount": amount])) { _ in }
            XCTAssertEqual(checkoutClient.request?.amount, amount)
            checkoutClient.completion?(CheckoutFactory.account(), nil)
        }
    }

    func testShouldReturnErrorWhenAuthorizationCannotCreateClient() {
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in nil })
        var checkoutResponse: Any?
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
        XCTAssertEqual((checkoutResponse as? FlutterError)?.code, "invalid_arguments")
    }

    func testShouldSerializeNullableAccountWithoutInventingAddress() throws {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        var checkoutResponse: Any?
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
        checkoutClient.completion?(CheckoutFactory.account(), nil)
        let jsonString = try XCTUnwrap(checkoutResponse as? String)
        let json = try XCTUnwrap(JSONSerialization.jsonObject(with: Data(jsonString.utf8)) as? [String: Any])
        XCTAssertEqual(json["nonce"] as? String, "test-nonce")
        XCTAssertEqual(json["isDefault"] as? Bool, false)
        XCTAssertTrue(json["payerId"] is NSNull)
        XCTAssertTrue(json["billingAddress"] is NSNull)
    }

    func testShouldDistinguishCancellationFromErrorsAndEmptyResponse() {
        let cases: [(Error?, String)] = [
            (BTPayPalError.canceled, "canceled"),
            (BTPayPalError.canceled as NSError, "canceled"),
            (NSError(domain: "other", code: 1), "error"),
            (BTPayPalError.disabled, "error"),
            (nil, "error")
        ]
        for (error, expectedCode) in cases {
            let checkoutClient = CheckoutClientFake()
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
            var checkoutResponse: Any?
            checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
            checkoutClient.completion?(nil, error)
            XCTAssertEqual((checkoutResponse as? FlutterError)?.code, expectedCode)
            XCTAssertNil((checkoutResponse as? FlutterError)?.details)
        }
    }

    func testShouldRejectEmptyNonce() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        var checkoutResponse: Any?
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
        checkoutClient.completion?(CheckoutFactory.account(nonce: " "), nil)
        XCTAssertEqual((checkoutResponse as? FlutterError)?.code, "error")
    }

    func testShouldIgnoreDuplicateAndStaleCallbacksAndAllowRetry() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        var firstResponses = 0
        var secondResponses = 0
        var busyResponse: Any?
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { _ in firstResponses += 1 }
        let firstCompletion = checkoutClient.completion
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { busyResponse = $0 }
        XCTAssertEqual((busyResponse as? FlutterError)?.code, "payment_in_progress")
        firstCompletion?(nil, BTPayPalError.canceled)
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { _ in secondResponses += 1 }
        firstCompletion?(CheckoutFactory.account(), nil)
        XCTAssertEqual(firstResponses, 1)
        XCTAssertEqual(secondResponses, 0)
        checkoutClient.completion?(CheckoutFactory.account(), nil)
        checkoutClient.completion?(CheckoutFactory.account(), nil)
        XCTAssertEqual(secondResponses, 1)
    }

    func testShouldRetainClientUntilOperationFinishes() {
        weak var retainedClient: CheckoutClientFake?
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in
            let checkoutClient = CheckoutClientFake()
            retainedClient = checkoutClient
            return checkoutClient
        })
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { _ in }
        XCTAssertNotNil(retainedClient)
        let completion = retainedClient?.completion
        completion?(nil, BTPayPalError.canceled)
        XCTAssertNil(retainedClient)
    }

    func testShouldDeliverBackgroundCallbackOnMainThread() async {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        let responseExpectation = expectation(description: "main thread response")
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { _ in
            XCTAssertTrue(Thread.isMainThread)
            responseExpectation.fulfill()
        }
        let completion = checkoutClient.completion
        DispatchQueue.global().async { completion?(nil, BTPayPalError.canceled) }
        await fulfillment(of: [responseExpectation], timeout: 2)
    }

    func testShouldExcludeVaultAndCheckoutInBothDirections() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        var vaultCompletion: FlutterResult?
        let coordinator = PayPalFlowCoordinator(checkoutHandler: checkoutHandler, vaultHandler: { _, completion in
            vaultCompletion = completion
        })
        var busyResponse: Any?
        coordinator.handleCheckout(arguments: CheckoutFactory.arguments()) { _ in }
        coordinator.handleVault(arguments: [:]) { busyResponse = $0 }
        XCTAssertEqual((busyResponse as? FlutterError)?.code, "payment_in_progress")
        XCTAssertNil(vaultCompletion)
        checkoutClient.completion?(nil, BTPayPalError.canceled)
        coordinator.handleVault(arguments: [:]) { _ in }
        XCTAssertNotNil(vaultCompletion)
        coordinator.handleCheckout(arguments: CheckoutFactory.arguments()) { busyResponse = $0 }
        XCTAssertEqual((busyResponse as? FlutterError)?.code, "payment_in_progress")
        vaultCompletion?("legacy-response")
        var checkoutResponse: Any?
        coordinator.handleCheckout(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
        checkoutClient.completion?(CheckoutFactory.account(), nil)
        XCTAssertTrue(checkoutResponse is String)
    }

    func testShouldPreserveVaultResultAndIgnoreLateCallback() {
        var vaultCompletions: [FlutterResult] = []
        let coordinator = PayPalFlowCoordinator(vaultHandler: { _, completion in vaultCompletions.append(completion) })
        let legacyError = FlutterError(code: "legacy", message: "Legacy error", details: nil)
        var firstResponses: [Any?] = []
        var secondResponses: [Any?] = []
        coordinator.handleVault(arguments: [:]) { firstResponses.append($0) }
        vaultCompletions[0](legacyError)
        coordinator.handleVault(arguments: [:]) { secondResponses.append($0) }
        vaultCompletions[0]("late")
        XCTAssertEqual(firstResponses.count, 1)
        XCTAssertTrue((firstResponses[0] as? FlutterError) === legacyError)
        XCTAssertTrue(secondResponses.isEmpty)
        vaultCompletions[1]("legacy-response")
        XCTAssertEqual(secondResponses[0] as? String, "legacy-response")
    }

    func testShouldNotBlockCheckoutAfterMalformedVaultArguments() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _, _ in checkoutClient })
        let coordinator = PayPalFlowCoordinator(checkoutHandler: checkoutHandler, vaultHandler: { _, _ in XCTFail() })
        var vaultResponse: Any?
        coordinator.handleVault(arguments: nil) { vaultResponse = $0 }
        XCTAssertEqual((vaultResponse as? FlutterError)?.code, "error")
        coordinator.handleCheckout(arguments: CheckoutFactory.arguments()) { _ in }
        XCTAssertNotNil(checkoutClient.request)
        checkoutClient.completion?(CheckoutFactory.account(), nil)
    }
}
