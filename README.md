
# braintree_checkout_flutter

A Flutter plugin that enables seamless **PayPal** and **Venmo** payments using **Braintree**, with support for native mobile experiences and device data collection for fraud prevention.

⚠️ **Note:** This plugin currently supports **Vault (tokenize only)** transactions. You are responsible for capturing the payment server-side using the nonce returned. Full **Checkout (automatic capture)** is not supported at this time.

## Features

- Native **PayPal** payment flow 
- Native **Venmo** payment flow 
- **Device data** collection
- Venmo App availability check

## Platform Support

| Feature              | Android | iOS |
|----------------------|:-------:|:---:|
| PayPal Vault         |   ✅    | ✅  |
| Venmo Vault          |   ✅    | ✅  |
| Device Data Collect  |   ✅    | ✅  |

## Installation

Add the dependency in your `pubspec.yaml`:

```yaml
dependencies:
  braintree_checkout_flutter: ^<latest_version>
````

Then run:

```bash
flutter pub get
```

## iOS Setup

1. Add required URL schemes to your `ios/Runner/Info.plist`:

```xml
<key>LSApplicationQueriesSchemes</key>
<array>
  <string>venmo</string>
  <string>com.venmo.touch.v2</string>
  <string>paypal</string>
</array>
```

2. Enable app switch handling in `AppDelegate.swift`:

```swift
import Braintree

func application(
  _ application: UIApplication,
  open url: URL,
  options: [UIApplication.OpenURLOptionsKey : Any] = [:]
) -> Bool {
  return BTAppSwitch.handleOpen(url, options: options)
}
```

## Android Setup

Make sure you have the necessary intent filters and SDK dependencies in your native Android project.

Refer to [Braintree's official Android guide](https://developer.paypal.com/braintree/docs/guides/client-sdk/setup/android/v4) for more details.

## Usage

### Create the plugin instance

```dart
import 'package:braintree_checkout_flutter/braintree_checkout_flutter.dart';

final checkout = BraintreeCheckoutFlutter();
```

### PayPal Vault Transaction

```dart
final result = await checkout.paypalPayment(
  PayPalRequest(
    token: 'your-client-token-or-tokenization-key',
    amount: '10.00',
    currencyCode: 'USD',
    displayName: 'Your Store',
  ),
);

if (result != null) {
  print('PayPal nonce: ${result.nonce}');
}
```

### Venmo Vault Transaction

```dart
final result = await checkout.venmoPayment(
  VenmoRequest(
    token: 'your-client-token-or-tokenization-key',
  ),
);

if (result != null) {
  print('Venmo nonce: ${result.nonce}');
}
```

### Device Data Collection

```dart
final deviceData = await checkout.collectDeviceData('your-client-token-or-tokenization-key');
print('Collected device data: $deviceData');
```

### Check if Venmo App is Installed

```dart
final isInstalled = await checkout.isVenmoAppInstalled();
print('Is Venmo installed: $isInstalled');
```

## Exports

The plugin exports these models:

* `PayPalRequest`, `PayPalAccountNonce`
* `VenmoRequest`, `VenmoAccountNonce`
* `PostalAddress` (for PayPal shipping address)

## Contributing

Contributions are welcome! Feel free to open issues or pull requests on the [GitHub repository](https://github.com/your-org/braintree_checkout_flutter).
