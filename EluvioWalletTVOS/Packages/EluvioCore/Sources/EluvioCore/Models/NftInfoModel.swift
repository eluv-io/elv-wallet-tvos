import EluvioCore

// Info about an NFT contract, not a specific NFT with a token ID
struct ContractInfoModel: Codable {
  var contract: String
  var cap: Int
  var minted: Int
  var total_supply: Int
  var burned: Int
}

// Details about a specific NFT instance
struct NftInfoModel: Codable {
  var contract_addr: String
  var offers: [NftRedeemableOffer]?
  var tenant: String  //e.g. "iten4TXq2en3qtu3JREnE5tSLRf9zLod"
  var token_id_str: String
  var token_owner: String  //e.g. "0xe05Ac81248A7e9A08678Ee7756CC72219955653f"
}

struct NftRedeemableOffer: Codable {
  var id: String
  var active: Bool
  var redeemer: String?
  var redeemed: String?  // this is a timestamp, but we only care about its existence, so leave as String
  var transaction: String?

  var offerRedeemed: Bool {
    return redeemer?.nilIfEmpty() != nil && redeemed?.nilIfEmpty() != nil
      && transaction?.nilIfEmpty() != nil
  }
}
