//
//  NavRailView.swift
//  EluvioWalletTVOS
//

import EluvioCore
import SwiftUI

/// Geometry of the nav rail. Android draws its drawer at 56x48dp items inside 12dp of padding;
/// these are the same values at tvOS's 2x scale (see CarouselItemCard's "1080p pixels are 2x dp").
enum NavRail {
  static let padding: CGFloat = 24
  static let collapsedItemWidth: CGFloat = 112
  static let expandedItemWidth: CGFloat = 360
  static let itemHeight: CGFloat = 96
  static let iconSize: CGFloat = 48
  /// Drawn size of the glyph inside that slot.
  static let glyphSize: CGFloat = 34

  /// Where the rail's outer edge — and its divider — sits.
  static let collapsedWidth: CGFloat = padding * 2 + collapsedItemWidth

  /// How far tab content is inset from the screen edge — the rail's outer edge plus a clear
  /// gap, so content doesn't crowd the divider.
  static let contentInset: CGFloat = collapsedWidth + 120

  /// The collapsed item is wider than it is tall, so a capsule leaves a stumpy pill rather than
  /// a circle. Insetting each side by half the difference squares it off into a true circle —
  /// and expands into a pill on its own once the item grows.
  static let highlightInset: CGFloat = (collapsedItemWidth - itemHeight) / 2

  /// Item colours, sampled from a screenshot of the Android rail rather than derived from
  /// `NavigationDrawerItemDefaults` — the library's documented defaults resolve the selected
  /// content to `onSecondaryContainer` (white), but Android actually renders it at
  /// `inverseSurface`. Measured: selected glyph #D4D4D4, unselected glyphs #787A79.
  static let focusedContainer = Color(hex: 0xD4D4D4)
  static let focusedContent = Color.black
  /// The focused item's glyph stops short of black, the same way the unfocused glyph stops
  /// short of the label's white.
  static let focusedIcon = Color(hex: 0x2A2A2A)
  static let selectedContainer = Color(hex: 0x626262, alpha: 0.4)
  static let selectedContent = Color(hex: 0xD4D4D4)
  /// Once the rail holds focus its unselected items go to full white (`onSurface`); until then
  /// they sit dimmed.
  static let content = Color.white
  static let inactiveContent = Color(hex: 0x787A79)
  /// Android tints the leading icon a step darker than the label, so an unselected item reads
  /// as white text beside a slightly grey glyph rather than both at full white.
  static let icon = Color(hex: 0xCCCCCC)

  static let expandAnimation = Animation.easeOut(duration: 0.2)
  static let dividerFadeIn = Animation.easeIn(duration: 0.3)
}

extension MainTab {
  var title: String {
    switch self {
    case .Discover: "Home"
    case .Items: "My Items"
    case .Profile: "Profile"
    }
  }

  /// SF Symbol for the tabs Android draws with Material defaults. My Items has its own vector
  /// (see `MyItemsIcon`), so it has no symbol here.
  var symbol: String? {
    switch self {
    case .Discover: "house.fill"
    case .Items: nil
    case .Profile: "person.crop.circle.fill"
    }
  }

  var accessibilityId: String {
    switch self {
    case .Discover: "tab_home"
    case .Items: "tab_my_items"
    case .Profile: "tab_profile"
    }
  }
}

/// The left-hand navigation rail: a column of icons that expands to show labels while it holds
/// focus, and collapses back to icons when focus moves into the tab content.
struct NavRailView: View {
  @Binding var selection: MainTab
  @FocusState.Binding var focusedTab: MainTab?
  var onSelect: (MainTab) -> Void
  /// Fired when Right should hand focus back to the tab content.
  var onExit: () -> Void

  var tabs: [MainTab] = [.Discover, .Items, .Profile]

  private var expanded: Bool { focusedTab != nil }

