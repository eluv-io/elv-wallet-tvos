public struct RedemptionStatus: Decodable {
  // A composite field of the form: op:contract:tokenId:offerId:clientRef
  public var op: String
  // Either "completed", "failed" or "" (pending)
  public var status: String?

  public var extra: NftClaimStatusExtra?
}

public struct NftClaimStatusExtra: Codable {
    var tx_hash: String?
}
