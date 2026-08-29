//
//  MediaPropertySectionView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-24.
//

import AVFoundation
import EluvioCore
import Foundation
import SwiftUI
import SwiftyJSON

struct ViewAllButton: View {
  @FocusState var isFocused
  var action: () -> Void

  var body: some View {
    Button(
      action: action,
      label: {
        Text("VIEW ALL").font(.system(size: 24)).bold()
      }
    )
    .buttonStyle(TextButtonStyle(focused: isFocused, bordered: true))
    .focused($isFocused)
    .opacity(isFocused ? 1.0 : 0.6)
  }
}

extension View {
  func getWidth(_ width: Binding<CGFloat>) -> some View {
    modifier(GetWidthModifier(width: width))
  }
}

struct GetWidthModifier: ViewModifier {
  @Binding var width: CGFloat
  func body(content: Content) -> some View {
    content
      .background(
        GeometryReader { proxy in
          let proxyWidth = proxy.size.width
          Color.clear
            .task(id: proxy.size.width) {
              $width.wrappedValue = max(proxyWidth, 0)
              debugPrint("Width: ", proxyWidth)
            }
        }
      )
  }
}

struct MediaPropertySectionGridView: View {
  @Namespace var NamespaceProperty
  @EnvironmentObject var eluvio: EluvioAPI
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  var pageCardThemeId: String? = nil
  var margin: CGFloat = 80
  @State var logoUrl: String? = nil
  @State private var refreshId = ""
  var useScale = false

  var logoText: String {
    return section.display?.logo_text ?? ""
  }

  // @State var inlineBackgroundUrl: String? = nil

  var body: some View {
    HStack(spacing: 0) {
      if let url = logoUrl {
        VStack(spacing: 20) {
          ScaledWebImage(url: url, height: 100)
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 180, height: 180)
          Text(logoText)
            .font(.sectionLogoText)
        }
        .padding(.leading, margin)
      }

      SectionGridView(
        property: property, pageId: pageId, section: section,
        pageCardThemeId: pageCardThemeId, margin: margin,
        useScale: useScale, showBackground: false)
    }
    .clipped()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      if self.refreshId == eluvio.refreshId {
        return
      }

      self.refreshId = eluvio.refreshId

      if let display = section.display {
        logoUrl = display.logo?.url
      }
    }
  }
}

