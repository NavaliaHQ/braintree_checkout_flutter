import 'package:braintree_checkout_flutter/paypal/paypal_checkout_request.dart';
import 'package:braintree_checkout_flutter/braintree_checkout_flutter_platform_interface.dart';
import 'package:braintree_checkout_flutter/card/card_account_nonce.dart';
import 'package:braintree_checkout_flutter/card/card_request.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_account_nonce.dart';
import 'package:braintree_checkout_flutter/paypal/paypal_request.dart';
import 'package:braintree_checkout_flutter/three_d_secure/three_d_secure_nonce.dart';
import 'package:braintree_checkout_flutter/three_d_secure/three_d_secure_request.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_account_nonce.dart';
import 'package:braintree_checkout_flutter/venmo/venmo_request.dart';

export 'commons/postal_address.dart';
export 'paypal/paypal_account_nonce.dart';
export 'paypal/paypal_request.dart';
export 'paypal/paypal_checkout_request.dart';
export 'venmo/venmo_account_nonce.dart';
export 'venmo/venmo_request.dart';
export 'card/card_account_nonce.dart';
export 'card/card_request.dart';

class BraintreeCheckoutFlutter {
  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.venmoPayment(request);

  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.paypalPayment(request);

  /// Starts the existing Vault flow using an explicit name.
  Future<PayPalAccountNonce?> paypalVaultPayment(PayPalRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.paypalVaultPayment(request);

  /// Approves a one-time PayPal payment on iOS without a billing agreement.
  /// Send the returned nonce to your server to create the transaction.
  /// Cancellation throws a PlatformException with code `canceled`.
  Future<PayPalAccountNonce?> paypalCheckoutPayment(
    PayPalCheckoutRequest request,
  ) => BraintreeCheckoutFlutterPlatform.instance.paypalCheckoutPayment(request);

  Future<CardAccountNonce?> tokenizeCard(CardRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.tokenizeCard(request);

  Future<ThreeDSecureNonce?> threeDSecurePayment(ThreeDSecureRequest request) =>
      BraintreeCheckoutFlutterPlatform.instance.threeDSecurePayment(request);

  Future<String?> collectDeviceData(String token) =>
      BraintreeCheckoutFlutterPlatform.instance.getData(token);

  Future<bool> isVenmoAppInstalled() async {
    final isVenmoAppInstalled = await BraintreeCheckoutFlutterPlatform.instance
        .isVenmoAppInstalled();
    return isVenmoAppInstalled ?? false;
  }
}
