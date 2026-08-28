import UIKit

private enum KoltKeyboardStorage {
  static let payloadKey = "keyboard.payload.v1"
  static let appGroupInfoKey = "KoltKeyboardAppGroup"

  static var defaults: UserDefaults? {
    guard let appGroup = Bundle.main.object(forInfoDictionaryKey: appGroupInfoKey) as? String else {
      return nil
    }
    return UserDefaults(suiteName: appGroup)
  }
}

private struct KoltKeyboardPayload: Decodable {
  let pages: [KoltKeyboardPage]
  let brand: String?
  let statusLabel: String?
  let appearance: KoltKeyboardAppearance?
}

private struct KoltKeyboardAppearance: Decodable {
  let theme: String
}

private struct KoltKeyboardPage: Decodable {
  let title: String
  let layout: String
  let keys: [KoltKeyboardKey]
  let columns: Int?
  let emptyState: String?
  let sections: [KoltKeyboardSection]?
}

private struct KoltKeyboardSection: Decodable {
  let title: String
  let keys: [KoltKeyboardKey]
  let columns: Int?
}

private struct KoltKeyboardKey: Decodable {
  let label: String
  let text: String
  let accessibilityLabel: String?
}

private final class KoltKeyButton: UIButton {
  var restingColor = UIColor.white.withAlphaComponent(0.13) {
    didSet { if !isHighlighted { backgroundColor = restingColor } }
  }

  override var isHighlighted: Bool {
    didSet {
      UIView.animate(withDuration: 0.08) {
        self.transform = self.isHighlighted
          ? CGAffineTransform(scaleX: 0.96, y: 0.96)
          : .identity
        self.backgroundColor = self.isHighlighted
          ? self.restingColor.withAlphaComponent(0.28)
          : self.restingColor
      }
    }
  }
}

private struct KoltKeyboardPalette {
  let backgroundStart: UIColor
  let backgroundEnd: UIColor
  let surface: UIColor
  let key: UIColor
  let systemKey: UIColor
  let text: UIColor
  let secondaryText: UIColor
  let border: UIColor
  let accent: UIColor

  static func forTheme(_ theme: String, interfaceStyle: UIUserInterfaceStyle = .unspecified) -> KoltKeyboardPalette {
    switch theme {
    case "system":
      return forTheme(interfaceStyle == .dark ? "dark" : "light", interfaceStyle: interfaceStyle)
    case "dark", "midnight":
      return .init(
        backgroundStart: rgb(24, 24, 21), backgroundEnd: rgb(18, 18, 16),
        surface: rgb(38, 38, 34), key: rgb(49, 49, 44), systemKey: rgb(67, 67, 60),
        text: rgb(247, 246, 240), secondaryText: rgb(174, 173, 162), border: rgb(76, 76, 68),
        accent: rgb(226, 169, 95)
      )
    case "graphite":
      return .init(
        backgroundStart: rgb(38, 39, 42), backgroundEnd: rgb(46, 47, 51),
        surface: rgb(57, 58, 62), key: rgb(67, 68, 73), systemKey: rgb(87, 88, 94),
        text: .white, secondaryText: rgb(197, 198, 202), border: rgb(87, 88, 94),
        accent: rgb(167, 169, 177)
      )
    case "ocean":
      return .init(
        backgroundStart: rgb(18, 43, 48), backgroundEnd: rgb(13, 34, 38),
        surface: rgb(31, 63, 68), key: rgb(43, 79, 84), systemKey: rgb(61, 100, 105),
        text: .white, secondaryText: rgb(190, 215, 216), border: rgb(69, 111, 116),
        accent: rgb(95, 193, 202)
      )
    default:
      return .init(
        backgroundStart: rgb(226, 225, 218), backgroundEnd: rgb(213, 212, 204),
        surface: rgb(244, 243, 237), key: rgb(255, 255, 253), systemKey: rgb(187, 186, 177),
        text: rgb(28, 28, 25), secondaryText: rgb(95, 95, 88), border: rgb(198, 197, 188),
        accent: rgb(181, 106, 18)
      )
    }
  }

  private static func rgb(_ red: CGFloat, _ green: CGFloat, _ blue: CGFloat) -> UIColor {
    UIColor(red: red / 255, green: green / 255, blue: blue / 255, alpha: 1)
  }
}

final class KeyboardViewController: UIInputViewController {
  private let gradientLayer = CAGradientLayer()
  private let brandLabel = UILabel()
  private let statusLabel = UILabel()
  private let pageControl = UISegmentedControl(items: [])
  private let scrollView = UIScrollView()
  private let keyStack = UIStackView()
  private let bottomBar = UIStackView()
  private var pages: [KoltKeyboardPage] = []
  private var activeTheme = "system"
  private var palette = KoltKeyboardPalette.forTheme("system")

