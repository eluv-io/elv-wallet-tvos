import EluvioCore
import SwiftUI

struct PrimaryFilterView: View {
  var filter: PrimaryFilterViewModel
  var title: String {
    filter.id == "" ? "All" : filter.id
  }

  var action: () -> Void

  /// The theme the Property names for its filters, applied to image filters
  /// only. Text filters keep the app's own chip styling, like the web's do.
  var cardTheme: CardTheme? = nil

  @FocusState var isFocused
  var selected = false

  static let imageHeight: CGFloat = 96

  var body: some View {
    // ZStack(alignment:.center){
    Button(action: action) {
      if !filter.imageUrl.isEmpty {
        VStack(spacing: 10) {
          ScaledWebImage(url: filter.imageUrl, height: Self.imageHeight)
            .resizable()
            .scaledToFit()
            .frame(height: Self.imageHeight)
            // A selected filter looks the same as a focused one
            .cardThemedFilter(cardTheme, active: isFocused || selected)
          FilterImageTitle(title: title, visible: isFocused || selected)
        }
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
