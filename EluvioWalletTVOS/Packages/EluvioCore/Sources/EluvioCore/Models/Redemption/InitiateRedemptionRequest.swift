public struct InitiateRedemptionRequest: Codable {
  public var op: String
  // random uuid.base58 e.g. "FooZeuHkupYb6cKKxDRAyQ",
  public var client_reference_id: String
  public var tok_addr: String
  public var tok_id: String
  public var offer_id: String
}
