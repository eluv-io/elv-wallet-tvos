import EluvioCore
import SwiftUI

@Observable
class DebugMenuHandler {
  private let sequence: [MoveCommandDirection] = [
    .up, .up, .down, .down,
    .left, .right, .left, .right,
  ]
  private var index = 0
  private var last: MoveCommandDirection?
  private var lastTime: Date = .distantPast

  /// The Siri Remote's directional input arrives as a move command, not a key press — only a
  /// hardware keyboard produces the latter, which is why the sequence worked in the simulator
  /// and nowhere else. Both paths feed the same state machine so either input can open the menu.
  func handle(_ direction: MoveCommandDirection, router: Router) {
    guard isDebugBuildOrTestFlight else { return }

    let now = Date()
    // De-dupe events because a single hardware tap can arrive twice — SwiftUI repeats key
    // presses, and in the simulator an arrow key lands as both a key press and a move command.
    if direction == last, now.timeIntervalSince(lastTime) < 0.15 {
      return
    }
    last = direction
    lastTime = now

    if direction == sequence[index] {
      index += 1
      if index == sequence.count {
        index = 0
        debugPrint("Debug menu activated!")
        router.push(to: .debugMenu)
      }
    } else {
      index = 0
    }
  }

  func handle(_ press: KeyPress, router: Router) -> KeyPress.Result {
    guard let direction = Self.direction(for: press.key) else { return .ignored }
    handle(direction, router: router)
    return .ignored
  }

  private static func direction(for key: KeyEquivalent) -> MoveCommandDirection? {
    switch key {
    case .upArrow: .up
    case .downArrow: .down
    case .leftArrow: .left
    case .rightArrow: .right
    default: nil
    }
  }
}
