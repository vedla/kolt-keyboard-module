//
//  KeyboardViewController.swift
//  Kolt Keyboard
//
//  Created by Taylor Fox on 2026-08-24.
//

import UIKit

private final class KoltKeyButton: UIButton {
    var restingColor = UIColor.white.withAlphaComponent(0.13) {
        didSet { if !isHighlighted { backgroundColor = restingColor } }
    }

    override var isHighlighted: Bool {
        didSet {
            UIView.animate(withDuration: 0.08) {
                self.transform = self.isHighlighted ? CGAffineTransform(scaleX: 0.96, y: 0.96) : .identity
                self.backgroundColor = self.isHighlighted ? self.restingColor.withAlphaComponent(0.28) : self.restingColor
            }
        }
    }
}

private enum KeyboardStorage {
    static let appGroup = "group.ca.vedla.kolt.keyboard"
    static let payloadKey = "keyboard.payload.v1"
}

private struct KeyboardPayload: Codable {
    let enabledSymbols: [String]
    let snippets: [KeyboardSnippet]
    let updatedAt: Date
}

private struct KeyboardSnippet: Codable {
    let id: UUID
    let title: String
    let text: String
}

final class KeyboardViewController: UIInputViewController {
    private let gradientLayer = CAGradientLayer()
    private let header = UIStackView()
    private let brandLabel = UILabel()
    private let privacyLabel = UILabel()
    private let segmentedControl = UISegmentedControl(items: ["Symbols", "Snippets"])
    private let scrollView = UIScrollView()
    private let contentStack = UIStackView()
    private let bottomBar = UIStackView()
    private lazy var globeButton: UIButton = {
        let button = makeSystemKey(title: "", action: #selector(showInputModes(_:event:)))
        button.setImage(UIImage(systemName: "globe"), for: .normal)
        button.accessibilityLabel = "Next keyboard"
        return button
    }()
    private var payload = KeyboardPayload(
        enabledSymbols: ["™", "®", "©", "", "°", "±", "•", "…", "—", "→"],
        snippets: [], updatedAt: .distantPast
    )

    override func viewDidLoad() {
        super.viewDidLoad()
        configureView()
        reloadSettings()
    }

    override func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        reloadSettings()
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
            UIColor(red: 0.20, green: 0.10, blue: 0.34, alpha: 1).cgColor
        ]
        gradientLayer.startPoint = CGPoint(x: 0, y: 0)
        gradientLayer.endPoint = CGPoint(x: 1, y: 1)
        view.layer.insertSublayer(gradientLayer, at: 0)

        brandLabel.text = "K"
        brandLabel.font = .systemFont(ofSize: 17, weight: .black)
        brandLabel.textAlignment = .center
        brandLabel.textColor = .white
        brandLabel.backgroundColor = UIColor(red: 0.49, green: 0.38, blue: 0.95, alpha: 1)
        brandLabel.layer.cornerRadius = 9
        brandLabel.clipsToBounds = true
        brandLabel.translatesAutoresizingMaskIntoConstraints = false
        NSLayoutConstraint.activate([
            brandLabel.widthAnchor.constraint(equalToConstant: 34),
            brandLabel.heightAnchor.constraint(equalToConstant: 34)
        ])

        privacyLabel.text = "ON-DEVICE"
        privacyLabel.font = .systemFont(ofSize: 9, weight: .bold)
        privacyLabel.textColor = UIColor.white.withAlphaComponent(0.55)
        privacyLabel.setContentHuggingPriority(.required, for: .horizontal)

