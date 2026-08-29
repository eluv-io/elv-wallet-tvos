import EluvioCore
import SwiftUI

/// Per-property search, reached from the magnifier in `PropertyView`'s nav bar.
/// Mirrors the tvOS `SearchView`: a search term plus optional primary/secondary
/// filter chips, all fed to the same `PropertySearchStore` endpoint. Results
/// come back as regular sections, so they render with the same cards the
/// property page uses.
struct MobileSearchView: View {
  let property: MediaProperty

  @State private var searchString = ""
  @State private var sections: [MediaPropertySection] = []
  @State private var primaryFilters: [PrimaryFilterViewModel] = []
  @State private var secondaryFilters: [SecondaryFilterViewModel] = []
  @State private var currentPrimaryFilter: PrimaryFilterViewModel?
  @State private var currentSecondaryFilter: SecondaryFilterViewModel?
  @State private var searching = false
  @State private var playingItem: MediaPropertySectionMediaItem?

  var body: some View {
    GeometryReader { geo in
      ScrollView {
        LazyVStack(alignment: .leading, spacing: 20) {
          if !primaryFilters.isEmpty {
            PrimaryFilterChips(
              filters: primaryFilters,
              current: $currentPrimaryFilter,
              currentSecondary: $currentSecondaryFilter,
              secondaryFilters: $secondaryFilters
            )
          }

          if !secondaryFilters.isEmpty {
            SecondaryFilterChips(
              filters: secondaryFilters,
              style: currentPrimaryFilter?.secondaryFilterStyle,
              current: $currentSecondaryFilter
            )
          }

          results(width: geo.size.width)
        }
        .padding(.vertical, 12)
      }
    }
    .navigationTitle("Search")
    .navigationBarTitleDisplayMode(.inline)
    .searchable(text: $searchString, prompt: "Search \(property.displayName)")
    .autocorrectionDisabled()
    .navigationDestination(item: $playingItem) { mediaItem in
      MobileVideoPlayerView(property: property, mediaItem: mediaItem)
    }
    .task(id: searchString) {
      if !searchString.isEmpty {
        // Debounce queries while typing to not spam the API for every character
        try? await Task.sleep(for: .milliseconds(300))
        guard !Task.isCancelled else { return }
      }
      await search()
    }
    .task(id: "\(currentPrimaryFilter?.id ?? "")_\(currentSecondaryFilter?.id ?? "")") {
      // Search immediately when any filter changes
      await search()
    }
    .task { await loadFilters() }
  }

  /// A single result section fills a grid; several keep the property page's
  /// horizontally-scrolling rows, the way tvOS splits them.
  @ViewBuilder private func results(width: CGFloat) -> some View {
    if searching && sections.isEmpty {
      ProgressView()
        .frame(maxWidth: .infinity)
        .padding(.top, 40)
    } else if sections.isEmpty {
      ContentUnavailableView(
        "No Results",
        systemImage: "magnifyingglass",
        description: Text("Nothing matched this search.")
      )
      .padding(.top, 40)
    } else if sections.count == 1 {
      SearchResultsGrid(
        section: sections[0], availableWidth: width, onTap: handleTap)
    } else {
      ForEach(sections) { section in
        SectionRow(section: section, onTap: handleTap)
      }
    }
  }

  private func handleTap(_ item: MediaPropertySectionItem) {
    if item.isInaccessible {
      print("Tap ignored — item is inaccessible: id=\(item.id ?? "?")")
      return
    }
    guard let media = item.media else { return }
    if media.media_type?.lowercased() == "video" {
      playingItem = media
    }
    // Non-video media types (gallery, html, image) aren't wired up yet.
  }

  private func loadFilters() async {
    do {
      primaryFilters = try await PropertySearchStore.shared.getPrimaryFilters(
        propertyId: property.id)
      if let first = primaryFilters.first {
        currentPrimaryFilter = first
        secondaryFilters = first.secondaryFilters
      }
    } catch {
      print("MobileSearchView: could not load filters:", error.localizedDescription)
    }
  }

