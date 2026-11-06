import 'package:braintree_checkout_flutter/paypal/paypal_checkout_request.dart';
import 'dart:convert';

import 'package:braintree_checkout_flutter/braintree_checkout_flutter_platform_interface.dart';
import 'package:braintree_checkout_flutter/braintree_constants.dart';
import 'package:braintree_checkout_flutter/card/card_account_nonce.dart';
import 'package:braintree_checkout_flutter/card/card_request.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';
import 'package:braintree_checkout_flutter/three_d_secure/three_d_secure_nonce.dart';
import 'package:braintree_checkout_flutter/three_d_secure/three_d_secure_request.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_account_nonce.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MethodChannelBraintreeCheckoutFlutter
    extends BraintreeCheckoutFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('braintree_checkout_flutter');

  @override
  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request) async {
    final responseChannel = await methodChannel.invokeMethod<String>(
      BraintreeConstants.venmoPaymentMethodKey,
      request.toJson(),
    );
    if (responseChannel != null) {
      final json = jsonDecode(responseChannel);
      return VenmoAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) async {
    final responseChannel = await methodChannel.invokeMethod<String>(
      BraintreeConstants.paypalPaymentMethodKey,
      request.toJson(),
    );
    if (responseChannel != null) {
      final json = jsonDecode(responseChannel);
      return PayPalAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<PayPalAccountNonce?> paypalCheckoutPayment(
    PayPalCheckoutRequest request,
  ) async {
    if (kIsWeb || defaultTargetPlatform != TargetPlatform.iOS) {
      throw PlatformException(
        code: 'unsupported_platform',
        message: 'PayPal Checkout is currently supported only on iOS.',
      );
    }
    try {
      request.validate();
    } on ArgumentError {
      throw PlatformException(
        code: 'invalid_arguments',
        message: 'Invalid PayPal Checkout request.',
      );
    }

    final response = await methodChannel.invokeMethod<Object?>(
      BraintreeConstants.paypalCheckoutPaymentMethodKey,
      request.toJson(),
    );
    try {
      if (response is! String) {
        throw const FormatException();
      }
      final decoded = jsonDecode(response);
      if (decoded is! Map<String, dynamic>) {
        throw const FormatException();
      }
      final account = PayPalAccountNonce.fromJson(decoded);
      if (account.nonce.trim().isEmpty) {
        throw const FormatException();
      }
      return account;
    } on FormatException {
      throw _invalidCheckoutResponse();
    } on TypeError {
      throw _invalidCheckoutResponse();
    }
  }

  PlatformException _invalidCheckoutResponse() => PlatformException(
    code: 'error',
    message: 'Invalid PayPal Checkout response.',
  );

  @override
  Future<CardAccountNonce?> tokenizeCard(CardRequest request) async {
    final responseChannel = await methodChannel.invokeMethod<String>(
      BraintreeConstants.tokenizeCardMethodKey,
      request.toJson(),
    );
    if (responseChannel != null) {
      final json = jsonDecode(responseChannel);
      return CardAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<ThreeDSecureNonce?> threeDSecurePayment(
    ThreeDSecureRequest request,
  ) async {
    final responseChannel = await methodChannel.invokeMethod<String>(
      BraintreeConstants.threeDSecurePaymentMethodKey,
      request.toJson(),
    );
    if (responseChannel != null) {
      final json = jsonDecode(responseChannel);
      return ThreeDSecureNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<String?> getData(String token) => methodChannel.invokeMethod<String>(
    BraintreeConstants.getDataMethodKey,
    {'token': token},
  );

  @override
  Future<bool?> isVenmoAppInstalled() => methodChannel.invokeMethod<bool?>(
    BraintreeConstants.isVenmoAppInstalledMethodKey,
  );
}
