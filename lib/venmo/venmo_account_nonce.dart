import 'package:braintree_checkout_flutter/commons/postal_address.dart';

class VenmoAccountNonce {
  const VenmoAccountNonce({
    required this.nonce,
    required this.isDefault,
    this.username,
    this.billingAddress,
    this.email,
    this.externalId,
    this.firstName,
    this.lastName,
    this.phoneNumber,
  });

  factory VenmoAccountNonce.fromJson(Map<String, dynamic> json) => VenmoAccountNonce(
    nonce: json['nonce'],
    isDefault: json['isDefault'] ?? false,
    username: json['username'] as String?,
    billingAddress: json['billingAddress'] != null ? PostalAddress.fromJson(json['billingAddress']) : null,
    email: json['email'] as String?,
    externalId: json['externalId'] as String?,
    firstName: json['firstName'] as String?,
    lastName: json['lastName'] as String?,
    phoneNumber: json['phoneNumber'] as String?,
  );

  final String nonce;
  final bool isDefault;
  final String? username;
  final PostalAddress? billingAddress;
  final String? email;
  final String? externalId;
  final String? firstName;
  final String? lastName;
  final String? phoneNumber;

  Map<String, dynamic> toJson() => {
    'nonce': nonce,
    'isDefault': isDefault,
    'username': username,
    'billingAddress': billingAddress?.toJson(),
    'email': email,
    'externalId': externalId,
    'firstName': firstName,
    'lastName': lastName,
    'phoneNumber': phoneNumber,
  };

  @override
  String toString() =>
      'VenmoAccountNonce{nonce: $nonce, isDefault: $isDefault, username: $username, email: $email, externalId: $externalId, firstName: $firstName, lastName: $lastName, phoneNumber: $phoneNumber}';
}
