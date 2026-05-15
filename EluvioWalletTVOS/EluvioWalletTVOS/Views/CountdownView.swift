//
//  CountdownView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-20.
//

import EluvioCore
import SwiftUI

struct PlayerErrorView: View {
  var propertyId: String = ""
  var title: String = "The media is not available"

  var backgroundImageUrl: String {
    PropertyStore.shared.getProperty(id: propertyId)?.backgroundImage ?? ""
  }

  var body: some View {
    ZStack(alignment: .center) {
      ScaledWebImage(url: backgroundImageUrl, height: UIScreen.main)
        .resizable()
        .edgesIgnoringSafeArea(.all)

      Color.black.opacity(0.5)
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 0) {
        Spacer()
        Image(systemName: "lock")
          .resizable()
          .scaledToFit()
          .frame(width: 100, height: 100)
          .padding(.bottom, 52)

        Text(title).font(.system(size: 32, weight: .semibold))
          .lineLimit(1)
          .frame(maxWidth: 1600)
          .multilineTextAlignment(.center)
          .padding(.bottom, 52)

        Spacer()
      }
    }
  }
}

struct CountDownView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  var mediaItem: MediaPropertySectionMediaItem
  var propertyId: String = ""

  var backgroundImageUrl: String {
    PropertyStore.shared.getProperty(id: propertyId)?.backgroundImage ?? ""
  }
  @State var timeRemaining: String = " "

  var images: [String] {
    mediaItem.icons?.compactMap { $0.icon?.url } ?? []
  }

  var title: String {
    mediaItem.title ?? ""
  }

  var description: String {
    mediaItem.description ?? ""
  }

  var infoText: String {
    mediaItem.headers?.joined(separator: "   ") ?? ""
  }

  var imageUrl: String {
    mediaItem.thumbnail_image_square?.url
      ?? mediaItem.thumbnail_image_landscape?.url
      ?? mediaItem.thumbnail_image_portrait?.url
      ?? ""
  }

  var body: some View {
    ZStack(alignment: .center) {
      ScaledWebImage(url: backgroundImageUrl, height: UIScreen.main)
        .resizable()
        .edgesIgnoringSafeArea(.all)

      Color.black.opacity(0.5)
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 0) {
        Spacer()
        if images.isEmpty {
          ScaledWebImage(url: imageUrl, height: 300)
            .resizable()
            .scaledToFit()
            .frame(width: 600, height: 300)
            .padding(.bottom, 52)
        } else if !images.isEmpty {
          HStack(spacing: 52) {
            ForEach(0..<images.count, id: \.self) { index in
              ScaledWebImage(url: images[index], height: 200)
                .resizable()
                .scaledToFit()
                .frame(width: 200, height: 200)
                .padding(.bottom, 52)
            }
          }
        }

        Text(infoText).font(.system(size: 32))
          .lineLimit(1)
          .frame(maxWidth: 1600)
          .padding(.bottom, 28)

        Text(title).font(.system(size: 32, weight: .semibold))
          .lineLimit(1)
          .frame(maxWidth: 1600)
          .multilineTextAlignment(.center)
          .padding(.bottom, 52)

        Text(timeRemaining).font(.system(size: 62, weight: .semibold))
          .lineLimit(1)
          .frame(maxWidth: 1600)
          .multilineTextAlignment(.center)
          .transition(.opacity)
          .id("time remainging: " + timeRemaining)
          .padding()
        Spacer()
      }
    }
    .repeatTask {
      guard let startDate = mediaItem.startDate else { return }
      if startDate > Date() && !mediaItem.hasStarted {
        timeRemaining = mediaItem.timeUntilStartLong
      } else {
        if timeRemaining.isEmpty || timeRemaining == " " {
          withAnimation(.easeInOut(duration: 1)) {
            timeRemaining = "Starting soon"
          }
        } else {
          timeRemaining = "Starting soon"
        }

        if mediaItem.hasStarted {
          await startVideo()
          throw "stop loop"
        }
      }
      try await Task.sleep(for: .seconds(1))
    }
  }

  private func startVideo() async {
    debugPrint("Starting stream...")

    if mediaItem.media_link?["."]["resolution_error"]["kind"].stringValue == "permission denied" {
      debugPrint("permission denied! ", mediaItem.title)

      let videoErrorParams = VideoPermissionErrorParams(propertyId: propertyId)
      await MainActor.run {
        router.replace(with: .videoPermissionError(videoErrorParams))
        return
      }
    }

    guard let link = mediaItem.media_link?["sources"]["default"] else { return }
    do {
      let optionsJson = try await eluvio.fabric.getMediaPlayoutOptions(
        propertyId: propertyId, mediaId: mediaItem.id ?? "")
      let playout = try ResolveMediaPlayoutInfo(
        fabric: eluvio.fabric, optionsJson: optionsJson)
      let viewModel = MediaPropertySectionMediaItemViewModel.create(
        media: mediaItem)
      let params = VideoParams(viewItem: viewModel, playout: playout)
      await MainActor.run {
        router.replace(with: .video(params))
      }
    } catch {
      print("Error getting link url for playback ", error)
      let videoErrorParams = VideoPermissionErrorParams(propertyId: propertyId)
      await MainActor.run {
        router.replace(with: .videoPermissionError(videoErrorParams))
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Player Error View") {
  PlayerErrorView(
    title: "This content is not available"
  )
}

#Preview("Player Error - Custom Message") {
  PlayerErrorView(
    title: "You don't have permission to view this content"
  )
}