  var body: some View {
    VStack(spacing: 8) {
      ForEach(tabs, id: \.self) { tab in
        NavRailItem(
          tab: tab,
          selected: selection == tab,
          expanded: expanded,
          focused: focusedTab == tab,
          action: { onSelect(tab) }
        )
        .focused($focusedTab, equals: tab)
      }
    }
    .frame(maxHeight: .infinity)
    .padding(NavRail.padding)
    // Scrims the tab content sliding under the rail. Only while collapsed — once the items
    // expand they carry their own highlights and the gradient would sit behind them.
    .background(alignment: .leading) {
      LinearGradient(
        stops: [
          .init(color: .black.opacity(0.8), location: 0),
          .init(color: .black.opacity(0.3), location: 0.8),
          .init(color: .clear, location: 1),
        ],
        startPoint: .leading,
        endPoint: .trailing
      )
      .frame(width: NavRail.collapsedWidth)
      .opacity(expanded ? 0 : 1)
      .allowsHitTesting(false)
    }
    // Pinned to the collapsed width rather than the rail's trailing edge, so it stays put
    // instead of riding outwards as the items expand.
    .overlay(alignment: .leading) {
      NavRailDivider()
        .opacity(expanded ? 0 : 1)
        // Fades in, but cuts out: on expand the items are sliding over where it sits, and a
        // fading divider would show through them.
        .animation(expanded ? nil : NavRail.dividerFadeIn, value: expanded)
        .offset(x: NavRail.collapsedWidth)
        .allowsHitTesting(false)
    }
    .animation(NavRail.expandAnimation, value: expanded)
    // Entering the rail lands on whichever item is spatially nearest; the current tab is what
    // the user expects. Only redirects on the way in, so it doesn't fight arrowing up/down.
    .onChange(of: focusedTab) { previous, current in
      guard previous == nil, let current, current != selection else { return }
      focusedTab = selection
    }
    .focusSection()
    // Android does not leave this to the focus engine either - its drawer intercepts
    // DirectionRight and closes itself (Dashboard.kt). Relying on spatial focus fails on a
    // screen whose only focusable element sits well above the rail items, which is exactly
    // what My Items is.
    .onMoveCommand { direction in
      if direction == .right { onExit() }
    }
    .accessibilityIdentifier("nav_rail")
  }
}

/// Hairline at the rail's outer edge. Per the design it doesn't run edge to edge: it fades up
/// from nothing, peaks just past centre, and is gone before the bottom.
private struct NavRailDivider: View {
  var body: some View {
    LinearGradient(
      stops: [
        .init(color: .clear, location: 0.10),
        .init(color: .white.opacity(0.45), location: 0.55),
        .init(color: .clear, location: 0.93),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    .frame(width: 1)
    .frame(maxHeight: .infinity)
  }
}

/// The rail draws its own highlight, so the button contributes no chrome of its own —
/// `.plain` still lays a system focus background under the label, which read as a second
/// highlight behind ours.
private struct NavRailButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}

private struct NavRailItem: View {
  var tab: MainTab
  var selected: Bool
  var expanded: Bool
  var focused: Bool
  var action: () -> Void

  private var highlightColor: Color {
    if focused { return NavRail.focusedContainer }
    if selected { return NavRail.selectedContainer }
    return .clear
  }

  /// The label is only visible while the rail is expanded, and is full white unless this is
  /// the focused item.
  private var labelColor: Color {
    focused ? NavRail.focusedContent : NavRail.content
  }

  private var iconColor: Color {
    if focused { return NavRail.focusedIcon }
    if selected { return NavRail.selectedContent }
    // Android dims every item while no nav item holds focus.
    return expanded ? NavRail.icon : NavRail.inactiveContent
  }

  /// My Items uses Android's own glyph; the other two are the SF Symbol equivalents of the
  /// Material icons Android uses.
  @ViewBuilder
  private var icon: some View {
    if let symbol = tab.symbol {
      Image(systemName: symbol)
        .font(.system(size: NavRail.glyphSize))
        .foregroundColor(iconColor)
    } else {
      MyItemsIcon(color: iconColor)
        .frame(
          width: NavRail.glyphSize * MyItemsIcon.aspectRatio, height: NavRail.glyphSize)
    }
  }

  var body: some View {
    Button(action: action) {
      HStack(spacing: 20) {
        icon
          .frame(width: NavRail.iconSize, height: NavRail.iconSize)
        if expanded {
          Text(tab.title)
            .foregroundColor(labelColor)
            .font(.system(size: 28))
            .lineLimit(1)
            .fixedSize()
            .transition(.opacity)
        }
        Spacer(minLength: 0)
      }
      .padding(.horizontal, NavRail.highlightInset + (NavRail.itemHeight - NavRail.iconSize) / 2)
      .frame(
        width: expanded ? NavRail.expandedItemWidth : NavRail.collapsedItemWidth,
        height: NavRail.itemHeight,
        alignment: .leading
      )
      .background(
        Capsule()
          .fill(highlightColor)
          .padding(.horizontal, NavRail.highlightInset)
      )
    }
    .buttonStyle(NavRailButtonStyle())
    .accessibilityIdentifier(tab.accessibilityId)
    .accessibilityLabel(tab.title)
  }
}
