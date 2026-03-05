#if DEBUG
  import SwiftUI

  struct DebugMenuView: View {
    @EnvironmentObject var router: Router
    @State private var isSwitching = false

    var body: some View {
      VStack(spacing: 40) {
        Text("Debug Menu")
          .font(.title2)

        if isSwitching {
          ProgressView("Switching network...")
        } else {
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
      .padding(60)
    }
  }
#endif