  private func search() async {
    searching = true
    defer { searching = false }

    var attributes: [String: [String]] = [:]
    if let primary = currentPrimaryFilter {
      if !primary.id.isEmpty {
        attributes[primary.attribute] = [primary.id]
      }
      if let secondary = currentSecondaryFilter, !secondary.id.isEmpty {
        attributes[primary.secondaryAttribute] = [secondary.id]
      }
    }

    let request = SearchRequest(search_term: searchString, attributes: attributes)
    do {
      let results = try await PropertySearchStore.shared.search(
        property: property, searchRequest: request)
      sections = results.filter { !$0.shouldHideInContainer }
    } catch {
      print("MobileSearchView: search failed:", error.localizedDescription)
      sections = []
    }
  }
}

// MARK: - Results grid

private struct SearchResultsGrid: View {
  let section: MediaPropertySection
  let availableWidth: CGFloat
  let onTap: (MediaPropertySectionItem) -> Void

  private let spacing: CGFloat = 12
  private let horizontalPadding: CGFloat = 16

  private var items: [MediaPropertySectionItem] {
    (section.content ?? []).filter { $0.resolvedPermissions?.hide != true }
  }

  private var sectionRatio: AspectRatio? {
    AspectRatio(section.display?.aspect_ratio)
  }

  /// Cards in a grid all share the column width, so the row's shape decides how
  /// many fit: wide landscape cards get two columns, taller ones three.
  private var ratio: AspectRatio {
    sectionRatio ?? items.first?.thumbnailAndRatio().ratio ?? .portrait
  }

  private var columnCount: Int {
    ratio == .landscape ? 2 : 3
  }

  private var cardWidth: CGFloat {
    let usable =
      availableWidth - horizontalPadding * 2 - spacing * CGFloat(columnCount - 1)
    return max(usable / CGFloat(columnCount), 1)
  }

  var body: some View {
    LazyVGrid(
      columns: Array(repeating: GridItem(.fixed(cardWidth), spacing: spacing), count: columnCount),
      alignment: .leading,
      spacing: 16
    ) {
      ForEach(items) { item in
        Button {
          onTap(item)
        } label: {
          SectionItemCard(item: item, sectionRatio: sectionRatio, cardWidth: cardWidth)
        }
        .buttonStyle(.plain)
        .contentShape(.rect)
      }
    }
    .padding(.horizontal, horizontalPadding)
  }
}

// MARK: - Filter chips

private struct PrimaryFilterChips: View {
  let filters: [PrimaryFilterViewModel]
  @Binding var current: PrimaryFilterViewModel?
  @Binding var currentSecondary: SecondaryFilterViewModel?
  @Binding var secondaryFilters: [SecondaryFilterViewModel]

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(filters) { filter in
          FilterChip(
            title: filter.title,
            imageUrl: filter.imageUrl,
            selected: current?.id == filter.id
          ) {
            if current?.id == filter.id {
              current = nil
              secondaryFilters = []
            } else {
              current = filter
              secondaryFilters = filter.secondaryFilters
            }
            currentSecondary = nil
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct SecondaryFilterChips: View {
  let filters: [SecondaryFilterViewModel]
  let style: FilterStyle?
  @Binding var current: SecondaryFilterViewModel?

  var body: some View {
    ScrollView(.horizontal, showsIndicators: false) {
      HStack(spacing: 10) {
        ForEach(filters) { filter in
          FilterChip(
            title: filter.title,
            imageUrl: style == .image ? filter.imageUrl : "",
            selected: current == filter || (current == nil && filter.id.isEmpty)
          ) {
            current = current == filter ? nil : filter
          }
        }
      }
      .padding(.horizontal, 16)
    }
  }
}

private struct FilterChip: View {
  let title: String
  let imageUrl: String
  let selected: Bool
  let action: () -> Void

  var body: some View {
    Button(action: action) {
      Group {
        if !imageUrl.isEmpty {
          ScaledWebImage(url: imageUrl, height: 44)
            .resizable()
            .scaledToFit()
            .frame(height: 44)
        } else {
          Text(title)
            .font(.subheadline)
        }
      }
      .padding(.vertical, 8)
      .padding(.horizontal, 14)
      .foregroundStyle(selected ? Color.black : Color.primary)
      .background(
        Capsule().fill(selected ? Color.primary : Color.gray.opacity(0.2))
      )
    }
    .buttonStyle(.plain)
  }
}
