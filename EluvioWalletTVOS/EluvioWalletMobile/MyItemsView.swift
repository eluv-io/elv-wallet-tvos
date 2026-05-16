import SwiftUI

struct MyItemsView: View {
  var body: some View {
    NavigationStack {
      ContentUnavailableView(
        "My Items",
        systemImage: "rectangle.stack",
        description: Text("Your owned items will appear here.")
      )
      .navigationTitle("My Items")
    }
  }
}

#Preview {
  MyItemsView()
}
