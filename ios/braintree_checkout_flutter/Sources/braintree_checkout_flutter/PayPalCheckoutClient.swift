import Foundation
#if SWIFT_PACKAGE
import BraintreeCore
import BraintreePayPal
#else
import Braintree
#endif

struct PayPalCheckoutAccount {
    let nonce: String
    let isDefault: Bool
    let billingAddress: BTPostalAddress?
    let clientMetadataId: String?
    let firstName: String?
    let lastName: String?
    let phone: String?
    let email: String?
    let payerId: String?
}

protocol PayPalCheckoutTokenizing: AnyObject {
    func tokenize(
        _ request: BTPayPalCheckoutRequest,
        completion: @escaping (PayPalCheckoutAccount?, Error?) -> Void
    )
}

final class PayPalCheckoutClient: PayPalCheckoutTokenizing {
    private let client: BTPayPalClient

    init?(authorization: String) {
        guard let apiClient = BTAPIClient(authorization: authorization) else { return nil }
        client = BTPayPalClient(apiClient: apiClient)
    }

    func tokenize(
        _ request: BTPayPalCheckoutRequest,
        completion: @escaping (PayPalCheckoutAccount?, Error?) -> Void
    ) {
        client.tokenize(request) { account, error in
            let checkoutAccount = account.map {
                PayPalCheckoutAccount(
                    nonce: $0.nonce,
                    isDefault: $0.isDefault,
                    billingAddress: $0.billingAddress,
                    clientMetadataId: $0.clientMetadataID,
                    firstName: $0.firstName,
                    lastName: $0.lastName,
                    phone: $0.phone,
                    email: $0.email,
                    payerId: $0.payerID
                )
            }
            completion(checkoutAccount, error)
        }
    }
}
