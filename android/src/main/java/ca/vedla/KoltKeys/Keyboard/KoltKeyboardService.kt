package ca.vedla.KoltKeys.Keyboard

import android.content.res.Configuration
import android.graphics.Color
import android.graphics.Typeface
import android.graphics.drawable.GradientDrawable
import android.inputmethodservice.InputMethodService
import android.os.Build
import android.text.TextUtils
import android.view.Gravity
import android.view.View
import android.view.ViewGroup
import android.view.inputmethod.EditorInfo
import android.view.inputmethod.InputMethodManager
import android.widget.Button
import android.widget.HorizontalScrollView
import android.widget.LinearLayout
import android.widget.ScrollView
import android.widget.TextView
import org.json.JSONObject

private data class KeyboardKey(val id: String, val label: String, val text: String)
private data class KeyboardSection(
  val title: String,
  val keys: List<KeyboardKey>,
  val columns: Int,
)
private data class KeyboardPage(
  val title: String,
  val layout: String,
  val keys: List<KeyboardKey>,
  val columns: Int,
  val emptyState: String,
  val sections: List<KeyboardSection>,
)
private data class KeyboardPayload(
  val brand: String,
  val statusLabel: String,
  val pages: List<KeyboardPage>,
  val theme: String,
  val frequentlyUsed: Boolean,
  val frequentKeyLimit: Int,
)
private data class KeyboardColors(
  val background: Int,
  val surface: Int,
  val key: Int,
  val text: Int,
  val secondaryText: Int,
  val border: Int,
  val accent: Int,
  val accentSoft: Int,
)

class KoltKeyboardService : InputMethodService() {
  private var selectedPage = 0
  private val matchParent = ViewGroup.LayoutParams.MATCH_PARENT
  private val wrapContent = ViewGroup.LayoutParams.WRAP_CONTENT

  override fun onEvaluateFullscreenMode() = false

  override fun onCreateInputView(): View = createKeyboardView()

  override fun onStartInputView(attribute: EditorInfo?, restarting: Boolean) {
    super.onStartInputView(attribute, restarting)
    setInputView(createKeyboardView())
  }

  private fun createKeyboardView(): View {
    val payload = parsePayload(KoltKeyboardStorage.payload(this))
    val colors = colors(payload.theme)
    if (selectedPage !in payload.pages.indices) selectedPage = 0

    val root = LinearLayout(this).apply {
      orientation = LinearLayout.VERTICAL
      setPadding(dp(10), dp(8), dp(10), dp(8))
      setBackgroundColor(colors.background)
    }
    root.addView(createHeader(payload, colors))

    val tabs = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      setPadding(0, dp(4), 0, dp(5))
    }
    root.addView(HorizontalScrollView(this).apply {
      isHorizontalScrollBarEnabled = false
      addView(tabs)
    }, LinearLayout.LayoutParams(matchParent, dp(44)))

    val content = LinearLayout(this).apply { orientation = LinearLayout.VERTICAL }
    root.addView(ScrollView(this).apply {
      isFillViewport = true
      isVerticalScrollBarEnabled = false
      addView(content)
    }, LinearLayout.LayoutParams(matchParent, dp(190)))

    fun renderPage() {
      tabs.removeAllViews()
      content.removeAllViews()
      payload.pages.forEachIndexed { index, page ->
        tabs.addView(createTab(page.title, index == selectedPage, colors) {
          selectedPage = index
          renderPage()
        })
      }

      val page = payload.pages.getOrNull(selectedPage)
      val pageKeys = page?.let { it.keys + it.sections.flatMap(KeyboardSection::keys) }.orEmpty()
      val frequentKeys = if (payload.frequentlyUsed) mostUsed(pageKeys, payload.frequentKeyLimit) else emptyList()
      if (frequentKeys.isNotEmpty()) {
        content.addView(createSectionHeader("MOST USED", colors))
        addGrid(content, frequentKeys, frequentKeys.size.coerceAtMost(6), colors)
      }
      if (page == null || pageKeys.isEmpty()) {
        content.addView(createEmptyState(page?.emptyState ?: "Configure Kolt Keys in the app.", colors))
      } else if (page.sections.isNotEmpty()) {
        page.sections.forEach { section ->
          content.addView(createSectionHeader(section.title.uppercase(), colors))
          addGrid(content, section.keys, section.columns, colors)
        }
      } else if (page.layout == "list") {
        page.keys.forEach { content.addView(createListKey(it, colors)) }
      } else {
        addGrid(content, page.keys, page.columns, colors)
      }
    }

