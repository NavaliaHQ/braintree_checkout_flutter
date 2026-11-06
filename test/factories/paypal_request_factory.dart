import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';

class PayPalRequestFactory {
  static PayPalRequest create() => const PayPalRequest(
    token: 'client-token',
    amount: '29.90',
    displayName: 'Store',
    androidAppLinkReturnUrl: 'https://example.com/return',
  );
}
