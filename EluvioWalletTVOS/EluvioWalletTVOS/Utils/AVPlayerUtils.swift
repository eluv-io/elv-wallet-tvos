import AVFoundation
import SwiftyJSON

extension AVPlayer {
  func addProgressObserver(intervalSeconds: Double = 5, action: @escaping ((Double) -> Void)) -> Any
  {
    return addPeriodicTimeObserver(
      forInterval: CMTime(value: Int64(intervalSeconds * 1000), timescale: 1000), queue: .main,
      using: { time in
        if let duration = self.currentItem?.duration {
          let duration = CMTimeGetSeconds(duration)
          let time = CMTimeGetSeconds(time)
          let progress = (time / duration)
          action(progress)
        }
      })
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
  optionsJson: JSON?,
  versionHash: String,
  offering: String = "default",
  title: String = "",
  description: String = "",
  imageThumb: String = ""
) async throws -> AVPlayerItem {
  // debugPrint("MakePlayerItemFromOptionsJson ", optionsJson)

  var hlsPlaylistUrl = ""
  var playerItem: AVPlayerItem? = nil

  guard let options = optionsJson else {
    throw RuntimeError("MakePlayerItemFromOptionsJson options is nil")
  }

  if options["hls-clear"].exists() {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      optionsJson: optionsJson, hash: versionHash, drm: "hls-clear", offering: offering)
    // print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else if options["hls-aes128"].exists() {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      optionsJson: optionsJson, hash: versionHash, drm: "hls-aes128", offering: offering)
    print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else if options["hls-fairplay"].exists() {
    let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue

    if licenseServer.isEmpty {
      throw RuntimeError("Error getting licenseServer")
    }
    print("license_server \(licenseServer)")

    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      optionsJson: optionsJson, hash: versionHash, drm: "hls-fairplay", offering: offering)
    // print("Playlist URL \(hlsPlaylistUrl)")

    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: licenseServer, authToken: fabric.fabricToken)
    playerItem = AVPlayerItem(asset: urlAsset)

  } else if options["hls-sample-aes"].exists() {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(
      optionsJson: optionsJson, hash: versionHash, drm: "hls-sample-aes", offering: offering)
    print("Playlist URL \(hlsPlaylistUrl)")
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)

    playerItem = AVPlayerItem(asset: urlAsset)
  } else {
    throw RuntimeError("No available playback options \(options)")
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
  optionsJson: JSON?,
  offering: String = "default"
) throws -> VideoParams.PlayoutInfo {
  guard let options = optionsJson else {
    throw RuntimeError("ResolveMediaPlayoutInfo options is nil")
  }

  if options["hls-clear"].exists() {
    let url = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-clear", offering: offering)
    return VideoParams.PlayoutInfo(hlsPlaylistUrl: url, drmType: "hls-clear")
  } else if options["hls-aes128"].exists() {
    let url = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-aes128", offering: offering)
    return VideoParams.PlayoutInfo(hlsPlaylistUrl: url, drmType: "hls-aes128")
  } else if options["hls-fairplay"].exists() {
    let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue
    if licenseServer.isEmpty {
      throw RuntimeError("Error getting licenseServer")
    }
    let url = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-fairplay", offering: offering)
    return VideoParams.PlayoutInfo(
      hlsPlaylistUrl: url, drmType: "hls-fairplay", licenseServer: licenseServer)
  } else if options["hls-sample-aes"].exists() {
    let url = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-sample-aes", offering: offering)
    return VideoParams.PlayoutInfo(hlsPlaylistUrl: url, drmType: "hls-sample-aes")
  }

  throw RuntimeError("No available playback options \(options)")
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
    if let url = URL(string: imageThumb) {
      let (data, _) = try await URLSession.shared.data(from: url)
      let image = AVMetaArtwork(value: data as NSData)
      playerItem.externalMetadata.append(image)
    }
  } catch {
    print("Error getting player info thumbnail ", error)
  }

  return playerItem
}

func MakePlayerItemFromMediaOptionsJson(
  fabric: Fabric,
  optionsJson: JSON?,
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
  optionsJson: JSON?,
  offering: String = "default"
) async throws -> String {
  var hlsPlaylistUrl = ""

  guard let options = optionsJson else {
    throw RuntimeError("GetUrlFromMediaOptionsJson options is nil")
  }

  if options["hls-clear"].exists() {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-clear", offering: offering)
  } else if options["hls-aes128"].exists() {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-aes128", offering: offering)
  } else if options["hls-fairplay"].exists() {
    let licenseServer = options["hls-fairplay"]["properties"]["license_servers"][0].stringValue
    if licenseServer.isEmpty {
      throw RuntimeError("Error getting licenseServer")
    }
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-fairplay", offering: offering)
    let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
    ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
    ContentKeyManager.shared.contentKeyDelegate.setDRM(
      licenseServer: licenseServer, authToken: fabric.fabricToken)
  } else if options["hls-sample-aes"].exists() {
    hlsPlaylistUrl = try fabric.getHlsPlaylistFromMediaOptions(
      optionsJson: optionsJson, drm: "hls-sample-aes", offering: offering)
  } else {
    throw RuntimeError("No available playback options \(options)")
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
