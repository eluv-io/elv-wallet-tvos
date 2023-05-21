//
//  TestData.swift
//  TestData
//
//  Created by Wayne Tran on 2021-09-27.
//

import Foundation
import SwiftyJSON

var test_NFTs: [NFTModel] = loadJsonFile("nfts.json")
var test_sale_NFTs: [NFTModel] = loadJsonFile("nfts_marketplace.json")
var test_marketplaces: [MarketplaceModel] = loadJsonFile("marketplaces.json")
var test_profile: ProfileModel = loadJsonFile("profile.json")

func CreateTestNFTs(num: Int) -> [NFTModel] {
    var nfts: [NFTModel] = [];
    for i in 0...num {
        var item = test_NFTs[0]
        item.contract_name = "Test NFT " + String(i)
        item.meta.displayName = "Test NFT Long Name Test NFT Long Name Test NFT Long Name Test NFT Long Name Test NFT Long Name Test NFT Long Name "
        item.token_id = i
        item.token_id_str = String(i)
        
        let width = Int.random(in: 200..<1000)
        let height = Int.random(in: 200..<1000)
        
        item.meta.image = "https://picsum.photos/\(width)/\(height)"
        
        item.ordinal = i
        item.id = String(i)
        
        nfts.append(item)
    }
    return nfts
}

func CreateTestProperty(num: Int) -> JSON {
    var property : JSON = [
        "id" : "prop_1",
        "title" : "Movieverse",
        "image" : "WarnerBrothersLogo",
        "parent_id" : "iten",
        "contents" : [
            [
                "id" : "proj_1",
                "title" : "The Lord of the Rings",
                "image" : "WarnerBrothers",
                "parent_id": "prop_1",
                "contents" : CreateTestNFTs(num: num)
            ]
        ]
    ]
    
    return property
}

func CreateTestPropertyModel(title: String, image: String, heroImage: String, featured: [AnyHashable] = [], media: [MediaCollection] = [], albums: [NFTModel] = [], items: [NFTModel]) -> PropertyModel {
    
    var projects : [ProjectModel] = []
    projects.append(ProjectModel(
        contents : items
    ))
    
    let property = PropertyModel(
        title : title,
        image : image,
        heroImage: heroImage,
        featured: featured,
        media: media,
        albums: albums,
        contents : projects
        )
    
    return property
}
