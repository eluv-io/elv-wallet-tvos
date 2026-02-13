//
//  LoadingStateView.swift
//  EluvioWalletTVOS
//
//  A reusable loading state view with smooth transitions
//

import SwiftUI

struct LoadingStateView: View {
    let isLoading: Bool
    let hasContent: Bool
    
    var body: some View {
        Group {
            if isLoading && !hasContent {
                VStack(spacing: 20) {
                    ProgressView()
                        .scaleEffect(1.2)
                        .tint(.white)
                    
                    Text("Loading content...")
                        .font(.title3)
                        .foregroundColor(.white.opacity(0.8))
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
                .transition(.opacity)
            }
        }
    }
}

struct RefreshIndicator: View {
    let isRefreshing: Bool
    
    var body: some View {
        HStack {
            if isRefreshing {
                ProgressView()
                    .scaleEffect(0.8)
                    .tint(.white)
                Text("Refreshing...")
                    .font(.caption)
                    .foregroundColor(.white.opacity(0.7))
            }
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(20)
        .opacity(isRefreshing ? 1 : 0)
        .animation(.easeInOut(duration: 0.3), value: isRefreshing)
    }
}

#Preview {
    ZStack {
        Color.black.ignoresSafeArea()
        LoadingStateView(isLoading: true, hasContent: false)
    }
}