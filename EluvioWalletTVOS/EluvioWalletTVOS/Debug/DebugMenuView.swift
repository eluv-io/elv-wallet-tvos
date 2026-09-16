import EluvioCore

#if DEBUG
  import SwiftUI

  struct DebugMenuView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    @EnvironmentObject var router: Router
    @State private var isSwitching = false
    /// Mirrored rather than read straight off the store, which isn't observable — without a
    /// copy of its own the row's checkmark wouldn't redraw when it's toggled.
    @State private var isStaging = NetworkStore.shared.environment == .staging

    var body: some View {
      VStack(spacing: 40) {
        Text("Debug Menu")
          .font(.title2)

        if isSwitching {
          ProgressView("Switching network...")
        } else {
          VStack(spacing: 12) {
            sectionHeader("Network")

            // Held at the outer spacing so the rows sit where they always have; only the
            // header is pulled in close to the group it names.
            VStack(spacing: 40) {
              ForEach(AppMode.allCases, id: \.self) { mode in
                Button {
                  guard mode != NetworkStore.shared.selectedNetwork else {
                    router.navigateBack()
                    return
                  }
                  isSwitching = true
                  Task {
                    debugPrint("Setting network to \(mode)")
                    NetworkStore.shared.selectedNetwork = mode
                    await FabricConfigStore.shared.refreshConfig(for: mode)
                    await SignOutHandler.signOut()
                  }
                } label: {
                  HStack {
                    Text(mode.rawValue.capitalized)
                    Spacer()
                    if mode == NetworkStore.shared.selectedNetwork {
                      Image(systemName: "checkmark")
                    }
                  }
                  .frame(width: 300)
                }
              }
            }
          }

          // Staging rides on top of whichever network is selected rather than being a
          // network of its own, which is why it's named apart from the list above. Same
          // switch as Profile's "Set to staging": the environment is recorded and the app
          // asked to refresh, with no config reload or sign-out of its own.
          VStack(spacing: 12) {
            sectionHeader("Environment")

            Button {
              isStaging.toggle()
              eluvio.setEnvironment(env: isStaging ? .staging : .prod)
            } label: {
              HStack {
                Text("Staging")
                Spacer()
                if isStaging {
                  Image(systemName: "checkmark")
                }
              }
              .frame(width: 300)
            }
          }
        }
      }
      .padding(60)
    }

    private func sectionHeader(_ title: String) -> some View {
      Text(title)
        .font(.caption)
        .foregroundStyle(.secondary)
        .frame(width: 300, alignment: .leading)
    }
  }
#endif
