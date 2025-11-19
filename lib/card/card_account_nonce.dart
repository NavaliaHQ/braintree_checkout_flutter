class CardAccountNonce {
  const CardAccountNonce({
    required this.nonce,
    required this.isDefault,
    required this.cardType,
    required this.lastTwo,
    required this.lastFour,
    required this.expirationMonth,
    required this.expirationYear,
    required this.cardholderName,
  });

  factory CardAccountNonce.fromJson(Map<String, dynamic> json) =>
      CardAccountNonce(
        nonce: json['nonce'] as String,
        isDefault: json['isDefault'] as bool,
        cardType: json['cardType'] as String,
        lastTwo: json['lastTwo'] as String,
        lastFour: json['lastFour'] as String,
        expirationMonth: json['expirationMonth'] as String,
        expirationYear: json['expirationYear'] as String,
        cardholderName: json['cardholderName'] as String,
      );

  final String nonce;
  final bool isDefault;
  final String cardType;
  final String lastTwo;
  final String lastFour;
  final String expirationMonth;
  final String expirationYear;
  final String cardholderName;

  Map<String, dynamic> toJson() => {
    'nonce': nonce,
    'isDefault': isDefault,
    'cardType': cardType,
    'lastTwo': lastTwo,
    'lastFour': lastFour,
    'expirationMonth': expirationMonth,
    'expirationYear': expirationYear,
    'cardholderName': cardholderName,
  };

  @override
  String toString() =>
      'CardAccountNonce{nonce: $nonce, isDefault: $isDefault, cardType: $cardType, lastTwo: $lastTwo, lastFour: $lastFour, expirationMonth: $expirationMonth, expirationYear: $expirationYear, cardholderName: $cardholderName}';
}
