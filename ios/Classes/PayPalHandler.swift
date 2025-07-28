import Braintree
import Flutter

class PayPalHandler {
    static func handle(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any] else { return }

        guard let token = args[Constants.TOKEN_KEY] as? String else {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Missing Braintree token", details: nil))
            return
        }

        guard let apiClient = BTAPIClient(authorization: token) else {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Invalid Braintree token", details: nil))
            return
        }

        let payPalClient = BTPayPalClient(apiClient: apiClient)
        let request = BTPayPalVaultRequest()

        payPalClient.tokenize(request) { account, error in
            if let error = error {
                result(FlutterError(code: Constants.ERROR_KEY, message: error.localizedDescription, details: nil))
            } else if let account = account {
                let address = BraintreeUtils.postalAddressToJson(account.billingAddress ?? BTPostalAddress())
                let json: [String: Any?] = [
                    "nonce": account.nonce,
                    "isDefault": account.isDefault,
                    "billingAddress": address,
                    "clientMetadataId": account.clientMetadataID,
                    "firstName": account.firstName,
                    "lastName": account.lastName,
                    "phone": account.phone,
                    "email": account.email,
                    "payerId": account.payerID
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
}
