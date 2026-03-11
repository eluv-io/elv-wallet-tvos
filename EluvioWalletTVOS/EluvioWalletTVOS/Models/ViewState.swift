//
//  ViewState.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-15.
//

import SwiftUI

enum LinkOp {
  case item, play, mint, property, gallery, none
}

class ViewState: ObservableObject {
  @Published var op: LinkOp = .none
  var itemContract = ""
  var itemTokenStr = ""
  var marketplaceId = ""
  var itemSKU = ""
  var mediaId = ""
  var backLink = ""
  var authToken = ""
  var address = ""
  var entitlement = ""

  // App states
  var isBranded = false
  var signInBackground: RadialGradient

  init(isBranded: Bool = false, signInBackground: RadialGradient = Color.mainBackground) {
    self.isBranded = isBranded
    self.signInBackground = signInBackground
  }

  func reset() {
    itemContract = ""
    itemTokenStr = ""
    marketplaceId = ""
    itemSKU = ""
    mediaId = ""
    backLink = ""
    if op == .none {
      return
    }
    op = .none
  }

  func handleLink(url: URL, fabric: Fabric) async {
    if let host = url.host()?.lowercased() {
      debugPrint("handleLink ", host)
      reset()

      if let backlink = url.valueOf("back_link")?.removingPercentEncoding {
        backLink = backlink
      }
      debugPrint("backlink: ", backLink)

      if let authToken = url.valueOf("authorization")?.removingPercentEncoding {
        self.authToken = authToken
        debugPrint("Deeplink with auth", authToken)
        var signInResponse = SignInResponse()
        signInResponse.idToken = authToken
        // try await fabric.signIn(signInResponse: signInResponse, external: true)

        debugPrint("Signed In!")

        await MainActor.run {
          setViewState(host: host, url: url)
        }
      } else {
        await MainActor.run {
          setViewState(host: host, url: url)
        }
      }
    }
  }

  /// @MainActor
  func setViewState(host: String, url: URL) {
    switch host {
    case "items":
      debugPrint("viewStateProperty items")
      itemContract = url.valueOf("contract")?.lowercased() ?? ""
      itemTokenStr = url.valueOf("token") ?? ""
      marketplaceId = url.valueOf("marketplace") ?? ""
      itemSKU = url.valueOf("sku") ?? ""
      debugPrint("backlink: ", backLink)
      op = .item
    case "play":
      debugPrint("viewStateProperty play")
      itemContract = url.valueOf("contract")?.lowercased() ?? ""
      itemTokenStr = url.valueOf("token") ?? ""
      mediaId = url.valueOf("media") ?? ""
      marketplaceId = url.valueOf("marketplace") ?? ""
      itemSKU = url.valueOf("sku") ?? ""
      op = .play
    case "mint":
      debugPrint("viewStateProperty mint")
      marketplaceId = url.valueOf("marketplace") ?? ""
      itemSKU = url.valueOf("sku") ?? ""
      entitlement = url.valueOf("entitlement") ?? ""
      op = .mint
    case "property":
      debugPrint("viewStateProperty property ", marketplaceId)
      marketplaceId = url.lastPathComponent
      op = .property
    default:
      return
    }
  }

  func setViewState(state: ViewState) {
    itemContract = state.itemContract
    itemTokenStr = state.itemTokenStr
    marketplaceId = state.marketplaceId
    itemSKU = state.itemSKU
    mediaId = state.mediaId
    op = state.op
  }

  /// Returns true if we can load the page
  func login(_ property: MediaProperty, eluvio: EluvioAPI, router: Router) {
    if property.accountType == AccountStore.shared.account?.type {
      debugPrint("Logged in with correct account type - navigating to Property.")
      let param = PropertyParam(propertyId: property.id)
      router.push(to: .property(param))
    } else {
      debugPrint("Not logged in with same account type as Property - navigating to Login.")
      router.push(to: .login(LoginParam(property: property)))
    }
  }
}
