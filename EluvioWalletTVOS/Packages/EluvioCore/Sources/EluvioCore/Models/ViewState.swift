//
//  ViewState.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-02-15.
//

import SwiftUI

public enum LinkOp {
  case item, play, mint, property, gallery, none
}

public class ViewState: ObservableObject {
  @Published public var op: LinkOp = .none
  public var itemContract = ""
  public var itemTokenStr = ""
  public var marketplaceId = ""
  public var itemSKU = ""
  public var mediaId = ""
  public var backLink = ""
  public var authToken = ""
  public var address = ""
  public var entitlement = ""

  // App states
  public var isBranded = false
  public var signInBackground: RadialGradient

  public init(
    isBranded: Bool = false,
    signInBackground: RadialGradient = RadialGradient(
      gradient: Gradient(colors: [
        Color(red: 0.1, green: 0.1, blue: 0.1),
        Color(red: 0.0, green: 0.00, blue: 0.0),
      ]),
      center: .top, startRadius: 0, endRadius: 1600)
  ) {
    self.isBranded = isBranded
    self.signInBackground = signInBackground
  }

  public func reset() {
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

  public func handleLink(url: URL, fabric: Fabric) async {
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
  public func setViewState(host: String, url: URL) {
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

  public func setViewState(state: ViewState) {
    itemContract = state.itemContract
    itemTokenStr = state.itemTokenStr
    marketplaceId = state.marketplaceId
    itemSKU = state.itemSKU
    mediaId = state.mediaId
    op = state.op
  }

}
