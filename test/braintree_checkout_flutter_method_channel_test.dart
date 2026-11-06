import 'dart:convert';

import 'package:braintree_checkout_flutter/braintree_checkout_flutter_method_channel.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'factories/paypal_account_nonce_factory.dart';
import 'factories/paypal_checkout_request_factory.dart';
import 'factories/paypal_request_factory.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('should send checkout payload when platform is iOS', () async {
    final checkoutChannel = MethodChannelBraintreeCheckoutFlutter();
    final checkoutRequest = PayPalCheckoutRequestFactory.create();
    final calls = <MethodCall>[];
    usePlatform(TargetPlatform.iOS);
    mockChannel(checkoutChannel, (call) async {
      calls.add(call);
      return jsonEncode(PayPalAccountNonceFactory.json());
    });
    final checkoutNonce = await checkoutChannel.paypalCheckoutPayment(
      checkoutRequest,
    );
    expect(checkoutNonce?.nonce, 'test-nonce');
    expect(calls.single.method, 'paypalCheckoutPayment');
    expect(calls.single.arguments, checkoutRequest.toJson());
  });

  test('should avoid native invocation when platform is unsupported', () async {
    final checkoutChannel = MethodChannelBraintreeCheckoutFlutter();
    var invocationCount = 0;
    usePlatform(TargetPlatform.android);
    mockChannel(checkoutChannel, (call) async {
      invocationCount++;
      return null;
    });
    await expectLater(
      checkoutChannel.paypalCheckoutPayment(
        PayPalCheckoutRequestFactory.create(),
      ),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'unsupported_platform',
        ),
      ),
    );
    expect(invocationCount, 0);
  });

  test('should avoid native invocation when request is invalid', () async {
    final checkoutChannel = MethodChannelBraintreeCheckoutFlutter();
    var invocationCount = 0;
    usePlatform(TargetPlatform.iOS);
    mockChannel(checkoutChannel, (call) async {
      invocationCount++;
      return null;
    });
    await expectLater(
      checkoutChannel.paypalCheckoutPayment(
        PayPalCheckoutRequestFactory.create(amount: '-1'),
      ),
      throwsA(
        isA<PlatformException>().having(
          (error) => error.code,
          'code',
          'invalid_arguments',
        ),
      ),
    );
    expect(invocationCount, 0);
  });

  for (final response in <Object?>[
    null,
    '{',
    '[]',
    '{}',
    'null',
    42,
    jsonEncode({...PayPalAccountNonceFactory.json(), 'nonce': ''}),
    jsonEncode({...PayPalAccountNonceFactory.json(), 'nonce': ' '}),
    jsonEncode({...PayPalAccountNonceFactory.json(), 'isDefault': 'false'}),
  ]) {
    test('should report error when native response is $response', () async {
      final checkoutChannel = MethodChannelBraintreeCheckoutFlutter();
      usePlatform(TargetPlatform.iOS);
      mockChannel(checkoutChannel, (call) async => response);
      await expectLater(
        checkoutChannel.paypalCheckoutPayment(
          PayPalCheckoutRequestFactory.create(),
        ),
        throwsA(
          isA<PlatformException>().having(
            (error) => error.code,
            'code',
            'error',
          ),
        ),
      );
    });
  }

  for (final code in [
    'canceled',
    'error',
    'payment_in_progress',
    'invalid_arguments',
  ]) {
    test('should preserve error code when native returns $code', () async {
      final checkoutChannel = MethodChannelBraintreeCheckoutFlutter();
      usePlatform(TargetPlatform.iOS);
      mockChannel(
        checkoutChannel,
        (call) async => throw PlatformException(code: code),
      );
      await expectLater(
        checkoutChannel.paypalCheckoutPayment(
          PayPalCheckoutRequestFactory.create(),
        ),
        throwsA(
          isA<PlatformException>().having((error) => error.code, 'code', code),
        ),
      );
    });
  }

  test('should preserve legacy wire contract when using vault alias', () async {
    final checkoutChannel = MethodChannelBraintreeCheckoutFlutter();
    final vaultRequest = PayPalRequestFactory.create();
    final calls = <MethodCall>[];
    usePlatform(TargetPlatform.android);
    mockChannel(checkoutChannel, (call) async {
      calls.add(call);
      return jsonEncode(PayPalAccountNonceFactory.json(withDetails: true));
    });
    final vaultNonce = await checkoutChannel.paypalVaultPayment(vaultRequest);
    final legacyNonce = await checkoutChannel.paypalPayment(vaultRequest);
    expect(vaultNonce?.toJson(), legacyNonce?.toJson());
    expect(calls, hasLength(2));
    for (final call in calls) {
      expect(call.method, 'paypalPayment');
      expect(call.arguments, vaultRequest.toJson());
    }
  });
}

void usePlatform(TargetPlatform platform) {
  final previousPlatform = debugDefaultTargetPlatformOverride;
  debugDefaultTargetPlatformOverride = platform;
  addTearDown(() => debugDefaultTargetPlatformOverride = previousPlatform);
}

void mockChannel(
  MethodChannelBraintreeCheckoutFlutter checkoutChannel,
  Future<Object?> Function(MethodCall) handler,
) {
  final messenger =
      TestDefaultBinaryMessengerBinding.instance.defaultBinaryMessenger;
  messenger.setMockMethodCallHandler(checkoutChannel.methodChannel, handler);
  addTearDown(
    () =>
        messenger.setMockMethodCallHandler(checkoutChannel.methodChannel, null),
  );
}
