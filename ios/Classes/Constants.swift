import Foundation

public struct Constants {
    static let DATA_INFO_METHOD_KEY = "getData"
    static let VENMO_PAYMENT_METHOD_KEY = "venmoPayment"
    static let PAYPAL_PAYMENT_METHOD_KEY = "paypalPayment"
    static let IS_VENMO_APP_INSTALLED = "isVenmoAppInstalled"

    static let TOKEN_KEY = "token"
    static let AMOUNT_KEY = "amount"
    static let CURRENCY_CODE_KEY = "currencyCode"
    static let IOS_UNIVERSAL_LINK_RETURN_URL = "iosUniversalLinkReturnUrl"
    static let DISPLAY_NAME_KEY = "displayName"
    static let PAYMENT_INTENT = "paymentIntent"
    static let USER_ACTION = "userAction"

    static let VENMO_X_CALLBACK_URL = "scheme://x-callback-url/path"
    static let VENMO_URL_SCHEME = "com.venmo.touch.v2"
    static let VENMO_PERCENT_ENCODED_PATH = "/vzero/auth"

    static let NONCE_KEY = "nonce"
    static let CANCELED_KEY = "canceled"
    static let ERROR_KEY = "error"
}
