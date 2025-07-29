import 'package:flutter/material.dart';
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

  static const _clientToken = 'YOUR_CLIENT_TOKEN_FROM_SERVER';

  void _startPayPalFlow() async {
    final result = await _braintree.paypalPayment(
      PayPalRequest(
        token: _clientToken,
        amount: '12.34',
        currencyCode: 'USD',
        displayName: 'Your Store',
        androidAppLinkReturnUrl: 'packageInfo.packageName',
        androidDeepLinkFallbackUrlScheme: 'packageInfo.packageName',
      ),
    );

    setState(() {
      _output = result == null
          ? 'PayPal flow canceled.'
          : 'PayPal nonce: ${result.nonce}';
    });
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
              onPressed: _startPayPalFlow,
              child: const Text('Pay with PayPal'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _startVenmoFlow,
              child: const Text('Pay with Venmo'),
            ),
            const SizedBox(height: 12),
            ElevatedButton(
              onPressed: _collectDeviceData,
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
