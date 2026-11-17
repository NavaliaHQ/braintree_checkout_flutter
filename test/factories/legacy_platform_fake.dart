import 'package:braintree_checkout_flutter/braintree_checkout_flutter_platform_interface.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';

import 'paypal_account_nonce_factory.dart';

class LegacyPlatformFake extends BraintreeCheckoutFlutterPlatform {
  PayPalRequest? vaultRequest;

  @override
  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) async {
    vaultRequest = request;
    return PayPalAccountNonce.fromJson(PayPalAccountNonceFactory.json());
  }

  @override
  dynamic noSuchMethod(Invocation invocation) => super.noSuchMethod(invocation);
}
