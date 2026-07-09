import EluvioCore
import SwiftUI

struct PrimaryFilterView: View {
  var filter: PrimaryFilterViewModel
  var title: String {
    filter.id == "" ? "All" : filter.id
  }

  var action: () -> Void

  @FocusState var isFocused
  var selected = false

  var body: some View {
    // ZStack(alignment:.center){
    Button(action: action) {
      if !filter.imageUrl.isEmpty {
        ScaledWebImage(url: filter.imageUrl, height: 80)
          .resizable()
          .scaledToFit()
          .frame(height: 80)
      } else {
        Text(title)
          .font(.rowTitle)
      }
    }
    .buttonStyle(
      primaryFilterButtonStyle(
        focused: isFocused, selected: selected, isImage: !filter.imageUrl.isEmpty)
    )
    .focused($isFocused)
    // .padding()
    // }
  }
}

// MARK: - SwiftUI Previews

#Preview("Primary Filter View") {
  PrimaryFilterView(
    filter: PrimaryFilterViewModel(
      id: "Action", imageUrl: "", secondaryFilters: [], attribute: "", secondaryAttribute: ""),
    action: {}
  )
  .padding()
  .background(Color.black)
}
