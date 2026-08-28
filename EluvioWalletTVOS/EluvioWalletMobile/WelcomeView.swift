import EluvioCore
import SwiftUI

/// Full-screen sign-in gate for single-property (whitelabel) builds. Branding
/// comes from the property's login styling when the fabric supplies it, falling
/// back to the bundled start-screen assets so a fresh install still looks right
/// before the property has loaded.
struct WelcomeView: View {
  let property: MediaProperty
  let onSignedIn: () -> Void

  @State private var signIn = MobileSignIn()
  @State private var isSigningIn = false

  /// `background_image_desktop` / `logo` are the non-TV variants — the `_tv`
  /// ones are cropped for a 16:9 safe area and read badly on a phone.
  private var backgroundUrl: String? {
    property.login?.styling?.background_image_desktop?.url?.nilIfEmpty()
      ?? property.startScreenBackground.nilIfEmpty()
  }

  private var logoUrl: String? {
    property.login?.styling?.logo?.url?.nilIfEmpty()
      ?? property.startScreenImage.nilIfEmpty()
  }

  var body: some View {
    GeometryReader { geo in
      ZStack {
        background(size: geo.size)

        // Keeps the logo and button legible over arbitrary artwork.
        LinearGradient(
          colors: [.black.opacity(0.2), .black.opacity(0.85)],
          startPoint: .top, endPoint: .bottom
        )

        VStack(spacing: 24) {
          Spacer()
          logo(width: geo.size.width * 0.7)
          Spacer()

          Button {
            startSignIn()
          } label: {
            Group {
              if isSigningIn {
                ProgressView().tint(.black)
              } else {
                Text("Sign In").font(.headline)
              }
            }
            .frame(maxWidth: .infinity, minHeight: 50)
          }
          .buttonStyle(.borderedProminent)
          .tint(.white)
          .foregroundStyle(.black)
          .disabled(isSigningIn)
          .padding(.horizontal, 32)
          .padding(.bottom, 40)
        }
      }
      .frame(width: geo.size.width, height: geo.size.height)
    }
    .ignoresSafeArea()
    .onDisappear { signIn.cancel() }
  }

  @ViewBuilder
  private func background(size: CGSize) -> some View {
    if let backgroundUrl {
      ScaledWebImage(url: backgroundUrl, height: size.height)
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: size.width, height: size.height)
        .clipped()
    } else {
      Image("start-screen-background")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .frame(width: size.width, height: size.height)
        .clipped()
    }
  }

  @ViewBuilder
  private func logo(width: CGFloat) -> some View {
    if let logoUrl {
      ScaledWebImage(url: logoUrl, width: width)
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: width)
    } else {
      Image("start-screen-logo")
        .resizable()
        .aspectRatio(contentMode: .fit)
        .frame(maxWidth: width)
    }
  }

  private func startSignIn() {
    isSigningIn = true
    signIn.start(property: property) {
      onSignedIn()
    } onDismiss: {
      // Fires on cancel and error too, so the button never stays stuck.
      isSigningIn = false
    }
  }
}
