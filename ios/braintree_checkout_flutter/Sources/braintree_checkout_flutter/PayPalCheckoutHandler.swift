import Foundation
import CoreFoundation
import Flutter
#if SWIFT_PACKAGE
import BraintreeCore
import BraintreePayPal
#else
import Braintree
#endif

func runOnPayPalMainThread(_ action: @escaping () -> Void) {
    if Thread.isMainThread {
        action()
    } else {
        DispatchQueue.main.async(execute: action)
    }
}

final class PayPalCheckoutHandler {
    private let clientFactory: (String, URL?) -> PayPalCheckoutTokenizing?
    private let returnURLHandler: (URL) -> Bool
    private var activeReturnURL: URL?
    private var activeClient: PayPalCheckoutTokenizing?
    private var activeOperation: UUID?

    init(
        clientFactory: @escaping (String, URL?) -> PayPalCheckoutTokenizing? = {
            PayPalCheckoutClient(authorization: $0, universalLink: $1)
        },
        returnURLHandler: @escaping (URL) -> Bool = {
            BTAppContextSwitcher.sharedInstance.handleOpen($0)
        }
    ) {
        self.clientFactory = clientFactory
        self.returnURLHandler = returnURLHandler
    }

    func handleReturnURL(_ url: URL) -> Bool {
        guard let expected = activeReturnURL,
              url.scheme?.lowercased() == expected.scheme?.lowercased(),
              url.host?.lowercased() == expected.host?.lowercased(),
              (url.port ?? 443) == (expected.port ?? 443),
              url.user == nil, url.password == nil,
              [expected.path + "/success", expected.path + "/cancel"].contains(url.path) else { return false }
        return returnURLHandler(url)
    }

    func handle(arguments: Any?, result: @escaping FlutterResult) {
        runOnPayPalMainThread { self.start(arguments: arguments, result: result) }
    }

    private func start(arguments: Any?, result: @escaping FlutterResult) {
        guard activeOperation == nil else {
            result(FlutterError(code: "payment_in_progress", message: "A PayPal payment is already in progress.", details: nil))
            return
        }
        guard let args = arguments as? [String: Any],
              let token = args[Constants.TOKEN_KEY] as? String, !token.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty,
              let request = Self.makeRequest(args),
              let client = clientFactory(token, Self.appSwitchLink(args)) else {
            result(FlutterError(code: "invalid_arguments", message: "Invalid PayPal Checkout request.", details: nil))
            return
        }

        tokenize(request, client: client, arguments: args, token: token,
                 universalLink: Self.appSwitchLink(args), result: result)
    }

    private func tokenize(
        _ request: BTPayPalCheckoutRequest, client: PayPalCheckoutTokenizing,
        arguments: [String: Any], token: String, universalLink: URL?,
        result: @escaping FlutterResult
    ) {
        let operation = UUID()
        activeOperation = operation
        activeClient = client
        activeReturnURL = universalLink?.appendingPathComponent("braintreeAppSwitchPayPal")
        client.tokenize(request) { [weak self] account, error in
            runOnPayPalMainThread {
                guard let self, self.activeOperation == operation else { return }
                if universalLink != nil, let error,
                   (error as NSError).domain == BTPayPalError.errorDomain,
                   (error as NSError).code == BTPayPalError.appSwitchFailed.errorCode {
                    // Only an unsuccessful app launch is safe to retry. Invalidate
                    // this attempt before starting web checkout, ignoring late callbacks.
                    self.activeOperation = UUID()
                    self.activeReturnURL = nil
                    var webArguments = arguments
                    webArguments[Constants.ENABLE_PAYPAL_APP_SWITCH_KEY] = false
                    if let webRequest = Self.makeRequest(webArguments),
                       let webClient = self.clientFactory(token, nil) {
                        self.tokenize(webRequest, client: webClient, arguments: webArguments,
                                      token: token, universalLink: nil, result: result)
                        return
                    }
                }
                self.activeOperation = nil
                self.activeReturnURL = nil
                self.activeClient = nil
                result(Self.response(account: account, error: error))
            }
        }
    }

