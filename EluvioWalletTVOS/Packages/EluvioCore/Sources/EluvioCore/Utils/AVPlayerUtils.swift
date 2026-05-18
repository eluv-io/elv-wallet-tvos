import AVFoundation
import SwiftyJSON

public extension AVPlayer {
  public func addProgressObserver(intervalSeconds: Double = 5, action: @escaping ((Double) -> Void)) -> Any
  {
    return addPeriodicTimeObserver(
      forInterval: CMTime(value: Int64(intervalSeconds * 1000), timescale: 1000), queue: .main,
      using: { time in
        guard self.currentItem?.status == .readyToPlay else { return }
        if let duration = self.currentItem?.duration {
          let duration = CMTimeGetSeconds(duration)
          let time = CMTimeGetSeconds(time)
          let progress = (time / duration)
          action(progress)
        }
      })
  }

  /// Recreates the current player item with a fresh token in the HTTP header,
  /// preserving playback position and metadata.
  public func refreshCurrentItemAuth() async {
    guard let currentItem = self.currentItem else { return }
    guard let asset = currentItem.asset as? AVURLAsset else { return }

    let currentTime = currentItem.currentTime()
    let wasPlaying = (self.rate != 0)
    let oldExternalMetadata = currentItem.externalMetadata

    let newAsset = AuthenticatedURLAsset(url: asset.url, token: AccountStore.shared.bestToken)
    let newItem = AVPlayerItem(asset: newAsset)
    newItem.externalMetadata = oldExternalMetadata

    await MainActor.run {
      self.replaceCurrentItem(with: newItem)
      self.seek(to: currentTime)
      if wasPlaying {
        self.play()
      }
      debugPrint("[Auth] Refreshed player item with new token")
    }
  }
}

public func MakePlayerItemFromVersionHash(
  fabric: Fabric,
  versionHash: String,
) async throws -> AVPlayerItem {
  debugPrint("MakePlayerItemFromVersionHash ", versionHash)
  let options = try await fabric.getOptionsFromHash(versionHash: versionHash)
  debugPrint("getOptionsFromHash ", options)
  return try await MakePlayerItemFromOptionsJson(
    fabric: fabric, optionsJson: options, versionHash: versionHash)
}

public func MakePlayerItemFromLink(
  fabric: Fabric,
  link: JSON?,
  params: [JSON]? = [],
  offering: String = "default",
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async throws -> AVPlayerItem {
  debugPrint("MakePlayerItemFromLink ", link)
  let options = try await fabric.getOptionsFromLink(link: link, params: params, offering: offering)
  debugPrint("getOptionsFromLink ", options)
  return try await MakePlayerItemFromOptionsJson(
    fabric: fabric, optionsJson: options.optionsJson, versionHash: options.versionHash,
    offering: offering, title: title, description: description, imageThumb: imageThumb)
}

public func MakePlayerItemFromOptionsJson(
  fabric: Fabric,
  optionsJson: JSON,
  versionHash: String,
  offering: String = "default",
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async throws -> AVPlayerItem {
  // debugPrint("MakePlayerItemFromOptionsJson ", optionsJson)

  var hlsPlaylistUrl = ""
  var playerItem: AVPlayerItem? = nil

  if let options = optionsJson.get("hls-clear") {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      uri: options["uri"].stringValue, hash: versionHash, offering: offering)
    // print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AuthenticatedURLAsset(
      url: URL(string: hlsPlaylistUrl)!, token: fabric.fabricToken)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else if let options = optionsJson.get("hls-aes128") {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      uri: options["uri"].stringValue, hash: versionHash, offering: offering)
    print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AuthenticatedURLAsset(
      url: URL(string: hlsPlaylistUrl)!, token: fabric.fabricToken)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else if let options = optionsJson.get("hls-fairplay") {
    let licenseServer = options["properties"]["license_servers"][0].stringValue

    if licenseServer.isEmpty {
      throw RuntimeError("Error getting licenseServer")
    }
    print("license_server \(licenseServer)")

    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      uri: options["uri"].stringValue, hash: versionHash, offering: offering)
    // print("Playlist URL \(hlsPlaylistUrl)")

    let urlAsset = AuthenticatedURLAsset(
      url: URL(string: hlsPlaylistUrl)!, token: fabric.fabricToken)

    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: licenseServer, authToken: fabric.fabricToken)
    playerItem = AVPlayerItem(asset: urlAsset)

  } else if let options = optionsJson.get("hls-sample-aes") {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      uri: options["uri"].stringValue, hash: versionHash, offering: offering)
    print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AuthenticatedURLAsset(
      url: URL(string: hlsPlaylistUrl)!, token: fabric.fabricToken)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else {
    throw RuntimeError("No available playback options \(optionsJson)")
  }

  if let player = playerItem {
    await updateMetadata(
      playerItem: player, title: title, description: description, imageThumb: imageThumb)
    return player
  }

  throw RuntimeError("Error creating playerItem")
}

private func updateMetadata(
  playerItem: AVPlayerItem, title: String, description: String, imageThumb: String
) async {
  await MainActor.run {
    playerItem.externalMetadata.append(AVMeta(title, key: .commonKeyTitle))
    playerItem.externalMetadata.append(AVMeta(description, key: .commonKeyDescription))
  }

  do {
    if let url = URL(string: imageThumb)?
      .replaceFabricUrlPlaceholder()?
      // Limit height for thumbnail
      .replacingQueryParam("height", "600")
    {
      let (data, _) = try await URLSession.shared.data(from: url)
      let image = AVMetaArtwork(value: data as NSData)
      await MainActor.run {
        playerItem.externalMetadata.append(image)
      }
    }
  } catch {
    print("Error getting player info thumbnail ", error)
  }
}

