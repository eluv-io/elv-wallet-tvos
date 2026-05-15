import UIKit

extension String: LocalizedError {
  public var errorDescription: String? {
    return self
  }
}

extension String {
  /// Converts empty strings to nil. This makes chaining fallbacks more convenient.
  public func nilIfEmpty() -> String? {
    if isEmpty {
      return nil
    }
    return self
  }
}

extension String {
  public enum ExtendedEncoding {
    case hexadecimal
  }

  public func ensuringSuffix(_ suffix: String) -> String {
    hasSuffix(suffix) ? self : self + suffix
  }

  public func trim() -> String {
    return trimmingCharacters(in: .whitespacesAndNewlines)
  }

  public func base64() -> String {
    let stringData = data(using: .utf8)!
    return stringData.base64EncodedString()
  }

  public func data(using _: ExtendedEncoding) -> Data? {
    let hexStr = dropFirst(hasPrefix("0x") ? 2 : 0)

    guard hexStr.count % 2 == 0 else { return nil }

    var newData = Data(capacity: hexStr.count / 2)

    var indexIsEven = true
    for i in hexStr.indices {
      if indexIsEven {
        let byteRange = i...hexStr.index(after: i)
        guard let byte = UInt8(hexStr[byteRange], radix: 16) else { return nil }
        newData.append(byte)
      }
      indexIsEven.toggle()
    }
    return newData
  }

  public func replaceFirst(
    of pattern: String,
    with replacement: String
  ) -> String {
    if let range = range(of: pattern) {
      return replacingCharacters(in: range, with: replacement)
    } else {
      return self
    }
  }

  public func capitalizingFirstLetter() -> String {
    return prefix(1).capitalized + dropFirst()
  }

  public func html2Attributed(fontScale: Double = 2.5) -> AttributedString {
    guard let data = data(using: String.Encoding.utf8) else {
      return ""
    }

    if let attr = try? NSMutableAttributedString(
      data: data,
      options: [
        .documentType: NSAttributedString.DocumentType.html,
        .characterEncoding: NSUTF8StringEncoding,
      ], documentAttributes: nil)
    {
      let range = NSRange(location: 0, length: attr.length)
      attr.enumerateAttribute(.font, in: range, options: .longestEffectiveRangeNotRequired) {
        attrib, range, _ in
        if let htmlFont = attrib as? UIFont {
          let traits = htmlFont.fontDescriptor.symbolicTraits
          var descrip = htmlFont.fontDescriptor.withFamily("Helvetica Neue")

          if (traits.rawValue & UIFontDescriptor.SymbolicTraits.traitBold.rawValue) != 0 {
            descrip = descrip.withSymbolicTraits(.traitBold)!
          }

          if (traits.rawValue & UIFontDescriptor.SymbolicTraits.traitItalic.rawValue) != 0 {
            descrip = descrip.withSymbolicTraits(.traitItalic)!
          }

          attr.addAttribute(
            .font, value: UIFont(descriptor: descrip, size: htmlFont.pointSize * fontScale),
            range: range)
        }
      }

      return AttributedString(attr)
    }

    return ""
  }
}
