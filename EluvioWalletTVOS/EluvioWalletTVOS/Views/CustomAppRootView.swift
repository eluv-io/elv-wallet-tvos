import SwiftUI

struct CustomAppRootView: View {
  @State private var property: MediaProperty? = PropertyStore.shared.properties.first

  var body: some View {
    Group {
      if let property = property {
        MediaPropertyDetailView(propertyId: property.id)
      } else {
        ProgressView()
          .edgesIgnoringSafeArea(.all)
          .accessibilityIdentifier("loading_indicator")
      }
    }
    .task {
      if property == nil {
        await PropertyStore.shared.fetchProperties()
        property = PropertyStore.shared.properties.first
      }
    }
  }
}
