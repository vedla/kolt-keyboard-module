package ca.vedla.KoltKeys.Keyboard

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import org.json.JSONObject

class KoltKeyboardModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("KoltKeyboard")

    Function("setConfiguration") { json: String, _: String? ->
      JSONObject(json)
      preferences().edit().putString(PAYLOAD_KEY, json).apply()
    }

    Function("getConfiguration") { _: String? ->
      preferences().getString(PAYLOAD_KEY, null)
    }

    Function("clearConfiguration") { _: String? ->
      preferences().edit().remove(PAYLOAD_KEY).apply()
    }
  }

  private fun preferences() = requireNotNull(appContext.reactContext)
    .getSharedPreferences(PREFERENCES_NAME, android.content.Context.MODE_PRIVATE)

  private companion object {
    const val PREFERENCES_NAME = "kolt_keyboard"
    const val PAYLOAD_KEY = "keyboard.payload.v1"
  }
}
