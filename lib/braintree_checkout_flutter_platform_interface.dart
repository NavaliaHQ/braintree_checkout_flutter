import 'package:flutter/services.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_checkout_request.dart';
import 'package:braintree_checkout_flutter/braintree_checkout_flutter_method_channel.dart';
import 'package:braintree_checkout_flutter/card/card_account_nonce.dart';
import 'package:braintree_checkout_flutter/card/card_request.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';
import 'package:braintree_checkout_flutter/three_d_secure/three_d_secure_nonce.dart';
import 'package:braintree_checkout_flutter/three_d_secure/three_d_secure_request.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_account_nonce.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class BraintreeCheckoutFlutterPlatform extends PlatformInterface {
  BraintreeCheckoutFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BraintreeCheckoutFlutterPlatform _instance =
      MethodChannelBraintreeCheckoutFlutter();

  static BraintreeCheckoutFlutterPlatform get instance => _instance;

  static set instance(BraintreeCheckoutFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request);

  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request);

  /// Explicit Vault alias preserving the legacy platform implementation.
  Future<PayPalAccountNonce?> paypalVaultPayment(PayPalRequest request) =>
      paypalPayment(request);

  /// Platforms must opt in to one-time checkout; never falls back to Vault.
  Future<PayPalAccountNonce?> paypalCheckoutPayment(
    PayPalCheckoutRequest request,
  ) async => throw PlatformException(
    code: 'unsupported_platform',
    message:
        'PayPal Checkout is not supported by this platform implementation.',
  );

  Future<CardAccountNonce?> tokenizeCard(CardRequest request);

  Future<ThreeDSecureNonce?> threeDSecurePayment(ThreeDSecureRequest request);

  Future<bool?> isVenmoAppInstalled();

  Future<String?> getData(String token);
}
