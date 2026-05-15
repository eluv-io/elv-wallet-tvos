// Info about an NFT contract, not a specific NFT with a token ID
public struct ContractInfoModel: Codable {
  public var contract: String
  public var cap: Int
  public var minted: Int
  public var total_supply: Int
  public var burned: Int
}

// Details about a specific NFT instance
public struct NftInfoModel: Codable {
  public var contract_addr: String
  public var offers: [NftRedeemableOffer]?
  public var tenant: String  //e.g. "iten4TXq2en3qtu3JREnE5tSLRf9zLod"
  public var token_id_str: String
  public var token_owner: String  //e.g. "0xe05Ac81248A7e9A08678Ee7756CC72219955653f"
}

public struct NftRedeemableOffer: Codable {
  public var id: String
  public var active: Bool
  public var redeemer: String?
  public var redeemed: String?  // this is a timestamp, but we only care about its existence, so leave as String
  public var transaction: String?

  public var offerRedeemed: Bool {
    return redeemer?.nilIfEmpty() != nil && redeemed?.nilIfEmpty() != nil
      && transaction?.nilIfEmpty() != nil
  }
}