struct MediaPropertyRegularSectionView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var router: Router
  @Namespace var SectionNamespace
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  var pageCardThemeId: String? = nil
  var margin: CGFloat = 80
  @State private var refreshId = ""
  @State var items: [MediaPropertySectionMediaItemViewModel] = []
  // private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @FocusState private var currentFocusItem: MediaPropertySectionMediaItemViewModel?
  @State private var lastFocusItem: MediaPropertySectionMediaItemViewModel?
  var useScale = false
  var scaleFactor: CGFloat = 0.7
  var lookForBackground = false

  var body: some View {
    ZStack(alignment: .leading) {
      HStack(alignment: .center) {
        if items.isEmpty {
          EmptyView()
        } else {
          if let url = logoUrl {
            VStack(spacing: 20) {
              ScaledWebImage(url: url, height: 180)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 180, height: 180)
              Text(logoText)
                .font(.sectionLogoText)
            }
            .padding(.trailing, 20)
          }

          VStack(alignment: hAlignment, spacing: 0) {
            VStack(alignment: hAlignment, spacing: 5) {
              HStack(alignment: .center, spacing: 20) {
                if !titleIcon.isEmpty {
                  ScaledWebImage(url: titleIcon, height: 60)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                }
                if !section.hideTitle, !section.displayTitle.isEmpty {
                  Text(section.displayTitle).font(.rowTitle)
                    .frame(alignment: alignment)
                }

                if section.showViewAll {
                  ViewAllButton(action: {
                    debugPrint("View All pressed")
                    let params = SectionViewAllParams(
                      property: property,
                      pageId: pageId,
                      section: section
                    )
                    router.path.append(.sectionViewAll(params))
                  })
                  .padding(0)
                }
              }
              .frame(alignment: alignment)

              if !section.displaySubtitle.isEmpty {
                Text(section.displaySubtitle).font(.rowSubtitle)
                  .frame(alignment: alignment)
              }
            }
            .focusSection()
            .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: alignment)
            .padding(.bottom, 10)
            .padding(.leading, 10)

            if alignment == .center && items.count < 5 {
              HStack(alignment: .top, spacing: 20) {
                ForEach(items) { item in
                  SectionItemView(
                    sectionId: section.id,
                    pageId: pageId,
                    property: property,
                    forceAspectRatio: forceAspectRatio,
                    cardSize: cardSize,
                    titleAlignment: titleAlignment,
                    cardTheme: cardTheme,
                    showItemTitle: showItemTitles,
                    viewItem: item
                  )
                  .focused($currentFocusItem, equals: item)
                }
              }
              .padding([.top, .bottom], 20)
              .padding(.leading, 10)
              .padding(.trailing, 0)
              .edgesIgnoringSafeArea([.leading, .trailing])
              .focusSection()
            } else {
              ScrollView(.horizontal) {
                HStack(alignment: .center, spacing: 20) {
                  ForEach(Array(items.enumerated()), id: \.offset) { _, item in
                    SectionItemView(
                      sectionId: section.id,
                      pageId: pageId,
                      property: property,
                      forceAspectRatio: forceAspectRatio,
                      cardSize: cardSize,
                      titleAlignment: titleAlignment,
                      cardTheme: cardTheme,
                      showItemTitle: showItemTitles,
                      viewItem: item
                    )
                    .padding(.top, 0)
                    .focused($currentFocusItem, equals: item)
                  }
                }
                .frame(maxWidth: .infinity)
                .padding([.top, .bottom], 20)
                .padding(.leading, 10)
                .focusSection()
              }
              .defaultFocus(
                $currentFocusItem, lastFocusItem ?? items.first, priority: .userInitiated
              )
              .onChange(of: currentFocusItem) {
                if currentFocusItem != nil {
                  lastFocusItem = currentFocusItem
                }
              }
            }
          }
          Spacer()
        }
      }
      .focusSection()
      .padding(.top, 40)
      .padding([.leading], margin)
      .padding(.bottom, 20)
      .padding(.trailing, 0)
      .edgesIgnoringSafeArea([.trailing])

      if lookForBackground {
        Group {
          if let url = inlineBackgroundUrl {
            ScaledWebImage(url: url, height: UIScreen.main)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(maxWidth: .infinity, maxHeight: .infinity)
              .clipped()
              .zIndex(-10)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity)
      }
    }
    .clipped()
    .edgesIgnoringSafeArea([.trailing])
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .task(id: section.content ?? []) {
      await refresh()
    }
  }

  func refresh() async {
    debugPrint("MediaPropertyRegularSectionView refresh() ", section.displayTitle)

    let max = 25
    var count = 0
    var sectionItems: [MediaPropertySectionMediaItemViewModel] = []
    if let content = section.content {
      for item in content {
        if item.media?.resolvedPermissions?.hide != true {
          let viewItem = MediaPropertySectionMediaItemViewModel.create(item: item)
          sectionItems.append(viewItem)
        }

        // Optimization so we show the first 4 first so faster loading sections don't render ahead of us as much
        if sectionItems.count == 4 {
          self.items = sectionItems
        }

        count += 1
        if count == max {
          break
        }
      }
    }
    debugPrint("section \(section.id) has \(sectionItems.count) items")
    self.items = sectionItems
  }

  var titleIcon: String {
    section.display?.title_icon?.url ?? ""
  }

  var logoUrl: String? {
    section.display?.logo?.url
  }

  var logoText: String {
    section.display?.logo_text ?? ""
  }

  var inlineBackgroundUrl: String? {
    lookForBackground ? section.display?.inline_background_image?.url : nil
  }

  var hAlignment: HorizontalAlignment {
    switch section.display?.justification?.lowercased() {
    case "right": .trailing
    case "center": .center
    default: .leading
    }
  }

  var alignment: Alignment {
    switch section.display?.justification?.lowercased() {
    case "right": .trailing
    case "center": .center
    default: .leading
    }
  }

  var forceAspectRatio: String {
    section.display?.aspect_ratio ?? ""
  }

  var cardSize: CardSize {
    CardSize(section.display?.card_size)
  }

  var titleAlignment: Alignment {
    switch section.displayTextJustification.lowercased() {
    case "right": .trailing
    case "center": .center
    default: .leading
    }
  }

  var cardTheme: CardTheme? {
    property.resolveCardTheme(pageThemeId: pageCardThemeId, section: section)
  }

  var showItemTitles: Bool {
    section.display?.showItemTitles != false
  }
}

