import EluvioCore
import SwiftUI

struct SecondaryFilterView: View {
  var title = ""
  var imageUrl = ""
  var action: () -> Void

  @FocusState var isFocused
  var selected = false

  var body: some View {
    ZStack(alignment: .center) {
      Button(action: action) {
        if !imageUrl.isEmpty {
          ScaledWebImage(url: imageUrl, height: 80)
            .resizable()
            .scaledToFit()
            .frame(width: 80, height: 80)
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

// MARK: - SwiftUI Previews

#Preview("Secondary Filter View") {
  SecondaryFilterView(title: "All", action: {})
    .padding()
    .background(Color.black)
}
