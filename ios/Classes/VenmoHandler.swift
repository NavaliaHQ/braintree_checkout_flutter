import Braintree
import Flutter

class VenmoHandler {
    static func handle(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let token = args[Constants.TOKEN_KEY] as? String,
              let link = args[Constants.IOS_UNIVERSAL_LINK_RETURN_URL] as? String else {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Invalid arguments", details: nil))
            return
        }

        let apiClient = BTAPIClient(authorization: token)!
        let universalLinkURL = URL(string: link)
        BraintreeCheckoutFlutterPlugin.shared.universalLinkURL = universalLinkURL
        let venmoClient = BTVenmoClient(apiClient: apiClient, universalLink: universalLinkURL!)

        let request = BTVenmoRequest(paymentMethodUsage: .multiUse)
        request.displayName = args[Constants.DISPLAY_NAME_KEY] as? String
        request.totalAmount = args[Constants.AMOUNT_KEY] as? String

        venmoClient.tokenize(request) { account, error in
            if let error = error {
                result(FlutterError(code: Constants.ERROR_KEY, message: error.localizedDescription, details: nil))
            } else if let account = account {
                let address = BraintreeUtils.postalAddressToJson(account.billingAddress ?? BTPostalAddress())
                let json: [String: Any?] = [
                    "nonce": account.nonce,
                    "isDefault": account.isDefault,
                    "billingAddress": address,
                    "firstName": account.firstName,
                    "lastName": account.lastName,
                    "phoneNumber": account.phoneNumber,
                    "email": account.email,
                    "externalId": account.externalID
                ]
                sendSuccess(json: json, result: result)
            } else {
                result(FlutterError(code: Constants.CANCELED_KEY, message: "Payment was canceled", details: nil))
            }
        }
    }

    private static func sendSuccess(json: [String: Any?], result: @escaping FlutterResult) {
        do {
            let data = try JSONSerialization.data(withJSONObject: json, options: [])
            let jsonString = String(data: data, encoding: .utf8)
            result(jsonString)
        } catch {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Failed to serialize JSON", details: error.localizedDescription))
        }
    }
    
    static func isVenmoAppInstalled(result: @escaping FlutterResult) {
        guard let venmoAppUrl = venmoBaseUrlComponents.url else {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Failed to get Venmo app URL", details: nil))
            return
        }
        let isVenmoAppInstalled = UIApplication.shared.canOpenURL(venmoAppUrl)
        debugPrint(isVenmoAppInstalled)
        result(isVenmoAppInstalled)
    }
    
    private static var venmoBaseUrlComponents: URLComponents {
        var components = URLComponents(string: Constants.VENMO_X_CALLBACK_URL) ?? URLComponents()
        components.scheme = Constants.VENMO_URL_SCHEME
        components.percentEncodedPath = Constants.VENMO_PERCENT_ENCODED_PATH
        return components
    }
}
