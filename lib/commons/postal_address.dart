class PostalAddress {
  PostalAddress({
    this.recipientName,
    this.phoneNumber,
    this.streetAddress,
    this.extendedAddress,
    this.locality,
    this.region,
    this.postalCode,
    this.sortingCode,
    this.countryCodeAlpha2,
  });

  factory PostalAddress.fromJson(Map<String, dynamic> map) => PostalAddress(
      recipientName: map['recipientName'],
      phoneNumber: map['phoneNumber'],
      streetAddress: map['streetAddress'],
      extendedAddress: map['extendedAddress'],
      locality: map['locality'],
      region: map['region'],
      postalCode: map['postalCode'],
      sortingCode: map['sortingCode'],
      countryCodeAlpha2: map['countryCodeAlpha2'],
    );

  String? recipientName;
  String? phoneNumber;
  String? streetAddress;
  String? extendedAddress;
  String? locality;
  String? region;
  String? postalCode;
  String? sortingCode;
  String? countryCodeAlpha2;

  Map<String, dynamic> toJson() => {
      'recipientName': recipientName,
      'phoneNumber': phoneNumber,
      'streetAddress': streetAddress,
      'extendedAddress': extendedAddress,
      'locality': locality,
      'region': region,
      'postalCode': postalCode,
      'sortingCode': sortingCode,
      'countryCodeAlpha2': countryCodeAlpha2,
    };

  @override
  String toString() => 'PostalAddress(recipientName: $recipientName, phoneNumber: $phoneNumber, streetAddress: $streetAddress, extendedAddress: $extendedAddress, locality: $locality, region: $region, postalCode: $postalCode, sortingCode: $sortingCode, countryCodeAlpha2: $countryCodeAlpha2)';
}
