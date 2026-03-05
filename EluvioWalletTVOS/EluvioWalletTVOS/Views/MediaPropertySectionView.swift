//
//  MediaPropertySectionView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-24.
//

import AVFoundation
import Foundation
import SDWebImageSwiftUI
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

enum SectionPosition {
  case Left, Right, Center
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
          WebImage(url: URL(string: url))
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 180, height: 180)
          Text(logoText)
            .font(.sectionLogoText)
        }
        .padding(.leading, margin)
      }

      SectionGridView(
        property: property, pageId: pageId, section: section, margin: margin,
        useScale: useScale, showBackground: false)
    }
    /*
     .background(
         Group {
             if let url = inlineBackgroundUrl {
                 WebImage(url:URL(string:url))
                     .resizable()
                     .aspectRatio(contentMode: .fill)
                     .frame(maxWidth: .infinity)
                     .clipped()
                     .zIndex(-10)
             }
         }
         .frame(maxWidth: .infinity)
     )
      */
    .clipped()
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .onAppear {
      if self.refreshId == eluvio.refreshId {
        return
      }

      self.refreshId = eluvio.refreshId

      if let display = section.display {
        logoUrl = display.logo?.url
        /*
         do {
             inlineBackgroundUrl = try eluvio.fabric.getUrlFromLink(link: display["inline_background_image"])
         }catch{}
          */
      }
    }
  }
}

