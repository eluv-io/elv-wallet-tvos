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
  var margin: CGFloat = 80
  var useScale = false

  @State var items: [MediaPropertySectionMediaItemViewModel] = []

  var forceDisplay: AspectRatio? = nil
  var showBackground = true
  var topPadding: CGFloat = 10

  @State var inlineBackgroundUrl: String? = nil
  var hasBackground: Bool {
    if let background = inlineBackgroundUrl {
      if !background.isEmpty {
        return true
      }
    }

    return false
  }

  var aspectRatio: AspectRatio {
    forceDisplay ?? items.first?.thumb_aspect_ratio ?? .square
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

  var scale: CGFloat {
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

  private let gridSpacing: CGFloat = 20

  private var itemMaxWidth: CGFloat {
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

  private var gridAlignment: HorizontalAlignment {
    switch section.displayJustification.lowercased() {
    case "center": .center
    case "right": .trailing
    default: .leading
    }
  }

  // Columns that fit the measured width, capped at the item count so the grid
  // shrink-wraps its content. The parent VStack then aligns the block per
  // gridAlignment (leading reproduces the original full-width layout).
  private var columnCount: Int {
    guard width > 0 else { return 1 }
    let fit = max(1, Int((width + gridSpacing) / (itemMaxWidth + gridSpacing)))
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

      LazyVGrid(columns: columns, alignment: .center, spacing: gridSpacing) {
        ForEach(items, id: \.self) { item in
          SectionItemView(
            sectionId: section.id,
            pageId: pageId,
            property: property,
            forceDisplay: aspectRatio,
            titleAlignment: titleAlignment,
            viewItem: item,
            scaleFactor: scale
          )
          .padding(.bottom, 40)
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
        if showBackground {
          if let url = inlineBackgroundUrl {
            ScaledWebImage(url: url, height: UIScreen.main)
              .resizable()
              .aspectRatio(contentMode: .fill)
              .frame(maxWidth: .infinity)
              .clipped()
              .zIndex(-10)
          }
        }
      }
      .frame(maxWidth: .infinity)
    )
    .padding([.leading], margin)
    .task {
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
