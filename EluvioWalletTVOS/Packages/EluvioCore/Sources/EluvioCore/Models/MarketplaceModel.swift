//
//  MarketplaceModel.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-08.
//

import Foundation
import SwiftUI
import SwiftyJSON

public struct MarketplaceViewModel: Identifiable, Codable {
  public var id = ""
  public var title: String = ""
  public var tenantId = ""
  public var image = ""
  public var logo = ""
  public var header = ""
  public var items: [JSON] = []
}

public func CreateMarketplaceViewModel(meta: AssetMetadataModel, id: String? = "", fabric: Fabric) throws
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

public struct AssetMetadataModel: Codable {
  public var display_title: String? = ""
  public var asset_type: String? = ""
  public var title: String? = ""
  public var slug: String? = ""
  public var title_type: String? = ""
  public var info: AMInfoModel?
}

public struct AMInfoModel: Codable {
  public var tenant_id: String? = ""
  public var branding: AMInfoBrandingModel?
  public var items: [JSON]? = []
}

public struct AMInfoBrandingModel: Codable {
  public var tv: AMInfoBrandingTVModel?
}

public struct AMInfoBrandingTVModel: Codable {
  public var header_image: ImageLink?
  public var image: ImageLink?
  public var logo: ImageLink?
}
