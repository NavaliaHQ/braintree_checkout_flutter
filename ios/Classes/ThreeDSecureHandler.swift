import Braintree
import Flutter

class ThreeDSecureHandler {
    private static var apiClient: BTAPIClient?
    private static var threeDSClient: BTThreeDSecureClient?
    private static var threeDSDelegate: ThreeDSDelegate?
    
    // Delegate 3DS v2
    final class ThreeDSDelegate: NSObject, BTThreeDSecureRequestDelegate {
        func onLookupComplete(_ request: BTThreeDSecureRequest,
                              lookupResult: BTThreeDSecureResult,
                              next: @escaping () -> Void) {
            next()
        }
    }
    
    static func handle(arguments: Any?, result: @escaping FlutterResult) {
        guard let args = arguments as? [String: Any],
              let token = args[Constants.TOKEN_KEY] as? String,
              let amount = args[Constants.AMOUNT_KEY] as? String,
              let nonce = args[Constants.NONCE_KEY] as? String else {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Invalid arguments", details: nil))
            return
        }
        let email = args[Constants.EMAIL_KEY] as? String

        guard let apiClient = BTAPIClient(authorization: token) else {
            result(FlutterError(code: Constants.ERROR_KEY, message: "Invalid Braintree token", details: nil))
            return
        }

        self.apiClient = apiClient
        let threeDSecureClient = BTThreeDSecureClient(apiClient: apiClient)
        self.threeDSClient = threeDSecureClient
        let request = BTThreeDSecureRequest()
        request.amount = NSDecimalNumber(string: amount)
        request.nonce = nonce
        request.email = email

        let delegate = ThreeDSDelegate()
        self.threeDSDelegate = delegate
        request.threeDSecureRequestDelegate = delegate
        
        threeDSecureClient.startPaymentFlow(request) { threeDSResult, error in
            if let error = error {
                result(FlutterError(code: Constants.ERROR_KEY, message: error.localizedDescription, details: nil))
                return
            }

            guard let threeDSResult = threeDSResult else {
                result(FlutterError(code: Constants.ERROR_KEY, message: "3DS failed", details: "No result and no error returned"))
                return
            }

            guard let tokenizedCard = threeDSResult.tokenizedCard else {
                result(FlutterError(code: Constants.ERROR_KEY, message: "Tokenize card failed", details: "No tokenized card in 3DS result"))
                return
            }

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
