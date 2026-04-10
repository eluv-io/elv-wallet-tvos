//
//  ProfileView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-31.
//

import SwiftUI

struct CheckboxRow: View {
  var label: String
  @Binding var isOn: Bool

  init(_ label: String, isOn: Binding<Bool>) {
    self.label = label
    self._isOn = isOn
  }

  var body: some View {
    Button {
      isOn.toggle()
    } label: {
      HStack {
        Text(label)
        Spacer()
        Image(systemName: isOn ? "checkmark.square.fill" : "square")
          .font(.system(size: 32))
      }
      .font(.system(size: 24))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 13)
      .background(Color.white.opacity(0.1))
      .cornerRadius(10)
    }
    .buttonStyle(.plain)
  }
}

struct FormEntry: View {
  var message: String
  init(_ message: String = "") {
    self.message = message
  }

  var body: some View {
    Text(message)
      .font(.system(size: 24))
      .frame(maxWidth: .infinity, alignment: .leading)
      .padding(.horizontal, 20)
      .padding(.vertical, 13)
      .background(Color.white.opacity(0.1))
      .cornerRadius(10)
  }
}

struct ProfileView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI
  @State var address: String = ""
  @State var userId: String = ""
  @State var network: String = ""
  @State var node: String = ""
  @State var asNode: String = ""
  @State var ethNode: String = ""
  @State var tokenExpiresAt: String = ""

  var logo = "e_logo"
  var logoUrl = ""
  var name = ""

  var locations: [String] {
    return eluvio.fabric.profile.profileData.locations ?? []
  }

  @State
  var selectedLocation: String = ""

  @State var initialized = false

  @State var isStaging = false
  @State var isDeveloper = false
  @State var isDebugNode = false

  var networks: [String] = ["main", "demo"]

  var body: some View {
    VStack {
      ScrollView {
        HStack(alignment: .top, spacing: 40) {
          // Left column: Profile + App
          VStack(alignment: .leading, spacing: 12) {
            Section(header: Text("PROFILE").foregroundColor(.white.opacity(0.6)).padding(.vertical, 8)) {
              FormEntry("Address: \(address)")
              FormEntry("User Id: \(userId)")
            }

            if IsDemoMode() {
              Section(header: Text("PREFERRED LOCATION").foregroundColor(.white.opacity(0.6)).padding(.vertical, 8)) {
                Picker("", selection: $selectedLocation) {
                  ForEach(locations, id: \.self) {
                    FormEntry($0.uppercased())
                  }
                }
                .accentColor(.gray)
                .onChange(of: selectedLocation) { selected in
                  print("Selected location: ", selected)
                  Task {
                    do {
                      try await eluvio.fabric.profile.setPreferredLocation(location: selected)
                    } catch {
                      print("Error setting preferred location", error)
                    }
                  }
                }
              }
            }

            Section(header: Text("APP").foregroundColor(.white.opacity(0.6)).padding(.vertical, 8)) {
              FormEntry("Version: \(BundleVersion)")
              FormEntry("Build: \(BundleBuild)")
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)

          // Right column: Fabric
          VStack(alignment: .leading, spacing: 12) {
            Section(header: Text("FABRIC").foregroundColor(.white.opacity(0.6)).padding(.vertical, 8)) {
              FormEntry("Network: \(network.capitalized)")
              FormEntry("Fabric Node: \(node)")
              FormEntry("Authority Service: \(asNode)")
              FormEntry("Eth Service: \(ethNode)")
              FormEntry("Session Expiration: \(tokenExpiresAt)")

              CheckboxRow("Set to staging", isOn: $isStaging)
              CheckboxRow("Use debug mode", isOn: $isDebugNode)
            }
          }
          .frame(maxWidth: .infinity, alignment: .leading)
        }
        .padding(.horizontal, 50)
        .padding(.top, 40)

        Button("Sign Out") {
          Task {
            await SignOutHandler.signOut()
          }
        }
        .padding(.top, 40)
        .padding(.bottom, 80)
      }
    }
    .onChange(of: isStaging) { _, val in
      if val {
        eluvio.setEnvironment(env: .staging)
      } else {
        eluvio.setEnvironment(env: .prod)
      }
    }
    .onChange(of: isDeveloper) { _, val in
      eluvio.setDevMode(devMode: val)
    }
    .onChange(of: isDebugNode) { _, val in
      eluvio.setIsDebugNode(debugNode: val)
      self.network = eluvio.fabric.getFabricEndpoint()
    }
    .onAppear {
      let account = AccountStore.shared.account
      self.address = account?.getAccountAddress() ?? ""
      self.userId = account?.getAccountId() ?? ""

      self.node = eluvio.fabric.getFabricEndpoint()
      self.asNode = FabricConfigStore.shared.apiBaseUrl
      self.ethNode = FabricConfigStore.shared.config.getEthereumAPI()[0]

      self.isStaging = NetworkStore.shared.environment == .staging
      self.isDeveloper = eluvio.getDevMode()
      self.tokenExpiresAt = account?.expiresAtDateString ?? ""
      self.isDebugNode = eluvio.isDebugNode()

      if !initialized {
        self.network = eluvio.fabric.network
        self.selectedLocation = eluvio.fabric.profile.profileData.preferredLocation ?? ""

        debugPrint("ProfileView OnAppear - locations", self.locations)
        debugPrint("ProfileView OnAppear - selectedLocation", self.selectedLocation)
        initialized = true
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Form Entry") {
  FormEntry("Sample Label: Sample Value")
    .padding()
    .background(Color.black)
}

#Preview("Profile View") {
  ProfileView()
    .preferredColorScheme(.dark)
    .environmentObject(EluvioAPI())
}
