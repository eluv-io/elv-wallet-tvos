extension Array {
  func filterNotNil<T>() -> [T] where Element == T? {
    compactMap { $0 }
  }
}
