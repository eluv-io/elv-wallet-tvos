public extension Duration {
  public static func minutes(_ minutes: Double) -> Duration {
    return .seconds(minutes * 60)
  }
}
