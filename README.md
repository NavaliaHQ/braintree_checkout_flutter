
# braintree_checkout_flutter

A Flutter plugin that enables seamless **PayPal**, **Venmo** and **Card** payments using **Braintree**, with support for native mobile experiences and device data collection for fraud prevention.

**PayPal supports Vault on iOS/Android and One-Time Checkout (OTC) on iOS.** Both return a nonce: your server must create the transaction. Checkout approval does not automatically capture funds.

## Features

- Native **PayPal** payment flow 
- Native **Venmo** payment flow 
- Native **Card** payment flow 
- **Device data** collection
- Venmo App availability check

## Platform Support

| Feature              | Android | iOS |
|----------------------|:-------:|:---:|
| PayPal Vault         |   ✅    | ✅  |
| PayPal OTC           |   —     | ✅  |
| Venmo Vault          |   ✅    | ✅  |
| Card Vault           |   ✅    | ✅  |
| 3D Secure            |   ✅    | ✅  |
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

### Choose the PayPal flow

The consumer explicitly selects the method. No flow is chosen from the amount,
platform or token, and Checkout never falls back to Vault after an error.
If your app uses a rollout flag, call Checkout only when the flag is enabled and
the platform is iOS; otherwise explicitly select Vault. Keep that decision in
your app. Do not retry a canceled or failed Checkout as Vault automatically.

### PayPal One-Time Checkout (iOS)

```dart
import 'package:flutter/services.dart';

try {
  final nonce = await checkout.paypalCheckoutPayment(
    const PayPalCheckoutRequest(
      token: 'client-token-from-your-server',
      amount: '29.90',
      currencyCode: 'USD',
      displayName: 'Your Store',
      intent: PayPalCheckoutIntent.sale,
      userAction: PayPalCheckoutUserAction.payNow,
    ),
  );
  if (nonce != null) {
    // Send nonce.nonce to your backend; do not log payment or personal data.
  }
} on PlatformException catch (error) {
  if (error.code == 'canceled') {
    // Buyer canceled approval. Leave the order unpaid.
  } else {
    // Show an appropriate error; do not switch to Vault automatically.
  }
}
```

`token`, `amount` and `currencyCode` are required. Amount is a string with up to
seven integer digits and either no decimal places or exactly two, separated by
`.` (for example `0`, `10`, `10.00`). No conversion or rounding is performed.
Currency must be three uppercase letters; Braintree validates supported
currencies and merchant eligibility. Optional `displayName` and
`merchantAccountId` must not be blank when provided.

Defaults are `PayPalCheckoutIntent.authorize` and
`PayPalCheckoutUserAction.none` (Continue). `sale`, `order` and `payNow` can be
selected explicitly. Align intent and currency with server processing and the
merchant account; even `sale`/`payNow` still requires your backend transaction.

This version uses the SDK web authentication session on iOS 14+ with Braintree
6.30.0, through CocoaPods or SPM. OTC does not require an Android return URL or
new universal-link setup. PayPal App Switch, shipping collection, Pay Later and
Checkout with Vault are not enabled. A billing agreement is never requested.
The app-switch setup above applies to other existing flows, not this OTC API.

| OTC error code | Meaning |
| --- | --- |
| `canceled` | Buyer canceled approval |
| `invalid_arguments` | Invalid request or authorization format |
| `unsupported_platform` | OTC is not implemented on this platform |
| `payment_in_progress` | Another PayPal flow is active |
| `error` | SDK/network failure or invalid native response |

The native handler completes each request once, retains its client until the
callback and serializes PayPal presentation. Vault and OTC cannot overlap.
Checkout success returns `PayPalAccountNonce`; cancellation throws instead of
returning null. The nullable signature is retained for API consistency, but a
null native Checkout response is an error. Optional account details, including
`payerId` and `billingAddress`, may be absent.

On the server, validate the order total and currency against your own cart,
select a matching merchant account, and create the transaction with the nonce.
Prevent duplicate processing per order. For pure OTC, do not request Vault
storage server-side. Never embed private gateway credentials in the app or mark
an order paid solely because tokenization succeeded. See
[Braintree server-side integration](https://developer.paypal.com/braintree/docs/guides/paypal/server-side/node).

### PayPal Vault Transaction

```dart
final result = await checkout.paypalVaultPayment(
  PayPalRequest(
    token: 'your-client-token-or-tokenization-key',
    amount: '10.00',
    currencyCode: 'USD',
    displayName: 'Your Store',
    androidAppLinkReturnUrl: 'https://your-company.com/payments',
    androidDeepLinkFallbackUrlScheme: 'your.app.payments',
  ),
);

if (result != null) {
  // Send result.nonce to your backend without logging it.
}
```

`paypalPayment(PayPalRequest)` remains supported with its existing Vault behavior.
`paypalVaultPayment` is an explicit alias; it keeps the legacy request (including
its required Android URL) and legacy error semantics. Existing platform subclasses
using `extends` inherit defaults for the new methods; implementations using
`implements` must add the new members.

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

### Card Vault Transaction

```dart
final result = await checkout.tokenizeCard(
  CardRequest(
    token: 'your-client-token-or-tokenization-key',
    cardholderName: 'cardholder-name',
    cardNumber: 'card-number',
    expirationMonth: 'expiration-month',
    exoprationYear: 'expiration-year',
    cvv: 'cvv',
  ),
);

if (result != null) {
  print('Card nonce: ${result.nonce}');
}
```

### 3D Secure Transaction

```dart
final result = await braintree.threeDSecurePayment(
  ThreeDSecureRequest(
    token: 'your-client-token-or-tokenization-key',
    amount: 'amount',
    nonce: 'card-nonce',
    email: 'optional-user-email',
  ),
);

if (result != null) {
  print('3D Secure nonce: ${result.nonce}');
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
* `PayPalCheckoutRequest`, `PayPalCheckoutIntent`, `PayPalCheckoutUserAction`
* `VenmoRequest`, `VenmoAccountNonce`
* `CardRequest`, `CardAccountNonce`
* `PostalAddress` (for PayPal shipping address)

## Contributing

Contributions are welcome! Feel free to open issues or pull requests on the [GitHub repository](https://github.com/your-org/braintree_checkout_flutter).
