class PayPalAccountNonceFactory {
  static Map<String, dynamic> json({bool withDetails = false}) => {
    'nonce': 'test-nonce',
    'isDefault': false,
    if (withDetails) ...{
      'payerId': 'payer-id',
      'email': 'buyer@example.com',
      'firstName': 'Test',
      'lastName': 'Buyer',
      'phone': '123',
      'clientMetadataId': 'metadata',
      'billingAddress': {'streetAddress': 'Test street'},
    },
  };
}
