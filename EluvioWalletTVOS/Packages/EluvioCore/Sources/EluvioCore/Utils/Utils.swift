//
//  Utils.swift
//  Utils
//
//  Created by Wayne Tran on 2021-09-27.
//

import Alamofire
import Base58Swift
import CryptoKit
import EluvioCore
import Foundation
import VarInt

let BundleVersion: String =
  Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? ""
let BundleBuild: String = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? ""

extension UnsignedInteger where Self: CVarArg {
  var hexa: String {
    .init(format: "%ll*0x", bitWidth / 4, self)
  }
}

extension SHA256Digest {
  var hexa: String {
    map(\.hexa).joined()
  }
}

extension URL {
  /// Returns a new URL with the given query parameter replaced (or added).
  func replacingQueryParam(_ name: String, _ value: String) -> URL? {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false) else {
      return nil
    }
    var queryItems = components.queryItems ?? []
    if let index = queryItems.firstIndex(where: { $0.name == name }) {
      queryItems[index] = URLQueryItem(name: name, value: value)
    } else {
      queryItems.append(URLQueryItem(name: name, value: value))
    }
    components.queryItems = queryItems
    return components.url
  }

  public var queryParameters: [String: String]? {
    guard
      let components = URLComponents(url: self, resolvingAgainstBaseURL: true),
      let queryItems = components.queryItems
    else { return nil }
    return queryItems.reduce(into: [String: String]()) { result, item in
      result[item.name] = item.value
    }
  }

  func replaceFabricUrlPlaceholder() -> URL? {
    guard var components = URLComponents(url: self, resolvingAgainstBaseURL: false),
      components.url?.absoluteString.contains(ImageLink.fabricUrlPlaceholder) == true
    else { return self }
    components.scheme = nil
    components.host = nil
    let base = FabricConfigStore.shared.fabricBaseUrl
    let rest = components.url!.absoluteString.trimmingPrefix("/")
    return URL(string: base + rest) ?? self
  }
}

func FormatAddress(address: String) -> String {
  if address.isEmpty {
    return address
  }

  var formatted = address.trim()
  if !formatted.starts(with: "0x") {
    formatted = "0x".appending(formatted)
  }

  return formatted.lowercased()
}

func loadJsonFile<T: Decodable>(_ filename: String) throws -> T {
  let data: Data

  guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
  else {
    throw "Couldn't find \(filename) in main bundle."
  }

  do {
    data = try Data(contentsOf: file)
  } catch {
    throw "Couldn't load \(filename) from main bundle:\n\(error)"
  }

  do {
    let decoder = JSONDecoder()
    return try decoder.decode(T.self, from: data)
  } catch {
    throw "Couldn't parse \(filename) as \(T.self):\n\(error)"
  }
}

func loadJsonFileFatal<T: Decodable>(_ filename: String) -> T {
  do {
    return try loadJsonFile(filename)
  } catch {
    fatalError(error.localizedDescription)
  }
}

func HexToBytes(_ string: String) -> [UInt8]? {
  var str = string

  if string.hasPrefix("0x") {
    str = String(string.dropFirst(2))
  }

  if str.isEmpty {
    print("Error: Length == 0")
    return nil
  }

  return str.hexaBytes
}

func Hash(_ string: String) -> String {
  SHA256.hash(data: string.data(using: .utf8)!).hexa
}

extension StringProtocol {
  var hexaBytes: [UInt8] {
    .init(hexa)
  }

  private var hexa: UnfoldSequence<UInt8, Index> {
    sequence(state: startIndex) { startIndex in
      guard startIndex < self.endIndex else { return nil }
      let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
      defer { startIndex = endIndex }
      return UInt8(self[startIndex..<endIndex], radix: 16)
    }
  }
}

func addressToId(prefix: String, address: String) throws -> String {
  guard let bytes = HexToBytes(address) else {
    throw FabricError.badInput("addressToId: could not get bytes from address \(address)")
  }

  let encoded = Base58.base58Encode(bytes)

  return "\(prefix)\(encoded)"
}

extension Data {
  struct HexEncodingOptions: OptionSet {
    let rawValue: Int
    static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
  }

  func hexEncodedString(options: HexEncodingOptions = []) -> String {
    let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
    return "0x\(map { String(format: format, $0) }.joined())"
  }

  var prettyPrintedJSONString: NSString? {  // NSString gives us a nice sanitized debugDescription
    guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
      let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
      let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue)
    else { return nil }

    return prettyPrintedString
  }
}

extension Date {
  var now: Int64 {
    Int64((timeIntervalSince1970 * 1000.0).rounded())
  }
}

func FindContentHash(uri: String) -> String? {
  guard let url = URL(string: uri) else {
    return nil
  }
  for component in url.pathComponents {
    if component.hasPrefix("hq__") {
      return component
    }
  }

  // try searching params (for embed
  do {
    let regexp = try Regex("hq__[^&/]+")
    if let result = uri.firstMatch(of: regexp) {
      print(result.output)
      if let sub = result.output[0].substring {
        return String(sub)
      }
    }
  } catch {
    print("Error in FindContentHash ", uri)
  }

  return nil
}

