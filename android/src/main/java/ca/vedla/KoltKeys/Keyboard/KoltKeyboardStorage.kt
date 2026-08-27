package ca.vedla.KoltKeys.Keyboard

import android.content.Context

internal object KoltKeyboardStorage {
  const val PAYLOAD_KEY = "keyboard.payload.v1"

  fun preferences(context: Context) =
    context.getSharedPreferences("kolt_keyboard", Context.MODE_PRIVATE)

  fun payload(context: Context): String? = preferences(context).getString(PAYLOAD_KEY, null)
}
