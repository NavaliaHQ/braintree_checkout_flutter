package io.navalia.braintree_checkout_flutter

import android.app.Activity
import android.app.Activity.RESULT_OK
import android.content.Context
import android.content.Intent
import com.braintreepayments.api.card.Card
import com.braintreepayments.api.card.CardClient
import com.braintreepayments.api.card.CardResult
import io.flutter.embedding.engine.plugins.FlutterPlugin
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import io.flutter.plugin.common.MethodChannel.MethodCallHandler
import io.flutter.plugin.common.MethodChannel.Result
import io.flutter.embedding.engine.plugins.activity.ActivityAware
import io.flutter.embedding.engine.plugins.activity.ActivityPluginBinding
import com.braintreepayments.api.datacollector.DataCollector
import com.braintreepayments.api.datacollector.DataCollectorRequest
import com.braintreepayments.api.core.BraintreeClient
import com.braintreepayments.api.core.DeviceInspector
import com.braintreepayments.api.paypal.PayPalResult
import org.json.JSONObject

class BraintreeCheckoutFlutterPlugin : FlutterPlugin, MethodCallHandler, ActivityAware {
    private lateinit var channel: MethodChannel
    private var activity: Activity? = null
    private var pendingResult: Result? = null
    private lateinit var context: Context

