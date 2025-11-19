class ThreeDSecureRequest {
  const ThreeDSecureRequest({
    required this.token,
    required this.amount,
    required this.nonce,
    required this.email,
  });

  final String token;
  final String amount;
  final String nonce;
  final String? email;

  Map<String, dynamic> toJson() => {
    'token': token,
    'amount': amount,
    'nonce': nonce,
    'email': email,
  };
}
