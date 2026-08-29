import EluvioCore
import SwiftUI
import SwiftyJSON

/// A `display_format == "hero"` section, rendered as a full-width banner in the
/// property's vertical scroll. Unlike tvOS - which hoists the first hero's
/// background behind the whole page - each hero draws its own background here,
/// so heroes further down the page render correctly too.
struct PropertyHeroView: View {
  let property: MediaProperty
  let section: MediaPropertySection
  let onPlay: (MediaPropertySectionMediaItem) -> Void

  @Environment(\.openURL) private var openURL

  /// Fabric links have to be resolved through the fabric, which needs the
  /// current auth token, so they're resolved in `.task` rather than inline.
  @State private var logoUrl: String?
  @State private var backgroundUrl: String?

  private var heroItem: JSON? { section.hero_items?.array?.first }

  private var title: String { heroItem?["display"]["title"].stringValue ?? "" }
  private var heroDescription: String { heroItem?["display"]["description"].stringValue ?? "" }

  private var actions: [HeroAction] {
    heroItem?["actions"].array?.compactMap { HeroAction.create(from: $0) } ?? []
  }

  /// media_link actions only carry the id of their target, so the media has to
  /// be fetched before the button knows where it goes.
  private var actionMedia: [String: MediaPropertySectionMediaItem] {
    let items = MediaItemStore.shared.observeMediaItems(ids: actions.compactMap(\.mediaId))
    return Dictionary(items.map { ($0.id, $0) }, uniquingKeysWith: { first, _ in first })
  }

  private var alignment: Alignment {
    switch heroItem?["display"]["position"].stringValue {
    case "Right": return .trailing
    case "Center": return .center
    default: return .leading
    }
  }

  private var horizontalAlignment: HorizontalAlignment {
    switch alignment {
    case .trailing: return .trailing
    case .center: return .center
    default: return .leading
    }
  }

  private var textAlignment: TextAlignment {
    switch alignment {
    case .trailing: return .trailing
    case .center: return .center
    default: return .leading
    }
  }

  var body: some View {
    VStack(alignment: horizontalAlignment, spacing: 12) {
      if let logoUrl {
        ScaledWebImage(url: logoUrl, height: 90)
          .resizable()
          .scaledToFit()
          .frame(maxWidth: 220, maxHeight: 90, alignment: alignment)
      }

      if !title.isEmpty {
        Text(title)
          .font(.title2.bold())
          .foregroundStyle(.white)
          .multilineTextAlignment(textAlignment)
      }

      if !heroDescription.isEmpty {
        Text(heroDescription)
          .font(.subheadline)
          .foregroundStyle(.white.opacity(0.85))
          .multilineTextAlignment(textAlignment)
          .lineLimit(4)
      }

      if !actions.isEmpty {
        // Buttons can outgrow the screen once there are three or more, so the
        // row scrolls rather than squeezing the labels.
        ScrollView(.horizontal, showsIndicators: false) {
          HStack(spacing: 12) {
            ForEach(renderableActions) { action in
              Button(action.text) { handleTap(action) }
                .buttonStyle(HeroActionButtonStyle(action: action))
            }
          }
        }
        .scrollBounceBehavior(.basedOnSize)
        .padding(.top, 4)
      }
    }
    .padding(.horizontal, 16)
    .padding(.vertical, 28)
    .frame(maxWidth: .infinity, minHeight: 340, alignment: alignment)
    .background {
      ZStack {
        if let backgroundUrl {
          ScaledWebImage(url: backgroundUrl, height: 340)
            .resizable()
            .aspectRatio(contentMode: .fill)
        }
        // Keeps white text legible over an arbitrary background image.
        LinearGradient(
          colors: [.black.opacity(0.2), .black.opacity(0.7)],
          startPoint: .top, endPoint: .bottom
        )
      }
    }
    .clipped()
    .task { await load() }
  }

  /// A media_link button whose media hasn't arrived yet isn't rendered, so it
  /// appears once fetched rather than misbehaving when tapped.
  private var renderableActions: [HeroAction] {
    actions.filter { $0.behavior != "media_link" || actionMedia[$0.mediaId ?? ""] != nil }
  }

  private func handleTap(_ action: HeroAction) {
    switch action.behavior {
    case "media_link":
      guard let media = actionMedia[action.mediaId ?? ""] else { return }
      if media.media_type?.lowercased() == "video" {
        onPlay(media)
      } else {
        print("Hero action media type not supported yet:", media.media_type ?? "?")
      }
    case "link":
      guard let url = action.url.flatMap(URL.init(string:)) else { return }
      openURL(url)
    case "page_link":
      // PropertyView only loads the property's first authorized page, so
      // there's nowhere to navigate to yet.
      print("Hero page_link not wired up yet: page=\(action.pageId ?? "?")")
    default:
      break
    }
  }

  private func load() async {
    let fabric = await EluvioAPI.shared.fabric
    if let logo = heroItem?["display"]["logo"], !logo.isEmpty {
      logoUrl = try? fabric.getUrlFromLink(link: logo)
    }
    // Properties that ship a phone-specific crop use it; the rest fall back to
    // the same image tvOS shows.
    let background = [
      heroItem?["display"]["background_image_mobile"],
      heroItem?["display"]["background_image"],
    ]
    .compactMap { $0 }
    .first { !$0.isEmpty }
    if let background {
      backgroundUrl = try? fabric.getUrlFromLink(link: background)
    }

    await MediaItemStore.shared.fetchMediaItems(
      propertyId: property.id,
      ids: actions.compactMap(\.mediaId),
      parentPermissions: section.resolvedPermissions,
      permissionStates: property.permission_auth_state ?? [:])
  }
}

/// Hero CTAs keep the colors the property owner picked, so they're styled from
/// the action rather than from the app's palette.
private struct HeroActionButtonStyle: ButtonStyle {
  let action: HeroAction

  func makeBody(configuration: Configuration) -> some View {
    configuration.label
      .font(.subheadline.bold())
      .foregroundStyle(action.textColor)
      .padding(.horizontal, 20)
      .padding(.vertical, 12)
      .background(action.backgroundColor)
      .clipShape(RoundedRectangle(cornerRadius: action.cornerRadius))
      .overlay {
        if let borderColor = action.borderColor {
          RoundedRectangle(cornerRadius: action.cornerRadius)
            .stroke(borderColor, lineWidth: 1)
        }
      }
      .opacity(configuration.isPressed ? 0.7 : 1)
  }
}
