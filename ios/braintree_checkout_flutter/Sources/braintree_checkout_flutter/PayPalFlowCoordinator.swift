import Foundation
import Flutter

/// Serializes PayPal presentation without changing the legacy Vault handler.
final class PayPalFlowCoordinator {
    private let checkoutHandler: PayPalCheckoutHandler
    private let vaultHandler: (Any?, @escaping FlutterResult) -> Void
    private var activeOperation: UUID?

    init(
        checkoutHandler: PayPalCheckoutHandler = PayPalCheckoutHandler(),
        vaultHandler: @escaping (Any?, @escaping FlutterResult) -> Void = PayPalHandler.handle
    ) {
        self.checkoutHandler = checkoutHandler
        self.vaultHandler = vaultHandler
    }

    func handleCheckout(arguments: Any?, result: @escaping FlutterResult) {
        runOnPayPalMainThread {
            self.start(result: result) { completion in
                self.checkoutHandler.handle(arguments: arguments, result: completion)
            }
        }
    }

    func handleVault(arguments: Any?, result: @escaping FlutterResult) {
        runOnPayPalMainThread {
            guard arguments is [String: Any] else {
                result(FlutterError(code: Constants.ERROR_KEY, message: "Invalid PayPal Vault arguments.", details: nil))
                return
            }
            self.start(result: result) { completion in
                self.vaultHandler(arguments, completion)
            }
        }
    }

    private func start(result: @escaping FlutterResult, action: (@escaping FlutterResult) -> Void) {
        guard activeOperation == nil else {
            result(FlutterError(code: "payment_in_progress", message: "A PayPal payment is already in progress.", details: nil))
            return
        }
        let operation = UUID()
        activeOperation = operation
        action { [weak self] response in
            runOnPayPalMainThread {
                guard let self, self.activeOperation == operation else { return }
                self.activeOperation = nil
                result(response)
            }
        }
    }
}