struct MediaPropertySectionBannerView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  var property: MediaProperty
  var pageId: String
  var margin: CGFloat = 80
  var isFullBleed = false
  var isFocusable = true
  @State var section: MediaPropertySection
  var items: [MediaPropertySectionItem] {
    section.content ?? []
  }

  var body: some View {
    VStack {
      ForEach(items, id: \.self) { item in
        MediaPropertyBanner(
          image: item.getBannerUrl(),
          margin: margin,
          isFullBleed: isFullBleed,
          isFocusable: isFocusable,
          action: {
            debugPrint("Banner clicked item ", item)

            let permission = section.resolvedPermissions
            if permission?.disable == true { return }
            let isUnauthorized = permission?.authorized == false
              && permission?.behavior != .showIfUnauthorized

            if item.type == "page_link" {
              guard let pageId = item.page_id?.nilIfEmpty() else { return }
              if isUnauthorized {
                Task {
                  do {
                    let url = try eluvio.fabric.createWalletPurchaseUrl(
                      id: section.id, propertyId: property.id, pageId: pageId,
                      permissionIds: permission?.permissionItemIds ?? [])
                    let params = HtmlParams(url: url, backgroundImage: property.backgroundImage)
                    router.path.append(.html(params))
                  } catch {
                    print("could not fetch page url for banner ", error.localizedDescription)
                  }
                }
              } else {
                let param = PropertyParam(propertyId: property.id, pageId: pageId)
                router.path.append(.property(param))
              }
            } else if item.type == "external_link" {
              if let url = item.url {
                let params = HtmlParams(url: url, backgroundImage: property.backgroundImage)
                router.path.append(.html(params))
              }
            } else if item.type == "subproperty_link" {
              if let subId = item.subproperty_id?.nilIfEmpty() {
                let param = PropertyParam(
                  propertyId: subId, pageId: item.subproperty_page_id)
                router.path.append(.property(param))
              }
            }
          })
      }
    }
  }
}

