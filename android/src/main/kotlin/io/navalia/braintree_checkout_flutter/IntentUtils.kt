package io.navalia.braintree_checkout_flutter

import android.content.Intent
import android.util.Log
import com.braintreepayments.api.core.PostalAddress
import org.json.JSONObject

public object IntentUtils {
    fun putArguments(intent: Intent, arguments: Map<String, Any>?) {
        arguments?.forEach { (key, value) ->
            when (value) {
                is String -> intent.putExtra(key, value)
                is Int -> intent.putExtra(key, value)
                is Boolean -> intent.putExtra(key, value)
                is Double -> intent.putExtra(key, value)
                is Float -> intent.putExtra(key, value)
                is Long -> intent.putExtra(key, value)
            }
        }
    }
    fun postalAddressToJson(address: PostalAddress): JSONObject {
        return JSONObject().apply {
            put("recipientName", address.recipientName ?: JSONObject.NULL)
            put("phoneNumber", address.phoneNumber ?: JSONObject.NULL)
            put("streetAddress", address.streetAddress ?: JSONObject.NULL)
            put("extendedAddress", address.extendedAddress ?: JSONObject.NULL)
            put("locality", address.locality ?: JSONObject.NULL)
            put("region", address.region ?: JSONObject.NULL)
            put("postalCode", address.postalCode ?: JSONObject.NULL)
            put("sortingCode", address.sortingCode ?: JSONObject.NULL)
            put("countryCodeAlpha2", address.countryCodeAlpha2 ?: JSONObject.NULL)
        }
    }
}
