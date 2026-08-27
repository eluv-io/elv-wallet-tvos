//
//  MyItemsIcon.swift
//  EluvioWalletTVOS
//

import SwiftUI

/// The "My Items" glyph, ported from Android's `EluvioIcons.MyItems` vector so the nav rail
/// matches. Two even-odd paths on a 39x49 viewport: a card behind, and a card in front whose
/// window and caption line are cut out of it.
struct MyItemsIcon: View {
  var color: Color

  /// The source vector's aspect, so callers can size it without distorting the glyph.
  static let aspectRatio: CGFloat = 39.0 / 49.0

  var body: some View {
    MyItemsShape()
      .fill(color, style: FillStyle(eoFill: true))
  }
}

private struct MyItemsShape: Shape {
  private static let viewport = CGSize(width: 39, height: 49)

  func path(in rect: CGRect) -> Path {
    let scale = min(rect.width / Self.viewport.width, rect.height / Self.viewport.height)
    let size = CGSize(
      width: Self.viewport.width * scale, height: Self.viewport.height * scale)
    let origin = CGPoint(
      x: rect.midX - size.width / 2, y: rect.midY - size.height / 2)

    func p(_ x: CGFloat, _ y: CGFloat) -> CGPoint {
      CGPoint(x: origin.x + x * scale, y: origin.y + y * scale)
    }

    var path = Path()

    // The card peeking out behind.
    path.move(to: p(7.3125, 45.0635))
    path.addLine(to: p(7.3125, 45.9302))
    path.addCurve(
      to: p(9.9125, 48.5303), control1: p(7.3125, 47.3662), control2: p(8.4766, 48.5303))
    path.addLine(to: p(36.4005, 48.5303))
    path.addCurve(
      to: p(39.0005, 45.9302), control1: p(37.8365, 48.5303), control2: p(39.0005, 47.3662))
    path.addLine(to: p(39.0005, 9.52972))
    path.addCurve(
      to: p(36.4005, 6.9297), control1: p(39.0005, 8.0938), control2: p(37.8365, 6.9297))
    path.addLine(to: p(35.7505, 6.9297))
    path.addLine(to: p(35.7505, 42.4635))
    path.addCurve(
      to: p(33.1504, 45.0635), control1: p(35.7505, 43.8995), control2: p(34.5864, 45.0635))
    path.addLine(to: p(7.3125, 45.0635))
    path.closeSubpath()

    // The front card...
    path.move(to: p(0, 2.60004))
    path.addCurve(to: p(2.6, 0), control1: p(0, 1.1641), control2: p(1.1641, 0))
    path.addLine(to: p(29.4671, 0))
    path.addCurve(to: p(32.0671, 2.6), control1: p(30.903, 0), control2: p(32.0671, 1.1641))
    path.addLine(to: p(32.0671, 39.0005))
    path.addCurve(
      to: p(29.4671, 41.6006), control1: p(32.0671, 40.4365), control2: p(30.903, 41.6006))
    path.addLine(to: p(2.60003, 41.6006))
    path.addCurve(to: p(0, 39.0005), control1: p(1.1641, 41.6006), control2: p(0, 40.4365))
    path.addLine(to: p(0, 2.60004))
    path.closeSubpath()

    // ...its window, knocked out by the even-odd rule.
    path.move(to: p(3.46671, 5.20007))
    path.addLine(to: p(28.6004, 5.20007))
    path.addLine(to: p(28.6004, 31.2004))
    path.addLine(to: p(3.46671, 31.2004))
    path.closeSubpath()

    // ...and its caption line.
    path.move(to: p(28.6004, 33.8005))
    path.addLine(to: p(3.46671, 33.8005))
    path.addLine(to: p(3.46671, 36.4005))
    path.addLine(to: p(28.6004, 36.4005))
    path.closeSubpath()

    return path
  }
}

#Preview {
  HStack(spacing: 40) {
    MyItemsIcon(color: .white).frame(width: 34 * MyItemsIcon.aspectRatio, height: 34)
    MyItemsIcon(color: .black).frame(width: 80 * MyItemsIcon.aspectRatio, height: 80)
  }
  .padding(60)
  .background(Color.gray)
}
