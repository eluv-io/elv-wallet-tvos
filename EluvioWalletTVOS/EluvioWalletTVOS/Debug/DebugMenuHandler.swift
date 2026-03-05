#if DEBUG
  import SwiftUI

  @Observable
  class DebugMenuHandler {
    private let sequence: [KeyEquivalent] = [
      .upArrow, .upArrow, .downArrow, .downArrow,
      .leftArrow, .rightArrow, .leftArrow, .rightArrow,
    ]
    private var index = 0
    private var lastKey: KeyEquivalent?
    private var lastKeyTime: Date = .distantPast

    func handle(_ press: KeyPress, router: Router) -> KeyPress.Result {
      let now = Date()
      // De-dupe events because SwiftUI can send us multiple events for the same hardware tap
      if press.key == lastKey, now.timeIntervalSince(lastKeyTime) < 0.15 {
        return .ignored
      }
      lastKey = press.key
      lastKeyTime = now

      if press.key == sequence[index] {
        index += 1
        if index == sequence.count {
          index = 0
          debugPrint("Debug menu activated!")
          router.push(to: .debugMenu)
          return .handled
        }
      } else {
        index = 0
      }
      return .ignored
    }
  }
#endif
