import EluvioCore
import Foundation

final class Router: ObservableObject {
  static let shared = Router()
  @Published var path: [NavDestination] = []

  private init() {}

  func push(to destination: NavDestination) {
    path.append(destination)
  }

  func replace(with destination: NavDestination) {
    _ = path.popLast()
    path.append(destination)
  }

  func reset() {
    path = []
  }

  func navigateBack() {
    _ = path.popLast()
  }
}
