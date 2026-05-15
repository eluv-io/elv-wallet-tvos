//
//  OryDeviceFlowView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-24.
//

import CoreImage.CIFilterBuiltins
import EluvioCore
import SwiftUI

struct OryDeviceFlowView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var router: Router

  @State private var activation: ActivationCode? = nil
  @State private var pollTask: Task<Void, Never>? = nil

  var property: MediaProperty

  var logo: String {
    return property.login?.styling?.logo_tv?.url ?? ""
  }

  var backgroundImage: String {
    return property.login?.styling?.background_image_tv?.url
      ?? property.login?.styling?.background_image_desktop?.url
      ?? ""
  }

  var body: some View {
    ZStack {
      Color.mainBackground.edgesIgnoringSafeArea(.all)
      ScaledWebImage(url: backgroundImage, height: UIScreen.main)
        .resizable()
        .scaledToFill()
        .edgesIgnoringSafeArea(.all)

      VStack(alignment: .center, spacing: 30) {
        VStack(alignment: .center, spacing: 20) {
          Text("Sign In")
            .font(.title)
            .fontWeight(.semibold)
            .padding()

          Text(activation?.code ?? "")
            .font(.custom("Helvetica Neue", size: 50))
            .fontWeight(.semibold)
          if let url = activation?.url {
            Image(uiImage: GenerateQRCode(from: url))
              .interpolation(.none)
              .resizable()
              .scaledToFit()
              .frame(width: 400, height: 400)
          } else {
            Rectangle()
              .fill(.clear)
              .frame(width: 400, height: 450)
          }
        }
        .frame(width: 700)

        Spacer()
          .frame(height: 10.0)

        HStack(alignment: .center, spacing: 40) {
          Button(action: {
            Task { await self.regenerateCode() }
          }) {
            Text("Request New Code")
          }
          Button(action: {
            self.presentationMode.wrappedValue.dismiss()
          }) {
            Text("Back")
          }
        }
        .focusSection()
        .padding(.bottom, 40)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .edgesIgnoringSafeArea(.all)
    .background(.thickMaterial)
    .accessibilityIdentifier("login_view")
    .task {
      debugPrint("OryDeviceFlowView path ", router.path)
      await self.regenerateCode()
    }
    .onDisappear {
      pollTask?.cancel()
    }
  }

  private func regenerateCode() async {
    pollTask?.cancel()
    let flow = DeviceActivationFlow(property: property, shortenUrl: true)
    do {
      let activation = try await flow.requestActivation()
      self.activation = activation
      pollTask = Task {
        do {
          try await flow.awaitCompletion(activation: activation)
          await MainActor.run { didSignIn() }
        } catch is CancellationError {
          // expected when view goes away or user re-requests
        } catch {
          print("Activation polling failed:", error)
        }
      }
    } catch {
      print("Could not get code for MetaMask login", error)
    }
  }

  private func didSignIn() {
    router.path.removeAll()
    router.path.append(.property(PropertyParam(propertyId: property.id)))
  }
}

// MARK: - SwiftUI Previews

#Preview("Ory Device Flow View") {
  // Disabled for now
  //  OryDeviceFlowView()
  //    .environmentObject(EluvioAPI())
  //    .preferredColorScheme(.dark)
}
