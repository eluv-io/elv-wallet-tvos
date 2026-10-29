import EluvioCore
import SwiftUI

struct PrimaryFiltersRow: View {
  var primaryFilters: [PrimaryFilterViewModel]
  @Binding var currentPrimaryFilter: PrimaryFilterViewModel?
  @Binding var currentSecondaryFilter: SecondaryFilterViewModel?
  @Binding var secondaryFilters: [SecondaryFilterViewModel]
  var cardTheme: CardTheme? = nil

  var hasImageFilters: Bool {
    primaryFilters.contains { !$0.imageUrl.isEmpty }
  }

  var body: some View {
    // Image filters carry their name below the image, so centering on the whole
    // button would sit "Filters" low - center it on the image instead.
    HStack(alignment: hasImageFilters ? .top : .center, spacing: 20) {
      Text("Filters")
        .frame(height: hasImageFilters ? PrimaryFilterView.imageHeight : nil)
        .padding(.top, hasImageFilters ? imageFilterButtonStyle.verticalPadding : 0)
      VStack {
        ScrollView(.horizontal) {
          LazyHStack(alignment: .center, spacing: 20) {
            ForEach(primaryFilters) { filter in
              PrimaryFilterView(
                filter: filter,
                action: {
                  if currentPrimaryFilter?.id != filter.id {
                    currentPrimaryFilter = filter
                    secondaryFilters = filter.secondaryFilters
                  } else {
                    currentPrimaryFilter = nil
                    secondaryFilters = []
                  }
                  currentSecondaryFilter = nil
                },
                cardTheme: cardTheme,
                selected: currentPrimaryFilter?.id == filter.id
              )
            }
          }
          .frame(maxHeight: .infinity, alignment: .center)
          // Focusing a filter scales it up past the scroll view's edge, where
          // it gets clipped. This leaves the end cards room to grow into.
          .padding(.horizontal, 10)
        }
        .frame(alignment: .center)
      }
    }
    .padding([.leading, .trailing])
    .padding([.top], primaryFilters.count > 0 && !hasImageFilters ? 20 : 0)
    .focusSection()
  }
}
