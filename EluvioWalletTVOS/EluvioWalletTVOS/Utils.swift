//
//  Utils.swift
//  Utils
//
//  Created by Wayne Tran on 2021-09-27.
//

import Foundation
import Base58Swift
import SwiftUI

func loadJsonFile<T: Decodable>(_ filename: String) -> T {
    let data: Data

    guard let file = Bundle.main.url(forResource: filename, withExtension: nil)
        else {
            fatalError("Couldn't find \(filename) in main bundle.")
    }

    do {
        data = try Data(contentsOf: file)
    } catch {
        fatalError("Couldn't load \(filename) from main bundle:\n\(error)")
    }

    do {
        let decoder = JSONDecoder()
        return try decoder.decode(T.self, from: data)
    } catch {
        fatalError("Couldn't parse \(filename) as \(T.self):\n\(error)")
    }
}

func HexToBytes(_ string: String) -> [UInt8]? {
    var str = string
    print("HexToBytes 1 \(str)")
    
    if(string.hasPrefix("0x")){
        str = String(string.dropFirst(2))
    }
    
    print("HexToBytes 2 \(str)")

    if str.isEmpty{
        print("Error: Length == 0")
        return nil
    }
    
    return str.hexaBytes
}

extension StringProtocol {
    var hexaData: Data { .init(hexa) }
    var hexaBytes: [UInt8] { .init(hexa) }
    private var hexa: UnfoldSequence<UInt8, Index> {
        sequence(state: startIndex) { startIndex in
            guard startIndex < self.endIndex else { return nil }
            let endIndex = self.index(startIndex, offsetBy: 2, limitedBy: self.endIndex) ?? self.endIndex
            defer { startIndex = endIndex }
            return UInt8(self[startIndex..<endIndex], radix: 16)
        }
    }
}

extension String {
    enum ExtendedEncoding {
        case hexadecimal
    }

    func data(using encoding:ExtendedEncoding) -> Data? {
        let hexStr = self.dropFirst(self.hasPrefix("0x") ? 2 : 0)

        guard hexStr.count % 2 == 0 else { return nil }

        var newData = Data(capacity: hexStr.count/2)

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
    
    public func replaceFirst(of pattern:String,
                             with replacement:String) -> String {
      if let range = self.range(of: pattern){
        return self.replacingCharacters(in: range, with: replacement)
      }else{
        return self
      }
    }
    
    public func replaceAll(of pattern:String,
                           with replacement:String,
                           options: NSRegularExpression.Options = []) -> String{
      do{
        let regex = try NSRegularExpression(pattern: pattern, options: [])
        let range = NSRange(0..<self.utf16.count)
        return regex.stringByReplacingMatches(in: self, options: [],
                                              range: range, withTemplate: replacement)
      }catch{
        NSLog("replaceAll error: \(error)")
        return self
      }
    }
    
    func capitalizingFirstLetter() -> String {
        return prefix(1).capitalized + dropFirst()
    }

    mutating func capitalizeFirstLetter() {
        self = self.capitalizingFirstLetter()
    }
}

extension Data {
    struct HexEncodingOptions: OptionSet {
        let rawValue: Int
        static let upperCase = HexEncodingOptions(rawValue: 1 << 0)
    }

    func hexEncodedString(options: HexEncodingOptions = []) -> String {
        let format = options.contains(.upperCase) ? "%02hhX" : "%02hhx"
        return "0x\(self.map { String(format: format, $0) }.joined())"
    }
    
    var prettyPrintedJSONString: NSString? { /// NSString gives us a nice sanitized debugDescription
        guard let object = try? JSONSerialization.jsonObject(with: self, options: []),
              let data = try? JSONSerialization.data(withJSONObject: object, options: [.prettyPrinted]),
              let prettyPrintedString = NSString(data: data, encoding: String.Encoding.utf8.rawValue) else { return nil }

        return prettyPrintedString
    }
}


func addressToId(prefix: String, address: String) throws -> String {
    guard let bytes = HexToBytes(address) else {
        throw FabricError.badInput("addressToId: could not get bytes from address \(address)")
    }
    
    let encoded = Base58.base58Encode(bytes)
    
    return "\(prefix)\(encoded)"
}

extension Date {
    var now:Int64 {
        Int64((self.timeIntervalSince1970 * 1000.0).rounded())
    }
    
    init(milliseconds:Int64) {
        self = Date(timeIntervalSince1970: TimeInterval(milliseconds) / 1000)
    }
}

func FindContentHash(uri: String) -> String? {
    guard let url = URL(string:uri) else {
        return nil
    }
    for component in url.pathComponents {
        if (component.hasPrefix("hq__")){
            return component
        }
    }
    
    return nil
}

extension NSNotification {
    static let LoggedOut = Notification.Name.init("LoggedOut")
}

func GenerateQRCode(from string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)

    if let outputImage = filter.outputImage {
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }

    return UIImage(systemName: "xmark.circle") ?? UIImage()
}

extension RangeReplaceableCollection where Element: Equatable {
    @discardableResult
    mutating func appendIfNotContains(_ element: Element) -> (appended: Bool, memberAfterAppend: Element) {
        if let index = firstIndex(of: element) {
            return (false, self[index])
        } else {
            append(element)
            return (true, element)
        }
    }
    
    func unique() -> [Element] where Element: Equatable {
        var newArray: [Element] = []
        self.forEach { i in
            if !newArray.contains(i) {
                newArray.append(i)
                
            }
        }
        return newArray
    }
    
    func group<Discrimininator>(by discriminator: (Element)->(Discrimininator)) -> [Discrimininator: [Element]] where Discrimininator: Hashable {
        
        var result = [Discrimininator: [Element]]()
        for element in self {
            
            let key = discriminator(element)
            var array = result[key] ?? [Element]()
            array.append(element)
            result[key] = array
        }
        
        return result
    }
}
