package io.navalia.braintree_checkout_flutter

object Constants {
    const val VENMO_PAYMENT_METHOD_KEY = "venmoPayment"
    const val PAYPAL_PAYMENT_METHOD_KEY = "paypalPayment"
    const val GET_DATA = "getData"
    const val IS_VENMO_APP_INSTALLED = "isVenmoAppInstalled"
    const val TOKENIZE_CARD_METHOD_KEY = "tokenizeCard"

    const val VENMO_REQUEST_CODE = 1001
    const val PAYPAL_REQUEST_CODE = 1002

    //Request keys
    const val TOKEN_KEY = "token"
    const val AMOUNT_KEY = "amount"
    const val DISPLAY_NAME_KEY = "displayName"
    const val CURRENCY_CODE_KEY = "currencyCode"
    const val ANDROID_APP_LINK_RETURN_URL = "androidAppLinkReturnUrl"
    const val ANDROID_DEEP_LINK_FALLBACK_URL_SCHEME = "androidDeepLinkFallbackUrlScheme"
    const val IOS_UNIVERSAL_LINK_RETURN_URL = "iosUniversalLinkReturnUrl"
    const val BILLING_AGREEMENT_DESCRIPTION = "billingAgreementDescription"

    //Request keys - Tokenize Card
    const val CARDHOLDER_NAME_KEY = "cardholderName"
    const val CARD_NUMBER_KEY = "cardNumber"
    const val EXPIRATION_MONTH_KEY = "expirationMonth"
    const val EXPIRATION_YEAR_KEY = "expirationYear"
    const val CVV_KEY = "cvv"

    //Response keys
    const val NONCE_KEY = "nonce"
    const val CANCELED_KEY = "canceled"
    const val ERROR_KEY = "error"
}
