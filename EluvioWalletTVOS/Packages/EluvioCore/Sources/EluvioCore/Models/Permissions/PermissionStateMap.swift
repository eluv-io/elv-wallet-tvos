typealias PermissionStateMap = [String: PermissionAuthState]

struct PermissionAuthState: Codable {
  var authorized: Bool
}
