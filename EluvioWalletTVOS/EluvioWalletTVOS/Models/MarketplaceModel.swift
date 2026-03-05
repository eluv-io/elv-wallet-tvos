//
//  MarketplaceModel.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-08.
//

import Foundation
import SwiftUI
import SwiftyJSON

struct MarketplaceViewModel: Identifiable, Codable {
  var id = ""
  var title: String = ""
  var tenantId = ""
  var image = ""
  var logo = ""
  var header = ""
  var items: [JSON] = []
}

func CreateMarketplaceViewModel(meta: AssetMetadataModel, id: String? = "", fabric: Fabric) throws
  -> MarketplaceViewModel
{
  let startTime = DispatchTime.now()

  let endTime = DispatchTime.now()

  let elapsedTime = endTime.uptimeNanoseconds - startTime.uptimeNanoseconds
  let elapsedTimeInMilliSeconds = Double(elapsedTime) / 1_000_000.0
  debugPrint("CreateMarketplaceViewModel function time ms: ", elapsedTimeInMilliSeconds)

  return MarketplaceViewModel(
    id: id ?? "",
    title: meta.title ?? "",
    tenantId: meta.info?.tenant_id ?? "",
    image: meta.info?.branding?.tv?.image?.url ?? "",
    logo: meta.info?.branding?.tv?.logo?.url ?? "",
    header: meta.info?.branding?.tv?.header_image?.url ?? "",
    items: meta.info?.items ?? []
  )
}

struct AssetMetadataModel: Codable {
  var display_title: String? = ""
  var asset_type: String? = ""
  var title: String? = ""
  var slug: String? = ""
  var title_type: String? = ""
  var info: AMInfoModel?
}

struct AMInfoModel: Codable {
  var tenant_id: String? = ""
  var branding: AMInfoBrandingModel?
  var items: [JSON]? = []
}

struct AMInfoBrandingModel: Codable {
  var tv: AMInfoBrandingTVModel?
}

struct AMInfoBrandingTVModel: Codable {
  var header_image: ImageLink?
  var image: ImageLink?
  var logo: ImageLink?
}
