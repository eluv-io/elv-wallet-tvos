//
//  TestData.swift
//  TestData
//
//  Created by Wayne Tran on 2021-09-27.
//

import Foundation

var test_NFTs: [NFTModel] = loadJsonFile("nfts.json")
var test_sale_NFTs: [NFTModel] = loadJsonFile("nfts_marketplace.json")
var test_marketplaces: [MarketplaceModel] = loadJsonFile("marketplaces.json")
var test_profile: ProfileModel = loadJsonFile("profile.json")
