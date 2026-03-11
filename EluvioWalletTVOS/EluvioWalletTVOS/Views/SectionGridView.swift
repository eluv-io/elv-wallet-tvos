//
//  SectionGridView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-24.
//

import SwiftUI
import SwiftyJSON

struct SectionGridView: View {
  var property: MediaProperty
  var pageId: String
  var section: MediaPropertySection
  var margin: CGFloat = 80
  var useScale = false

  @State var items: [MediaPropertySectionMediaItemViewModel] = []

  var forceDisplay: MediaDisplay? = nil
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

  var display: MediaDisplay {
    if let force = forceDisplay {
      return force
    }
    if let item = items.first {
      if item.thumb_aspect_ratio == .portrait {
        return .feature
      } else if item.thumb_aspect_ratio == .landscape {
        return .video
      } else {
        return .square
      }
    }
    return .square
  }

  var title: String {
    return section.displayTitle
  }

  var scale: CGFloat {
    if !useScale {
      return 1.0
    }

    if display == .square {
      return 0.8
    } else {
      return 0.7
    }
  }

  @State var width: CGFloat = 0

  private var columns: [GridItem] {
    if !useScale {
      if display == .square {
        return [
          .init(.adaptive(minimum: 280, maximum: 300))
        ]
      } else if display == .feature {
        return [
          .init(.adaptive(minimum: 300, maximum: 320))
        ]
      } else {
        return [
          .init(.adaptive(minimum: 400, maximum: 420))
        ]
      }
    }

    if display == .square {
      return [
        .init(.adaptive(minimum: 200, maximum: 240))
      ]
    } else if display == .feature {
      return [
        .init(.adaptive(minimum: 240, maximum: 260))
      ]
    } else {
      return [
        .init(.adaptive(minimum: 260, maximum: 280))
      ]
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 0) {
      HStack {
        if !title.isEmpty {
          Text(title)
            .font(.rowTitle)
          Spacer()
        }
      }
      .padding(.top, topPadding)
      .padding(.bottom, 20)

      LazyVGrid(columns: columns, alignment: .leading, spacing: 20) {
        ForEach(items, id: \.self) { item in
          SectionItemView(
            sectionId: section.id,
            pageId: pageId,
            property: property,
            forceDisplay: display,
            viewItem: item,
            scaleFactor: scale
          )
          .padding(.bottom, 40)
        }
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
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
