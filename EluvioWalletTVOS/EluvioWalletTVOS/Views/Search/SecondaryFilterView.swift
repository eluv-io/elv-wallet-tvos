import EluvioCore
import SwiftUI

struct SecondaryFilterView: View {
  var title = ""
  var imageUrl = ""
  var action: () -> Void

  /// The theme the primary filter names for its secondary row, applied to
  /// image filters only.
  var cardTheme: CardTheme? = nil

  @FocusState var isFocused
  var selected = false

  var body: some View {
    ZStack(alignment: .center) {
      Button(action: action) {
        if !imageUrl.isEmpty {
          VStack(spacing: 10) {
            ScaledWebImage(url: imageUrl, height: 96)
              .resizable()
              .scaledToFit()
              .frame(width: 96, height: 96)
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
        secondaryFilterButtonStyle(
          focused: isFocused, selected: selected, isImage: !imageUrl.isEmpty)
      )
      .focused($isFocused)
    }
  }
}

/// The filter's name under its image, shown only while the filter is focused or selected
struct FilterImageTitle: View {
  var title: String
  var visible: Bool

  var body: some View {
    Text(title)
      .font(.system(size: 24, weight: .semibold))
      // The image button style turns a selected filter's label black, which
      // would vanish against the dark background
      .foregroundStyle(.white)
      .lineLimit(1)
      // Hidden rather than removed, so the row's height doesn't jump with focus
      .opacity(visible ? 1 : 0)
  }
}

// MARK: - SwiftUI Previews

#Preview("Secondary Filter View") {
  SecondaryFilterView(title: "All", action: {})
    .padding()
    .background(Color.black)
}
