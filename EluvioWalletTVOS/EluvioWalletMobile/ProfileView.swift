import EluvioCore
import SwiftUI

struct ProfileView: View {
  var body: some View {
    NavigationStack {
      if let account = AccountStore.shared.account {
        SignedInProfile(account: account)
      } else {
        ContentUnavailableView(
          "Not Signed In",
          systemImage: "person.crop.circle.badge.questionmark",
          description: Text("Open a property from the Home tab to sign in.")
        )
        .navigationTitle("Profile")
      }
    }
  }
}

private struct SignedInProfile: View {
  let account: Account

  var identifier: String {
    if let email = account.email, !email.isEmpty {
      return email
    }
    return account.addr ?? ""
  }

  var body: some View {
    List {
      Section {
        VStack(spacing: 12) {
          Image(systemName: "person.crop.circle.fill")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(width: 80, height: 80)
            .foregroundStyle(.secondary)
          Text(identifier)
            .font(.headline)
            .lineLimit(2)
            .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .listRowBackground(Color.clear)
      }

      Section("Account") {
        if let email = account.email, !email.isEmpty {
          LabeledContent("Email", value: email)
        }
        LabeledContent("User ID", value: account.getAccountId() ?? "—")
          .lineLimit(1)
          .truncationMode(.middle)
        LabeledContent("Address", value: account.addr ?? "—")
          .lineLimit(1)
          .truncationMode(.middle)
      }

      Section("Session") {
        LabeledContent("Expires", value: account.expiresAtDateString)
      }

      Section("System") {
        LabeledContent("Network", value: NetworkStore.shared.selectedNetwork.rawValue.capitalized)
        LabeledContent("App Version", value: "\(BundleVersion) (\(BundleBuild))")
      }

      Section {
        Button("Sign Out", role: .destructive) {
          Task { await SignOutHandler.signOut() }
        }
      }
    }
    .navigationTitle("Profile")
  }
}

#Preview {
  ProfileView()
}
