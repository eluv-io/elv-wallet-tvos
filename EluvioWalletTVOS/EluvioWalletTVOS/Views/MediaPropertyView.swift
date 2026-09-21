//
//  MediaPropertyView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import EluvioCore
import Foundation
import SwiftUI

/// Card geometry. Android draws 116x174dp cards on its 960dp-wide TV layout; these are the
/// same proportions at tvOS's 1920x1080.
private let cardWidth: CGFloat = 240
private let cardHeight: CGFloat = 360
private let cardCornerRadius: CGFloat = 12
private let cardShape = AnyShape(
  RoundedRectangle(cornerRadius: cardCornerRadius, style: .continuous))
private let cardSpacing: CGFloat = 20
private let cardFocusedScale = 1.08
/// Room for the focused card's scale to draw without being clipped by the row's bounds.
private let cardFocusMargin: CGFloat = 12
/// Where a row's cards stop once it's scrolled to its end - the plain screen margin, so the
/// last card doesn't sit against the right edge. The leading side gets its inset from the
/// host instead, which has the nav rail to clear.
private let rowTrailingInset: CGFloat = 80
/// The rows take whatever height is left below the hero, so the list always ends at the
/// bottom of the screen. This is only the scroll affordance below the last row now.
private let rowsViewportHeight: CGFloat = 700
/// Where the top fading edge reaches full opacity, as a fraction of the rows viewport.
private let topFadeEnd: CGFloat = 0.03

/// The vertically scrolling list of Discover rows.
///
/// tvOS scrolls the focused card to the vertical centre of the list on every focus change -
/// including sideways moves within a row - and re-asserts that position, so a `scrollTo` to
/// anywhere else is undone by the next press. The rows are laid out to make that centred
/// position the one we want instead: every row reserves the same height above its cards, so
/// centring the focused card leaves the row above just off the top edge.
struct DiscoverRowsView: View {
  var rows: [DiscoverStore.PropertyRow]
  @Binding var selected: MediaProperty?

  /// "rowIndex:propertyId" of the card that was clicked to navigate away, so it can take
  /// focus again when we come back - otherwise nothing here is focused and the tab bar
  /// steals it. The same Property can sit in more than one row, hence the row-scoped key.
  @State private var lastClickedCard: String? = nil
  @FocusState private var focusedCard: String?
  /// Guards the one-time focus grab below, so it can't yank focus off the rail later.
  @State private var claimedInitialFocus = false

  /// The card that takes focus when the page has none: the one we left from, or the first.
  private var initialCard: String? {
    if let lastClickedCard { return lastClickedCard }
    guard let first = rows.first?.properties.first else { return nil }
    return focusKey(rowIndex: 0, property: first)
  }

  var body: some View {
    // The top padding is a slice of the viewport, which is whatever the hero leaves behind,
    // so it has to be measured rather than written down.
    GeometryReader { geo in
      ScrollView(.vertical) {
        // Same reasoning as the title gap: the cards sit `cardFocusMargin` inside their
        // scroll view, so subtracting it leaves 50pt between one row's cards and the next row.
        LazyVStack(alignment: .leading, spacing: 50 - cardFocusMargin) {
          ForEach(Array(rows.enumerated()), id: \.element.id) { rowIndex, row in
            DiscoverRowView(
              rowIndex: rowIndex,
              row: row,
              lastClickedCard: $lastClickedCard,
              focusedCard: $focusedCard,
              selected: $selected
            )
          }
        }
        // Starts the first row where the top fade finishes, so its title is crisp at rest.
        // Centring row 0 would put it a shade lower, so the list has nowhere above to go
        // and stays pinned at offset 0 for as long as row 0 holds focus.
        .padding(.top, geo.size.height * topFadeEnd)
        // Lets the last row rise like every other row.
        .padding(.bottom, rowsViewportHeight / 2)
      }
    }
    .frame(maxHeight: .infinity)
    .mask(verticalFadingEdges)
    .defaultFocus($focusedCard, initialCard, priority: .userInitiated)
    .onAppear {
      // `defaultFocus` only applies to a view that has no focus yet, and by the time the
      // rows arrive the nav rail has already claimed it - the page starts out empty while
      // Discover loads. So claim focus outright the first time the rows render, which also
      // covers restoring the card we left from.
      guard !claimedInitialFocus else { return }
      claimedInitialFocus = true
      focusedCard = lastClickedCard ?? initialCard
    }
    .onChange(of: focusedCard) { _, key in
      // Focus landed somewhere on this page: restoration is either done or moot.
      if key != nil {
        lastClickedCard = nil
      }
    }
  }

  /// Fades content out at the top and bottom edges of the rows viewport.
  private var verticalFadingEdges: some View {
    LinearGradient(
      stops: [
        .init(color: .clear, location: 0),
        .init(color: .black, location: topFadeEnd),
        .init(color: .black, location: 0.55),
        .init(color: .clear, location: 1),
      ],
      startPoint: .top,
      endPoint: .bottom
    )
    // A mask otherwise takes the faded-out edges out of hit testing too, which would make
    // the cards under them unfocusable.
    .allowsHitTesting(false)
  }
}