struct MediaPropertySectionView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  /// The page's own `card_theme_id`, which sections can override.
  var pageCardThemeId: String? = nil
  var margin: CGFloat = 80
  @State private var refreshId = ""

  var subsections: [MediaPropertySection] { section.sections_resolved ?? [] }

  var useScale = false
  var isFirstSection = false

  var inlineBackgroundUrl: String? {
    section.display?.inline_background_image?.url
  }
  var hasBackground: Bool { inlineBackgroundUrl?.nilIfEmpty() != nil }

  var title: String { section.displayTitle }

  var titleIcon: String { section.display?.title_icon?.url ?? "" }

  var isDisplayable: Bool { section.display?.display_format == "carousel" || isHero }

  var isRegular: Bool { !isHero && !isBanner && !isContainer }

  var isHero: Bool { section.display?.display_format == "hero" }

  var isBanner: Bool { section.display?.display_format == "banner" }

  var isContainer: Bool {
    if let type = section.type {
      return type.lowercased() == "container"
    }
    return false
  }

  var isGrid: Bool {
    return section.display?.display_format == "grid"
  }

  var isFullBleed: Bool {
    return section.display?.full_bleed == true
  }

  @State var logoUrl: String? = nil
  var logoText: String {
    return section.display?.logo_text ?? ""
  }

  @State var playerItem: AVPlayerItem? = nil

  var minHeight: CGFloat { hasBackground ? 420 : 400 }

  var heroItem: JSON? { section.hero_items?.array?.first }

  var heroPosition: SectionPosition {
    if let hero = heroItem {
      if hero["display"]["position"].stringValue == "Left" {
        return .Left
      } else if hero["display"]["position"].stringValue == "Right" {
        return .Right
      } else if hero["display"]["position"].stringValue == "Center" {
        return .Center
      }
    }

    return .Left
  }

  var heroLogoUrl: String {
    if let logo = heroItem?["display"]["logo"] {
      do {
        return try eluvio.fabric.getUrlFromLink(link: logo)
      } catch {
        return ""
      }
    }

    return ""
  }

  var heroTitle: String {
    heroItem?["display"]["title"].stringValue ?? ""
  }

  var heroDescription: String {
    heroItem?["display"]["description"].stringValue ?? ""
  }

  var heroActions: [HeroAction] {
    heroItem?["actions"].array?.compactMap { HeroAction.create(from: $0) } ?? []
  }

  var hAlignment: HorizontalAlignment {
    if let justification = section.display?.justification {
      if justification.lowercased() == "left" {
        return .leading
      }
      if justification.lowercased() == "right" {
        return .trailing
      }
      if justification.lowercased() == "center" {
        return .center
      }
    }

    return .leading
  }

  var alignment: Alignment {
    if let justification = section.display?.justification {
      if justification.lowercased() == "left" {
        return .leading
      }
      if justification.lowercased() == "right" {
        return .trailing
      }
      if justification.lowercased() == "center" {
        return .center
      }
    }

    return .leading
  }

  var permission: ResolvedPermission? { section.resolvedPermissions }

  var hide: Bool {
    if let permission = permission {
      if !permission.authorized && permission.hide {
        debugPrint("Section \(section.id) is hidden (permission)")
        return true
      }
    }

    if let content = section.content {
      if section.displayTitle == "Match Replays - 2024/25 EPCR Challenge Cup" {
        debugPrint("EMPTY CONTENT")
        debugPrint("subsections ", subsections)
        debugPrint("isHero ", isHero)
        debugPrint("content ", content.count)
        debugPrint("type ", section.type)
      }
      if (isRegular || isGrid) && content.count == 0 {
        return true
      }
    }
    if isContainer && subsections.isEmpty {
      return true
    } else {
      if isContainer {
        var hasContent = false
        for section in subsections {
          if section.content?.count ?? 0 > 0 {
            hasContent = true
          }
        }

        if !hasContent {
          return true
        }
      }
    }

    return section.display?.hide_on_tv == true
  }

  var forceAspectRatio: String {
    return section.display?.aspect_ratio ?? ""
  }

  var body: some View {
    Group {
      if !hide {
        if isHero {
          VStack(alignment: .leading, spacing: 0) {
            MediaPropertyHeader(
              logo: heroLogoUrl, title: heroTitle,
              description: heroDescription,
              position: heroPosition,
              margin: margin
            )

            if !heroActions.isEmpty {
              MediaPropertyHeroActions(
                property: property,
                pageId: pageId,
                section: section,
                actions: heroActions,
                margin: margin
              )
            }
          }
          .edgesIgnoringSafeArea([.leading, .trailing])
        } else if isBanner {
          MediaPropertySectionBannerView(
            property: property,
            pageId: pageId,
            margin: margin,
            isFullBleed: isFullBleed,
            isFocusable: !isFirstSection,
            section: section
          )
          .edgesIgnoringSafeArea([.leading, .trailing])
        } else if isContainer {
          VStack(alignment: .leading, spacing: 0) {
            VStack(alignment: hAlignment, spacing: 5) {
              if !section.hideTitle, !section.displayTitle.isEmpty {
                HStack(alignment: .center, spacing: 20) {
                  if !titleIcon.isEmpty {
                    ScaledWebImage(url: titleIcon, height: 60)
                      .resizable()
                      .aspectRatio(contentMode: .fit)
                      .frame(width: 60, height: 60)
                  }

                  Text(section.displayTitle).font(.sectionContainerTitle)
                    .frame(maxWidth: .infinity, alignment: alignment)
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
              }

              if !section.displaySubtitle.isEmpty {
                Text(section.displaySubtitle).font(.sectionContainerSubtitle)
                  .frame(maxWidth: .infinity, alignment: alignment)
              }
            }
            .padding([.leading, .trailing], margin + 10)
            .padding(.top, 40)
            .padding(.bottom, 10)

            ForEach(subsections.filter { !$0.shouldHideInContainer }) { sub in
              MediaPropertyRegularSectionView(
                property: property, pageId: pageId, section: sub,
                pageCardThemeId: pageCardThemeId, margin: margin,
                useScale: useScale, lookForBackground: true)
            }
          }
        } else if isGrid {
          MediaPropertySectionGridView(
            property: property, pageId: pageId, section: section,
            pageCardThemeId: pageCardThemeId, margin: margin,
            useScale: useScale)
        } else {
          MediaPropertyRegularSectionView(
            property: property,
            pageId: pageId,
            section: section,
            pageCardThemeId: pageCardThemeId,
            margin: margin,
            useScale: useScale
          )
        }
      }
    }
    .clipped()
    .background(
      Group {
        if let url = inlineBackgroundUrl {
          ScaledWebImage(url: url, height: UIScreen.main)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .zIndex(-10)
        }
      }
      .frame(maxWidth: .infinity)
      .clipped()
    )
    .focusSection()
  }
}

