import 'dart:convert';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';

import 'paypal/paypal_request.dart';
import 'braintree_constants.dart';
import 'braintree_checkout_flutter_platform_interface.dart';
import 'paypal/paypal_account_nonce.dart';
import 'venmo/venmo_account_nonce.dart';
import 'venmo/venmo_request.dart';

class MethodChannelBraintreeCheckoutFlutter extends BraintreeCheckoutFlutterPlatform {
  @visibleForTesting
  final methodChannel = const MethodChannel('braintree_payment');

  @override
  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request) async {
    final String? res = await methodChannel.invokeMethod<String>(BraintreeConstants.venmoPaymentMethodKey, request.toJson());
    if (res != null) {
      final json = jsonDecode(res);
      return VenmoAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) async {
    final String? res = await methodChannel.invokeMethod<String>(BraintreeConstants.paypalPaymentMethodKey, request.toJson());
    if (res != null) {
      final json = jsonDecode(res);
      return PayPalAccountNonce.fromJson(json);
    } else {
      return null;
    }
  }

  @override
  Future<String?> getData(String token) async {
    final String? res = await methodChannel.invokeMethod<String>(BraintreeConstants.getDataMethodKey, {'token': token});
    return res;
  }
}
