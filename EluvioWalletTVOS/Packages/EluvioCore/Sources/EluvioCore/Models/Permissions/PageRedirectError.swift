public enum PageRedirectError: Error {
  case purchaseRequired(propertyId: String, pageId: String?)
  case circularRedirect
}