struct MediaPropertyHeader: View {
  @Namespace var NamespaceProperty
  var logo: String = ""
  var title: String = ""
  var description: String = ""
  var position: SectionPosition = .Left
  var margin: CGFloat = 80
  var horizontalAlignment: HorizontalAlignment {
    if position == .Left {
      return .leading
    } else if position == .Right {
      return .trailing
    } else if position == .Center {
      return .center
    }

    return .leading
  }

  var alignment: Alignment {
    if position == .Left {
      return .leading
    } else if position == .Right {
      return .trailing
    } else if position == .Center {
      return .center
    }

    return .leading
  }

  var hasOnlyImage: Bool {
    return !logo.isEmpty && title.isEmpty && description.isEmpty
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      ScaledWebImage(url: logo, height: 180)
        .resizable()
        .scaledToFit()
        // Cap the width so very wide logos scale down instead of running off
        // the screen (matches Android).
        .frame(maxWidth: UIScreen.main.bounds.width * 0.7, alignment: alignment)
        .frame(height: 180, alignment: alignment)

      if !title.isEmpty {
        Text(title).font(.title3)
          .foregroundColor(Color.white)
          .fontWeight(.bold)
          .frame(maxWidth: 1100, alignment: alignment)
          .padding(.top, 60)
      }

      if !description.isEmpty {
        Text(description)
          .foregroundColor(Color.white)
          .font(.propertyDescription)
          .frame(width: 900, alignment: alignment)
          .frame(minHeight: 130)
          .lineLimit(4)
          .padding(.top, 30)
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding([.leading, .trailing], margin + 15)  // FIXME: there's a padding in the other sections for some reason
    .padding([.bottom], hasOnlyImage ? 10 : 20)
    .padding([.top], hasOnlyImage ? 10 : 95)
  }
}

/// The row of CTA buttons defined by a hero item's actions.
struct MediaPropertyHeroActions: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  var actions: [HeroAction]
  var margin: CGFloat = 80

  /// media_link actions only carry the id of their target, so the media items
  /// they point to have to be fetched separately before we can figure out
  /// where the button should navigate to.
  private var heroActionMedia: [String: MediaPropertySectionMediaItem] {
    let items = MediaItemStore.shared.observeMediaItems(ids: actions.compactMap(\.mediaId))
    return Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  }

  var body: some View {
    HStack(alignment: .center, spacing: 24) {
      ForEach(actions) { action in
        // A media_link button whose media hasn't arrived yet isn't rendered,
        // so it appears once fetched rather than misbehaving when clicked.
        if action.behavior != "media_link" || heroActionMedia[action.mediaId ?? ""] != nil {
          HeroActionButton(action: action, onClick: { handleClick(action) })
        }
      }
    }
    .frame(maxWidth: .infinity, alignment: .leading)
    .padding([.leading, .trailing], margin + 15)
    .padding(.bottom, 40)
    .focusSection()
    .task {
      await MediaItemStore.shared.fetchMediaItems(
        propertyId: property.id,
        ids: actions.compactMap(\.mediaId),
        parentPermissions: section.resolvedPermissions,
        permissionStates: property.permission_auth_state ?? [:])
    }
  }