        segmentedControl.selectedSegmentIndex = 0
        segmentedControl.selectedSegmentTintColor = UIColor.white.withAlphaComponent(0.19)
        segmentedControl.backgroundColor = UIColor.black.withAlphaComponent(0.16)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white.withAlphaComponent(0.68)], for: .normal)
        segmentedControl.setTitleTextAttributes([.foregroundColor: UIColor.white, .font: UIFont.systemFont(ofSize: 13, weight: .semibold)], for: .selected)
        segmentedControl.addTarget(self, action: #selector(pageChanged), for: .valueChanged)
        segmentedControl.translatesAutoresizingMaskIntoConstraints = false

        header.axis = .horizontal
        header.alignment = .center
        header.spacing = 8
        header.translatesAutoresizingMaskIntoConstraints = false
        header.addArrangedSubview(brandLabel)
        header.addArrangedSubview(segmentedControl)
        header.addArrangedSubview(privacyLabel)

        scrollView.translatesAutoresizingMaskIntoConstraints = false
        scrollView.alwaysBounceVertical = true
        contentStack.axis = .vertical
        contentStack.spacing = 7
        contentStack.translatesAutoresizingMaskIntoConstraints = false
        scrollView.addSubview(contentStack)

        bottomBar.axis = .horizontal
        bottomBar.spacing = 7
        bottomBar.distribution = .fill
        bottomBar.translatesAutoresizingMaskIntoConstraints = false
        bottomBar.addArrangedSubview(globeButton)
        let space = makeSystemKey(title: "space", action: #selector(insertSpace))
        bottomBar.addArrangedSubview(space)
        bottomBar.addArrangedSubview(makeSystemKey(title: "⌫", action: #selector(deleteBackward)))

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
            contentStack.topAnchor.constraint(equalTo: scrollView.contentLayoutGuide.topAnchor),
            contentStack.leadingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.leadingAnchor),
            contentStack.trailingAnchor.constraint(equalTo: scrollView.contentLayoutGuide.trailingAnchor),
            contentStack.bottomAnchor.constraint(equalTo: scrollView.contentLayoutGuide.bottomAnchor),
            contentStack.widthAnchor.constraint(equalTo: scrollView.frameLayoutGuide.widthAnchor),
            bottomBar.leadingAnchor.constraint(equalTo: view.leadingAnchor, constant: 7),
            bottomBar.trailingAnchor.constraint(equalTo: view.trailingAnchor, constant: -7),
            bottomBar.bottomAnchor.constraint(equalTo: view.safeAreaLayoutGuide.bottomAnchor, constant: -7),
            bottomBar.heightAnchor.constraint(equalToConstant: 43),
            space.widthAnchor.constraint(greaterThanOrEqualTo: view.widthAnchor, multiplier: 0.5)
        ])
    }

    private func reloadSettings() {
        if let data = UserDefaults(suiteName: KeyboardStorage.appGroup)?.data(forKey: KeyboardStorage.payloadKey),
           let saved = try? JSONDecoder().decode(KeyboardPayload.self, from: data) { payload = saved }
        rebuildKeys()
    }

    private func rebuildKeys() {
        contentStack.arrangedSubviews.forEach {
            contentStack.removeArrangedSubview($0)
            $0.removeFromSuperview()
        }
        segmentedControl.selectedSegmentIndex == 1 ? buildSnippetKeys() : buildSymbolKeys()
        updateColors()
    }

    private func buildSymbolKeys() {
        guard !payload.enabledSymbols.isEmpty else {
            contentStack.addArrangedSubview(makeMessage("Choose symbols in the Kolt Keyboard app."))
            return
        }
        let columns = traitCollection.horizontalSizeClass == .regular ? 10 : 7
        for start in stride(from: 0, to: payload.enabledSymbols.count, by: columns) {
            let row = UIStackView()
            row.axis = .horizontal
            row.spacing = 6
            row.distribution = .fillEqually
            for index in start..<min(start + columns, payload.enabledSymbols.count) {
                let value = payload.enabledSymbols[index]
                row.addArrangedSubview(makeInsertKey(title: value, value: value))
            }
            for _ in row.arrangedSubviews.count..<columns { row.addArrangedSubview(UIView()) }
            row.heightAnchor.constraint(equalToConstant: 45).isActive = true
            contentStack.addArrangedSubview(row)
        }
    }

    private func buildSnippetKeys() {
        guard !payload.snippets.isEmpty else {
            contentStack.addArrangedSubview(makeMessage("Add snippets in the Kolt Keyboard app."))
            return
        }
        for snippet in payload.snippets {
            let button = makeInsertKey(title: snippet.title.isEmpty ? snippet.text : snippet.title, value: snippet.text)
            button.contentHorizontalAlignment = .leading
            button.titleLabel?.lineBreakMode = .byTruncatingTail
            button.contentEdgeInsets = UIEdgeInsets(top: 0, left: 14, bottom: 0, right: 14)
            button.heightAnchor.constraint(equalToConstant: 45).isActive = true
            contentStack.addArrangedSubview(button)
        }
    }

    private func makeInsertKey(title: String, value: String) -> UIButton {
        let button = KoltKeyButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: 20, weight: .medium)
        button.accessibilityLabel = title
        button.accessibilityHint = "Inserts text"
        style(button)
        button.addAction(UIAction { [weak self] _ in self?.textDocumentProxy.insertText(value) }, for: .touchUpInside)
        return button
    }

    private func makeSystemKey(title: String, action: Selector) -> UIButton {
        let button = KoltKeyButton(type: .system)
        button.setTitle(title, for: .normal)
        button.titleLabel?.font = .systemFont(ofSize: title == "space" ? 13 : 19, weight: .semibold)
        style(button)
        button.restingColor = UIColor.white.withAlphaComponent(title == "space" ? 0.17 : 0.23)
        button.addTarget(self, action: action, for: .touchUpInside)
        return button
    }

    private func style(_ button: UIButton) {
        button.backgroundColor = UIColor.white.withAlphaComponent(0.13)
        button.setTitleColor(.white, for: .normal)
        button.tintColor = .white
        button.layer.cornerRadius = 11
        button.layer.borderWidth = 0.5
        button.layer.borderColor = UIColor.white.withAlphaComponent(0.16).cgColor
        button.layer.shadowColor = UIColor.black.cgColor
        button.layer.shadowOpacity = 0.24
        button.layer.shadowOffset = CGSize(width: 0, height: 2)
        button.layer.shadowRadius = 3
    }

    private func makeMessage(_ text: String) -> UILabel {
        let label = UILabel()
        label.text = text
        label.textAlignment = .center
        label.numberOfLines = 0
        label.font = .systemFont(ofSize: 14, weight: .medium)
        label.textColor = UIColor.white.withAlphaComponent(0.7)
        label.heightAnchor.constraint(greaterThanOrEqualToConstant: 100).isActive = true
        return label
    }

    private func updateColors() {
        view.backgroundColor = UIColor(red: 0.06, green: 0.07, blue: 0.16, alpha: 1)
    }

    @objc private func pageChanged() { rebuildKeys() }
    @objc private func insertSpace() { textDocumentProxy.insertText(" ") }
    @objc private func deleteBackward() { textDocumentProxy.deleteBackward() }
    @objc private func showInputModes(_ sender: UIButton, event: UIEvent) {
        handleInputModeList(from: sender, with: event)
    }
}
