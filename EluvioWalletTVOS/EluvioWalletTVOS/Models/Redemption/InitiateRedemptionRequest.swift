struct InitiateRedemptionRequest: Codable {
  var op: String
  // random uuid.base58 e.g. "FooZeuHkupYb6cKKxDRAyQ",
  var client_reference_id: String
  var tok_addr: String
  var tok_id: String
  var offer_id: String
}
