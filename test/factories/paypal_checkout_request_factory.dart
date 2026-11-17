import 'package:braintree_checkout_flutter/paypal/paypal_checkout_request.dart';

class PayPalCheckoutRequestFactory {
  static PayPalCheckoutRequest create({
    String token = 'client-token',
    String amount = '29.90',
    String currencyCode = 'USD',
    bool enablePayPalAppSwitch = true,
    String? universalLink,
    String? userAuthenticationEmail,
    String? displayName,
    String? merchantAccountId,
    PayPalCheckoutIntent intent = PayPalCheckoutIntent.authorize,
    PayPalCheckoutUserAction userAction = PayPalCheckoutUserAction.none,
  }) => PayPalCheckoutRequest(
    token: token,
    amount: amount,
    currencyCode: currencyCode,
    enablePayPalAppSwitch: enablePayPalAppSwitch,
    universalLink: universalLink,
    userAuthenticationEmail: userAuthenticationEmail,
    displayName: displayName,
    merchantAccountId: merchantAccountId,
    intent: intent,
    userAction: userAction,
  );
}
