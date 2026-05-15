import EluvioCore
import SwiftUI

/// Minimal post-auth property landing. Confirms sign-in worked end-to-end and
/// gives the user a place to sign out. Section rendering / item navigation
/// follow in subsequent iterations.
struct PropertyView: View {
  let property: MediaProperty

  @Environment(\.dismiss) private var dismiss

  var body: some View {
    List {
      Section("Property") {
        LabeledContent("Name", value: property.displayName)
        LabeledContent("ID", value: property.id)
      }

      Section("Account") {
        if let account = AccountStore.shared.account {
          LabeledContent("Address", value: account.addr ?? "—")
          if let email = account.email, !email.isEmpty {
            LabeledContent("Email", value: email)
          }
          Button("Sign Out", role: .destructive) {
            Task {
              await SignOutHandler.signOut()
              dismiss()
            }
          }
        } else {
          Text("Not signed in")
            .foregroundStyle(.secondary)
        }
      }
    }
    .navigationTitle(property.displayName)
    .navigationBarTitleDisplayMode(.inline)
  }
}