  private lazy var globeButton: UIButton = {
    let button = systemKey(title: "", action: #selector(showInputModes(_:event:)))
    button.setImage(UIImage(systemName: "globe"), for: .normal)
    button.accessibilityLabel = "Next keyboard"
    return button
  }()

  override func viewDidLoad() {
    super.viewDidLoad()
    configureView()
    reloadConfiguration()
  }

  override func viewWillAppear(_ animated: Bool) {
    super.viewWillAppear(animated)
    reloadConfiguration()
  }

  override func viewWillLayoutSubviews() {
    super.viewWillLayoutSubviews()
    globeButton.isHidden = !needsInputModeSwitchKey
    gradientLayer.frame = view.bounds
  }

  override func traitCollectionDidChange(_ previousTraitCollection: UITraitCollection?) {
    super.traitCollectionDidChange(previousTraitCollection)
    if activeTheme == "system", previousTraitCollection?.userInterfaceStyle != traitCollection.userInterfaceStyle {
      applyTheme(activeTheme)
      rebuildKeys()
    }
  }

  private func configureView() {
    let height = view.heightAnchor.constraint(equalToConstant: 300)
    height.priority = .defaultHigh
    height.isActive = true

    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    view.layer.insertSublayer(gradientLayer, at: 0)

    brandLabel.font = .systemFont(ofSize: 17, weight: .black)
    brandLabel.textAlignment = .center
    brandLabel.textColor = .white
    brandLabel.layer.cornerRadius = 10
    brandLabel.clipsToBounds = true
    brandLabel.translatesAutoresizingMaskIntoConstraints = false
    brandLabel.widthAnchor.constraint(equalToConstant: 34).isActive = true
    brandLabel.heightAnchor.constraint(equalToConstant: 34).isActive = true

    statusLabel.font = .systemFont(ofSize: 9, weight: .semibold)
    statusLabel.setContentHuggingPriority(.required, for: .horizontal)

    pageControl.addTarget(self, action: #selector(pageChanged), for: .valueChanged)

    let header = UIStackView(arrangedSubviews: [brandLabel, pageControl, statusLabel])
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8
    header.translatesAutoresizingMaskIntoConstraints = false

    scrollView.alwaysBounceVertical = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    keyStack.axis = .vertical
    keyStack.spacing = 6
    keyStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(keyStack)

    bottomBar.axis = .horizontal
    bottomBar.spacing = 6
    bottomBar.translatesAutoresizingMaskIntoConstraints = false
    bottomBar.addArrangedSubview(globeButton)
    let space = systemKey(title: "space", action: #selector(insertSpace))
    bottomBar.addArrangedSubview(space)
    bottomBar.addArrangedSubview(systemKey(title: "⌫", action: #selector(deleteBackward)))

    view.addSubview(header)
    view.addSubview(scrollView)
    view.addSubview(bottomBar)
    NSLayoutConstraint.activate([
      header.topAnchor.constraint(equalTo: view.topAnchor, constant: 8),
      header.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 8),
      header.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -10),
      header.heightAnchor.constraint(equalToConstant: 34),
      scrollView.topAnchor.constraint(equalTo: header.bottomAnchor, constant: 8),
      scrollView.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 7),
      scrollView.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -7),
      scrollView.bottomAnchor.constraint(equalTo: bottomBar.topAnchor, constant: -7),
      keyStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
      keyStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
      keyStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
      keyStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
      keyStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
      bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 7),
      bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -7),
      bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -7),
      bottomBar.heightAnchor.constraint(equalToConstant: 43),
      space.widthAnchor.constraint(greaterThanOrEqualTo: view.widthAnchor, multiplier: 0.5),
    ])
    applyTheme("system")
  }

  private func reloadConfiguration() {
    guard
      let data = KoltKeyboardStorage.defaults?.data(forKey: KoltKeyboardStorage.payloadKey),
      let payload = try? JSONDecoder().decode(KoltKeyboardPayload.self, from: data)
    else {
      showMessage("Configure Kolt Keyboard in the app.")
      return
    }

    pages = payload.pages
    applyTheme(payload.appearance?.theme ?? "system")
    brandLabel.text = payload.brand ?? "K"
    statusLabel.text = payload.statusLabel ?? ""
    let selectedPage = max(pageControl.selectedSegmentIndex, 0)
    pageControl.removeAllSegments()
    for (index, page) in pages.enumerated() {
      pageControl.insertSegment(withTitle: page.title, at: index, animated: false)
    }
    if !pages.isEmpty { pageControl.selectedSegmentIndex = min(selectedPage, pages.count - 1) }
    rebuildKeys()
  }

  private func rebuildKeys() {
    keyStack.arrangedSubviews.forEach {
      keyStack.removeArrangedSubview($0)
      $0.removeFromSuperview()
    }
    guard pages.indices.contains(pageControl.selectedSegmentIndex) else {
      showMessage("Configure Kolt Keyboard in the app.")
      return
    }

    let page = pages[pageControl.selectedSegmentIndex]
    let sections = page.sections?.filter { !$0.keys.isEmpty } ?? []
    guard !page.keys.isEmpty || !sections.isEmpty else {
      showMessage(page.emptyState ?? "No keys configured.")
      return
    }
    if !sections.isEmpty {
      buildSections(sections)
    } else if page.layout == "list" {
      buildList(page.keys)
    } else {
      buildGrid(page.keys, page.columns)
    }
  }

  private func buildSections(_ sections: [KoltKeyboardSection]) {
    for section in sections {
      let header = UILabel()
      header.text = section.title.uppercased()
      header.font = .systemFont(ofSize: 10, weight: .bold)
      header.textColor = palette.secondaryText
      header.accessibilityTraits = .header
      header.heightAnchor.constraint(equalToConstant: 18).isActive = true
      keyStack.addArrangedSubview(header)
      buildGrid(section.keys, section.columns)
    }
  }

  private func buildGrid(_ keys: [KoltKeyboardKey], _ requestedColumns: Int?) {
    let columns = max(1, requestedColumns ?? (traitCollection.horizontalSizeClass == .regular ? 10 : 7))
    for start in stride(from: 0, to: keys.count, by: columns) {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 5
      row.distribution = .fillEqually
      for index in start..<min(start + columns, keys.count) { row.addArrangedSubview(insertKey(keys[index])) }
      for _ in row.arrangedSubviews.count..<columns { row.addArrangedSubview(UIView()) }
      row.heightAnchor.constraint(equalToConstant: 44).isActive = true
      keyStack.addArrangedSubview(row)
    }
  }

  private func buildList(_ keys: [KoltKeyboardKey]) {
    for key in keys {
      let button = insertKey(key)
      button.contentHorizontalAlignment = .leading
      button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
      button.heightAnchor.constraint(equalToConstant: 44).isActive = true
      keyStack.addArrangedSubview(button)
    }
  }

  private func insertKey(_ key: KoltKeyboardKey) -> UIButton {
    let button = KoltKeyButton(type: .system)
    button.setTitle(key.label, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
    button.accessibilityLabel = key.accessibilityLabel ?? key.label
    button.accessibilityHint = "Inserts text"
    style(button)
    button.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText(key.text) }, for: .touchUpInside)
    return button
  }

  private func systemKey(title: String, action: Selector) -> KoltKeyButton {
    let button = KoltKeyButton(type: .system)
    button.setTitle(title, for: .normal)
    button.titleLabel?.font = .systemFont(ofSize: title == "space" ? 13 : 19, weight: .semibold)
    style(button)
    button.restingColor = palette.systemKey
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  private func style(_ button: KoltKeyButton) {
    button.restingColor = palette.key
    button.backgroundColor = button.restingColor
    button.setTitleColor(palette.text, for: .normal)
    button.tintColor = palette.text
    button.layer.cornerRadius = 7
    button.layer.borderWidth = 0.5
    button.layer.borderColor = palette.border.cgColor
    button.layer.shadowColor = UIColor.black.cgColor
    button.layer.shadowOpacity = traitCollection.userInterfaceStyle == .dark ? 0.18 : 0.22
    button.layer.shadowOffset = CGSize(width: 0, height: 1)
    button.layer.shadowRadius = 0.5
  }

  private func applyTheme(_ theme: String) {
    activeTheme = theme
    palette = KoltKeyboardPalette.forTheme(theme, interfaceStyle: traitCollection.userInterfaceStyle)
    gradientLayer.colors = [palette.backgroundStart.cgColor, palette.backgroundEnd.cgColor]
    brandLabel.backgroundColor = palette.accent
    statusLabel.textColor = palette.secondaryText
    pageControl.backgroundColor = palette.surface
    pageControl.selectedSegmentTintColor = palette.key
    pageControl.setTitleTextAttributes([.foregroundColor: palette.secondaryText], for: .normal)
    pageControl.setTitleTextAttributes([.foregroundColor: palette.text], for: .selected)
    for case let button as KoltKeyButton in bottomBar.arrangedSubviews {
      style(button)
      button.restingColor = palette.systemKey
    }
  }

  private func showMessage(_ text: String) {
    keyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    let label = UILabel()
    label.text = text
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = palette.secondaryText
    label.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
    keyStack.addArrangedSubview(label)
  }

  @objc private func pageChanged() { rebuildKeys() }
  @objc private func insertSpace() { textDocumentProxy.insertText(" ") }
  @objc private func deleteBackward() { textDocumentProxy.deleteBackward() }
  @objc private func showInputModes(_ sender: UIButton, event: UIEvent) {
    handleInputModeList(from: sender, with: event)
  }
}
