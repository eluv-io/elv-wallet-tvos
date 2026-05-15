public extension Array {
  public func filterNotNil<T>() -> [T] where Element == T? {
    compactMap { $0 }
  }
}
