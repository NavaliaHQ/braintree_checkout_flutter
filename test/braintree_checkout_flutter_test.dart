import 'package:braintree_checkout_flutter/braintree_checkout_flutter.dart';
import 'package:braintree_checkout_flutter/braintree_checkout_flutter_platform_interface.dart';
import 'package:flutter_test/flutter_test.dart';

import 'factories/legacy_platform_fake.dart';
import 'factories/paypal_account_nonce_factory.dart';
import 'factories/paypal_checkout_request_factory.dart';
import 'factories/paypal_request_factory.dart';

class CheckoutPlatformFake extends LegacyPlatformFake {
  PayPalCheckoutRequest? checkoutRequest;

  @override
  Future<PayPalAccountNonce?> paypalCheckoutPayment(
    PayPalCheckoutRequest request,
  ) async {
    checkoutRequest = request;
    return PayPalAccountNonce.fromJson(PayPalAccountNonceFactory.json());
  }
}

void main() {
  test(
    'should delegate each explicit method when selected by consumer',
    () async {
      final previousPlatform = BraintreeCheckoutFlutterPlatform.instance;
      final checkoutPlatform = CheckoutPlatformFake();
      BraintreeCheckoutFlutterPlatform.instance = checkoutPlatform;
      addTearDown(
        () => BraintreeCheckoutFlutterPlatform.instance = previousPlatform,
      );
      final checkout = BraintreeCheckoutFlutter();
      final checkoutRequest = PayPalCheckoutRequestFactory.create();
      final vaultRequest = PayPalRequestFactory.create();
      final checkoutNonce = await checkout.paypalCheckoutPayment(
        checkoutRequest,
      );
      expect(checkoutNonce?.nonce, 'test-nonce');
      expect(checkoutPlatform.checkoutRequest, same(checkoutRequest));
      expect(checkoutPlatform.vaultRequest, isNull);
      await checkout.paypalVaultPayment(vaultRequest);
      expect(checkoutPlatform.vaultRequest, same(vaultRequest));
      await checkout.paypalPayment(vaultRequest);
      expect(checkoutPlatform.vaultRequest, same(vaultRequest));
    },
  );
}
