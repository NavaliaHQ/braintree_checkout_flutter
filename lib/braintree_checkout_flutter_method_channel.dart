import 'dart:convert';

import 'package:braintree_checkout_flutter/braintree_checkout_flutter_platform_interface.dart';
import 'package:braintree_checkout_flutter/braintree_constants.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_account_nonce.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_request.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

class MethodChannelBraintreeCheckoutFlutter extends BraintreeCheckoutFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('braintree_checkout_flutter');

  @override
  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request) async {
    final responseChannel = await methodChannel.invokeMethod<String>(BraintreeConstants.venmoPaymentMethodKey, request.toJson());
    if (responseChannel != null) {
      final json = jsonDecode(responseChannel);
      return VenmoAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) async {
    final responseChannel = await methodChannel.invokeMethod<String>(BraintreeConstants.paypalPaymentMethodKey, request.toJson());
    if (responseChannel != null) {
      final json = jsonDecode(responseChannel);
      return PayPalAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<String?> getData(String token) => methodChannel.invokeMethod<String>(BraintreeConstants.getDataMethodKey, {'token': token});

  @override
  Future<bool?> isVenmoAppInstalled() => methodChannel.invokeMethod<bool?>(BraintreeConstants.isVenmoAppInstalledMethodKey);
}