public struct PlayoutInfo: Hashable {
  public var uri: String
  public var drmType: String
  public var licenseServer: String = ""

  public init(uri: String, drmType: String, licenseServer: String = "") {
    self.uri = uri
    self.drmType = drmType
    self.licenseServer = licenseServer
  }
}

public func ResolveMediaPlayoutInfo(
  fabric: Fabric,
  optionsJson: JSON,
  offering: String = "default"
) throws -> PlayoutInfo {

  guard
    let dict = optionsJson.get("hls-clear")
      ?? optionsJson.get("hls-aes128")
      ?? optionsJson.get("hls-fairplay")
      ?? optionsJson.get("hls-sample-aes")
  else { throw RuntimeError("No available playback options \(optionsJson)") }

  let uri = dict["uri"].stringValue
  let properties = dict["properties"]
  let drmType = properties["protocol"].stringValue + "-" + properties["drm"].stringValue
  let licenseServer = properties["license_servers"][0].stringValue
  return PlayoutInfo(
    uri: uri,
    drmType: drmType,
    licenseServer: licenseServer
  )
}

public func MakePlayerItemFromPlayoutInfo(
  playoutInfo: PlayoutInfo,
  fabricToken: String,
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async -> AVPlayerItem {
  let urlAsset = AuthenticatedURLAsset(uri: playoutInfo.uri, token: fabricToken)

  if playoutInfo.drmType == "hls-fairplay" {
    #if targetEnvironment(simulator)
      // FairPlay isn't available on the iOS Simulator — touching
      // AVContentKeySession(keySystem: .fairPlayStreaming) crashes with an
      // NSInternalInconsistencyException. Skip DRM setup; protected streams
      // will fail to decode cleanly instead of taking down the app.
      print("FairPlay is unsupported on simulator — skipping DRM setup")
    #else
      ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
      ContentKeyManager.shared.contentKeyDelegate.setDRM(
        licenseServer: playoutInfo.licenseServer, authToken: fabricToken)
    #endif
  }

  let playerItem = AVPlayerItem(asset: urlAsset)
  await updateMetadata(
    playerItem: playerItem,
    title: title,
    description: description,
    imageThumb: imageThumb
  )
  return playerItem
}

public func MakePlayerItemFromMediaOptionsJson(
  fabric: Fabric,
  optionsJson: JSON,
  offering: String = "default",
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async throws -> AVPlayerItem {
  let playoutInfo = try ResolveMediaPlayoutInfo(
    fabric: fabric, optionsJson: optionsJson, offering: offering)
  return await MakePlayerItemFromPlayoutInfo(
    playoutInfo: playoutInfo, fabricToken: fabric.fabricToken,
    title: title, description: description, imageThumb: imageThumb)
}

public func GetUriFromMediaOptionsJson(
  fabric: Fabric,
  optionsJson: JSON,
  offering: String = "default"
) async throws -> String {
  guard
    let dict = optionsJson.get("hls-clear")
      ?? optionsJson.get("hls-aes128")
      ?? optionsJson.get("hls-fairplay")
      ?? optionsJson.get("hls-sample-aes")
  else { throw RuntimeError("No available playback options \(optionsJson)") }

  let uri = dict["uri"].stringValue

  if optionsJson.get("hls-fairplay") != nil {
    let licenseServer = dict["properties"]["license_servers"][0].stringValue
    if licenseServer.isEmpty {
      throw RuntimeError("Error getting licenseServer")
    }
    let urlAsset = AuthenticatedURLAsset(uri: uri, token: fabric.fabricToken)
    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: licenseServer, authToken: fabric.fabricToken)
  }

  return uri
}

public func AuthenticatedURLAsset(url: URL, token: String) -> AVURLAsset {
  /// Adding the token as a query param will result in every URI in the response referencing the token, which bloats the size of the response.
  /// This can  be very significant for long running (6+ hours) VODS.
  /// Adding it as a header avoids all that bloat.
  AVURLAsset(
    url: url,
    options: [
      "AVURLAssetHTTPHeaderFieldsKey": ["Authorization": "Bearer \(token)"]
    ])
}

public func AuthenticatedURLAsset(uri: String, token: String) -> AVURLAsset {
  let url = URL(string: "\(FabricConfigStore.shared.fabricBaseUrl)\(uri)")!
  return AuthenticatedURLAsset(url: url, token: token)
}

public func AVMeta(_ data: String, key: AVMetadataKey) -> AVMutableMetadataItem {
  let mdi = AVMutableMetadataItem()
  mdi.locale = NSLocale.current
  mdi.key = key as (NSCopying & NSObjectProtocol)
  mdi.keySpace = AVMetadataKeySpace.common
  mdi.value = data as (NSCopying & NSObjectProtocol)?
  return mdi
}

public func AVMetaArtwork(value: Any) -> AVMetadataItem {
  let item = AVMutableMetadataItem()
  item.identifier = AVMetadataIdentifier(
    rawValue: AVMetadataIdentifier.commonIdentifierArtwork.rawValue)
  item.value = value as? NSCopying & NSObjectProtocol
  item.extendedLanguageTag = "und"
  return item.copy() as! AVMetadataItem
}

public extension JSON {
  /// Convenience to get a value only if it exists
  public func get(_ key: String) -> JSON? {
    let value = self[key]
    return value.exists() ? value : nil
  }
}
