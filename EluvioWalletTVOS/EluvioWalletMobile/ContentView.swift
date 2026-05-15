import EluvioCore
import SwiftUI

struct ContentView: View {
  var body: some View {
    VStack(spacing: 16) {
      Text("Eluvio Wallet Mobile")
        .font(.title)
      Text("EluvioCore wired in — replace this view in Phase 6.")
        .foregroundStyle(.secondary)
        .multilineTextAlignment(.center)
        .padding(.horizontal)
    }
    .padding()
  }
}

#Preview {
  ContentView()
}
