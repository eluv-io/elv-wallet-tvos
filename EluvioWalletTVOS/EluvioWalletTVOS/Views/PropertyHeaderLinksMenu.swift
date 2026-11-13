import EluvioCore
import SwiftUI

/// The property page's header menu: a pill naming the current page, which opens a list of the
/// property's `header_links`, headed by a "Home" row for the property's main page.
struct PropertyHeaderLinksMenu: View {
  @EnvironmentObject var router: Router
  @EnvironmentObject var eluvio: EluvioAPI
  let property: MediaProperty
  /// The page this screen was opened for. nil means the property's main page.
  let pageId: String?

  private enum Item: Hashable {
    case pill, home, link(String)
  }

  @State private var isOpen = false
  /// Whether the pill shows its text. Follows the pill's focus (and stays on while the menu is
  /// open), but changed in withAnimation so the toolbar animates the pill's position along with
  /// its width: an animation modifier here would only animate the width, and the pill would jump
  /// left before growing.
  @State private var isExpanded = false
  @FocusState private var focus: Item?

  private static let pillHeight: CGFloat = 72
  private static let minWidth: CGFloat = 276
  private static let maxWidth: CGFloat = 364
  private static let menuGap: CGFloat = 9
  private static let rowPadding: CGFloat = 51
  private static let rowIconSpacing: CGFloat = 21
  private static let pillPadding: CGFloat = 28
  private static let pillSpacing: CGFloat = 20
  private static let chevronWidth: CGFloat = 27.25
  private static let homeIconSize = CGSize(width: 36, height: 40)
  private static let linkIconSize = CGSize(width: 48, height: 48)
  private static let font = UIFont.systemFont(ofSize: 24, weight: .medium)
  private static let tracking: CGFloat = 0.24

  private var links: [HeaderLink] {
    // media_link targets need their media fetched before they can be opened; no property
    // uses them in the header yet.
    property.headerLinks.filter { $0.target.behavior != "media_link" }
  }

  private var selected: Item? {
    if pageId == nil || pageId == property.main_page?.id {
      return .home
    }
    let link = links.first { $0.target.behavior == "page_link" && $0.target.pageId == pageId }
    return link.map { .link($0.id) }
  }

  private var selectedLink: HeaderLink? {
    guard case .link(let id) = selected else { return nil }
    return links.first { $0.id == id }
  }

  /// The menu's width, which the expanded pill matches: wide enough for its widest row, within
  /// the min and max. Rows that don't fit are truncated.
  private var menuWidth: CGFloat {
    let rows =
      [Self.rowWidth(text: "Home", iconWidth: Self.homeIconSize.width)]
      + links.map {
        Self.rowWidth(text: $0.text, iconWidth: $0.iconUrl == nil ? nil : Self.linkIconSize.width)
      }
    return min(max(rows.max() ?? 0, Self.minWidth), Self.maxWidth)
  }

  private static func rowWidth(text: String, iconWidth: CGFloat?) -> CGFloat {
    let icon = iconWidth.map { $0 + rowIconSpacing } ?? 0
    return rowPadding * 2 + icon + textWidth(text)
  }

  private static func textWidth(_ text: String) -> CGFloat {
    let size = (text as NSString).size(withAttributes: [.font: font, .kern: tracking])
    // Rounded up, plus a point of slack so SwiftUI doesn't truncate text we measured as fitting.
    return ceil(size.width) + 1
  }

  var body: some View {
    if !links.isEmpty {
      // The menu is part of the layout rather than an overlay: focus can't reach views that
      // fall outside the toolbar's bounds.
      VStack(alignment: .leading, spacing: Self.menuGap) {
        pill
        if isOpen {
          menu.transition(.opacity)
        }
      }
      .animation(.easeInOut(duration: 0.15), value: isOpen)
      .onChange(of: focus) { oldFocus, newFocus in
        // Stay expanded through the menu opening and closing: focus goes pill -> row on open,
        // and row -> nil -> pill on close. Collapse only when the pill itself loses focus to
        // something outside the menu.
        let expand: Bool? =
          newFocus == .pill ? true : (oldFocus == .pill && !isOpen ? false : nil)
        if let expand, expand != isExpanded {
          withAnimation(.easeInOut(duration: 0.2)) { isExpanded = expand }
        }
        // Keep focus in the open menu: send it back to the row it tried to leave. Only Back
        // or choosing a row closes the menu.
        if isOpen, newFocus == nil || newFocus == .pill, let oldFocus, oldFocus != .pill {
          focus = oldFocus
        }
      }
    }
  }

