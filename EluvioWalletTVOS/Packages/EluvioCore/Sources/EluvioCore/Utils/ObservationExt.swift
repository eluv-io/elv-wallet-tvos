import Foundation
import Observation

// Don't forget to weakly capture [self] in your callback:
//     `guard let self else { return }`
public func withObservationTracking(execute: @Sendable @escaping () -> Void) {
  Observation.withObservationTracking {
    execute()
  } onChange: {
    DispatchQueue.main.async {
      withObservationTracking(execute: execute)
    }
  }
}

public func waitForNonNil<T>(_ getValue: () -> T?) async -> T {
  while true {
    if let value = getValue() {
      return value
    }
    try? await Task.sleep(for: .milliseconds(50))
  }
}
