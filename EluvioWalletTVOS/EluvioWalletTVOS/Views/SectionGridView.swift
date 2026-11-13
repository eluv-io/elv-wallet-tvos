//
//  SectionGridView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-24.
//

import EluvioCore
import SwiftUI
import SwiftyJSON

struct SectionGridView: View {
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  var pageCardThemeId: String? = nil
  var margin: CGFloat = 80
  var useScale = false

  @State var items: [MediaPropertySectionMediaItemViewModel] = []

  var forceDisplay: AspectRatio? = nil
  var showBackground = true
  var topPadding: CGFloat = 10
  var gridSpacing: CGFloat = 34
  var fixedColumnCount: Int? = nil
  /// See MediaGridView.lazy
  var lazy = true

  @State var inlineBackgroundUrl: String? = nil
  var hasBackground: Bool {
    if let background = inlineBackgroundUrl {
      if !background.isEmpty {
        return true
      }
    }

    return false
  }

  var title: String {
    return section.displayTitle
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

  private var gridAlignment: HorizontalAlignment {
    switch section.displayJustification.lowercased() {
    case "center": .center
    case "right": .trailing
    default: .leading
    }
  }

  var body: some View {
    MediaGridView(
      property: property, pageId: pageId, sectionId: section.id,
      title: title, items: items,
      titleAlignment: titleAlignment, gridAlignment: gridAlignment,
      cardTheme: cardTheme, showItemTitles: showItemTitles,
      forceDisplay: forceDisplay, useScale: useScale,
      margin: margin, topPadding: topPadding,
      backgroundUrl: showBackground ? inlineBackgroundUrl : nil,
      gridSpacing: gridSpacing, fixedColumnCount: fixedColumnCount, lazy: lazy
    )
    // Keyed on section so the grid reloads when the same view instance is
    // handed a different section (e.g. SearchView's single-section layout).
    .task(id: section) {
      guard let content = section.content else { return }
      items =
        content
        .prefix(100)
        .filter { $0.resolvedPermissions?.hide != true }
        .map { MediaPropertySectionMediaItemViewModel.create(item: $0) }
      if showBackground {
        inlineBackgroundUrl = section.display?.inline_background_image?.url
      }
    }
  }
}

/// A media list's contents as a MediaGridView - the media list counterpart of SectionGridView.
struct MediaListGridView: View {
  var property: MediaProperty
  var mediaItemIds: [String]
  var title: String = ""
  var parentMediaItem: MediaPropertySectionMediaItem

  private var items: [MediaPropertySectionMediaItem] {
    MediaItemStore.shared.observeMediaItems(ids: mediaItemIds)
  }

  var body: some View {
    MediaGridView(
      property: property, mediaListId: parentMediaItem.id, title: title,
      items: items
        .filter { $0.resolvedPermissions?.hide != true }
        .map { MediaPropertySectionMediaItemViewModel.create(media: $0) },
      topPadding: 40
    )
    .focusSection()
    .task {
      await MediaItemStore.shared.fetchMediaItems(
        propertyId: property.id,
        ids: mediaItemIds,
        parentPermissions: parentMediaItem.resolvedPermissions,
        permissionStates: property.permission_auth_state ?? [:])
    }
  }
}

/// A titled grid of media cards - the page behind both a section's View All and a media
/// list. Callers turn their own content into view items; this only lays them out.
struct MediaGridView: View {
  var property: MediaProperty
  var pageId: String = ""
  var sectionId: String = ""
  /// Set when these items are the contents of a media list, which autoplay needs to know
  var mediaListId: String = ""
  var title: String
  var items: [MediaPropertySectionMediaItemViewModel]
  var titleAlignment: Alignment = .leading
  var gridAlignment: HorizontalAlignment = .leading
  var cardTheme: CardTheme? = nil
  var showItemTitles = true
  var forceDisplay: AspectRatio? = nil
  var useScale = false
  var margin: CGFloat = 80
  var topPadding: CGFloat = 10
  var backgroundUrl: String? = nil
  var gridSpacing: CGFloat = 34
  /// Overrides the width-based column count and sizes the cards to fill the width;
  /// still capped at the item count
  var fixedColumnCount: Int? = nil
  /// Build cards only as they near the screen. Turn off for a grid that sits on a scrolling
  /// page below other rows: the focus engine can only move to cards that exist, so if the
  /// grid's first row is just off screen, Down from the row above has nowhere to go.
  var lazy = true

