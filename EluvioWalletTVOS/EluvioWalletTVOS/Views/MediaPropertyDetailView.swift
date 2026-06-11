//
//  MediaPropertyDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-14.
//

import AVFoundation
import EluvioCore
import Foundation
import SwiftUI
import SwiftyJSON

struct IconButton: View {
  @FocusState var focused
  var action: () -> Void
  var iconName: String

  var body: some View {
    Button(action: action) {
      HStack {
        Group {
          if UIImage(named: iconName) != nil {
            Image(iconName)
              .renderingMode(.template)
              .resizable()
              .scaledToFit()
              .foregroundColor(focused ? .black : .gray)
          } else {
            Image(systemName: iconName)
              .resizable()
              .scaledToFit()
              .foregroundColor(focused ? .black : .gray)
          }
        }
        .frame(width: 40, height: 40)
        .padding()
      }
      .background(focused ? .white : Color.black.opacity(0.5))
      .clipShape(Circle())
    }
    .buttonStyle(IconButtonStyle(focused: focused, initialOpacity: 0.7, scale: 1.2))
    .focused($focused)
    .focusEffectDisabled()
  }
}

struct MediaPropertyDetailView: View {
  @Namespace var NamespaceProperty
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var router: Router
  @EnvironmentObject var eluvio: EluvioAPI

  private let propertyId: String
  private let pageId: String?

  private var property: MediaProperty? {
    PropertyStore.shared.getProperty(id: propertyId)
  }
  @State private var activePage: MediaPropertyPage?
  @FocusState private var switcherFocused
  @State private var playerItem: AVPlayerItem? = nil
  @State private var backgroundImage: String = ""
  @State private var propertyLinks: [PropertyLink]
  @State private var selectedLinkId: String

  // Assume not loading by default, so we don't flicker a spinner when cache
  // is already filled.
  // When we have no cache, we'll very quickly detect it and flip to loading
  @State private var sectionsLoading = false

  init(propertyId: String, pageId: String? = nil, propertyLinks: [PropertyLink] = []) {
    self.propertyId = propertyId
    self.pageId = pageId
    self._propertyLinks = State(initialValue: propertyLinks)
    self._selectedLinkId = State(initialValue: propertyId)
  }

  var body: some View {
    ScrollView {
      ZStack(alignment: .topLeading) {
        if let item = playerItem {
          VStack {
            LoopingVideoPlayer([item], endAction: .loop)
              .frame(
                width: UIScreen.main.bounds.size.width, height: UIScreen.main.bounds.size.height
              )
              .edgesIgnoringSafeArea([.top, .leading, .trailing])
              .padding(0)
              .frame(alignment: .topLeading)
              .id("property video \(item.hashValue)")
            Spacer()
          }
          .frame(maxWidth: .infinity, maxHeight: UIScreen.main.bounds.size.height)
        } else if backgroundImage.hasPrefix("http") {
          ScaledWebImage(url: backgroundImage, height: UIScreen.main)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .edgesIgnoringSafeArea([.top, .leading, .trailing])
            .frame(
              width: UIScreen.main.bounds.width,
              height: UIScreen.main.bounds.height, alignment: .topLeading
            )
            .clipped()
            .id(backgroundImage)
        } else if backgroundImage != "" {
          Image(backgroundImage)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .edgesIgnoringSafeArea([.top, .leading, .trailing])
            .frame(alignment: .topLeading)
            .clipped()
            .id(backgroundImage)
        }

        VStack(spacing: 0) {
          if let pv = property, let page = activePage {
            PropertyDetailForResolvedPage(
              property: pv,
              page: page,
              sectionsLoading: $sectionsLoading
            ) { video, image in
              playerItem = video
              backgroundImage = image ?? ""
            }.id([pv.id, page.id])
          }
        }
        .prefersDefaultFocus(in: NamespaceProperty)

        HStack(alignment: .top) {
          Spacer()
          VStack {
            HStack(spacing: 20) {
              if propertyLinks.count >= 2 {
                Menu {
                  Picker(selection: $selectedLinkId, label: Text("")) {
                    ForEach(propertyLinks, id: \.id) { link in
                      Text(link.title)
                        .padding(40)
                        .tag(link.id)
                    }
                  }
                } label: {
                  HStack {
                    Image("switcher")
                      .renderingMode(.template)
                      .resizable()
                      .scaledToFit()
                      .foregroundColor(switcherFocused ? .black : .gray)
                      .frame(width: 40, height: 40)
                      .padding()
                  }
                  .background(switcherFocused ? .white : Color.black.opacity(0.5))
                  .clipShape(Circle())
                }
                .buttonStyle(
                  IconButtonStyle(focused: switcherFocused, initialOpacity: 0.7, scale: 1.2)
                )
                .focused($switcherFocused)
              }

              if eluvio.isCustomApp() {
                IconButton(
                  action: {
                    router.path.append(.profile)
                  }, iconName: "person.crop.circle"
                )

                IconButton(
                  action: {
                    router.path.append(.myItems)
                  }, iconName: "rectangle.stack"
                )
              }

              IconButton(
                action: {
                  router.path.append(.search(SearchParams(propertyId: propertyId)))
                }, iconName: "search"
              )
            }

            Spacer()
          }
        }
        .zIndex(20)
        .focusSection()
        .padding(.trailing, 80)
        .padding(.top, 80)
        .frame(maxWidth: .infinity, maxHeight: 120)
      }
      .frame(maxWidth: .infinity, alignment: .topLeading)
    }
    .overlay {
      if sectionsLoading {
        Color.mainBackground
          .edgesIgnoringSafeArea(.all)
          .overlay(ProgressView())
          .transition(.opacity)
      }
    }
    .animation(.easeInOut, value: sectionsLoading)
    .onAnyChange(of: property) { oldValue, newValue in
      Task {
        await loadProperty()
      }
    }
    .scrollClipDisabled()
    .edgesIgnoringSafeArea(.all)
    .accessibilityIdentifier("property_detail_\(propertyId)")
    .onChange(of: selectedLinkId) { _, newId in
      guard newId != propertyId else { return }
      // New property selected, replace current screen
      router.replace(
        with: .property(
          PropertyParam(
            propertyId: newId,
            propertyLinks: propertyLinks
          )))
    }
    .background(
      Color.black.edgesIgnoringSafeArea(.all)
    )
  }

