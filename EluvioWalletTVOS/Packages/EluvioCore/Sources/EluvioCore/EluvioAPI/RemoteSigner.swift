import SwiftyJSON

enum APIEnvironment: String {
  case prod = ""
  case staging
}

enum RemoteSigner {
  static func getContractInfo(contractAddress: String) async throws -> ContractInfoModel {
    return try await NetworkManager.shared.request("nft/info/\(contractAddress)")
  }

  static func getNftInfo(nftAddress: String, tokenId: String) async throws -> NftInfoModel {
    return try await NetworkManager.shared.request("nft/info/\(nftAddress)/\(tokenId)")
  }

  static func createEntitlement(
    tenantId: String, marketplace: String, sku: String, purchaseId: String, authToken: String
  ) async throws -> String {
    return try await NetworkManager.shared.requestUrl(
      url: "https://appsvc.svc.eluv.io/sample-purchase/gen-entitlement")
  }
}