  var aspectRatio: AspectRatio {
    forceDisplay ?? items.first?.thumb_aspect_ratio ?? .square
  }

  var scale: CGFloat {
    // A fixed column count grows the cards to fill their columns
    if fixedColumnCount != nil, width > 0 {
      let naturalWidth =
        MediaCard.baseHeight(cardSize: .medium, aspectRatio: aspectRatio) * aspectRatio.value
      return itemMaxWidth / naturalWidth
    }

    if !useScale {
      return 1.0
    }

    if aspectRatio == .square {
      return 0.8
    } else {
      return 0.7
    }
  }

  @State var width: CGFloat = 0

  private var itemMaxWidth: CGFloat {
    if let fixedColumnCount, width > 0 {
      let gaps = CGFloat(fixedColumnCount - 1) * gridSpacing
      return ((width - gaps) / CGFloat(fixedColumnCount)).rounded(.down)
    }
    if !useScale {
      switch aspectRatio {
      case .square: return 245
      case .portrait: return 320
      default: return 420
      }
    }
    switch aspectRatio {
    case .square: return 240
    case .portrait: return 260
    default: return 280
    }
  }

  // Columns that fit the measured width, capped at the item count so the grid
  // shrink-wraps its content. The parent VStack then aligns the block per
  // gridAlignment (leading reproduces the original full-width layout).
  private var columnCount: Int {
    guard width > 0 else { return 1 }
    let fit =
      fixedColumnCount ?? max(1, Int((width + gridSpacing) / (itemMaxWidth + gridSpacing)))
    return min(fit, max(1, items.count))
  }

  // Width of the column block; centering it in the parent splits the leftover
  // space equally on leading and trailing.
  private var contentWidth: CGFloat {
    CGFloat(columnCount) * itemMaxWidth + CGFloat(columnCount - 1) * gridSpacing
  }

  // Fixed widths so the rendered layout matches contentWidth exactly
  // (adaptive packs at the minimum and would disagree).
  // Using .adaptive won't allow us to center/right align the grid content
  private var columns: [GridItem] {
    Array(repeating: GridItem(.fixed(itemMaxWidth), spacing: gridSpacing), count: columnCount)
  }

  private func card(_ item: MediaPropertySectionMediaItemViewModel) -> some View {
    SectionItemView(
      sectionId: sectionId,
      pageId: pageId,
      property: property,
      forceDisplay: aspectRatio,
      titleAlignment: titleAlignment,
      cardTheme: cardTheme,
      showItemTitle: showItemTitles,
      viewItem: item,
      mediaListId: mediaListId,
      scaleFactor: scale
    )
    .padding(.bottom, 40)
  }

  var body: some View {
    VStack(alignment: gridAlignment, spacing: 0) {
      HStack {
        if !title.isEmpty {
          Text(title)
            .font(.rowTitle)
          Spacer()
        }
      }
      .padding(.top, topPadding)
      .padding(.bottom, 20)

      Group {
        if lazy {
          LazyVGrid(columns: columns, alignment: .center, spacing: gridSpacing) {
            ForEach(items, id: \.self) { card($0) }
          }
        } else {
          // Same layout as the LazyVGrid: fixed-width columns, cards centered in them,
          // a short last row starting at the left.
          VStack(alignment: .leading, spacing: gridSpacing) {
            ForEach(Array(stride(from: 0, to: items.count, by: columnCount)), id: \.self) { start in
              HStack(spacing: gridSpacing) {
                ForEach(items[start..<min(start + columnCount, items.count)], id: \.self) {
                  card($0).frame(width: itemMaxWidth)
                }
              }
            }
          }
        }
      }
      .frame(width: width > 0 ? contentWidth : nil)
    }
    .frame(
      maxWidth: .infinity,
      maxHeight: .infinity,
      alignment: Alignment(horizontal: gridAlignment, vertical: .center)
    )
    // Measures the available width so the grid can shrink to its content width
    // and be centered by the parent VStack (see columnCount / contentWidth).
    .background(
      GeometryReader { proxy in
        Color.clear
          .onChange(of: proxy.size.width, initial: true) { _, newValue in width = newValue }
      }
    )
    .background(
      Group {
        if let url = backgroundUrl {
          ScaledWebImage(url: url, height: UIScreen.main)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(maxWidth: .infinity)
            .clipped()
            .zIndex(-10)
        }
      }
      .frame(maxWidth: .infinity)
    )
    .padding([.leading], margin)
  }
}