  private func loadProperty() async {
    async let fetchProperty: () = PropertyStore.shared.fetchProperty(id: propertyId)
    async let loadPropertyLinks: () = loadPropertyLinks()
    async let loadPage: () = loadPage()
    _ = await (fetchProperty, loadPropertyLinks, loadPage)
  }

  private func loadPage() async {
    guard let mediaProperty = property else { return }

    do {
      let page = try await PropertyStore.shared.getFirstAuthorizedPage(
        property: mediaProperty, pageId: pageId)
      activePage = page
    } catch PageRedirectError.purchaseRequired {
      // TODO: Show purchase UI
    } catch {
      print("Error loading page: \(error)")
    }
  }

  private func loadPropertyLinks() async {
    guard propertyLinks.isEmpty else {
      // links already set, probably set by the parent property, so just use as-is,
      // no need to parse them out
      return
    }
    guard let mediaProperty = property else { return }
    guard mediaProperty.show_property_selection == true else { return }
    guard let subproperties = mediaProperty.property_selection, !subproperties.isEmpty else {
      return
    }

    // Start with self as first entry
    var links: [PropertyLink] = [
      PropertyLink(id: mediaProperty.id, title: mediaProperty.name ?? mediaProperty.title ?? "")
    ]

    for subproperty in subproperties {
      let id = subproperty.property_id
      guard !id.isEmpty, id != mediaProperty.id else { continue }

      await PropertyStore.shared.fetchProperty(id: id)
      guard let vm = PropertyStore.shared.getProperty(id: id),
        vm.resolvedPropertyPermissions?.authorized != false
      else { continue }

      let title =
        (subproperty.title ?? "").isEmpty
        ? (vm.displayName)
        : (subproperty.title ?? "")
      links.append(PropertyLink(id: id, title: title))
    }

    if links.count >= 2 {
      propertyLinks = links
    }
  }
}

struct PropertyDetailForResolvedPage: View {
  @EnvironmentObject var eluvio: EluvioAPI
  private var property: MediaProperty
  @State var page: MediaPropertyPage
  @Binding var sectionsLoading: Bool
  private var sections: [MediaPropertySection] {
    PropertyStore.shared.sections(for: page)
  }
  var onBackgroundLoaded: (AVPlayerItem?, String?) -> Void
  init(
    property: MediaProperty,
    page: MediaPropertyPage,
    sectionsLoading: Binding<Bool>,
    onBackgroundLoaded: @escaping (AVPlayerItem?, String?) -> Void
  ) {
    self.property = property
    self.page = page
    self._sectionsLoading = sectionsLoading
    self.onBackgroundLoaded = onBackgroundLoaded
  }
  var body: some View {
    Group {
      // Color.clear ensures the Group always has content, so .task fires
      // even before sections are loaded.
      Color.clear.frame(height: 0)

      ForEach(Array(sections.enumerated()), id: \.element.id) { index, section in
        MediaPropertySectionView(
          property: property, pageId: page.id, section: section,
          isFirstSection: index == 0
        )
        .fixedSize(horizontal: false, vertical: true)
        .padding(0)
      }
    }.repeatTask {
      // Refresh page and sections every minute
      if let newPage = try? await PropertyStore.shared.fetchPage(
        property: property, pageId: page.id)
      {
        self.page = newPage
      }
      await PropertyStore.shared.fetchSections(property: property, page: page)
      try await Task.sleep(for: .minutes(1))  // This throws if task is cancelled

      // Side note: this will help keep the token fresh,
      // so the bg video player doesn't need to worry about proactive token refreshing
    }
    .onAnyChange(of: sections) { _, _ in
      sectionsLoading = sections.isEmpty
      Task {
        await loadHeroBackground()
      }
    }
  }

  private func loadHeroBackground() async {
    guard let section = sections.first,
      let hero = section.hero_items?.array?.first
    else { return }

    let videoLink = hero["display"]["background_video"]
    let backgroundLink = hero["display"]["background_image"]

    var video: AVPlayerItem? = nil
    if !videoLink.isEmpty {
      do {
        video = try await MakePlayerItemFromLink(fabric: eluvio.fabric, link: videoLink)
      } catch {
        debugPrint("Error making video item: ", error)
      }
    }

    var image: String? = nil
    if !backgroundLink.isEmpty {
      do {
        image = try eluvio.fabric.getUrlFromLink(link: backgroundLink)
      } catch {
        debugPrint("Error getting background image url: ", error)
      }
    }
    onBackgroundLoaded(video, image)
  }
}

// MARK: - SwiftUI Previews

#Preview("Icon Button") {
  IconButton(action: {}, iconName: "search")
    .padding()
    .background(Color.black)
}

#Preview("Media Property Detail View") {
  MediaPropertyDetailView(propertyId: "sample-property")
    .environmentObject(EluvioAPI())
    .preferredColorScheme(.dark)
}