extension NSNotification {
  static let LoggedOut = Notification.Name("LoggedOut")
}

extension String: ParameterEncoding {
  public func encode(_ urlRequest: URLRequestConvertible, with _: Parameters?) throws -> URLRequest
  {
    var request = try urlRequest.asURLRequest()
    request.httpBody = data(using: .utf8, allowLossyConversion: false)
    return request
  }
}

extension Request {
  public func debugLog() -> Self {
    #if DEBUG
      cURLDescription(calling: { curl in
        debugPrint("=======================================")
        print(curl)
        debugPrint("=======================================")
      })
    #endif
    return self
  }

  public func debugLog(_ enabled: Bool) -> Self {
    if enabled {
      return debugLog()
    }
    return self
  }
}

extension RangeReplaceableCollection where Element: Equatable {
  func unique() -> [Element] where Element: Equatable {
    var newArray: [Element] = []
    for i in self {
      if !newArray.contains(i) {
        newArray.append(i)
      }
    }
    return newArray
  }
}

extension URL {
  func valueOf(_ queryParameterName: String) -> String? {
    guard let url = URLComponents(string: absoluteString) else { return nil }
    return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
  }
}

extension Double {
  func asTimeString(style: DateComponentsFormatter.UnitsStyle) -> String {
    let formatter = DateComponentsFormatter()
    formatter.allowedUnits = [.hour, .minute, .second, .nanosecond]
    formatter.unitsStyle = style
    return formatter.string(from: self) ?? ""
  }
}

extension Int64 {
  var msToSeconds: Double {
    Double(self) / 1000
  }
}

extension TimeInterval {
  var hourMinuteSecond: String {
    String(format: "%d:%02d:%02d", hour, minute, second)
  }

  var hour: Int {
    Int((self / 3600).truncatingRemainder(dividingBy: 3600))
  }

  var minute: Int {
    Int((self / 60).truncatingRemainder(dividingBy: 60))
  }

  var second: Int {
    Int(truncatingRemainder(dividingBy: 60))
  }
}

/// Logic copied from elv-client-js
func DecodeVersionHash(versionHash: String) -> (
  digest: String, size: UInt64, objectId: String, partHash: String
) {
  var digest = ""
  var size: UInt64 = 0
  var objectId = ""
  var partHash = ""

  if !versionHash.hasPrefix("hq__"), !versionHash.hasPrefix("tq__") {
    return ("", 0, "", "")
  }

  var hash = versionHash.replaceFirst(
    of: "hq__",
    with: "")

  debugPrint("HASH ", hash)

  if var bytes = Base58.base58Decode(hash) {
    let digestBytes = bytes[0...31]

    debugPrint("Digest Bytes ", digestBytes)

    digest = digestBytes.map { String(format: "%02hhx", $0) }.joined()
    debugPrint("Digest", digest)

    bytes = Array(bytes[32...])
    debugPrint("Bytes", bytes)

    // Determine size of varint content size
    var sizeLength = 0
    while bytes[sizeLength] >= 128 {
      sizeLength += 1
    }
    sizeLength += 1

    debugPrint("sizeLength", sizeLength)

    // Remove size
    let sizeBytes = bytes[0...sizeLength - 1]

    debugPrint("sizeBytes", sizeBytes)

    size = uVarInt(Array(sizeBytes)).value
    debugPrint("size", size)

    bytes = Array(bytes[sizeLength...])

    // Remaining bytes is object ID
    objectId = "iq__" + Base58.base58Encode(bytes)

    // Part hash is B58 encoded version hash without the ID
    partHash = "hqp_" + Base58.base58Encode(Array(digestBytes) + Array(sizeBytes))
  }

  // TODO:
  return (digest, size, objectId, partHash)
}

extension Array {
  func dividedIntoGroups(of i: Int = 3) -> [[Element]] {
    var copy = self
    var res = [[Element]]()
    while copy.count > i {
      res.append((0..<i).map { _ in copy.remove(at: 0) })
    }
    res.append(copy)
    return res
  }
}

func parseDateString(_ dateString: String) -> Date? {
  let dateFormatter = ISO8601DateFormatter()
  dateFormatter.formatOptions = [
    .withFractionalSeconds,
    .withFullDate,
    .withTime,  // without time zone
    .withColonSeparatorInTime,
    .withDashSeparatorInDate,
  ]
  var date = dateFormatter.date(from: dateString)

  if date == nil {
    dateFormatter.formatOptions = [
      .withFullDate,
      .withTime,
      .withColonSeparatorInTime,
      .withDashSeparatorInDate,
    ]
    date = dateFormatter.date(from: dateString)
  }
  return date
}
