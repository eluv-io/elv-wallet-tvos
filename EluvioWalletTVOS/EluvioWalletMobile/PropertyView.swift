import EluvioCore
import SwiftUI

/// Post-auth property landing — renders the property's first authorized page
/// as a vertical scroll of hero banners and horizontally-scrolling section
/// rows. Section items don't yet navigate anywhere; tapping prints the item id
/// for now.
struct PropertyView: View {
  let property: MediaProperty

  @State private var page: MediaPropertyPage?
  @State private var sections: [MediaPropertySection] = []
  @State private var loading = true
  @State private var playingItem: MediaPropertySectionMediaItem?

  var body: some View {
    Group {
      if loading {
        ProgressView()
          .frame(maxWidth: .infinity, maxHeight: .infinity)
      } else if sections.isEmpty {
        ContentUnavailableView(
          "No Content",
          systemImage: "tray",
          description: Text("This property has no sections available to your account.")
        )
      } else {
        ScrollView {
          LazyVStack(alignment: .leading, spacing: 24) {
            ForEach(sections) { section in
              if section.display?.display_format == "hero" {
                PropertyHeroView(
                  property: property, section: section,
                  onPlay: { playingItem = $0 })
              } else {
                SectionRow(section: section, onTap: handleTap)
              }
            }
          }
          .padding(.bottom, 16)
        }
      }
    }
    .navigationTitle(property.displayName)
    .navigationBarTitleDisplayMode(.inline)
    .task { await load() }
    .navigationDestination(item: $playingItem) { mediaItem in
      MobileVideoPlayerView(property: property, mediaItem: mediaItem)
    }
  }

  private func handleTap(_ item: MediaPropertySectionItem) {
    // Gated items shouldn't navigate — they need a purchase/alt-page flow
    // that we haven't wired up yet. Surface the gate state until then.
    if item.isInaccessible {
      print("Tap ignored — item is inaccessible: id=\(item.id ?? "?") perm=\(String(describing: item.resolvedPermissions))")
      return
    }
    guard let media = item.media else { return }
    if media.media_type?.lowercased() == "video" {
      playingItem = media
    }
    // Non-video media types (gallery, html, image) aren't wired up yet.
  }

  private func load() async {
    do {
      let page = try await PropertyStore.shared.getFirstAuthorizedPage(property: property)
      await PropertyStore.shared.fetchSections(property: property, page: page)
      self.page = page
      self.sections = PropertyStore.shared.sections(for: page)
        .filter { !$0.shouldHideInContainer }
    } catch {
      print("PropertyView load failed:", error)
    }
    loading = false
  }
}

private struct SectionRow: View {
  let section: MediaPropertySection
  let onTap: (MediaPropertySectionItem) -> Void

  var items: [MediaPropertySectionItem] {
    (section.content ?? [])
      .filter { $0.resolvedPermissions?.hide != true }
  }

  /// A section can force the shape of every card in its row.
  var sectionRatio: AspectRatio? {
    AspectRatio(section.display?.aspect_ratio)
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 8) {
      if !section.displayTitle.isEmpty {
        Text(section.displayTitle)
          .font(.title3.bold())
          .padding(.horizontal, 16)
      }
      if !section.displaySubtitle.isEmpty {
        Text(section.displaySubtitle)
          .font(.subheadline)
          .foregroundStyle(.secondary)
          .padding(.horizontal, 16)
      }

      ScrollView(.horizontal, showsIndicators: false) {
        HStack(alignment: .top, spacing: 12) {
          ForEach(items) { item in
            Button {
              onTap(item)
            } label: {
              SectionItemCard(item: item, sectionRatio: sectionRatio)
            }
            .buttonStyle(.plain)
            .contentShape(.rect)
          }
        }
        .padding(.horizontal, 16)
      }
    }
  }
}

private struct SectionItemCard: View {
  let item: MediaPropertySectionItem
  let sectionRatio: AspectRatio?

  private var resolved: (thumbnail: String, ratio: AspectRatio) {
    item.thumbnailAndRatio(sectionRatio: sectionRatio)
  }

  /// Portrait cards are taller and landscape ones shorter, so that a row of
  /// either still reads at roughly the same width. Mirrors tvOS `MediaCard`.
  private var height: CGFloat {
    switch resolved.ratio {
    case .square: 160
    case .portrait: 240
    case .landscape: 135
    }
  }

  private var width: CGFloat { height * resolved.ratio.value }

  var imageUrl: String? {
    resolved.thumbnail.nilIfEmpty()
      ?? item.banner_image_mobile?.url?.nilIfEmpty()
      ?? item.banner_image?.url?.nilIfEmpty()
  }

  var title: String {
    item.display?.title?.nilIfEmpty()
      ?? item.media?.title?.nilIfEmpty()
      ?? item.label?.nilIfEmpty()
      ?? ""
  }

  /// Live and upcoming streams get a badge in the bottom corner of the card,
  /// the way tvOS `MediaCard` draws them.
  @ViewBuilder private var statusBadge: some View {
    if let media = item.media {
      if media.isUpcoming {
        VStack(spacing: 1) {
          Text("UPCOMING")
          Text(media.startDateTimeString)
        }
        .font(.caption2)
        .foregroundStyle(.white)
        .padding(.vertical, 3)
        .padding(.horizontal, 6)
        .background(RoundedRectangle(cornerRadius: 4).fill(.black.opacity(0.6)))
      } else if media.currentlyLive {
        Text("LIVE")
          .font(.caption2.bold())
          .foregroundStyle(.white)
          .padding(.vertical, 3)
          .padding(.horizontal, 6)
          .background(RoundedRectangle(cornerRadius: 4).fill(.red))
      }
    }
  }

  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      Group {
        if let imageUrl {
          ScaledWebImage(url: imageUrl, height: height)
            .resizable()
            .aspectRatio(contentMode: .fill)
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
            .overlay(
              Image(systemName: "photo")
                .foregroundStyle(.secondary)
            )
        }
      }
      .frame(width: width, height: height)
      .overlay {
        if item.isInaccessible {
          Color.black.opacity(0.6)
        }
      }
      .overlay(alignment: .bottomTrailing) {
        statusBadge.padding(6)
      }
      .clipShape(RoundedRectangle(cornerRadius: 8))

      if !title.isEmpty {
        Text(title)
          .font(.caption)
          .foregroundStyle(.primary)
          .lineLimit(2)
          .frame(width: width, alignment: .leading)
      }
    }
  }
}
