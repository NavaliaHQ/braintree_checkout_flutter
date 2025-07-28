import Braintree

public struct BraintreeUtils {
    static func postalAddressToJson(_ address: BTPostalAddress) -> [String: Any] {
        return [
            "recipientName": address.recipientName ?? NSNull(),
            "streetAddress": address.streetAddress ?? NSNull(),
            "extendedAddress": address.extendedAddress ?? NSNull(),
            "locality": address.locality ?? NSNull(),
            "countryCodeAlpha2": address.countryCodeAlpha2 ?? NSNull(),
            "postalCode": address.postalCode ?? NSNull(),
            "region": address.region ?? NSNull(),
        ]
    }
}
