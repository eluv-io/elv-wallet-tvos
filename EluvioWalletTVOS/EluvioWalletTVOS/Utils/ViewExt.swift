import SwiftUI

extension View {
  /// Same as calling .onChange(of: value, initial: true, action).
  /// Just a convenience to remember calling initial: true
  func onAnyChange<V: Equatable>(of value: V, _ action: @escaping (V, V) -> Void) -> some View {
    return onChange(of: value, initial: true, action)
  }

  /// Starts a task when view appears and repeats it until repeatAction throws.
  /// The caller is responsible for calling Task.sleep
  func repeatTask(_ repeatAction: @escaping () async throws -> Void) -> some View {
    task {
      repeat {
        do {
          try await repeatAction()
        } catch {
          break
        }
      } while !Task.isCancelled
    }
  }
}