    renderPage()
    root.addView(createSystemRow(colors), LinearLayout.LayoutParams(matchParent, dp(54)))
    return root
  }

  private fun addGrid(content: LinearLayout, keys: List<KeyboardKey>, requestedColumns: Int, colors: KeyboardColors) {
    val columns = requestedColumns.coerceIn(1, 10)
    keys.chunked(columns).forEach { rowKeys ->
      val row = LinearLayout(this).apply {
        orientation = LinearLayout.HORIZONTAL
        gravity = Gravity.CENTER
      }
      rowKeys.forEach { row.addView(createGridKey(it, colors)) }
      repeat(columns - rowKeys.size) {
        row.addView(View(this), LinearLayout.LayoutParams(0, dp(48), 1f))
      }
      content.addView(row, LinearLayout.LayoutParams(matchParent, wrapContent))
    }
  }

  private fun createSectionHeader(title: String, colors: KeyboardColors) = TextView(this).apply {
    text = title
    setTextColor(colors.secondaryText)
    textSize = 10f
    typeface = Typeface.DEFAULT_BOLD
    letterSpacing = 0.1f
    gravity = Gravity.CENTER_VERTICAL
    setPadding(dp(5), dp(8), 0, 0)
    layoutParams = LinearLayout.LayoutParams(matchParent, dp(32))
  }

  private fun createHeader(payload: KeyboardPayload, colors: KeyboardColors): View {
    val row = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER_VERTICAL
      setPadding(dp(2), 0, dp(4), 0)
    }
    row.addView(TextView(this).apply {
      text = payload.brand.take(2)
      gravity = Gravity.CENTER
      setTextColor(Color.WHITE)
      textSize = 16f
      typeface = Typeface.DEFAULT_BOLD
      background = rounded(colors.accent, 11)
    }, LinearLayout.LayoutParams(dp(34), dp(34)))
    row.addView(TextView(this).apply {
      text = "Kolt Keys"
      setTextColor(colors.text)
      textSize = 15f
      typeface = Typeface.DEFAULT_BOLD
      setPadding(dp(9), 0, 0, 0)
    }, LinearLayout.LayoutParams(0, matchParent, 1f))
    row.addView(TextView(this).apply {
      text = payload.statusLabel
      setTextColor(colors.accent)
      textSize = 10f
      typeface = Typeface.DEFAULT_BOLD
      gravity = Gravity.CENTER
      letterSpacing = 0.08f
      setPadding(dp(10), 0, dp(10), 0)
      background = rounded(colors.accentSoft, 10)
    }, LinearLayout.LayoutParams(wrapContent, dp(28)))
    return row.apply { layoutParams = LinearLayout.LayoutParams(matchParent, dp(36)) }
  }

  private fun createTab(
    label: String,
    selected: Boolean,
    colors: KeyboardColors,
    onClick: () -> Unit,
  ) = TextView(this).apply {
    text = label
    gravity = Gravity.CENTER
    setPadding(dp(15), 0, dp(15), 0)
    setTextColor(if (selected) Color.WHITE else colors.secondaryText)
    textSize = 13f
    typeface = Typeface.DEFAULT_BOLD
    background = rounded(if (selected) colors.accent else Color.TRANSPARENT, 10)
    setOnClickListener { onClick() }
    layoutParams = LinearLayout.LayoutParams(wrapContent, dp(34)).apply { marginEnd = dp(6) }
  }

  private fun createGridKey(key: KeyboardKey, colors: KeyboardColors) =
    keyButton(key, colors, true).apply {
      textSize = if (key.label.length <= 2) 20f else 14f
      layoutParams = LinearLayout.LayoutParams(0, dp(48), 1f).apply {
        setMargins(dp(3), dp(3), dp(3), dp(3))
      }
    }

  private fun createListKey(key: KeyboardKey, colors: KeyboardColors) =
    keyButton(key, colors, false).apply {
      maxLines = 1
      ellipsize = TextUtils.TruncateAt.END
      layoutParams = LinearLayout.LayoutParams(matchParent, dp(48)).apply {
        setMargins(dp(3), dp(3), dp(3), dp(3))
      }
    }

  private fun keyButton(key: KeyboardKey, colors: KeyboardColors, centered: Boolean) =
    Button(this).apply {
      text = key.label
      contentDescription = key.label
      isAllCaps = false
      gravity = if (centered) Gravity.CENTER else Gravity.CENTER_VERTICAL or Gravity.START
      setPadding(dp(14), 0, dp(14), 0)
      setTextColor(colors.text)
      textSize = 15f
      stateListAnimator = null
      background = rounded(colors.key, 12, colors.border)
      setOnClickListener {
        currentInputConnection?.commitText(key.text, 1)
        recordUsage(key.id)
      }
    }

  private fun createEmptyState(message: String, colors: KeyboardColors) = TextView(this).apply {
    text = message
    gravity = Gravity.CENTER
    setTextColor(colors.secondaryText)
    textSize = 14f
    layoutParams = LinearLayout.LayoutParams(matchParent, dp(180))
  }

  private fun createSystemRow(colors: KeyboardColors): View {
    val row = LinearLayout(this).apply {
      orientation = LinearLayout.HORIZONTAL
      gravity = Gravity.CENTER
      setPadding(0, dp(5), 0, 0)
    }
    val switchKey = systemButton("🌐", "Switch keyboard", colors, 0.8f) { switchKeyboard() }
    switchKey.setOnLongClickListener {
      showKeyboardPicker()
      true
    }
    row.addView(switchKey)
    row.addView(systemButton("space", "Space", colors, 2.4f) {
      currentInputConnection?.commitText(" ", 1)
    })
    row.addView(systemButton("⌫", "Delete", colors, 0.8f) {
      currentInputConnection?.deleteSurroundingText(1, 0)
    })
    return row
  }

  private fun systemButton(
    label: String,
    description: String,
    colors: KeyboardColors,
    weight: Float,
    onClick: () -> Unit,
  ) = Button(this).apply {
    text = label
    contentDescription = description
    isAllCaps = false
    textSize = 14f
    setTextColor(colors.text)
    stateListAnimator = null
    background = rounded(colors.surface, 12, colors.border)
    setOnClickListener { onClick() }
    layoutParams = LinearLayout.LayoutParams(0, matchParent, weight).apply {
      setMargins(dp(3), 0, dp(3), 0)
    }
  }

  private fun switchKeyboard() {
    if (
      Build.VERSION.SDK_INT >= Build.VERSION_CODES.P &&
      shouldOfferSwitchingToNextInputMethod() &&
      switchToNextInputMethod(false)
    ) {
      return
    }
    showKeyboardPicker()
  }

  private fun showKeyboardPicker() {
    (getSystemService(INPUT_METHOD_SERVICE) as? InputMethodManager)?.showInputMethodPicker()
  }

  private fun mostUsed(keys: List<KeyboardKey>, limit: Int): List<KeyboardKey> {
    val counts = usageCounts()
    return keys
      .filter { counts.optInt(it.id, 0) > 0 }
      .sortedByDescending { counts.optInt(it.id, 0) }
      .take(limit.coerceIn(1, 10))
  }

  private fun recordUsage(id: String) {
    val counts = usageCounts()
    counts.put(id, counts.optInt(id, 0) + 1)
    KoltKeyboardStorage.preferences(this)
      .edit()
      .putString("keyboard.usage.v1", counts.toString())
      .apply()
  }

  private fun usageCounts(): JSONObject = try {
    JSONObject(KoltKeyboardStorage.preferences(this).getString("keyboard.usage.v1", "{}") ?: "{}")
  } catch (_: Exception) {
    JSONObject()
  }

  private fun parsePayload(json: String?): KeyboardPayload {
    if (json.isNullOrBlank()) return emptyPayload()
    return try {
      val root = JSONObject(json)
      val pagesJson = root.optJSONArray("pages")
      val pages = buildList {
        if (pagesJson != null) for (pageIndex in 0 until pagesJson.length()) {
          val pageJson = pagesJson.optJSONObject(pageIndex) ?: continue
          val keysJson = pageJson.optJSONArray("keys")
          val keys = buildList {
            if (keysJson != null) for (keyIndex in 0 until keysJson.length()) {
              val keyJson = keysJson.optJSONObject(keyIndex) ?: continue
              val text = keyJson.optString("text")
              if (text.isNotEmpty()) add(KeyboardKey(keyJson.optString("id", "key-$keyIndex"), keyJson.optString("label", text), text))
            }
          }
          val sectionsJson = pageJson.optJSONArray("sections")
          val sections = buildList {
            if (sectionsJson != null) for (sectionIndex in 0 until sectionsJson.length()) {
              val sectionJson = sectionsJson.optJSONObject(sectionIndex) ?: continue
              val sectionKeysJson = sectionJson.optJSONArray("keys")
              val sectionKeys = buildList {
                if (sectionKeysJson != null) for (keyIndex in 0 until sectionKeysJson.length()) {
                  val keyJson = sectionKeysJson.optJSONObject(keyIndex) ?: continue
                  val text = keyJson.optString("text")
                  if (text.isNotEmpty()) add(KeyboardKey(keyJson.optString("id", "section-$sectionIndex-$keyIndex"), keyJson.optString("label", text), text))
                }
              }
              add(
                KeyboardSection(
                  sectionJson.optString("title", "Keys"),
                  sectionKeys,
                  sectionJson.optInt("columns", 7),
                )
              )
            }
          }
          add(
            KeyboardPage(
              pageJson.optString("title", "Keys"),
              pageJson.optString("layout", "grid"),
              keys,
              pageJson.optInt("columns", 7),
              pageJson.optString("emptyState", "No keys configured."),
              sections,
            )
          )
        }
      }
      KeyboardPayload(
        root.optString("brand", "K"),
        root.optString("statusLabel", "ON-DEVICE"),
        pages.ifEmpty { emptyPayload().pages },
        root.optJSONObject("appearance")?.optString("theme", "lavender") ?: "lavender",
        root.optJSONObject("frequentlyUsed")?.optBoolean("enabled", true) ?: true,
        root.optJSONObject("frequentlyUsed")?.optInt("maxKeys", 6) ?: 6,
      )
    } catch (_: Exception) {
      emptyPayload()
    }
  }

  private fun emptyPayload() = KeyboardPayload(
    "K",
    "ON-DEVICE",
    listOf(KeyboardPage("Setup", "grid", emptyList(), 7, "Configure Kolt Keys in the app.", emptyList())),
    "lavender",
    true,
    6,
  )

  private fun colors(theme: String): KeyboardColors {
    if (theme == "midnight") return KeyboardColors(Color.rgb(24, 27, 49), Color.rgb(39, 43, 72), Color.rgb(48, 52, 82), Color.WHITE, Color.rgb(187, 190, 211), Color.rgb(68, 72, 104), Color.rgb(128, 111, 246), Color.rgb(53, 48, 91))
    if (theme == "graphite") return KeyboardColors(Color.rgb(38, 39, 42), Color.rgb(57, 58, 62), Color.rgb(67, 68, 73), Color.WHITE, Color.rgb(197, 198, 202), Color.rgb(87, 88, 94), Color.rgb(167, 169, 177), Color.rgb(72, 73, 79))
    if (theme == "ocean") return KeyboardColors(Color.rgb(18, 43, 52), Color.rgb(27, 62, 72), Color.rgb(34, 73, 84), Color.WHITE, Color.rgb(180, 211, 217), Color.rgb(54, 94, 104), Color.rgb(48, 183, 205), Color.rgb(29, 79, 91))
    val dark = resources.configuration.uiMode and Configuration.UI_MODE_NIGHT_MASK ==
      Configuration.UI_MODE_NIGHT_YES
    return if (dark) {
      KeyboardColors(
        Color.rgb(28, 26, 32), Color.rgb(47, 44, 53), Color.rgb(55, 52, 61),
        Color.rgb(246, 242, 250), Color.rgb(183, 176, 192), Color.rgb(74, 69, 81),
        Color.rgb(142, 118, 246), Color.rgb(57, 48, 84),
      )
    } else {
      KeyboardColors(
        Color.rgb(244, 241, 247), Color.WHITE, Color.WHITE,
        Color.rgb(34, 31, 39), Color.rgb(112, 106, 120), Color.rgb(221, 215, 228),
        Color.rgb(110, 76, 213), Color.rgb(235, 228, 252),
      )
    }
  }

  private fun rounded(fill: Int, radius: Int, stroke: Int? = null) = GradientDrawable().apply {
    shape = GradientDrawable.RECTANGLE
    cornerRadius = dp(radius).toFloat()
    setColor(fill)
    if (stroke != null) setStroke(dp(1), stroke)
  }

  private fun dp(value: Int) = (value * resources.displayMetrics.density).toInt()
}
