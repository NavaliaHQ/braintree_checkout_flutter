import 'package:braintree_checkout_flutter/braintree_checkout_flutter_method_channel.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_account_nonce.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_request.dart';
import 'package:plugin_platform_interface/plugin_platform_interface.dart';

abstract class BraintreeCheckoutFlutterPlatform extends PlatformInterface {
  BraintreeCheckoutFlutterPlatform() : super(token: _token);

  static final Object _token = Object();

  static BraintreeCheckoutFlutterPlatform _instance = MethodChannelBraintreeCheckoutFlutter();

  static BraintreeCheckoutFlutterPlatform get instance => _instance;

  static set instance(BraintreeCheckoutFlutterPlatform instance) {
    PlatformInterface.verifyToken(instance, _token);
    _instance = instance;
  }

  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request);

  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request);

  Future<bool?> isVenmoAppInstalled();

  Future<String?> getData(String token);
}
