import 'package:braintree_checkout_flutter/paypal/paypal_checkout_request.dart';
import 'package:flutter_test/flutter_test.dart';

import '../factories/paypal_checkout_request_factory.dart';

void main() {
  test('should serialize defaults when optional fields are absent', () {
    final checkoutRequest = PayPalCheckoutRequestFactory.create();
    expect(checkoutRequest.intent, PayPalCheckoutIntent.authorize);
    expect(checkoutRequest.userAction, PayPalCheckoutUserAction.none);
    expect(checkoutRequest.toJson(), {
      'token': 'client-token',
      'amount': '29.90',
      'currencyCode': 'USD',
      'paymentIntent': 'authorize',
      'userAction': 'none',
    });
  });

  test('should serialize explicit options when supplied', () {
    final checkoutRequest = PayPalCheckoutRequestFactory.create(
      displayName: 'Store',
      merchantAccountId: 'merchant',
      intent: PayPalCheckoutIntent.sale,
      userAction: PayPalCheckoutUserAction.payNow,
    );
    expect(checkoutRequest.toJson(), {
      'token': 'client-token',
      'amount': '29.90',
      'currencyCode': 'USD',
      'displayName': 'Store',
      'merchantAccountId': 'merchant',
      'paymentIntent': 'sale',
      'userAction': 'payNow',
    });
    expect(
      PayPalCheckoutRequestFactory.create(
        intent: PayPalCheckoutIntent.order,
      ).toJson()['paymentIntent'],
      'order',
    );
  });

  for (final amount in ['0', '0.00', '10', '10.00', '9999999.99']) {
    test('should preserve amount when valid input is $amount', () {
      final checkoutRequest = PayPalCheckoutRequestFactory.create(
        amount: amount,
      );
      expect(checkoutRequest.validate, returnsNormally);
      expect(checkoutRequest.toJson()['amount'], amount);
    });
  }

  for (final amount in [
    '',
    '-1',
    '1,00',
    ' 1',
    '1 ',
    '1\n',
    '1e2',
    'NaN',
    '1.0',
    '1.000',
    '10000000',
    '.00',
  ]) {
    test(
      'should reject amount when input is ${amount.replaceAll('\n', r'\n')}',
      () {
        final checkoutRequest = PayPalCheckoutRequestFactory.create(
          amount: amount,
        );
        expect(checkoutRequest.validate, throwsArgumentError);
      },
    );
  }

  for (final currencyCode in ['', 'usd', 'US', 'USDD', '123', 'USD\n']) {
    test(
      'should reject currency when input is ${currencyCode.replaceAll('\n', r'\n')}',
      () {
        final checkoutRequest = PayPalCheckoutRequestFactory.create(
          currencyCode: currencyCode,
        );
        expect(checkoutRequest.validate, throwsArgumentError);
      },
    );
  }

  test('should reject blank strings when supplied', () {
    for (final checkoutRequest in [
      PayPalCheckoutRequestFactory.create(token: ' \n'),
      PayPalCheckoutRequestFactory.create(displayName: ' '),
      PayPalCheckoutRequestFactory.create(merchantAccountId: ''),
    ]) {
      expect(checkoutRequest.validate, throwsArgumentError);
    }
  });
}
