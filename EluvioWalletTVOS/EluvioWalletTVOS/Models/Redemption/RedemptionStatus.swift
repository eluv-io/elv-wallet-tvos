struct RedemptionStatus: Decodable {
  // A composite field of the form: op:contract:tokenId:offerId:clientRef
  var op: String
  // Either "completed", "failed" or "" (pending)
  var status: String?

  var extra: NftClaimStatusExtra?
}

struct NftClaimStatusExtra: Codable {
    var tx_hash: String?
}
