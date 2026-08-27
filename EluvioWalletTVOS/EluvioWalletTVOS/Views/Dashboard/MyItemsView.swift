//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import Combine
import EluvioCore
import SwiftUI
import SwiftyJSON

struct MyItemsView: View {
  @EnvironmentObject var eluvio: EluvioAPI
  @State var searchString = ""
  @State var nfts: [NFTModel] = []
  var propertyId = ""
  var logo = "e_logo"
  var logoUrl = ""
  var name = ""
  @State var isFiltered = false
  /// Which filter chip holds focus, so Down out of the search field can name its target rather
  /// than leaving the choice to the focus engine.
  @FocusState private var focusedFilter: String?
  var properties: [MediaProperty] = PropertyStore.shared.ownedProperties.map { $0.value }
  var address: String {
    AccountStore.shared.account?.getAccountAddress() ?? ""
  }

  func search() {
    Task {
      do {
        nfts = try await eluvio.fabric.getNFTs(address: address, name: searchString)
      } catch {
        print("Error searching properties: ", error.localizedDescription)
      }
    }
  }

  var body: some View {
    ScrollView {
      // In-content rather than `.searchable`: tvOS sizes that modifier's field and keyboard
      // against the window, so they reach straight out of the slot the Dashboard puts this
      // screen in. Geometry and colours are measured from the Android screen.
      MyItemsSearchField(text: $searchString)
        .padding(.leading, MyItems.fieldLeading)
        .padding(.trailing, MyItems.fieldTrailing)
        .padding(.bottom, MyItems.fieldBottomGap)

      if !isFiltered {
        VStack {
          ScrollView(.horizontal) {
            LazyHStack(spacing: 10) {
              if !properties.isEmpty {
                SecondaryFilterView(
                  title: "All",
                  action: {
                    Task {
                      do {
                        searchString = ""
                        nfts = try await eluvio.fabric.getNFTs(address: address)
                      } catch {
                        print("Could not get nfts ", error.localizedDescription)
                      }
                    }
                  }
                )
                .focused($focusedFilter, equals: MyItems.allFilterID)
              }
              ForEach(properties) { property in
                SecondaryFilterView(
                  title: property.displayName,
                  action: {
                    debugPrint("Property \(property.id) pressed.")
                    Task {
                      do {
                        searchString = ""
                        nfts = try await eluvio.fabric.getNFTs(
                          address: address, propertyId: property.id)
                      } catch {
                        print("Could not get nfts ", error.localizedDescription)
                      }
                    }
                  }
                )
                .focused($focusedFilter, equals: property.id)
              }
            }
          }
          .scrollClipDisabled()
          // Declares where focus enters the row, rather than correcting it afterwards: the
          // field spans nearly the full width, so tvOS's own choice is rarely the first chip,
          // and moving focus after the fact is visible as a jump. Same pairing the property
          // carousels use (MediaPropertySectionView).
          .focusSection()
          .defaultFocus($focusedFilter, MyItems.allFilterID, priority: .userInitiated)
        }
      }

      if nfts.isEmpty {
        Text("No items to display")
          .font(.system(size: 32))
          .foregroundColor(.white)
          .frame(maxWidth: .infinity, alignment: .leading)
          .padding(.leading, MyItems.fieldLeading)
      } else {
        NFTGrid(nfts: nfts)
          .focusSection()
          .padding(.top, 40)
      }
    }
    .task {
      await PropertyStore.shared.fetchProperties(includePublic: false)
    }
    .onChange(of: searchString) {
      search()
    }
    .onAnyChange(of: AccountStore.shared.account) { _, newAccount in
      if newAccount == nil {
        nfts = []
      }
    }
    .onAppear {
      Task {
        for _ in 1...2 {
          var retry = false
          do {
            var allowedNFTs: [NFTModel] = []
            isFiltered = false
            if let allowedProperties = APP_CONFIG.allowed_properties {
              if !allowedProperties.isEmpty {
                for propertyId in allowedProperties {
                  let resp = try await eluvio.fabric.getNFTs(
                    address: address, propertyId: propertyId)
                  allowedNFTs.append(contentsOf: resp)
                }

                nfts = allowedNFTs
                isFiltered = true
              }
            }
            if !isFiltered {
              nfts = try await eluvio.fabric.getNFTs(address: address, propertyId: propertyId)
            }
          } catch let FabricError.apiError(code, response, error) {
            eluvio.handleApiError(code: code, response: response, error: error)
            await eluvio.refreshFabricToken()
            retry = true
          } catch {
            print("An error occured getting nfts in MyItemsView", error)
          }
          if !retry {
            break
          }
        }
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("My Items View") {
  MyItemsView()
    .environmentObject(EluvioAPI())
}

/// Geometry measured off the Android My Items screen, converted to tvOS points. The Dashboard's
/// slot already supplies the leading room for the nav rail, so these are relative to the slot.
private enum MyItems {
  static let fieldLeading: CGFloat = 40
  static let fieldTrailing: CGFloat = 207
  static let fieldHeight: CGFloat = 95
  static let fieldBottomGap: CGFloat = 40
  static let cornerRadius: CGFloat = 12
  static let fill = Color(hex: 0x181818)
  static let placeholder = Color(hex: 0x8D8D8D)
  /// Focus id for the "All" chip, which is always the first one in the row.
  static let allFilterID = "all"
}

/// A bordered search field matching Android's: white outline over a near-black fill, magnifier
/// inside it.
///
/// The box is drawn here rather than left to `TextField`, because tvOS paints its own
/// translucent chrome inside a text field and offers no way to restyle it. The real field sits
/// underneath at full opacity — hiding it by transparency instead takes it out of the focus
/// engine, which leaves this screen with nothing focusable at all — and the drawn box covers
/// its chrome without removing it from the focus engine.
private struct MyItemsSearchField: View {
  @Binding var text: String
  @FocusState private var focused: Bool

  var body: some View {
    ZStack(alignment: .leading) {
      TextField("Search My Items", text: $text)
        .autocorrectionDisabled(true)
        .frame(maxWidth: .infinity)
        .frame(height: MyItems.fieldHeight)
        .focused($focused)

      HStack(spacing: 22) {
        Image("search")
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 36, height: 36)
          .foregroundColor(.white)
        Text(text.isEmpty ? "Search My Items" : text)
          .font(.system(size: 38))
          .foregroundColor(text.isEmpty ? MyItems.placeholder : .white)
          .lineLimit(1)
        Spacer(minLength: 0)
      }
      .padding(.horizontal, 34)
      .frame(maxWidth: .infinity)
      .frame(height: MyItems.fieldHeight)
      .background(RoundedRectangle(cornerRadius: MyItems.cornerRadius).fill(MyItems.fill))
      .overlay(
        RoundedRectangle(cornerRadius: MyItems.cornerRadius)
          .stroke(Color.white, lineWidth: focused ? 5 : 3)
      )
      .allowsHitTesting(false)
    }
  }
}