  private func handleClick(_ action: HeroAction) {
    debugPrint("Hero action clicked ", action.id)
    switch action.behavior {
    case "media_link":
      // Delegate to the media item, so live/upcoming/unauthorized media are
      // handled the same way they are when clicked from a carousel.
      guard let media = heroActionMedia[action.mediaId ?? ""] else { return }
      Task {
        await handleSectionItemTap(
          router: router, eluvio: eluvio,
          property: property, pageId: pageId, sectionId: section.id,
          viewItem: MediaPropertySectionMediaItemViewModel.create(media: media))
      }
    case "page_link":
      guard let pageId = action.pageId else { return }
      let param = PropertyParam(propertyId: property.id, pageId: pageId)
      router.path.append(.property(param))
    case "link":
      guard let url = action.url else { return }
      let params = HtmlParams(url: url, backgroundImage: property.backgroundImage)
      router.path.append(.html(params))
    default:
      break
    }
  }
}

struct HeroActionButton: View {
  var action: HeroAction
  var onClick: () -> Void
  @FocusState var isFocused

  var body: some View {
    Button(
      action: onClick,
      label: {
        Text(action.text).font(.system(size: 28)).bold()
      }
    )
    .buttonStyle(
      HeroActionButtonStyle(
        focused: isFocused,
        backgroundColor: action.backgroundColor,
        textColor: action.textColor,
        borderColor: action.borderColor,
        cornerRadius: action.cornerRadius)
    )
    .focused($isFocused)
  }
}

// MARK: - SwiftUI Previews

#Preview("Hero Action Buttons") {
  HStack(spacing: 24) {
    HeroActionButton(
      action: HeroAction(
        id: "1",
        behavior: "link",
        text: "WATCH NOW",
        backgroundColor: Color(hex: 0x75FF61),
        textColor: Color(hex: 0x103234),
        borderColor: nil,
        cornerRadius: 5
      ), onClick: {})
    HeroActionButton(
      action: HeroAction(
        id: "2",
        behavior: "link",
        text: "MORE INFO",
        backgroundColor: .white,
        textColor: .black,
        borderColor: .black,
        cornerRadius: 20
      ), onClick: {})
  }
  .padding()
  .background(Color.black)
}

#Preview("View All Button") {
  ViewAllButton(action: {})
    .padding()
    .background(Color.black)
}

#Preview("Media Property Header") {
  MediaPropertyHeader(
    logo: "https://picsum.photos/180/180",
    title: "Sample Property Title",
    description: "This is a sample description for the property header section."
  )
  .environmentObject(EluvioAPI())
  .background(Color.black)
}

struct MediaPropertyBanner: View {
  @Namespace var NamespaceProperty
  var image: String = ""
  var imageURL: String {
    return image + "&width=600"
  }

  var margin: CGFloat = 80
  var isFullBleed = false
  var isFocusable = true
  var action: () -> Void
  @FocusState var isFocused: Bool
  @State var opacity: CGFloat = 0

  var body: some View {
    if !image.isEmpty {
      if isFocusable {
        Button(
          action: action,
          label: {
            HStack(alignment: .center) {
              // Height shouldn't actually reach full screen height, this is
              // just an upper bound to prevent downloading insanely large images
              ScaledWebImage(url: image, height: UIScreen.main)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .edgesIgnoringSafeArea(.horizontal)
                .frame(maxWidth: .infinity)
            }
          }
        )
        .clipped()
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding([.leading, .trailing], isFullBleed ? 0 : margin)
        .padding([.top, .bottom], isFullBleed ? 0 : 40)
        .buttonStyle(BannerButtonStyle(focused: isFocused, scale: 1.0, bordered: false))
        .focused($isFocused)
        .opacity(isFocused ? 1.0 : 0.6)
      } else {
        HStack(alignment: .center) {
          // Height shouldn't actually reach full screen height, this is
          // just an upper bound to prevent downloading insanely large images
          ScaledWebImage(url: image, height: UIScreen.main)
            .resizable()
            .aspectRatio(contentMode: isFullBleed ? .fill : .fit)
            .edgesIgnoringSafeArea(.horizontal)
            .frame(maxWidth: .infinity)
            .padding([.leading, .trailing], isFullBleed ? 0 : margin)
            .padding([.top, .bottom], isFullBleed ? 0 : 40)
        }
      }
    } else {
      EmptyView()
    }
  }
}
