import Foundation
import Observation

/// Settings flipped from the debug menu. Persisted so a toggle survives a relaunch.
@Observable
class DebugSettings {
  static let shared = DebugSettings()

  /// Opens an inaccessible Property's card anyway so its pages can be worked on. The
  /// focused card's overlay still draws, only the press goes through.
  var bypassInaccessible: Bool {
    didSet {
      UserDefaults.standard.set(bypassInaccessible, forKey: "debug_bypass_inaccessible")
    }
  }

  private init() {
    bypassInaccessible = UserDefaults.standard.bool(forKey: "debug_bypass_inaccessible")
  }
}
