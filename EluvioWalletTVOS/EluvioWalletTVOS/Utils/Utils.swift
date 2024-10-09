//
//  Utils.swift
//  Utils
//
//  Created by Wayne Tran on 2021-09-27.
//

import Foundation
import Base58Swift
import SwiftUI
import Alamofire
import AVKit
import SwiftyJSON

extension Encodable {
    /// Converting object to postable JSON
    func toJSONString(_ encoder: JSONEncoder = JSONEncoder()) -> String {
        do {
            let jsonData = try encoder.encode(self)
            let json = String(data: jsonData, encoding: String.Encoding.utf8)
            return json ?? ""
        }catch{
            return ""
        }

    }
}


func FormatAddress(address: String) -> String {
    if address.isEmpty {
        return address
    }
        
    var formatted = address.trim()
    if(!formatted.starts(with: "0x")){
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
    }catch{
        fatalError(error.localizedDescription)
    }
}

func HexToBytes(_ string: String) -> [UInt8]? {
    var str = string

    if(string.hasPrefix("0x")){
        str = String(string.dropFirst(2))
    }
    
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

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}

extension String {
    enum ExtendedEncoding {
        case hexadecimal
    }
    
    func trim() -> String {
        return self.trimmingCharacters(in: .whitespacesAndNewlines)
    }
    
    var fixedBase64Format: Self {
        let offset = count % 4
        guard offset != 0 else { return self.trim() }
        return padding(toLength: count + 4 - offset, withPad: "=", startingAt: 0).trim()
      }
    
    func base64() -> String {
        let stringData = self.data(using: .utf8)!
        return stringData.base64EncodedString()
    }
    
    func fromBase64() -> String? {
        guard let data = Data(base64Encoded: self) else {
            return nil
        }

        return String(data: data, encoding: .utf8)
    }
    
    func jsonToDictionary() -> [String: Any]? {
        if let data = self.data(using: .utf8) {
            do {
                return try JSONSerialization.jsonObject(with: data, options: []) as? [String: Any]
            } catch {
                print(error.localizedDescription)
            }
        }
        return nil
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
    
    func html2Attributed(fontScale: Double = 2.5) -> AttributedString {

        guard let data = data(using: String.Encoding.utf8) else {
            return ""
        }
 
        if let attr = try? NSMutableAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html, .characterEncoding: NSUTF8StringEncoding], documentAttributes: nil) {
            
            let range = NSRange(location: 0, length: attr.length)
            attr.enumerateAttribute(.font, in: range, options: .longestEffectiveRangeNotRequired) { attrib, range, _ in
                if let htmlFont = attrib as? UIFont {
                    let traits = htmlFont.fontDescriptor.symbolicTraits
                    var descrip = htmlFont.fontDescriptor.withFamily("Helvetica Neue")

                    if (traits.rawValue & UIFontDescriptor.SymbolicTraits.traitBold.rawValue) != 0 {
                        descrip = descrip.withSymbolicTraits(.traitBold)!
                    }

                    if (traits.rawValue & UIFontDescriptor.SymbolicTraits.traitItalic.rawValue) != 0 {
                        descrip = descrip.withSymbolicTraits(.traitItalic)!
                    }

                    attr.addAttribute(.font, value: UIFont(descriptor: descrip, size: htmlFont.pointSize * fontScale), range: range)
                }
            }
            
            return AttributedString(attr)
        }
         
        return ""
        
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
    
    //try searching params (for embed
    do {
        let regexp = try Regex("hq__[^&/]+")
        if let result = uri.firstMatch(of: regexp) {
            print(result.output)
            if let sub  = result.output[0].substring {
                return String(sub)
            }
        }
    }catch{
        print("Error in FindContentHash ", uri)
    }
    
    return nil
}

extension NSNotification {
    static let LoggedOut = Notification.Name.init("LoggedOut")
}

extension String: ParameterEncoding {

    public func encode(_ urlRequest: URLRequestConvertible, with parameters: Parameters?) throws -> URLRequest {
        var request = try urlRequest.asURLRequest()
        request.httpBody = data(using: .utf8, allowLossyConversion: false)
        return request
    }

}

/*
func GenerateQRCodeUIImage(from string: String) -> UIImage {
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
*/

func GenerateQRCode(from string: String) -> UIImage {
    let ciContext = CIContext()
    
    guard let data = string.data(using: .ascii, allowLossyConversion: false) else {
        return UIImage()
        
    }
    let filter = CIFilter.qrCodeGenerator()
    filter.message = data
    
    if let ciImage = filter.outputImage {
        if let cgImage = ciContext.createCGImage(
            ciImage,
            from: ciImage.extent) {
            
            return UIImage(cgImage: cgImage)
        }
    }
    
    return UIImage()
}