    private static func makeRequest(_ args: [String: Any]) -> BTPayPalCheckoutRequest? {
        guard let amount = args[Constants.AMOUNT_KEY] as? String,
              matchesEntire("[0-9]{1,7}(\\.[0-9]{2})?", amount),
              let currency = args[Constants.CURRENCY_CODE_KEY] as? String,
              matchesEntire("[A-Z]{3}", currency),
              validOptionalBoolean(args[Constants.ENABLE_PAYPAL_APP_SWITCH_KEY]),
              validOptionalString(args[Constants.DISPLAY_NAME_KEY]),
              validOptionalString(args[Constants.MERCHANT_ACCOUNT_ID_KEY]) else { return nil }

        let intent: BTPayPalRequestIntent
        switch args[Constants.PAYMENT_INTENT] as? String {
        case "authorize": intent = .authorize
        case "sale": intent = .sale
        case "order": intent = .order
        default: return nil
        }
        let userAction: BTPayPalRequestUserAction
        switch args[Constants.USER_ACTION] as? String {
        case "none": userAction = .none
        case "payNow": userAction = .payNow
        default: return nil
        }

        // 6.30.0 requires the email argument for this initializer; an empty
        // value is omitted from the SDK payload and preserves existing behavior.
        let request = BTPayPalCheckoutRequest(
            userAuthenticationEmail: "",
            enablePayPalAppSwitch: appSwitchLink(args) != nil,
            amount: amount,
            intent: intent,
            userAction: userAction,
            currencyCode: currency,
            requestBillingAgreement: false
        )
        request.displayName = args[Constants.DISPLAY_NAME_KEY] as? String
        request.merchantAccountID = args[Constants.MERCHANT_ACCOUNT_ID_KEY] as? String
        request.isShippingAddressRequired = false
        return request
    }

    private static func appSwitchLink(_ args: [String: Any]) -> URL? {
        guard (args[Constants.ENABLE_PAYPAL_APP_SWITCH_KEY] as? Bool ?? true),
              let value = args[Constants.PAYPAL_UNIVERSAL_LINK_KEY] as? String,
              !value.contains(where: { $0.isWhitespace }),
              let url = URL(string: value), url.scheme?.lowercased() == "https",
              let host = url.host, !host.isEmpty,
              url.user == nil, url.password == nil,
              url.query == nil, url.fragment == nil else { return nil }
        return url
    }

    private static func validOptionalBoolean(_ value: Any?) -> Bool {
        guard let value else { return true }
        guard let number = value as? NSNumber else { return false }
        return CFGetTypeID(number) == CFBooleanGetTypeID()
    }

    private static func matchesEntire(_ pattern: String, _ value: String) -> Bool {
        guard let range = value.range(of: pattern, options: .regularExpression) else { return false }
        return range == value.startIndex..<value.endIndex
    }

    private static func validOptionalString(_ value: Any?) -> Bool {
        guard let value else { return true }
        guard let string = value as? String else { return false }
        return !string.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    private static func response(account: PayPalCheckoutAccount?, error: Error?) -> Any {
        if let error {
            let nativeError = error as NSError
            if nativeError.domain == BTPayPalError.errorDomain && nativeError.code == BTPayPalError.canceled.errorCode {
                return FlutterError(code: Constants.CANCELED_KEY, message: "Payment was canceled.", details: nil)
            }
            return failure()
        }
        guard let account, !account.nonce.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return failure()
        }
        let json: [String: Any] = [
            "nonce": account.nonce,
            "isDefault": account.isDefault,
            "billingAddress": account.billingAddress.map(BraintreeUtils.postalAddressToJson) as Any? ?? NSNull(),
            "clientMetadataId": account.clientMetadataId as Any? ?? NSNull(),
            "firstName": account.firstName as Any? ?? NSNull(),
            "lastName": account.lastName as Any? ?? NSNull(),
            "phone": account.phone as Any? ?? NSNull(),
            "email": account.email as Any? ?? NSNull(),
            "payerId": account.payerId as Any? ?? NSNull()
        ]
        guard let data = try? JSONSerialization.data(withJSONObject: json),
              let jsonString = String(data: data, encoding: .utf8) else { return failure() }
        return jsonString
    }

    private static func failure() -> FlutterError {
        FlutterError(code: Constants.ERROR_KEY, message: "PayPal Checkout failed.", details: nil)
    }
}
