import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:flutter_test/flutter_test.dart';

import '../factories/paypal_account_nonce_factory.dart';

void main() {
  test('should decode optional fields when details are present', () {
    final accountNonce = PayPalAccountNonce.fromJson(
      PayPalAccountNonceFactory.json(withDetails: true),
    );
    expect(accountNonce.payerId, 'payer-id');
    expect(accountNonce.billingAddress?.streetAddress, 'Test street');
    expect(accountNonce.email, 'buyer@example.com');
  });

  test('should decode nonce when optional fields are absent or null', () {
    for (final nonceJson in [
      PayPalAccountNonceFactory.json(),
      {
        ...PayPalAccountNonceFactory.json(),
        'payerId': null,
        'billingAddress': null,
      },
    ]) {
      final accountNonce = PayPalAccountNonce.fromJson(nonceJson);
      expect(accountNonce.nonce, 'test-nonce');
      expect(accountNonce.isDefault, isFalse);
      expect(accountNonce.payerId, isNull);
      expect(accountNonce.billingAddress, isNull);
    }
  });

  test('should reject payload when required fields are invalid', () {
    for (final nonceJson in [
      {...PayPalAccountNonceFactory.json(), 'nonce': null},
      {...PayPalAccountNonceFactory.json(), 'isDefault': 'false'},
    ]) {
      expect(
        () => PayPalAccountNonce.fromJson(nonceJson),
        throwsA(isA<TypeError>()),
      );
    }
  });
}
