//
//  SearchView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-16.
//

import EluvioCore
import SwiftUI

struct SearchView: View {
  @State var searchString: String = ""
  var propertyId: String
  private var property: MediaProperty? {
    PropertyStore.shared.getProperty(id: propertyId)
  }
  @State var logoUrl = ""
  @State var name = ""

  @State var sections: [MediaPropertySection] = []
  @State var primaryFilters: [PrimaryFilterViewModel] = []
  @State var currentPrimaryFilter: PrimaryFilterViewModel? = nil
  @State var currentSecondaryFilter: SecondaryFilterViewModel? = nil
  @State var secondaryFilters: [SecondaryFilterViewModel] = []

  var body: some View {
    VStack {
      ScrollView(.vertical) {
        VStack(alignment: .leading, spacing: 0) {
          if !primaryFilters.isEmpty {
            PrimaryFiltersRow(
              primaryFilters: primaryFilters,
              currentPrimaryFilter: $currentPrimaryFilter,
              currentSecondaryFilter: $currentSecondaryFilter,
              secondaryFilters: $secondaryFilters,
            )
          }

          if !secondaryFilters.isEmpty {
            SecondaryFiltersRow(
              secondaryFilters: secondaryFilters,
              secondaryFilterStyle: currentPrimaryFilter?.secondaryFilterStyle,
              currentSecondaryFilter: $currentSecondaryFilter,
            )
          }

          if let propertyVM = property {
            if sections.count == 1 {
              SectionGridView(
                property: propertyVM, pageId: "main", section: sections.first!,
                useScale: true, showBackground: false
              )
              .focusSection()
            } else {
              ForEach(sections, id: \.self) { section in
                VStack {
                  MediaPropertySectionView(
                    property: propertyVM, pageId: "main", section: section, margin: 0,
                    useScale: true)
                }
                .focusSection()
              }
            }
          }

          Spacer()
        }
      }
    }
    .searchable(text: $searchString, prompt: "Search \(name)", suggestions: {})
    .autocorrectionDisabled(true)
    .edgesIgnoringSafeArea([.top])
    // .scrollTargetBehavior(.custom)
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
    .task {
      debugPrint("Search View onAppear")
      await loadFilters()
    }
    .onAnyChange(of: property) { _, property in
      name = property?.displayName ?? ""
      logoUrl = property?.tv_header_logo?.url ?? property?.header_logo?.url ?? ""
    }
  }

  private func loadFilters() async {
    debugPrint("SearchView refresh propertyId \(propertyId)")
    do {
      debugPrint("Search refresh()")

      self.primaryFilters = try await PropertySearchStore.shared.getPrimaryFilters(
        propertyId: propertyId)
      debugPrint("Got PrimaryFilters: ", primaryFilters)

      if !primaryFilters.isEmpty {
        currentPrimaryFilter = primaryFilters.first
        secondaryFilters = currentPrimaryFilter?.secondaryFilters ?? []
        debugPrint("Secondary filters: ", secondaryFilters)
      }
    } catch {
      print("Could not do search ", error.localizedDescription)
      // TODO: Send to error screen
    }
  }

  private func search() async {
    debugPrint("Replace Search")
    guard let property = property else { return }
    do {
      var attributes: [String: [String]] = [:]

      if let primary = currentPrimaryFilter {
        if !primary.id.isEmpty {
          attributes[primary.attribute] = [primary.id]
        }
        // debugPrint("currentSecondaryFilter:", currentSecondaryFilter)
        if let secondary = currentSecondaryFilter {
          if !secondary.id.isEmpty {
            attributes[primary.secondaryAttribute] = [secondary.id]
          }
        }
      }

      debugPrint("attributes:", attributes)

      let request = SearchRequest(
        search_term: searchString,
        attributes: attributes
      )
      let sections = try await PropertySearchStore.shared.search(
        property: property, searchRequest: request)

      debugPrint("Search sections found:", sections.count)

      await MainActor.run {
        self.sections = []
        self.sections = sections
        debugPrint("Search finished sections", sections.count)
      }
    } catch {
      print("Could not do search ", error.localizedDescription)
      // TODO: Send to error screen
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Search View") {
  SearchView(propertyId: "iq__prop1")
}
