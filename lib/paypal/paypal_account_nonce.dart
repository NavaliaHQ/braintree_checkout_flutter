import 'package:braintree_checkout_flutter/commons/postal_address.dart';

class PayPalAccountNonce {
  const PayPalAccountNonce({
    required this.nonce,
    required this.isDefault,
    this.billingAddress,
    this.clientMetadataId,
    this.firstName,
    this.lastName,
    this.phone,
    this.email,
    this.payerId,
    this.authenticateUrl,
  });

  factory PayPalAccountNonce.fromJson(Map<String, dynamic> json) => PayPalAccountNonce(
      nonce: json['nonce'] as String,
      isDefault: json['isDefault'] as bool,
      billingAddress: json['billingAddress'] != null ? PostalAddress.fromJson(json['billingAddress']) : null,
      clientMetadataId: json['clientMetadataId'] as String?,
      firstName: json['firstName'] as String?,
      lastName: json['lastName'] as String?,
      phone: json['phone'] as String?,
      email: json['email'] as String?,
      payerId: json['payerId'] as String,
      authenticateUrl: json['authenticateUrl'] as String?,
    );

  final String nonce;
  final bool isDefault;
  final String? clientMetadataId;
  final PostalAddress? billingAddress;
  final String? firstName;
  final String? lastName;
  final String? phone;
  final String? email;
  final String? payerId;
  final String? authenticateUrl;

  Map<String, dynamic> toJson() => {
      'nonce': nonce,
      'isDefault': isDefault,
      'clientMetadataId': clientMetadataId,
      'billingAddress': billingAddress?.toJson(),
      'firstName': firstName,
      'lastName': lastName,
      'phone': phone,
      'email': email,
      'payerId': payerId,
      'authenticateUrl': authenticateUrl,
    };

  @override
  String toString() => 'PayPalAccountNonce{nonce: $nonce, isDefault: $isDefault, clientMetadataId: $clientMetadataId, firstName: $firstName, lastName: $lastName, phone: $phone, email: $email, payerId: $payerId, authenticateUrl: $authenticateUrl}';
}
