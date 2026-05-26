import EluvioCore
import SwiftUI

struct DiscoverView: View {
  /// Owned by ContentView so deep links can reset it without going through us.
  @Binding var path: NavigationPath
  @State private var properties: [MediaProperty] = []
  @State private var signIn = MobileSignIn()

  private let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
  ]

  var body: some View {
    NavigationStack(path: $path) {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(properties) { property in
            Button {
              tapped(property)
            } label: {
              PropertyTile(property: property)
            }
            .buttonStyle(.plain)
          }
        }
        .padding(12)
      }
      .navigationTitle("Discover")
      .overlay {
        if properties.isEmpty {
          ProgressView()
        }
      }
      .navigationDestination(for: MediaProperty.self) { property in
        PropertyView(property: property)
      }
    }
    .task {
      await PropertyStore.shared.fetchProperties()
      properties = PropertyStore.shared.properties
      consumePendingDeepLink()
    }
    .onChange(of: DeepLinkRouter.shared.pendingPropertyId) { _, _ in
      consumePendingDeepLink()
    }
  }

  /// If a deep link is queued and the matching property is loaded, jump there.
  /// Called both after the property list loads and whenever the queued ID changes.
  private func consumePendingDeepLink() {
    guard let id = DeepLinkRouter.shared.pendingPropertyId,
      let property = properties.first(where: { $0.id == id })
    else { return }
    DeepLinkRouter.shared.pendingPropertyId = nil
    signIn.cancel()  // tear down any in-progress sign-in
    tapped(property)
  }

  private func tapped(_ property: MediaProperty) {
    let alreadySignedIn = property.accountType == AccountStore.shared.account?.type
    if alreadySignedIn {
      path.append(property)
    } else {
      signIn.start(property: property) {
        path.append(property)
      }
    }
  }
}

private struct PropertyTile: View {
  let property: MediaProperty

  // Tiles are 2-column on iPhone; aim for a portrait-ish aspect (≈ 7:10) so
  // the main `image` from the fabric (designed portrait) fits cleanly.
  private let aspectRatio: CGFloat = 7.0 / 10.0

  var body: some View {
    GeometryReader { geo in
      let width = geo.size.width
      let height = width / aspectRatio
      ZStack(alignment: .bottomLeading) {
        if let imageUrl = property.image?.url?.nilIfEmpty() {
          ScaledWebImage(url: imageUrl, height: height)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
        } else if !property.backgroundImage.isEmpty {
          ScaledWebImage(url: property.backgroundImage, height: height)
            .resizable()
            .aspectRatio(contentMode: .fill)
            .frame(width: width, height: height)
            .clipped()
            .overlay(Color.black.opacity(0.35))
        } else {
          Rectangle()
            .fill(Color.gray.opacity(0.3))
            .frame(width: width, height: height)
        }

        // Always-visible title overlay so tiles without text-on-image have a label.
        LinearGradient(
          colors: [.clear, .black.opacity(0.7)],
          startPoint: .center, endPoint: .bottom
        )
        .frame(width: width, height: height)

        Text(property.displayName)
          .font(.headline)
          .foregroundStyle(.white)
          .lineLimit(2)
          .padding(8)
          .frame(width: width, alignment: .leading)
      }
      .frame(width: width, height: height)
      .clipShape(RoundedRectangle(cornerRadius: 10))
    }
    .aspectRatio(aspectRatio, contentMode: .fit)
  }
}

#Preview {
  DiscoverView(path: .constant(NavigationPath()))
}
