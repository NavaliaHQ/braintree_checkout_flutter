/// The intent approved by the buyer. The server still creates the transaction.
enum PayPalCheckoutIntent { authorize, sale, order }

/// The call to action displayed in the PayPal approval session.
enum PayPalCheckoutUserAction { none, payNow }

/// Options for an iOS PayPal one-time checkout, without a billing agreement.
class PayPalCheckoutRequest {
  const PayPalCheckoutRequest({
    required this.token,
    required this.amount,
    required this.currencyCode,
    this.displayName,
    this.merchantAccountId,
    this.intent = PayPalCheckoutIntent.authorize,
    this.userAction = PayPalCheckoutUserAction.none,
  });

  final String token;

  /// Decimal amount, with up to seven integer digits and zero or two decimals.
  final String amount;
  final String currencyCode;
  final String? displayName;
  final String? merchantAccountId;
  final PayPalCheckoutIntent intent;
  final PayPalCheckoutUserAction userAction;

  /// Checks syntax only; merchant and currency eligibility are checked remotely.
  /// Throws [ArgumentError] without including payment data in the message.
  void validate() {
    if (token.trim().isEmpty) {
      throw ArgumentError('token must not be blank');
    }
    if (!_matchesEntire(RegExp(r'[0-9]{1,7}(\.[0-9]{2})?'), amount)) {
      throw ArgumentError(
        'amount must contain up to seven digits and zero or two decimal places',
      );
    }
    if (!_matchesEntire(RegExp(r'[A-Z]{3}'), currencyCode)) {
      throw ArgumentError('currencyCode must contain three uppercase letters');
    }
    if (displayName != null && displayName!.trim().isEmpty) {
      throw ArgumentError('displayName must not be blank');
    }
    if (merchantAccountId != null && merchantAccountId!.trim().isEmpty) {
      throw ArgumentError('merchantAccountId must not be blank');
    }
  }

  static bool _matchesEntire(RegExp pattern, String value) {
    final match = pattern.matchAsPrefix(value);
    return match != null && match.end == value.length;
  }

  Map<String, dynamic> toJson() => {
    'token': token,
    'amount': amount,
    'currencyCode': currencyCode,
    if (displayName != null) 'displayName': displayName,
    if (merchantAccountId != null) 'merchantAccountId': merchantAccountId,
    'paymentIntent': switch (intent) {
      PayPalCheckoutIntent.authorize => 'authorize',
      PayPalCheckoutIntent.sale => 'sale',
      PayPalCheckoutIntent.order => 'order',
    },
    'userAction': switch (userAction) {
      PayPalCheckoutUserAction.none => 'none',
      PayPalCheckoutUserAction.payNow => 'payNow',
    },
  };
}
