package io.navalia.braintree_checkout_flutter

import android.content.Intent
import android.os.Bundle
import androidx.activity.ComponentActivity
import com.braintreepayments.api.threedsecure.ThreeDSecureClient
import com.braintreepayments.api.threedsecure.ThreeDSecureLauncher
import com.braintreepayments.api.threedsecure.ThreeDSecureNonce
import com.braintreepayments.api.threedsecure.ThreeDSecurePaymentAuthRequest
import com.braintreepayments.api.threedsecure.ThreeDSecureRequest
import com.braintreepayments.api.threedsecure.ThreeDSecureResult
import org.json.JSONObject

class ThreeDSecureActivity : ComponentActivity() {
    private lateinit var threeDSecureClient: ThreeDSecureClient
    private lateinit var threeDSecureLauncher: ThreeDSecureLauncher

    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)

        val token = intent.getStringExtra(Constants.TOKEN_KEY)
        val amount = intent.getStringExtra(Constants.AMOUNT_KEY)
        val nonce = intent.getStringExtra(Constants.NONCE_KEY)
        val email = intent.getStringExtra(Constants.EMAIL_KEY)

        if (token.isNullOrBlank() || amount.isNullOrBlank() || nonce.isNullOrBlank()) {
            handleErrorResult(IllegalArgumentException("Missing required ThreeDSecure parameters"))
            return
        }

        threeDSecureLauncher = ThreeDSecureLauncher(this) { paymentAuthResult ->
            threeDSecureClient.tokenize(paymentAuthResult) { result ->
                handleThreeDSecureResult(result)
            }
        }
        threeDSecureClient = ThreeDSecureClient(
            context = this,
            authorization = token,
        )

        val threeDSecureRequest = ThreeDSecureRequest(
            amount = amount,
            nonce = nonce,
            email = email,
        )

        startThreeDSecureFlow(threeDSecureRequest)
    }

    private fun startThreeDSecureFlow(request: ThreeDSecureRequest) {
        try {
            threeDSecureClient.createPaymentAuthRequest(
                this, request
            ) { paymentAuthRequest ->
                when (paymentAuthRequest) {
                    is ThreeDSecurePaymentAuthRequest.Failure -> {
                        val error = paymentAuthRequest.error
                        handleErrorResult(error)
                    }

                    is ThreeDSecurePaymentAuthRequest.ReadyToLaunch -> {
                        threeDSecureLauncher.launch(paymentAuthRequest)
                    }

                    is ThreeDSecurePaymentAuthRequest.LaunchNotRequired -> {
                        handleSuccessResult(paymentAuthRequest.nonce)
                    }
                }
            }
        } catch (error: Exception) {
            handleErrorResult(error)
        }
    }

    private fun handleThreeDSecureResult(result: ThreeDSecureResult) {
        when (result) {
            is ThreeDSecureResult.Success -> {
                handleSuccessResult(result.nonce)
            }

            is ThreeDSecureResult.Failure -> {
                val error = result.error
                handleErrorResult(error)
            }

            is ThreeDSecureResult.Cancel -> {
                handleCancelResult(result.toString())
            }
        }
    }

    private fun handleSuccessResult(nonce: ThreeDSecureNonce) {
        val nonceJson = JSONObject().apply {
            put("nonce", nonce.string)
            put("isDefault", nonce.isDefault)
            put("cardType", nonce.cardType)
            put("lastTwo", nonce.lastTwo)
            put("lastFour", nonce.lastFour)
            put("expirationMonth", nonce.expirationMonth)
            put("expirationYear", nonce.expirationYear)
            put("cardholderName", nonce.cardholderName)
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
            putExtra(Constants.CANCELED_KEY, message)
        }
        setResult(RESULT_CANCELED, resultIntent)
        finish()
    }
}
