import SwiftUI

public extension Color {
  public init(hex: UInt, alpha: Double = 1) {
    self.init(
      .sRGB,
      red: Double((hex >> 16) & 0xFF) / 255,
      green: Double((hex >> 08) & 0xFF) / 255,
      blue: Double((hex >> 00) & 0xFF) / 255,
      opacity: alpha
    )
  }

  /// Parses a "#RRGGBB" or "#RRGGBBAA" hex string, as sent by the server.
  init?(hexString: String?) {
    var hex = hexString?.trimmingCharacters(in: .whitespacesAndNewlines) ?? ""
    if hex.hasPrefix("#") { hex.removeFirst() }
    guard let value = UInt64(hex, radix: 16) else { return nil }
    switch hex.count {
    case 6:
      self.init(hex: UInt(value))
    case 8:
      self.init(hex: UInt(value >> 8), alpha: Double(value & 0xFF) / 255)
    default:
      return nil
    }
  }
}
