import Flutter
import UIKit
import Braintree

public class BraintreeCheckoutFlutterPlugin: NSObject, FlutterPlugin {
    private var flutterResult: FlutterResult?
    var universalLinkURL: URL?
    
    public static var shared = BraintreeCheckoutFlutterPlugin()
    
    override private init() {}

    public static func register(with registrar: FlutterPluginRegistrar) {
        let channel = FlutterMethodChannel(name: "braintree_checkout_flutter", binaryMessenger: registrar.messenger())
        let instance = BraintreeCheckoutFlutterPlugin.shared
        registrar.addMethodCallDelegate(instance, channel: channel)
    }

    public func handle(_ call: FlutterMethodCall, result: @escaping FlutterResult) {
        self.flutterResult = result

        switch call.method {
        case Constants.DATA_INFO_METHOD_KEY:
            if let args = call.arguments as? [String: Any] {
                collectDeviceData(arguments: args, result: result)
            } else {
                result(FlutterError(code: Constants.ERROR_KEY, message: "Invalid arguments for getData", details: nil))
            }

        case Constants.PAYPAL_PAYMENT_METHOD_KEY:
            PayPalHandler.handle(arguments: call.arguments, result: result)

        case Constants.VENMO_PAYMENT_METHOD_KEY:
            VenmoHandler.handle(arguments: call.arguments, result: result)
            
        case Constants.IS_VENMO_APP_INSTALLED:
            VenmoHandler.isVenmoAppInstalled(result: result)
            
        case Constants.TOKENIZE_CARD_METHOD_KEY:
            tokenizeCard(arguments: call.arguments, result: result)
        
        case Constants.THREE_D_SECURE_METHOD_KEY:
            ThreeDSecureHandler.handle(arguments: call.arguments, result: result)
            
        default:
            result(FlutterMethodNotImplemented)
        }
    }
    
    private func isBraintreeUniversalLink(url: URL) -> Bool {
        guard let universalLinkURL else {
            return false
        }

        return url.scheme == universalLinkURL.scheme &&
               url.host == universalLinkURL.host &&
               url.path.hasPrefix(universalLinkURL.path)
    }

    private func collectDeviceData(arguments: [String: Any], result: @escaping FlutterResult) {
        guard let token = arguments[Constants.TOKEN_KEY] as? String else {
            flutterResult?(FlutterError(code: Constants.ERROR_KEY, message: "Token is required for data collection", details: nil))
            return
        }

        guard let braintreeClient = BTAPIClient(authorization: token) else {
            flutterResult?(FlutterError(code: Constants.ERROR_KEY, message: "Invalid Braintree client", details: nil))
            return
        }

        let dataCollector = BTDataCollector(apiClient: braintreeClient)
        dataCollector.collectDeviceData { (deviceData, error) in
            if let error = error {
                result(FlutterError(code: Constants.ERROR_KEY, message: error.localizedDescription, details: nil))
            } else if let deviceData = deviceData {
                result(deviceData)
            } else {
                result(FlutterError(code: Constants.ERROR_KEY, message: "Device data collection failed", details: "No data and no error returned"))
            }
        }
    }
    
    private func tokenizeCard(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any] else { return }
        
        guard
            let token = args[Constants.TOKEN_KEY] as? String,
            let cardholderName = args[Constants.CARDHOLDER_NAME_KEY] as? String,
            let cardNumber = args[Constants.CARD_NUMBER_KEY] as? String,
            let expirationMonth = args[Constants.EXPIRATION_MONTH_KEY] as? String,
            let expirationYear = args[Constants.EXPIRATION_YEAR_KEY] as? String,
            let cvv = args[Constants.CVV_KEY] as? String
        else {
            flutterResult?(FlutterError(code: Constants.ERROR_KEY, message: "Token, card number, expiration month, expiration year and cvv are required for tokenization", details: nil))
            return
        }
        
        guard let braintreeClient = BTAPIClient(authorization: token) else {
            flutterResult?(FlutterError(code: Constants.ERROR_KEY, message: "Invalid Braintree client", details: nil))
            return
        }
        
        let cardClient = BTCardClient(apiClient: braintreeClient)
        let card = BTCard()
        card.cardholderName = cardholderName
        card.number = cardNumber
        card.expirationMonth = expirationMonth
        card.expirationYear = expirationYear
        card.cvv = cvv
        cardClient.tokenize(card) { tokenizedCard, error in
            if let error = error {
                result(FlutterError(code: Constants.ERROR_KEY, message: error.localizedDescription, details: nil))
            } else if let tokenizedCard = tokenizedCard {
                let json: [String: Any?] = [
                    "nonce": tokenizedCard.nonce,
                    "isDefault": tokenizedCard.isDefault,
                    "cardType": tokenizedCard.type,
                    "lastTwo": tokenizedCard.lastTwo,
                    "lastFour": tokenizedCard.lastFour,
                    "expirationMonth": tokenizedCard.expirationMonth,
                    "expirationYear": tokenizedCard.expirationYear,
                    "cardholderName": tokenizedCard.cardholderName
                ]
                self.sendSuccess(json: json, result: result)
            } else {
                result(FlutterError(code: Constants.ERROR_KEY, message: "Tokenize card failed", details: "No data and no error returned"))
            }
        }
    }
    
    private func sendSuccess(json: [String: Any?], result: @escaping FlutterResult) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: data, encoding: .utf8)
            result(jsonString)
        } catch {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Failed to serialize JSON", details: error.localizedDescription))
        }
    }
}

extension BraintreeCheckoutFlutterPlugin {
    public func application(
        _ application: UIApplication,
        continue userActivity: NSUserActivity,
        restorationHandler: @escaping ([UIUserActivityRestoring]?) -> Void
    ) -> Bool {
        guard userActivity.activityType == NSUserActivityTypeBrowsingWeb,
              let url = userActivity.webpageURL else {
            return false
        }

        if isBraintreeUniversalLink(url: url) {
            BTAppContextSwitcher.sharedInstance.handleOpen(url)
            return true
        }
        
        return false
    }
}