struct MediaPropertyRegularSectionView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  @EnvironmentObject var router: Router
  @Namespace var SectionNamespace
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  var margin: CGFloat = 80
  @State private var refreshId = ""
  @State var items: [MediaPropertySectionMediaItemViewModel] = []
  // private let refreshTimer = Timer.publish(every: 60, on: .main, in: .common).autoconnect()
  @FocusState private var currentFocusItem: MediaPropertySectionMediaItemViewModel?
  @State private var lastFocusItem: MediaPropertySectionMediaItemViewModel?
  var useScale = false
  var scaleFactor: CGFloat = 0.7
  var lookForBackground = false

  var showViewAll: Bool {
    if let sectionItems = section.content {
      if sectionItems.count > 5
        || (sectionItems.count > section.displayLimit && section.displayLimit > 0)
      {
        return true
      }
    }

    return false
  }

  var title: String {
    return section.displayTitle
  }

  var titleIcon: String {
    return section.display?.title_icon?.url ?? ""
  }

  var isDisplayable: Bool {
    if section.display?.display_format == "carousel" {
      return true
    }

    return false
  }

  @State var logoUrl: String? = nil
  var logoText: String {
    return section.display?.logo_text ?? ""
  }

  @State var inlineBackgroundUrl: String? = nil
  var hasBackground: Bool {
    if let background = inlineBackgroundUrl {
      if !background.isEmpty {
        return true
      }
    }

    return false
  }

  var minHeight: CGFloat {
    if hasBackground {
      return 420
    }

    return 400
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

  var forceAspectRatio: String {
    return section.display?.aspect_ratio ?? ""
  }

  var body: some View {
    ZStack(alignment: .leading) {
      HStack(alignment: .center) {
        if items.isEmpty {
          EmptyView()
        } else {
          if let url = logoUrl {
            VStack(spacing: 20) {
              WebImage(url: URL(string: url))
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
                  WebImage(url: URL(string: titleIcon))
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width: 60, height: 60)
                }
                if !section.displayTitle.isEmpty {
                  Text(section.displayTitle).font(.rowTitle)
                    .frame(alignment: alignment)
                }

                if showViewAll {
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
            WebImage(url: URL(string: url))
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
    .task {
      await refresh()
    }
  }

  func refresh() async {
    debugPrint("MediaPropertyRegularSectionView refresh() ", section.displayTitle)

    if let display = section.display {
      logoUrl = display.logo?.url

      if lookForBackground {
        inlineBackgroundUrl = display.inline_background_image?.url
      }
    }

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
            if item.type == "page_link" {
              Task {
                do {
                  debugPrint("Banner clicked page link ")
                  let permission = section.resolvedPermissions!

                  if let content = section.content {
                    if let pageId = content[0].page_id {
                      if !pageId.isEmpty {
                        let url = try eluvio.fabric.createWalletPurchaseUrl(
                          id: section.id, propertyId: property.id, pageId: pageId,
                          permissionIds: permission.permissionItemIds)
                        debugPrint("URL ", url)

                        let backgroundImage = property.backgroundImage

                        let params = HtmlParams(url: url, backgroundImage: backgroundImage)
                        router.path.append(.html(params))
                      }
                    }
                  }

                } catch {
                  print("could not fetch page url for banner ", error.localizedDescription)
                }
              }
            } else if item.type == "external_link" {
              Task {
                debugPrint("Banner clicked external link")

                if let url = item.url {
                  let params = HtmlParams(url: url, backgroundImage: property.backgroundImage)
                  router.path.append(.html(params))
                }
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
  @State var section: MediaPropertySection
  var margin: CGFloat = 80
  @State private var refreshId = ""

  var subsections: [MediaPropertySection] { section.sections_resolved ?? [] }

  var useScale = false
  var isFirstSection = false

  @State var inlineBackgroundUrl: String? = nil
  var hasBackground: Bool {
    if let background = inlineBackgroundUrl {
      if !background.isEmpty {
        return true
      }
    }

    return false
  }

  var showViewAll: Bool {
    if let sectionItems = section.content {
      if sectionItems.count > 5
        || (sectionItems.count > section.displayLimit && section.displayLimit > 0)
      {
        return true
      }
    }

    return false
  }

  var title: String {
    return section.displayTitle
  }

  var titleIcon: String {
    return section.display?.title_icon?.url ?? ""
  }

  var isDisplayable: Bool {
    return section.display?.display_format == "carousel" || isHero
  }

  var isRegular: Bool {
    return !isHero && !isBanner && !isContainer
  }

  var isHero: Bool {
    return section.display?.display_format == "hero"
  }

  var isBanner: Bool {
    return section.display?.display_format == "banner"
  }

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

  var minHeight: CGFloat {
    if hasBackground {
      return 420
    }

    return 400
  }

  var heroPosition: SectionPosition {
    if let items = section.hero_items?.arrayValue {
      if !items.isEmpty {
        if items[0]["display"]["position"].stringValue == "Left" {
          return .Left
        } else if items[0]["display"]["position"].stringValue == "Right" {
          return .Right
        } else if items[0]["display"]["position"].stringValue == "Center" {
          return .Center
        }
      }
    }

    return .Left
  }

  var heroLogoUrl: String {
    if let items = section.hero_items?.arrayValue {
      if !items.isEmpty {
        do {
          return try eluvio.fabric.getUrlFromLink(link: items[0]["display"]["logo"])
        } catch {
          return ""
        }
      }
    }

    return ""
  }

  var heroTitle: String {
    if let items = section.hero_items?.arrayValue {
      if !items.isEmpty {
        return items[0]["display"]["title"].stringValue
      }
    }
    return ""
  }

  var heroDescription: String {
    if let items = section.hero_items?.arrayValue {
      if !items.isEmpty {
        return items[0]["display"]["description"].stringValue
      }
    }
    return ""
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

  var disable: Bool {
    if let permission = permission {
      return !permission.authorized && permission.disable
    }
    return false
  }

  var forceAspectRatio: String {
    return section.display?.aspect_ratio ?? ""
  }

  var body: some View {
    Group {
      if !hide {
        if isHero {
          MediaPropertyHeader(
            logo: heroLogoUrl, title: heroTitle,
            description: heroDescription,
            position: heroPosition,
            margin: margin
          )
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
              if !section.displayTitle.isEmpty {
                HStack(alignment: .center, spacing: 20) {
                  if !titleIcon.isEmpty {
                    WebImage(url: URL(string: titleIcon))
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

            ForEach(subsections) { sub in
              MediaPropertyRegularSectionView(
                property: property, pageId: pageId, section: sub, margin: margin,
                useScale: useScale, lookForBackground: true)
            }
          }
        } else if isGrid {
          MediaPropertySectionGridView(
            property: property, pageId: pageId, section: section, margin: margin,
            useScale: useScale)
        } else {
          MediaPropertyRegularSectionView(
            property: property,
            pageId: pageId,
            section: section,
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
          WebImage(url: URL(string: url))
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
    .disabled(disable)
    .focusSection()
    .onAppear {
      refresh()
    }
  }

  func refresh() {
    debugPrint("MediaPropertySectionView section ", section.displayTitle)
    debugPrint("section isHero ", isHero)
    debugPrint("section isBanner ", isBanner)
    debugPrint("number of contents: ", section.content?.count)

    inlineBackgroundUrl = section.display?.inline_background_image?.url
  }
}

struct MediaPropertyHeader: View {
  @Namespace var NamespaceProperty
  @EnvironmentObject var eluvio: EluvioAPI
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
      WebImage(url: URL(string: logo))
        .resizable()
        .scaledToFit()
        .frame(height: 180, alignment: alignment)
      // .frame(maxWidth:.infinity)
      // .clipped()

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
          .frame(width: 1200, alignment: alignment)
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

// MARK: - SwiftUI Previews

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
  @EnvironmentObject var eluvio: EluvioAPI
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
              WebImage(url: URL(string: image))
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
          WebImage(url: URL(string: image))
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