  // MARK: - Pill

  private var pill: some View {
    let focused = focus == .pill
    let wide = isExpanded || isOpen
    let text = selectedLink?.text ?? "Home"
    let iconWidth: CGFloat? =
      selectedLink == nil
      ? Self.homeIconSize.width
      : selectedLink?.iconUrl == nil ? nil : Self.linkIconSize.width
    // Collapsed to the page's icon until focused or opened. A page without an icon always
    // shows its name.
    let showsText = wide || iconWidth == nil
    let textSpacing = iconWidth == nil ? 0 : Self.pillSpacing
    // What's left for the text once the padding, chevron and icon are taken out.
    let textRoom =
      menuWidth - Self.pillPadding * 2 - Self.chevronWidth - Self.pillSpacing
      - (iconWidth.map { $0 + textSpacing } ?? 0)
    let tint = focused ? ToolbarIcon.focusedTint : .white
    return Button {
      isOpen = true
      // The rows only exist once the menu opens.
      Task { @MainActor in focus = selected ?? .home }
    } label: {
      HStack(spacing: 0) {
        // Icon and text are centered together in the space left of the chevron.
        HStack(spacing: 0) {
          if let selectedLink {
            if let url = selectedLink.iconUrl {
              linkIcon(url)
            }
          } else {
            icon("home", size: Self.homeIconSize)
          }
          // Laid out at a fixed width and revealed by widening its frame, so it slides in with
          // the pill's edge instead of fading in over the chevron, and doesn't re-truncate as
          // the frame animates.
          Text(text)
            .font(Font(Self.font))
            .tracking(Self.tracking)
            .lineLimit(1)
            .frame(width: min(Self.textWidth(text), textRoom), alignment: .leading)
            .padding(.leading, textSpacing)
            .frame(width: showsText ? nil : 0, alignment: .leading)
            .clipped()
            .opacity(showsText ? 1 : 0)
        }
        .frame(maxWidth: wide ? .infinity : nil)
        chevron
          .foregroundColor(focused ? tint : Color(hex: 0x868686))
          .padding(.leading, Self.pillSpacing)
      }
      .foregroundColor(tint)
      .padding(.horizontal, Self.pillPadding)
      .frame(width: wide ? menuWidth : nil, height: Self.pillHeight)
      .background {
        if isOpen {
          Capsule()
            .fill(Color(hex: 0x070809))
            .overlay(Capsule().strokeBorder(Color(hex: 0x868686), lineWidth: 2))
        } else {
          Capsule().fill(ToolbarIcon.background(focused: focused))
        }
      }
    }
    .buttonStyle(IconButtonStyle(focused: focused, scale: 1.05))
    // The open pill keeps the design's faint glow; unfocused toolbar buttons have none.
    .shadow(
      color: focused ? ToolbarIcon.glow : isOpen ? .white.opacity(0.5) : .clear,
      radius: focused ? 10 : 5)
    .focused($focus, equals: .pill)
    .focusEffectDisabled()
    .accessibilityIdentifier("header_menu_pill")
  }

  private var chevron: some View {
    // The asset points left; the design rotates it to point down.
    Image("menu_chevron")
      .renderingMode(.template)
      .resizable()
      .frame(width: 14.75, height: Self.chevronWidth)
      .rotationEffect(.degrees(-90))
      .frame(width: Self.chevronWidth, height: 14.75)
  }

  // MARK: - Menu