extension Request {
    public func debugLog() -> Self {
    #if DEBUG
    cURLDescription(calling: { (curl) in
        debugPrint("=======================================")
        print(curl)
        debugPrint("=======================================")
    })
    #endif
    return self
  }
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

extension URL {
    func valueOf(_ queryParameterName: String) -> String? {
        guard let url = URLComponents(string: self.absoluteString) else { return nil }
        return url.queryItems?.first(where: { $0.name == queryParameterName })?.value
    }
}


extension AVPlayer {
    func addProgressObserver(intervalSeconds: Double = 5, action:@escaping ((Double) -> Void)) -> Any {
        return self.addPeriodicTimeObserver(forInterval: CMTime.init(value: Int64(intervalSeconds *  1000), timescale: 1000), queue: .main, using: { time in
            if let duration = self.currentItem?.duration {
                let duration = CMTimeGetSeconds(duration), time = CMTimeGetSeconds(time)
                let progress = (time/duration)
                action(progress)
            }
        })
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

extension Color {
    init(hex: UInt, alpha: Double = 1) {
        self.init(
            .sRGB,
            red: Double((hex >> 16) & 0xff) / 255,
            green: Double((hex >> 08) & 0xff) / 255,
            blue: Double((hex >> 00) & 0xff) / 255,
            opacity: alpha
        )
    }
}

func imageForPDF(document : CGPDFDocument, pageNumber: Int, imageWidth: CGFloat = 0, imageHeight: CGFloat = 0) -> UIImage? {

    guard let page = document.page(at: pageNumber) else { return nil }

    var pageRect = page.getBoxRect(.mediaBox)
    
    var scale = 1.0
    
    if imageWidth > 0 {
        scale = imageWidth / pageRect.size.width
    }else if imageHeight > 0 {
        scale = imageHeight / pageRect.size.height
    }

    //Clamp the scale because a larger scale just shrinks the content int the frame
    /*if scale > 1 {
        scale = 1.0
    }*/
    
    pageRect.size = CGSize(width: pageRect.size.width * scale,
                           height: pageRect.size.height * scale)
    pageRect.origin = CGPoint.zero
    
    UIGraphicsBeginImageContext(pageRect.size)
    guard let context = UIGraphicsGetCurrentContext()  else { return nil }
    context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
    context.fill(pageRect)
    context.saveGState()
    
    // Rotate the PDF so that it’s the right way around
    context.translateBy(x: 0.0, y: pageRect.size.height)
    context.scaleBy(x: 1.0, y: -1.0)
    context.scaleBy(x: scale, y: scale)
   // context.concatenate(page.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
    
    context.drawPDFPage(page)
    context.restoreGState()
    
    let image = UIGraphicsGetImageFromCurrentImageContext()
    UIGraphicsEndImageContext()
    return image
}

extension Int64 {
    var msToSeconds: Double { Double(self) / 1000 }
}

extension TimeInterval {
    var hourMinuteSecond: String {
        String(format:"%d:%02d:%02d", hour, minute, second)
    }
    
    var hourMinuteSecondMS: String {
        String(format:"%d:%02d:%02d.%03d", hour, minute, second, millisecond)
    }
    var minuteSecondMS: String {
        String(format:"%d:%02d.%03d", minute, second, millisecond)
    }
    var hour: Int {
        Int((self/3600).truncatingRemainder(dividingBy: 3600))
    }
    var minute: Int {
        Int((self/60).truncatingRemainder(dividingBy: 60))
    }
    var second: Int {
        Int(truncatingRemainder(dividingBy: 60))
    }
    var millisecond: Int {
        Int((self*1000).truncatingRemainder(dividingBy: 1000))
    }
}
/*
 DecodeVersionHash: (versionHash) => {
   if(!(versionHash.startsWith("hq__") || versionHash.startsWith("tq__"))) {
     throw new Error(`Invalid version hash: "${versionHash}"`);
   }

   versionHash = versionHash.slice(4);

   // Decode base58 payload
   let bytes = Utils.FromB58(versionHash);

   // Remove 32 byte SHA256 digest
   const digestBytes = bytes.slice(0, 32);
   const digest = digestBytes.toString("hex");
   bytes = bytes.slice(32);

   // Determine size of varint content size
   let sizeLength = 0;
   while(bytes[sizeLength] >= 128) {
     sizeLength++;
   }
   sizeLength++;

   // Remove size
   const sizeBytes = bytes.slice(0, sizeLength);
   const size = VarInt.decode(sizeBytes);
   bytes = bytes.slice(sizeLength);

   // Remaining bytes is object ID
   const objectId = "iq__" + Utils.B58(bytes);

   // Part hash is B58 encoded version hash without the ID
   const partHash = "hqp_" + Utils.B58(Buffer.concat([digestBytes, sizeBytes]));

   return {
     digest,
     size,
     objectId,
     partHash
   };
 }
 */
func DecodeVersionHash(versionHash: String) -> (digest:String, size:String, objectId:String, partHash:String){
    //TODO:
    return ("","","", "")
}

extension Array {
    func dividedIntoGroups(of i: Int = 3) -> [[Element]] {
        var copy = self
        var res = [[Element]]()
        while copy.count > i {
            res.append( (0 ..< i).map { _ in copy.remove(at: 0) } )
        }
        res.append(copy)
        return res
    }
}


func MakePlayerItemFromMediaOptions(fabric: Fabric, optionsJson: JSON?, versionHash: String, offering: String = "default") throws -> AVPlayerItem {
    
    debugPrint("MakePlayerItemFromOptionsJson ", optionsJson)
    
    var hlsPlaylistUrl: String = ""
    
    guard let options = optionsJson else {
        throw RuntimeError("MakePlayerItemFromOptionsJson options is nil")
    }
    
    if options["hls-clear"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson, drm:"hls-clear", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-sample-aes"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson, drm:"hls-sample-aes", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-fairplay"].exists() {
        let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue
        
        if(licenseServer.isEmpty)
        {
            throw RuntimeError("Error getting licenseServer")
        }
        print("license_server \(licenseServer)")
        
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson,  drm:"hls-fairplay", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
        ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
        return AVPlayerItem(asset: urlAsset)
        
    }else{
        throw RuntimeError("No available playback options \(options)")
    }
}

// APIs below are used on
func MakePlayerItemFromVersionHash(fabric: Fabric, versionHash: String, params: [JSON]? = [], offering: String = "default") async throws -> AVPlayerItem {
    let options = try await fabric.getOptions(versionHash: versionHash, offering: offering)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options, versionHash: versionHash, offering: offering)
}

func MakePlayerItemFromLink(fabric: Fabric, link: JSON?, params: [JSON]? = [], offering: String = "default", hash: String = "") async throws -> AVPlayerItem {
    //debugPrint("MakePlayerItemFromLink ", link)
    let options = try await fabric.getOptionsFromLink(link: link, params: params, offering: offering, hash:hash)
    //debugPrint("options finished ", options)
    return try MakePlayerItemFromOptionsJson(fabric: fabric, optionsJson: options.optionsJson, versionHash: options.versionHash, offering: offering)
}

func MakePlayerItemFromOptionsJson(fabric: Fabric, optionsJson: JSON?, versionHash: String, offering: String = "default") throws -> AVPlayerItem {
    
    //debugPrint("MakePlayerItemFromOptionsJson ", optionsJson)
    
    var hlsPlaylistUrl: String = ""
    
    guard let options = optionsJson else {
        throw RuntimeError("MakePlayerItemFromOptionsJson options is nil")
    }
    
    if options["hls-clear"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-clear", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-aes128"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-aes128", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-fairplay"].exists() {
        let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue
        
        if(licenseServer.isEmpty)
        {
            throw RuntimeError("Error getting licenseServer")
        }
        print("license_server \(licenseServer)")
        
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-fairplay", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
        ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
        return AVPlayerItem(asset: urlAsset)
        
    }else if options["hls-sample-aes"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: versionHash, drm:"hls-sample-aes", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else{
        throw RuntimeError("No available playback options \(options)")
    }
}

func MakePlayerItemFromMediaOptionsJson(fabric: Fabric, optionsJson: JSON?, offering: String = "default") throws -> AVPlayerItem {
    
    debugPrint("MakePlayerItemFromOptionsJson ", optionsJson)
    
    var hlsPlaylistUrl: String = ""
    
    guard let options = optionsJson else {
        throw RuntimeError("MakePlayerItemFromOptionsJson options is nil")
    }
    
    if options["hls-clear"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson, drm:"hls-clear", offering: offering)
        //print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-aes128"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson, drm:"hls-aes128", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else if options["hls-fairplay"].exists() {
        let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue
        
        if(licenseServer.isEmpty)
        {
            throw RuntimeError("Error getting licenseServer")
        }
        print("license_server \(licenseServer)")
        
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson, drm:"hls-fairplay", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
        ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
        return AVPlayerItem(asset: urlAsset)
        
    }else if options["hls-sample-aes"].exists() {
        hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(optionsJson: optionsJson, drm:"hls-sample-aes", offering: offering)
        print("Playlist URL \(hlsPlaylistUrl)")
        let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
        
        return AVPlayerItem(asset: urlAsset)
    }else{
        throw RuntimeError("No available playback options \(options)")
    }
}
