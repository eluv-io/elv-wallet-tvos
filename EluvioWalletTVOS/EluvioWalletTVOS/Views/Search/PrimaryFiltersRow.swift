import SwiftUI

struct PrimaryFiltersRow: View {
  var primaryFilters: [PrimaryFilterViewModel]
  @Binding var currentPrimaryFilter: PrimaryFilterViewModel?
  @Binding var currentSecondaryFilter: SecondaryFilterViewModel?
  @Binding var secondaryFilters: [SecondaryFilterViewModel]

  var body: some View {
    HStack(alignment: .center, spacing: 20) {
      Text("Filters")
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
                selected: currentPrimaryFilter?.id == filter.id
              )
            }
          }
          .frame(maxHeight: .infinity, alignment: .center)
        }
        .frame(alignment: .center)
      }
    }
    .padding([.leading, .trailing])
    .padding([.top], primaryFilters.count > 0 ? 20 : 0)
    .focusSection()
  }
}
