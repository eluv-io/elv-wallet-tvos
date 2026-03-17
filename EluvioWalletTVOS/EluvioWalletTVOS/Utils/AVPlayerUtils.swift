import AVFoundation
import SwiftyJSON

extension AVPlayer {
  func addProgressObserver(intervalSeconds: Double = 5, action: @escaping ((Double) -> Void)) -> Any
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

  /// Recreates the current player item with a fresh token in the URL query param,
  /// preserving playback position and metadata.
  func refreshCurrentItemAuth() async {
    guard let currentItem = self.currentItem else { return }
    guard let asset = currentItem.asset as? AVURLAsset else { return }

    let currentTime = currentItem.currentTime()
    let wasPlaying = (self.rate != 0)
    let oldExternalMetadata = currentItem.externalMetadata

    guard let newUrl = asset.url.replacingQueryParam("authorization", AccountStore.shared.bestToken)
    else {
      debugPrint("[Auth] Failed to update authorization query param")
      return
    }

    let newAsset = AVURLAsset(url: newUrl)
    let newItem = AVPlayerItem(asset: newAsset)
    newItem.externalMetadata = oldExternalMetadata

    await MainActor.run {
      self.replaceCurrentItem(with: newItem)
      self.seek(to: currentTime)
      if wasPlaying {
        self.play()
      }
      debugPrint("[Auth] Refreshed player item with new token in URL")
    }
  }
}

func MakePlayerItemFromVersionHash(
  fabric: Fabric,
  versionHash: String,
  params: [JSON]? = [],
  offering: String = "default",
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async throws -> AVPlayerItem {
  debugPrint("MakePlayerItemFromVersionHash ", versionHash)
  let options = try await fabric.getOptionsFromHash(versionHash: versionHash)
  debugPrint("getOptionsFromHash ", options)
  return try await MakePlayerItemFromOptionsJson(
    fabric: fabric, optionsJson: options, versionHash: versionHash, offering: offering)
}

func MakePlayerItemFromLink(
  fabric: Fabric,
  link: JSON?,
  params: [JSON]? = [],
  offering: String = "default",
  // hash: String = "",
  title _: String = "",
  description _: String = "",
  imageThumb _: String = ""
) async throws -> AVPlayerItem {
  debugPrint("MakePlayerItemFromLink ", link)
  let options = try await fabric.getOptionsFromLink(link: link, params: params, offering: offering)
  debugPrint("getOptionsFromLink ", options)
  return try await MakePlayerItemFromOptionsJson(
    fabric: fabric, optionsJson: options.optionsJson, versionHash: options.versionHash,
    offering: offering)
}

func MakePlayerItemFromOptionsJson(
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
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else if let options = optionsJson.get("hls-aes128") {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      uri: options["uri"].stringValue, hash: versionHash, offering: offering)
    print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

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

    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: licenseServer, authToken: fabric.fabricToken)
    playerItem = AVPlayerItem(asset: urlAsset)

  } else if let options = optionsJson.get("hls-sample-aes") {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      uri: options["uri"].stringValue, hash: versionHash, offering: offering)
    print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else {
    throw RuntimeError("No available playback options \(optionsJson)")
  }

  if let player = playerItem {
    await MainActor.run {
      player.externalMetadata.append(AVMeta(title, key: .commonKeyTitle))
      player.externalMetadata.append(AVMeta(description, key: .commonKeyDescription))
    }

    do {
      if let url = URL(string: imageThumb) {
        let (data, _) = try await URLSession.shared.data(from: url)
        let image = AVMetaArtwork(value: data as NSData)
        player.externalMetadata.append(image)
      }
    } catch {
      print("Error getting player info thumbnail ", error)
    }

    return player
  }

  throw RuntimeError("Error creating playerItem")
}

func ResolveMediaPlayoutInfo(
  fabric: Fabric,
  optionsJson: JSON,
  offering: String = "default"
) throws -> VideoParams.PlayoutInfo {

  guard
    let dict = optionsJson.get("hls-clear")
      ?? optionsJson.get("hls-aes128")
      ?? optionsJson.get("hls-fairplay")
      ?? optionsJson.get("hls-sample-aes")
  else { throw RuntimeError("No available playback options \(optionsJson)") }

  let url = fabric.getHlsPlaylistFromMediaOptions(uri: dict["uri"].stringValue)
  let properties = dict["properties"]
  let drmType = properties["protocol"].stringValue + "-" + properties["drm"].stringValue
  let licenseServer = properties["license_servers"][0].stringValue
  return VideoParams.PlayoutInfo(
    hlsPlaylistUrl: url,
    drmType: drmType,
    licenseServer: licenseServer
  )
}

func MakePlayerItemFromPlayoutInfo(
  playoutInfo: VideoParams.PlayoutInfo,
  fabricToken: String,
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async -> AVPlayerItem {
  let urlAsset = AVURLAsset(url: URL(string: playoutInfo.hlsPlaylistUrl)!)

  if playoutInfo.drmType == "hls-fairplay" {
    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: playoutInfo.licenseServer, authToken: fabricToken)
  }

  let playerItem = AVPlayerItem(asset: urlAsset)

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

  return playerItem
}

func MakePlayerItemFromMediaOptionsJson(
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

func GetUrlFromMediaOptionsJson(
  fabric: Fabric,
  optionsJson: JSON,
  offering: String = "default"
) async throws -> String {
  var hlsPlaylistUrl = ""

  if let options = optionsJson.get("hls-clear") {
    hlsPlaylistUrl = fabric.getHlsPlaylistFromMediaOptions(
      uri: options["uri"].stringValue)
  } else if let options = optionsJson.get("hls-aes128") {
    hlsPlaylistUrl = fabric.getHlsPlaylistFromMediaOptions(
      uri: options["uri"].stringValue)
  } else if let options = optionsJson.get("hls-fairplay") {
    let licenseServer = options["properties"]["license_servers"][0].stringValue
    if licenseServer.isEmpty {
      throw RuntimeError("Error getting licenseServer")
    }
    hlsPlaylistUrl = fabric.getHlsPlaylistFromMediaOptions(
      uri: options["uri"].stringValue)
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: licenseServer, authToken: fabric.fabricToken)
  } else if let options = optionsJson.get("hls-sample-aes") {
    hlsPlaylistUrl = fabric.getHlsPlaylistFromMediaOptions(
      uri: options["uri"].stringValue)
  } else {
    throw RuntimeError("No available playback options \(optionsJson)")
  }

  return hlsPlaylistUrl
}

func AVMeta(_ data: String, key: AVMetadataKey) -> AVMutableMetadataItem {
  let mdi = AVMutableMetadataItem()
  mdi.locale = NSLocale.current
  mdi.key = key as (NSCopying & NSObjectProtocol)
  mdi.keySpace = AVMetadataKeySpace.common
  mdi.value = data as (NSCopying & NSObjectProtocol)?
  return mdi
}

func AVMetaArtwork(value: Any) -> AVMetadataItem {
  let item = AVMutableMetadataItem()
  item.identifier = AVMetadataIdentifier(
    rawValue: AVMetadataIdentifier.commonIdentifierArtwork.rawValue)
  item.value = value as? NSCopying & NSObjectProtocol
  item.extendedLanguageTag = "und"
  return item.copy() as! AVMetadataItem
}

extension JSON {
  /// Convenience to get a value only if it exists
  func get(_ key: String) -> JSON? {
    let value = self[key]
    return value.exists() ? value : nil
  }
}