  private var menu: some View {
    VStack(spacing: 8) {
      row(.home, text: "Home") {
        icon("home", size: Self.homeIconSize)
      } action: {
        show(nil)
      }
      ForEach(links) { link in
        row(.link(link.id), text: link.text) {
          if let url = link.iconUrl {
            linkIcon(url)
          }
        } action: {
          show(linkDestination(link.target, property: property))
        }
      }
    }
    .padding(.vertical, 14)
    .background(
      RoundedRectangle(cornerRadius: 30)
        .fill(Color(hex: 0x050505).opacity(0.9))
        // The same faint glow as the open pill.
        .shadow(color: .white.opacity(0.5), radius: 5)
    )
    .focusSection()
    .onExitCommand {
      isOpen = false
      focus = .pill
    }
  }

  private func row<Icon: View>(
    _ item: Item, text: String, @ViewBuilder icon: () -> Icon, action: @escaping () -> Void
  ) -> some View {
    let focused = focus == item
    return Button {
      isOpen = false
      focus = .pill
      // We're already on the selected page.
      if item != selected { action() }
    } label: {
      // Icon and text are centered together; the checkmark sits in the leading margin.
      HStack(spacing: Self.rowIconSpacing) {
        icon()
        Text(text)
          .font(Font(Self.font))
          .tracking(Self.tracking)
          .lineLimit(1)
      }
      .foregroundColor(.white)
      .padding(.horizontal, Self.rowPadding)
      .frame(width: menuWidth, height: 66)
      .overlay(alignment: .leading) {
        Image("checkmark")
          .renderingMode(.template)
          .resizable()
          .scaledToFit()
          .frame(width: 21, height: 16)
          .foregroundColor(Color(hex: 0x959595))
          .opacity(item == selected ? 1 : 0)
          .padding(.leading, 14)
      }
      .background {
        if focused {
          // The focused row's highlight pokes out past the menu's edges.
          RoundedRectangle(cornerRadius: 21)
            .fill(Color(hex: 0x393939))
            .shadow(color: Color(hex: 0x020202).opacity(0.5), radius: 24)
            .padding(.horizontal, -13)
        }
      }
      .opacity(focused ? 1 : 0.5)
    }
    .buttonStyle(MenuRowButtonStyle())
    .focused($focus, equals: item)
    .focusEffectDisabled()
    .accessibilityIdentifier("header_menu_row_\(text)")
  }

  // MARK: - Navigation

  /// Header link pages sit directly on top of the property's Home screen: opening one replaces
  /// whichever page was above Home, and Home (nil) clears the stack back down to it.
  private func show(_ destination: NavDestination?) {
    var path = router.path
    if let home = path.lastIndex(where: isHome) {
      path.removeSubrange((home + 1)...)
    } else if path.isEmpty || isAppRoot {
      // Home is the app's root screen.
      path.removeAll()
    } else {
      // This page was opened without Home under it (e.g. by a link straight to it): put Home in
      // its place.
      path.removeLast()
      path.append(.property(PropertyParam(propertyId: property.id)))
    }
    if let destination {
      path.append(destination)
    }
    router.path = path
  }

  private func isHome(_ destination: NavDestination) -> Bool {
    guard case .property(let param) = destination, param.propertyId == property.id else {
      return false
    }
    return param.pageId == nil || param.pageId == property.main_page?.id
  }

  /// Whether this property's Home is the app's root screen (see CustomAppRootView).
  private var isAppRoot: Bool {
    guard eluvio.isCustomApp(), !AccountStore.shared.isLoggedOut,
      let slug = APP_CONFIG.allowed_properties?.first
    else { return false }
    return PropertyStore.shared.getProperty(id: slug)?.id == property.id
  }

  // MARK: - Icons

  private func icon(_ name: String, size: CGSize) -> some View {
    Image(name)
      .renderingMode(.template)
      .resizable()
      .scaledToFit()
      .frame(width: size.width, height: size.height)
  }

  private func linkIcon(_ url: String) -> some View {
    ScaledWebImage(url: url, height: Self.linkIconSize.height)
      .resizable()
      .scaledToFit()
      .frame(width: Self.linkIconSize.width, height: Self.linkIconSize.height)
  }
}

/// Draws a row as-is; focus is shown by the row itself.
private struct MenuRowButtonStyle: ButtonStyle {
  func makeBody(configuration: Configuration) -> some View {
    configuration.label
  }
}
