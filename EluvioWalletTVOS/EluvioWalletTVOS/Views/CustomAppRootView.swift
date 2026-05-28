import SwiftUI

struct CustomAppRootView: View {
  @State private var property: MediaProperty?

  init() {
    let slug = APP_CONFIG.allowed_properties?.first
    let initial = slug.flatMap { PropertyStore.shared.getProperty(id: $0) }
    _property = State(initialValue: initial)
  }

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
      guard property == nil, let slug = APP_CONFIG.allowed_properties?.first else { return }
      await PropertyStore.shared.fetchProperty(id: slug)
      property = PropertyStore.shared.getProperty(id: slug)
    }
  }
}