    override fun onAttachedToEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        context = binding.applicationContext
        channel = MethodChannel(binding.binaryMessenger, "braintree_checkout_flutter")
        channel.setMethodCallHandler(this)
    }

    override fun onMethodCall(call: MethodCall, result: Result) {
        when (call.method) {
            Constants.VENMO_PAYMENT_METHOD_KEY -> {
                val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
                startActivity(
                    VenmoActivity::class.java,
                    Constants.VENMO_REQUEST_CODE,
                    arguments, result,
                )
            }

            Constants.PAYPAL_PAYMENT_METHOD_KEY -> {
                val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
                startActivity(
                    PayPalActivity::class.java,
                    Constants.PAYPAL_REQUEST_CODE,
                    arguments, result,
                )
            }

            Constants.GET_DATA -> {
                val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
                collectDeviceData(arguments, result)
            }

            Constants.IS_VENMO_APP_INSTALLED -> {
                val isVenmoAppInstalled = DeviceInspector().isVenmoAppSwitchAvailable(context)
                result.success(isVenmoAppInstalled)
            }

            Constants.TOKENIZE_CARD_METHOD_KEY -> {
                val arguments = call.arguments as? Map<String, Any> ?: emptyMap()
                tokenizeCard(arguments, result)
            }

            else -> result.notImplemented()
        }
    }

    private fun startActivity(
        activityClass: Class<out Activity>,
        activityRequestCode: Int,
        arguments: Map<String, Any>, result: Result
    ) {
        if (activity == null) {
            result.error(Constants.ERROR_KEY, "Activity is not available", null)
            return
        } 
        if (arguments.isEmpty()) {
            result.error(Constants.ERROR_KEY, "Arguments is not available", null)
            return
        }
        val intent = Intent(activity, activityClass)
        IntentUtils.putArguments(intent, arguments)
        pendingResult = result
        activity!!.startActivityForResult(intent, activityRequestCode)
    }

    fun onActivityResult(requestCode: Int, resultCode: Int, intent: Intent?) {
        if (requestCode == Constants.VENMO_REQUEST_CODE
            || requestCode == Constants.PAYPAL_REQUEST_CODE
        ) {
            when {
                resultCode == Activity.RESULT_OK && intent != null -> {
                    val nonce = intent.getStringExtra(Constants.NONCE_KEY)
                    pendingResult?.success(nonce)
                }
                resultCode == Activity.RESULT_CANCELED && intent != null -> {
                    val error = intent.getStringExtra(Constants.ERROR_KEY)
                    if (error != null) {
                        pendingResult?.error(Constants.ERROR_KEY, error, null)
                        return
                    }
                    val canceled = intent.getStringExtra(Constants.CANCELED_KEY)
                    if (canceled != null) {
                        pendingResult?.success(null)
                        return
                    }
                }
                else -> {
                    pendingResult?.success(null)
                }
            }
            pendingResult = null
        }
    }

    override fun onDetachedFromEngine(binding: FlutterPlugin.FlutterPluginBinding) {
        channel.setMethodCallHandler(null)
    }

    override fun onAttachedToActivity(binding: ActivityPluginBinding) {
        activity = binding.activity
        binding.addActivityResultListener { requestCode, resultCode, data ->
            onActivityResult(requestCode, resultCode, data)
            true
        }
    }

    override fun onDetachedFromActivity() {
        activity = null
    }

    override fun onDetachedFromActivityForConfigChanges() {}

    override fun onReattachedToActivityForConfigChanges(binding: ActivityPluginBinding) {
        activity = binding.activity
    }

    private fun collectDeviceData(arguments: Map<String, Any>, result: Result) {
        if (activity == null) {
            result.error(Constants.ERROR_KEY, "Activity is not available", null)
            return
        }
        try {
            val token = arguments[Constants.TOKEN_KEY] as? String
            if (token == null) {
                result.error(Constants.ERROR_KEY, "Token is required for data collection", null)
                return
            }
            val braintreeClient = BraintreeClient(activity!!, token)
            val dataCollector = DataCollector(braintreeClient)
            val dataCollectorRequest = DataCollectorRequest(hasUserLocationConsent = true)
            dataCollector.collectDeviceData(activity!!, dataCollectorRequest) { dataCollectorResult ->
                when (dataCollectorResult) {
                    is com.braintreepayments.api.datacollector.DataCollectorResult.Success -> {
                        result.success(dataCollectorResult.deviceData)
                    }
                    is com.braintreepayments.api.datacollector.DataCollectorResult.Failure -> {
                        result.error(Constants.ERROR_KEY, "Device data collection failed", dataCollectorResult.error.localizedMessage)
                    }
                }
            }
        } catch (e: Exception) {
            result.error(Constants.ERROR_KEY, "Error during device data collection", e.localizedMessage)
        }
    }

    private fun tokenizeCard(arguments: Map<String, Any>, result: Result) {
        if (activity == null) {
            result.error(Constants.ERROR_KEY, "Activity is not available", null)
            return
        }
        try {
            val token = arguments[Constants.TOKEN_KEY] as? String
            val cardholderName = arguments[Constants.CARDHOLDER_NAME_KEY] as? String
            val cardNumber = arguments[Constants.CARD_NUMBER_KEY] as? String
            val expirationMonth = arguments[Constants.EXPIRATION_MONTH_KEY] as? String
            val expirationYear = arguments[Constants.EXPIRATION_YEAR_KEY] as? String
            val cvv = arguments[Constants.CVV_KEY] as? String
            if (token == null || cardNumber == null || expirationMonth == null || expirationYear == null || cvv == null) {
                result.error(Constants.ERROR_KEY, "Token, card number, expiration month, expiration year and cvv are required for tokenization", null)
                return
            }
            val card = Card(
                cardholderName = cardholderName,
                number = cardNumber,
                expirationMonth = expirationMonth,
                expirationYear = expirationYear,
                cvv = cvv
            )
            val cardClient = CardClient(
                activity!!, token
            )
            cardClient.tokenize(card) { cardResult ->
                when (cardResult) {
                    is CardResult.Success -> {
                        result.success(parseSuccessResult(cardResult))
                    }

                    is CardResult.Failure -> {
                        result.error(Constants.ERROR_KEY, "Tokenize card failed", cardResult.error.localizedMessage)
                    }
                }
            }
        } catch (e: Exception) {
            result.error(Constants.ERROR_KEY, "Error during device data collection", e.localizedMessage)
        }
    }

     private fun parseSuccessResult(result: CardResult.Success) : String {
        val nonce = result.nonce
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
        return nonceJson.toString()
    }
}
