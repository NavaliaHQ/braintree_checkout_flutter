package io.navalia.braintree_checkout_flutter

import android.app.Activity.RESULT_CANCELED
import android.app.Activity.RESULT_OK
import android.content.Intent
import android.net.Uri
import android.os.Bundle
import android.util.Log
import androidx.activity.ComponentActivity
import com.braintreepayments.api.paypal.PayPalCheckoutRequest
import com.braintreepayments.api.paypal.PayPalClient
import com.braintreepayments.api.paypal.PayPalLauncher
import com.braintreepayments.api.paypal.PayPalLineItem
import com.braintreepayments.api.paypal.PayPalLineItemKind
import com.braintreepayments.api.paypal.PayPalPaymentAuthRequest
import com.braintreepayments.api.paypal.PayPalPaymentAuthResult
import com.braintreepayments.api.paypal.PayPalPendingRequest
import com.braintreepayments.api.paypal.PayPalResult
import com.braintreepayments.api.paypal.PayPalVaultRequest
import org.json.JSONObject

class PayPalActivity : ComponentActivity() {
    private lateinit var paypalClient: PayPalClient
    private lateinit var paypalLauncher: PayPalLauncher

    private var storedPendingRequest: PayPalPendingRequest.Started? = null

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        val intent = getIntent();
        
        val token: String = intent.getStringExtra(Constants.TOKEN_KEY) as String
        val displayName: String = intent.getStringExtra(Constants.DISPLAY_NAME_KEY) as String
        val amount: String = intent.getStringExtra(Constants.AMOUNT_KEY) as String
        val currencyCode: String = intent.getStringExtra(Constants.CURRENCY_CODE_KEY) as String

        val appLinkReturnUrl: String =
            intent.getStringExtra(Constants.ANDROID_APP_LINK_RETURN_URL) as String
        val deepLinkFallbackUrlScheme: String? =
            intent.getStringExtra(Constants.ANDROID_DEEP_LINK_FALLBACK_URL_SCHEME)
        val billingAgreementDescription: String? =
            intent.getStringExtra(Constants.BILLING_AGREEMENT_DESCRIPTION)

        paypalLauncher = PayPalLauncher()
        paypalClient = PayPalClient(
            context = this,
            authorization = token,
            appLinkReturnUrl = Uri.parse("$appLinkReturnUrl.paypal"),
            deepLinkFallbackUrlScheme = "$deepLinkFallbackUrlScheme.paypal",
        )

        val lineItem = PayPalLineItem(kind = PayPalLineItemKind.CREDIT , name="Item Name", unitAmount = amount,quantity = "1")

        val payPalRequest = PayPalVaultRequest(
            displayName = displayName,
            hasUserLocationConsent = true,
            billingAgreementDescription = billingAgreementDescription,
            lineItems = arrayListOf(lineItem)
        )

        startPayPalFlow(payPalRequest)

    }

    private fun startPayPalFlow(request: PayPalVaultRequest) {
        try {

            paypalClient.createPaymentAuthRequest(
                this, request
            ) { paymentAuthRequest ->
                when (paymentAuthRequest) {
                    is PayPalPaymentAuthRequest.Failure -> {
                        val error = paymentAuthRequest.error
                        handleErrorResult(error)
                    }

                    is PayPalPaymentAuthRequest.ReadyToLaunch -> {
                        launch(paymentAuthRequest)
                    }

                }
            }
        } catch (error: Exception) {
            handleErrorResult(error)
        }
    }

    private fun launch(paymentAuthResult: PayPalPaymentAuthRequest.ReadyToLaunch) {
        try {
            val pendingRequest: PayPalPendingRequest = paypalLauncher.launch(
                this, paymentAuthResult
            )
            when (pendingRequest) {
                is PayPalPendingRequest.Started -> {
                    storedPendingRequest = pendingRequest
                }

                is PayPalPendingRequest.Failure -> {
                    val error = pendingRequest.error
                    handleErrorResult(error)
                }
            }
        } catch (error: Exception) {
            handleErrorResult(error)
        }
    }

    override fun onNewIntent(intent: Intent) {
        super.onNewIntent(intent)
        handleReturnToApp(intent)
    }

    override fun onResume() {
        super.onResume()
        handleReturnToApp(intent)
    }

    private fun handleReturnToApp(intent: Intent) {
        super.onResume()
        val pendingRequest = storedPendingRequest

        pendingRequest?.let {
            val paymentAuthResult: PayPalPaymentAuthResult = paypalLauncher.handleReturnToApp(
                pendingRequest = it, intent = intent
            )
            when (paymentAuthResult) {
                is PayPalPaymentAuthResult.Success -> {
                    completePayPalFlow(paymentAuthResult)
                }

                is PayPalPaymentAuthResult.Failure -> {
                    val error = paymentAuthResult.error
                    handleErrorResult(error)
                }

                is PayPalPaymentAuthResult.NoResult -> {
                    handleCancelResult(paymentAuthResult.toString())
                }
            }
            storedPendingRequest = null
        }
    }

    private fun completePayPalFlow(paymentAuthResult: PayPalPaymentAuthResult.Success) {
        paypalClient.tokenize(paymentAuthResult) { result: PayPalResult ->
            this.handlePayPalResult(result)
        }
    }

    private fun handlePayPalResult(result: PayPalResult) {
        when (result) {
            is PayPalResult.Success -> {
                handleSuccessResult(result)
            }

            is PayPalResult.Failure -> {
                val error = result.error
                handleErrorResult(error)
            }

            is PayPalResult.Cancel -> {
                handleCancelResult(result.toString())
            }
        }
    }

    private fun handleSuccessResult(result: PayPalResult.Success) {
        val nonce = result.nonce
        val nonceJson = JSONObject().apply {
            put("nonce", nonce.string)
            put("isDefault", nonce.isDefault)
            put("clientMetadataId", nonce.clientMetadataId ?: JSONObject.NULL)
            put("firstName", nonce.firstName)
            put("lastName", nonce.lastName)
            put("phone", nonce.phone)
            put("email", nonce.email ?: JSONObject.NULL)
            put("payerId", nonce.payerId)
            put("authenticateUrl", nonce.authenticateUrl ?: JSONObject.NULL)
        }
        val resultIntent = Intent().apply {
            putExtra(Constants.NONCE_KEY, nonceJson.toString())
        }
        setResult(RESULT_OK, resultIntent)
        finish()
    }

    private fun handleErrorResult(error: Exception) {
        val resultIntent = Intent().apply {
            putExtra(Constants.ERROR_KEY, error.toString())
        }
        setResult(RESULT_CANCELED, resultIntent)
        finish()
    }

    private fun handleCancelResult(message: String) {
        val resultIntent = Intent().apply {
            putExtra(Constants.CANCELED_KEY, message.toString())
        }
        setResult(RESULT_CANCELED, resultIntent)
        finish()
    }
}
