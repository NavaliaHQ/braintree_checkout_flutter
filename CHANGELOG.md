## Unreleased

- Add iOS PayPal One-Time Checkout through `paypalCheckoutPayment` and the typed
  `PayPalCheckoutRequest`, intent and user-action enums.
- Add `paypalVaultPayment` as an explicit alias for the existing Vault API.
- Preserve legacy contracts and reject OTC on unsupported platforms without fallback.
- Handle OTC cancellation, input validation, nullable payer details and concurrent
  PayPal operations; add Dart and iOS regression tests.

## 2.0.0

Migrate to support UISceneDelegate protocol

## 1.1.0

Add support for 3D secure and cart tokenization

## 1.0.4

Update launch mode on Android Manifest for PayPal

## 1.0.3

Adjust onResume for PayPal and Venmo activities

## 1.0.2

Adjust launch mode to singleTask and add more guards

## 1.0.1

Fix error where arguments are not set in activity

## 1.0.0

Initial release with vault suport for PayPal and Venmo
