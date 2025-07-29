import 'package:braintree_checkout_flutter/braintree_checkout_flutter_platform_interface.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_account_nonce.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_request.dart';

export 'commons/postal_address.dart';
export 'paypal/paypal_account_nonce.dart';
export 'paypal/paypal_request.dart';
export 'venmo/venmo_account_nonce.dart';
export 'venmo/venmo_request.dart';

class BraintreeCheckoutFlutter {
  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.venmoPayment(request);

  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.paypalPayment(request);

  Future<String?> collectDeviceData(String token) =>
      BraintreeCheckoutFlutterPlatform.instance.getData(token);

  Future<bool> isVenmoAppInstalled() async {
    final isVenmoAppInstalled = await BraintreeCheckoutFlutterPlatform.instance
        .isVenmoAppInstalled();
    return isVenmoAppInstalled ?? false;
  }
}
