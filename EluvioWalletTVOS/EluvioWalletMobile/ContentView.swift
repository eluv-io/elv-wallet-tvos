import EluvioCore
import SwiftUI

struct ContentView: View {
  @State private var properties: [MediaProperty] = []
  @State private var signInProperty: MediaProperty?

  var body: some View {
    NavigationStack {
      List(properties) { property in
        Button {
          signInProperty = property
        } label: {
          Text(property.displayName)
            .font(.headline)
        }
      }
      .navigationTitle("Properties")
      .overlay {
        if properties.isEmpty {
          ProgressView()
        }
      }
    }
    .task {
      await PropertyStore.shared.fetchProperties()
      properties = PropertyStore.shared.properties
    }
    .sheet(item: $signInProperty) { property in
      MobileSignInView(property: property)
    }
  }
}

#Preview {
  ContentView()
}
