import EluvioCore
import SwiftUI

struct DiscoverView: View {
  @State private var properties: [MediaProperty] = []
  @State private var signInProperty: MediaProperty?

  private let columns = [
    GridItem(.flexible(), spacing: 12),
    GridItem(.flexible(), spacing: 12),
  ]

  var body: some View {
    NavigationStack {
      ScrollView {
        LazyVGrid(columns: columns, spacing: 12) {
          ForEach(properties) { property in
            Button {
              signInProperty = property
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
  DiscoverView()
}
