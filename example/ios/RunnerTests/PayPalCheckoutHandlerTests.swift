import XCTest
import Flutter
#if canImport(BraintreePayPal)
import BraintreePayPal
#else
import Braintree
#endif
@testable import braintree_checkout_flutter

final class CheckoutClientFake: PayPalCheckoutTokenizing {
    var request: BTPayPalCheckoutRequest?
    var completion: ((PayPalCheckoutAccount?, Error?) -> Void)?

    func tokenize(_ request: BTPayPalCheckoutRequest, completion: @escaping (PayPalCheckoutAccount?, Error?) -> Void) {
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
    func testShouldBuildCheckoutWhenOptionsAreProvided() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
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
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
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
            CheckoutFactory.arguments(["userAction": 1])]
        for arguments in invalidArguments {
            var clientCreations = 0
            var responses: [Any?] = []
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in
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
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
            checkoutHandler.handle(arguments: CheckoutFactory.arguments(["amount": amount])) { _ in }
            XCTAssertEqual(checkoutClient.request?.amount, amount)
            checkoutClient.completion?(CheckoutFactory.account(), nil)
        }
    }

    func testShouldReturnErrorWhenAuthorizationCannotCreateClient() {
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in nil })
        var checkoutResponse: Any?
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
        XCTAssertEqual((checkoutResponse as? FlutterError)?.code, "invalid_arguments")
    }

    func testShouldSerializeNullableAccountWithoutInventingAddress() throws {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
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
            let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
            var checkoutResponse: Any?
            checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
            checkoutClient.completion?(nil, error)
            XCTAssertEqual((checkoutResponse as? FlutterError)?.code, expectedCode)
            XCTAssertNil((checkoutResponse as? FlutterError)?.details)
        }
    }

    func testShouldRejectEmptyNonce() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
        var checkoutResponse: Any?
        checkoutHandler.handle(arguments: CheckoutFactory.arguments()) { checkoutResponse = $0 }
        checkoutClient.completion?(CheckoutFactory.account(nonce: " "), nil)
        XCTAssertEqual((checkoutResponse as? FlutterError)?.code, "error")
    }

    func testShouldIgnoreDuplicateAndStaleCallbacksAndAllowRetry() {
        let checkoutClient = CheckoutClientFake()
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
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
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in
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
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
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
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
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
        let checkoutHandler = PayPalCheckoutHandler(clientFactory: { _ in checkoutClient })
        let coordinator = PayPalFlowCoordinator(checkoutHandler: checkoutHandler, vaultHandler: { _, _ in XCTFail() })
        var vaultResponse: Any?
        coordinator.handleVault(arguments: nil) { vaultResponse = $0 }
        XCTAssertEqual((vaultResponse as? FlutterError)?.code, "error")
        coordinator.handleCheckout(arguments: CheckoutFactory.arguments()) { _ in }
        XCTAssertNotNil(checkoutClient.request)
        checkoutClient.completion?(CheckoutFactory.account(), nil)
    }
}
