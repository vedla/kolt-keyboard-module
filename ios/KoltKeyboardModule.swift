import ExpoModulesCore

private enum KoltKeyboardStorage {
  static let payloadKey = "keyboard.payload.v1"
  static let appGroupInfoKey = "KoltKeyboardAppGroup"

  static func defaults(explicitAppGroup: String?) throws -> UserDefaults {
    let appGroup = explicitAppGroup
      ?? Bundle.main.object(forInfoDictionaryKey: appGroupInfoKey) as? String

    guard let appGroup, appGroup.hasPrefix("group.") else {
      throw GenericException(
        "KoltKeyboard needs an iOS App Group. Pass appGroupIdentifier or set KoltKeyboardAppGroup in Info.plist."
      )
    }
    guard let defaults = UserDefaults(suiteName: appGroup) else {
      throw GenericException("Unable to open the KoltKeyboard App Group: \(appGroup)")
    }
    return defaults
  }
}

public class KoltKeyboardModule: Module {
  public func definition() -> ModuleDefinition {
    Name("KoltKeyboard")

    Function("setConfiguration") { (json: String, appGroupIdentifier: String?) in
      guard let data = json.data(using: .utf8),
            (try? JSONSerialization.jsonObject(with: data)) is [String: Any] else {
        throw GenericException("KoltKeyboard configuration must be a valid JSON object.")
      }
      let defaults = try KoltKeyboardStorage.defaults(explicitAppGroup: appGroupIdentifier)
      defaults.set(data, forKey: KoltKeyboardStorage.payloadKey)
    }

    Function("getConfiguration") { (appGroupIdentifier: String?) -> String? in
      let defaults = try KoltKeyboardStorage.defaults(explicitAppGroup: appGroupIdentifier)
      guard let data = defaults.data(forKey: KoltKeyboardStorage.payloadKey) else { return nil }
      return String(data: data, encoding: .utf8)
    }

    Function("clearConfiguration") { (appGroupIdentifier: String?) in
      let defaults = try KoltKeyboardStorage.defaults(explicitAppGroup: appGroupIdentifier)
      defaults.removeObject(forKey: KoltKeyboardStorage.payloadKey)
    }
  }
}
