import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:braintree_checkout_flutter/braintree_checkout_flutter.dart';

void main() {
  runApp(const BraintreeExampleApp());
}

class BraintreeExampleApp extends StatelessWidget {
  const BraintreeExampleApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Braintree Checkout Example',
      theme: ThemeData(primarySwatch: Colors.blue),
      home: const CheckoutPage(),
    );
  }
}

class CheckoutPage extends StatefulWidget {
  const CheckoutPage({super.key});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  final BraintreeCheckoutFlutter _braintree = BraintreeCheckoutFlutter();
  String _output = 'Result will appear here...';
  bool _isPayPalInProgress = false;

  static const _clientToken = 'YOUR_CLIENT_TOKEN_FROM_SERVER';

  Future<void> _startPayPalFlow({required bool oneTimeCheckout}) async {
    if (_isPayPalInProgress) return;
    setState(() => _isPayPalInProgress = true);
    try {
      final nonce = oneTimeCheckout
          ? await _braintree.paypalCheckoutPayment(
              const PayPalCheckoutRequest(
                token: _clientToken,
                amount: '12.34',
                currencyCode: 'USD',
                displayName: 'Your Store',
                intent: PayPalCheckoutIntent.sale,
                userAction: PayPalCheckoutUserAction.payNow,
              ),
            )
          : await _braintree.paypalVaultPayment(
              const PayPalRequest(
                token: _clientToken,
                amount: '12.34',
                currencyCode: 'USD',
                displayName: 'Your Store',
                androidAppLinkReturnUrl: 'https://your-company.com/payments',
                androidDeepLinkFallbackUrlScheme: 'your.app.payments',
              ),
            );
      if (!mounted) return;
      setState(() {
        _output = nonce == null
            ? 'No PayPal authorization returned.'
            : 'PayPal authorized. Send the nonce to your server to process payment.';
      });
    } on PlatformException catch (error) {
      if (!mounted) return;
      setState(() {
        _output = error.code == 'canceled'
            ? 'PayPal approval canceled.'
            : 'PayPal could not complete (${error.code}).';
      });
    } finally {
      if (mounted) setState(() => _isPayPalInProgress = false);
    }
  }

  void _startVenmoFlow() async {
    final isInstalled = await _braintree.isVenmoAppInstalled();
    if (!isInstalled) {
      setState(() {
        _output = 'Venmo app is not installed.';
      });
      return;
    }

    final result = await _braintree.venmoPayment(
      VenmoRequest(
        token: _clientToken,
        amount: '10.99',
        displayName: 'Name',
        androidAppLinkReturnUrl: 'packageInfo.packageName',
        androidDeepLinkFallbackUrlScheme: 'packageInfo.packageName',
        iosUniversalLinkReturnUrl: 'your-company.com/order',
      ),
    );

    setState(() {
      _output = result == null
          ? 'Venmo flow canceled.'
          : 'Venmo nonce: ${result.nonce}';
    });
  }

  void _collectDeviceData() async {
    final deviceData = await _braintree.collectDeviceData(_clientToken);
    setState(() {
      _output = deviceData ?? 'Failed to collect device data.';
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Braintree Checkout Example')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: [
            ElevatedButton(
              onPressed: _isPayPalInProgress
                  ? null
                  : () => _startPayPalFlow(oneTimeCheckout: false),
              child: const Text('PayPal Vault'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed:
                  !_isPayPalInProgress &&
                      !kIsWeb &&
                      defaultTargetPlatform == TargetPlatform.iOS
                  ? () => _startPayPalFlow(oneTimeCheckout: true)
                  : null,
              child: const Text('PayPal One-Time Checkout (iOS)'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isPayPalInProgress ? null : _startVenmoFlow,
              child: const Text('Pay with Venmo'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _isPayPalInProgress ? null : _collectDeviceData,
              child: const Text('Collect Device Data'),
            ),
            const SizedBox(height: 24),
            Text(_output),
          ],
        ),
      ),
    );
  }
}
