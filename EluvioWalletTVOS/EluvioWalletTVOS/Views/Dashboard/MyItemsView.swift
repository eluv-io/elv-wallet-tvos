//
//  MyItemsView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-05-15.
//

import Combine
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
                  })
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
                  })
              }
            }
          }
          .scrollClipDisabled()
          .padding(.leading, 0)
        }

        NFTGrid(nfts: nfts)
          .focusSection()
          .padding(.top, 40)
      }
    }
    .task {
      await PropertyStore.shared.fetchProperties(includePublic: false)
    }
    .searchable(text: $searchString, prompt: "Search My Items", suggestions: {})
    .autocorrectionDisabled(true)
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
