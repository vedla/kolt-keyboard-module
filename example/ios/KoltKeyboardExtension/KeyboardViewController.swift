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
}

private struct KoltKeyboardPage: Decodable {
  let title: String
  let layout: String
  let keys: [KoltKeyboardKey]
  let columns: Int?
  let emptyState: String?
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

final class KeyboardViewController: UIInputViewController {
  private let gradientLayer = CAGradientLayer()
  private let brandLabel = UILabel()
  private let statusLabel = UILabel()
  private let pageControl = UISegmentedControl(items: [])
  private let scrollView = UIScrollView()
  private let keyStack = UIStackView()
  private let bottomBar = UIStackView()
  private var pages: [KoltKeyboardPage] = []

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

  private func configureView() {
    let height = view.heightAnchor.constraint(equalToConstant: 300)
    height.priority = .defaultHigh
    height.isActive = true

    gradientLayer.colors = [
      UIColor(red: 0.06, green: 0.07, blue: 0.16, alpha: 1).cgColor,
      UIColor(red: 0.20, green: 0.10, blue: 0.34, alpha: 1).cgColor,
    ]
    gradientLayer.startPoint = CGPoint(x: 0, y: 0)
    gradientLayer.endPoint = CGPoint(x: 1, y: 1)
    view.layer.insertSublayer(gradientLayer, at: 0)

    brandLabel.font = .systemFont(ofSize: 17, weight: .black)
    brandLabel.textAlignment = .center
    brandLabel.textColor = .white
    brandLabel.backgroundColor = UIColor(red: 0.49, green: 0.38, blue: 0.95, alpha: 1)
    brandLabel.layer.cornerRadius = 9
    brandLabel.clipsToBounds = true
    brandLabel.translatesAutoresizingMaskIntoConstraints = false
    brandLabel.widthAnchor.constraint(equalToConstant: 34).isActive = true
    brandLabel.heightAnchor.constraint(equalToConstant: 34).isActive = true

    statusLabel.font = .systemFont(ofSize: 9, weight: .bold)
    statusLabel.textColor = UIColor.white.withAlphaComponent(0.55)
    statusLabel.setContentHuggingPriority(.required, for: .horizontal)

    pageControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.19)
    pageControl.backgroundColor = UIColor.black.withAlphaComponent(0.16)
    pageControl.setTitleTextAttributes([.foregroundColor: UIColor.white], for: .normal)
    pageControl.addTarget(self, action: #selector(pageChanged), for: .valueChanged)

    let header = UIStackView(arrangedSubviews: [brandLabel, pageControl, statusLabel])
    header.axis = .horizontal
    header.alignment = .center
    header.spacing = 8
    header.translatesAutoresizingMaskIntoConstraints = false

    scrollView.alwaysBounceVertical = true
    scrollView.translatesAutoresizingMaskIntoConstraints = false
    keyStack.axis = .vertical
    keyStack.spacing = 7
    keyStack.translatesAutoresizingMaskIntoConstraints = false
    scrollView.addSubview(keyStack)

    bottomBar.axis = .horizontal
    bottomBar.spacing = 7
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
    guard !page.keys.isEmpty else {
      showMessage(page.emptyState ?? "No keys configured.")
      return
    }
    if page.layout == "list" { buildList(page.keys) } else { buildGrid(page.keys, page.columns) }
  }

  private func buildGrid(_ keys: [KoltKeyboardKey], _ requestedColumns: Int?) {
    let columns = max(1, requestedColumns ?? (traitCollection.horizontalSizeClass == .regular ? 10 : 7))
    for start in stride(from: 0, to: keys.count, by: columns) {
      let row = UIStackView()
      row.axis = .horizontal
      row.spacing = 6
      row.distribution = .fillEqually
      for index in start..<min(start + columns, keys.count) { row.addArrangedSubview(insertKey(keys[index])) }
      for _ in row.arrangedSubviews.count..<columns { row.addArrangedSubview(UIView()) }
      row.heightAnchor.constraint(equalToConstant: 45).isActive = true
      keyStack.addArrangedSubview(row)
    }
  }

  private func buildList(_ keys: [KoltKeyboardKey]) {
    for key in keys {
      let button = insertKey(key)
      button.contentHorizontalAlignment = .leading
      button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
      button.heightAnchor.constraint(equalToConstant: 45).isActive = true
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
    button.restingColor = UIColor.white.withAlphaComponent(title == "space" ? 0.17 : 0.23)
    button.addTarget(self, action: action, for: .touchUpInside)
    return button
  }

  private func style(_ button: KoltKeyButton) {
    button.restingColor = UIColor.white.withAlphaComponent(0.13)
    button.backgroundColor = button.restingColor
    button.setTitleColor(.white, for: .normal)
    button.tintColor = .white
    button.layer.cornerRadius = 11
    button.layer.borderWidth = 0.5
    button.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
  }

  private func showMessage(_ text: String) {
    keyStack.arrangedSubviews.forEach { $0.removeFromSuperview() }
    let label = UILabel()
    label.text = text
    label.textAlignment = .center
    label.numberOfLines = 0
    label.textColor = UIColor.white.withAlphaComponent(0.7)
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
