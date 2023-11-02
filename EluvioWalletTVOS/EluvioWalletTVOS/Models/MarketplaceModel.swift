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
    var items : [JSON] = []
}

func CreateMarketplaceVeiwModel(meta: AssetMetadataModel, id: String?="", fabric: Fabric) throws -> MarketplaceViewModel {
    
    
    let imageUrl = try fabric.getUrlFromLink(link: meta.info?.branding?.tv?.image)
    let logoUrl = try fabric.getUrlFromLink(link: meta.info?.branding?.tv?.logo)
    let headerUrl = try fabric.getUrlFromLink(link: meta.info?.branding?.tv?.header_image)
    
    return MarketplaceViewModel(
        id: id ?? "",
        title: meta.title ?? "",
        tenantId: meta.info?.tenant_id ?? "",
        image: imageUrl,
        logo: logoUrl,
        header: headerUrl,
        items: meta.info?.items ?? []
    );
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
    var items : [JSON]? = []
}

struct AMInfoBrandingModel: Codable {
    var tv: AMInfoBrandingTVModel?
}

struct AMInfoBrandingTVModel: Codable {
    var header_image : JSON?
    var image : JSON?
    var logo : JSON?
}
