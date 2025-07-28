class PayPalRequest {
  const PayPalRequest({
    required this.token,
    required this.amount,
    required this.displayName, 
    required this.androidAppLinkReturnUrl, 
    this.currencyCode = 'USD',
    this.androidDeepLinkFallbackUrlScheme,
    this.billingAgreementDescription,
  });

  final String token;
  final String amount;
  final String currencyCode;
  final String displayName;
  final String androidAppLinkReturnUrl;
  final String? androidDeepLinkFallbackUrlScheme;
  final String? billingAgreementDescription;

  Map<String, dynamic> toJson() => {
      'token': token,
      'amount': amount,
      'currencyCode': currencyCode,
      'displayName': displayName,
      'androidAppLinkReturnUrl': androidAppLinkReturnUrl,
      'androidDeepLinkFallbackUrlScheme': androidDeepLinkFallbackUrlScheme,
      'billingAgreementDescription': billingAgreementDescription,
    };
}
