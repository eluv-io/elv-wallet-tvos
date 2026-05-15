import EluvioCore
import SwiftUI

struct SecondaryFiltersRow: View {
  var secondaryFilters: [SecondaryFilterViewModel]
  var secondaryFilterStyle: FilterStyle?
  @Binding var currentSecondaryFilter: SecondaryFilterViewModel?

  var body: some View {
    ScrollView(.horizontal) {
      LazyHStack(spacing: 20) {
        ForEach(secondaryFilters) { filter in
          SecondaryFilterView(
            title: filter.title,
            imageUrl: secondaryFilterStyle == .image ? filter.imageUrl : "",
            action: {
              if currentSecondaryFilter != filter {
                currentSecondaryFilter = filter
              } else {
                currentSecondaryFilter = nil
              }
            },
            selected: currentSecondaryFilter == filter
              || currentSecondaryFilter == nil && filter.id.isEmpty
          )
        }
      }
    }
    .padding([.leading])
    .padding([.top], secondaryFilters.count > 0 ? 10 : 0)
    .focusSection()
  }
}
