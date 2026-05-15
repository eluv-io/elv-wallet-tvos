public typealias PermissionStateMap = [String: PermissionAuthState]

public struct PermissionAuthState: Codable {
  public var authorized: Bool
}
