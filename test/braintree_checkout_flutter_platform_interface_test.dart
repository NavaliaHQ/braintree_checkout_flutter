import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';

import 'factories/legacy_platform_fake.dart';
import 'factories/paypal_checkout_request_factory.dart';
import 'factories/paypal_request_factory.dart';

void main() {
  test(
    'should support alias when subclass only implements legacy vault',
    () async {
      final legacyPlatform = LegacyPlatformFake();
      final vaultRequest = PayPalRequestFactory.create();
      final vaultNonce = await legacyPlatform.paypalVaultPayment(vaultRequest);
      expect(legacyPlatform.vaultRequest, same(vaultRequest));
      expect(vaultNonce?.nonce, 'test-nonce');
    },
  );

  test('should reject checkout when subclass has no implementation', () async {
    final legacyPlatform = LegacyPlatformFake();
    await expectLater(
      legacyPlatform.paypalCheckoutPayment(
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
    expect(legacyPlatform.vaultRequest, isNull);
  });
}
