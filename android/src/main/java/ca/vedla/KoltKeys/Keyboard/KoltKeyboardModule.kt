package ca.vedla.KoltKeys.Keyboard

import expo.modules.kotlin.modules.Module
import expo.modules.kotlin.modules.ModuleDefinition
import org.json.JSONObject

class KoltKeyboardModule : Module() {
  override fun definition() = ModuleDefinition {
    Name("KoltKeyboard")

    Function("setConfiguration") { json: String, _: String? ->
      JSONObject(json)
      preferences().edit().putString(KoltKeyboardStorage.PAYLOAD_KEY, json).apply()
    }

    Function("getConfiguration") { _: String? ->
      preferences().getString(KoltKeyboardStorage.PAYLOAD_KEY, null)
    }

    Function("clearConfiguration") { _: String? ->
      preferences().edit().remove(KoltKeyboardStorage.PAYLOAD_KEY).apply()
    }
  }

  private fun preferences() =
    KoltKeyboardStorage.preferences(requireNotNull(appContext.reactContext))
}