/// A row of Property cards, under a title line that's reserved whether or not it's filled.
private struct DiscoverRowView: View {
  var rowIndex: Int
  var row: DiscoverStore.PropertyRow
  @Binding var lastClickedCard: String?
  @FocusState.Binding var focusedCard: String?
  @Binding var selected: MediaProperty?

  var body: some View {
    // The cards sit `cardFocusMargin` inside their scroll view, so subtracting it here leaves
    // 50pt of actual space between the title and the tops of the cards.
    VStack(alignment: .leading, spacing: 50 - cardFocusMargin) {
      // Rows aren't required to have a title, and featured rows never have one - but the
      // line is reserved either way. The focus engine centres the focused card, so the room
      // above a row's cards is the same however the row is built; a row that gave that room
      // back would just have the tail of the row above sitting in it.
      Text(row.title.nilIfEmpty() ?? " ")
        .font(.system(size: 28, weight: .medium))
        .foregroundColor(Color(white: 0.96))
        .padding(.leading, cardFocusMargin)
      ScrollView(.horizontal) {
        HStack(spacing: cardSpacing) {
          ForEach(row.properties) { property in
            DiscoverPropertyCard(
              property: property,
              focusKey: focusKey(rowIndex: rowIndex, property: property),
              lastClickedCard: $lastClickedCard,
              focusedCard: $focusedCard,
              selected: $selected
            )
          }
        }
        .padding(cardFocusMargin)
        .padding(.trailing, rowTrailingInset - cardFocusMargin)
        // Keeps vertical moves landing on the row's last-focused card, rather than
        // whichever card happens to sit under the previous row's focus position.
        .focusSection()
      }
      .scrollClipDisabled()
    }
  }
}

/// Flip on for local dev only, to open an inaccessible Property's card anyway so its pages
/// can be worked on. The focused card's overlay still draws, only the press goes through.
private let bypassInaccessibleFlag = false

/// A portrait Property card on the Discover page.
private struct DiscoverPropertyCard: View {
  @EnvironmentObject var router: Router
  var property: MediaProperty
  var focusKey: String
  @Binding var lastClickedCard: String?
  @FocusState.Binding var focusedCard: String?
  @Binding var selected: MediaProperty?

  private var focused: Bool { focusedCard == focusKey }

  var body: some View {
    VStack(spacing: 0) {
      Button(action: buttonPressed) {
        ZStack {
          Color(red: 0.082, green: 0.086, blue: 0.102)
          if let image = property.image?.url?.nilIfEmpty() {
            ScaledWebImage(url: image, height: cardHeight)
              .resizable()
              .aspectRatio(contentMode: .fill)
          } else {
            Text(property.displayName)
              .font(.itemSubtitle)
              .multilineTextAlignment(.center)
              .padding(20)
          }
          if property.main_page_inaccessible == true && focused {
            InaccessibleOverlay(
              message: property.main_page_inaccessible_message?.nilIfEmpty() ?? "Coming Soon")
          }
          if focused {
            // Top "sheen" highlight on the focused card.
            LinearGradient(
              stops: [
                .init(color: .white.opacity(0.45), location: 0),
                .init(color: .white.opacity(0.16), location: 0.16),
                .init(color: .clear, location: 0.42),
              ],
              startPoint: .top,
              endPoint: .bottom
            )
          }
        }
        .frame(width: cardWidth, height: cardHeight)
        .clipShape(cardShape)
        .overlay {
          if focused {
            AnimatedFocusRing(shape: cardShape)
          }
        }
      }
      .buttonStyle(TitleButtonStyle(focused: focused, scale: cardFocusedScale))
      .focused($focusedCard, equals: focusKey)
      .accessibilityIdentifier("property_\(property.id)")
    }
    .accessibilityIdentifier("property_card_\(property.id)")
    .onChange(of: focused) { _, focused in
      if focused {
        selected = property
      }
    }
  }

  private func buttonPressed() {
    debugPrint("propertyID clicked: ", property.id)
    // The card stays focusable so the hero still follows it, but there's nothing to open.
    if property.main_page_inaccessible == true && !bypassInaccessibleFlag {
      debugPrint("Press ignored - main page is inaccessible: ", property.id)
      return
    }
    lastClickedCard = focusKey

    let loggedInWithSameProvider =
      property.accountType == AccountStore.shared.account?.type
    let skipLogin = property.login?.settings?.disable_login == true
    debugPrint("disableLogin: ", skipLogin)

    if skipLogin || loggedInWithSameProvider {
      debugPrint("Going to property page ", property.id)
      let param = PropertyParam(propertyId: property.id)
      router.path.append(.property(param))
    } else {
      debugPrint("Not logged in with same account type as Property - navigating to Login.")
      router.push(to: .login(LoginParam(property: property)))
    }
  }
}

/// Covers the focused card of a Property whose main page can't be opened, with the
/// Property's own copy ("Coming Soon" when it doesn't define any).
private struct InaccessibleOverlay: View {
  var message: String

  var body: some View {
    ZStack {
      Color.black.opacity(0.6)
      Text(message)
        .font(.system(size: 30, weight: .bold))
        .textCase(.uppercase)
        .multilineTextAlignment(.center)
        .foregroundColor(Color(white: 0.96))
        .padding(.horizontal, 16)
    }
  }
}

private func focusKey(rowIndex: Int, property: MediaProperty) -> String {
  "\(rowIndex):\(property.id)"
}
