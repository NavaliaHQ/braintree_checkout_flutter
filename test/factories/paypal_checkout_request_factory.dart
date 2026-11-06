import 'package:braintree_checkout_flutter/paypal/paypal_checkout_request.dart';

class PayPalCheckoutRequestFactory {
  static PayPalCheckoutRequest create({
    String token = 'client-token',
    String amount = '29.90',
    String currencyCode = 'USD',
    String? displayName,
    String? merchantAccountId,
    PayPalCheckoutIntent intent = PayPalCheckoutIntent.authorize,
    PayPalCheckoutUserAction userAction = PayPalCheckoutUserAction.none,
  }) => PayPalCheckoutRequest(
    token: token,
    amount: amount,
    currencyCode: currencyCode,
    displayName: displayName,
    merchantAccountId: merchantAccountId,
    intent: intent,
    userAction: userAction,
  );
}
