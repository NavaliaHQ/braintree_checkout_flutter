class CardRequest {
  const CardRequest({
    required this.token,
    this.cardholderName,
    required this.cardNumber,
    required this.expirationMonth,
    required this.exoprationYear,
    required this.cvv,
  });

  final String token;
  final String? cardholderName;
  final String cardNumber;
  final String expirationMonth;
  final String exoprationYear;
  final String cvv;

  Map<String, dynamic> toJson() => {
    'token': token,
    'cardholderName': cardholderName,
    'cardNumber': cardNumber,
    'expirationMonth': expirationMonth,
    'expirationYear': exoprationYear,
    'cvv': cvv,
  };
}
