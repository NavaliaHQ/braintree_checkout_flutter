import 'braintree_checkout_flutter_platform_interface.dart';
import 'paypal/paypal_account_nonce.dart';
import 'paypal/paypal_request.dart';
import 'venmo/venmo_account_nonce.dart';
import 'venmo/venmo_request.dart';

export 'paypal/paypal_account_nonce.dart';
export 'paypal/paypal_request.dart';
export 'venmo/venmo_account_nonce.dart';
export 'venmo/venmo_request.dart';

class BraintreeCheckoutFlutter {
  Future<VenmoAccountNonce?> venmoPayment(VenmoRequest request) async {
    return BraintreeCheckoutFlutterPlatform.instance.venmoPayment(request);
  }

  Future<PayPalAccountNonce?> paypalPayment(PayPalRequest request) async {
    return BraintreeCheckoutFlutterPlatform.instance.paypalPayment(request);
  }

  Future<String?> getData(String token) async {
    return BraintreeCheckoutFlutterPlatform.instance.getData(token);
  }
}
