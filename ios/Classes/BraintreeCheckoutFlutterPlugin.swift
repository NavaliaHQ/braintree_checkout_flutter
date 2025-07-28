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
