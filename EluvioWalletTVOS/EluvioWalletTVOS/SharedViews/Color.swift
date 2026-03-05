//
//  Color.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-04.
//

import Foundation
import SwiftUI

extension Color {
  static let buttonGradient = LinearGradient(
    gradient: Gradient(colors: [
      Color(red: 0.22, green: 0.21, blue: 0.31),
      Color(red: 0.12, green: 0.12, blue: 0.16),
    ]),
    startPoint: .top, endPoint: .bottom)
  static let mainBackground = RadialGradient(
    gradient: Gradient(colors: [
      Color(red: 0.1, green: 0.1, blue: 0.1),
      Color(red: 0.0, green: 0.00, blue: 0.0),
    ]),
    center: .top, startRadius: 0, endRadius: 1600)

  static let secondaryBackground = LinearGradient(
    gradient: Gradient(colors: [
      Color(red: 0.14, green: 0.14, blue: 0.14),
      Color(red: 0.05, green: 0.05, blue: 0.05),
    ]),
    startPoint: .top, endPoint: .bottom)
  static let headerForeground = Color("headerForeground")
  static let profileHeader1 = Color("ProfileHeader1")
  static let profileHeader2 = Color("ProfileHeader2")
  static let tinted = Color.indigo.opacity(0.1)
  static let translucent = Color.indigo.opacity(0.1)
  static let highlight = Color.white.opacity(0.7)
  static let backgroundGradient = LinearGradient(
    gradient: Gradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.35), Color.black]),
    startPoint: .top, endPoint: .bottom)
}

extension Color {
  init(hex: Int, alpha: Double = 1.0) {
    let r = Double((hex >> 16) & 0xFF) / 255
    let g = Double((hex >> 8) & 0xFF) / 255
    let b = Double(hex & 0xFF) / 255
    self.init(red: r, green: g, blue: b, opacity: alpha)
  }
}

// MARK: - SwiftUI Previews

#Preview("Color Palette") {
  VStack(spacing: 20) {
    Text("App Color Palette")
      .font(.headline)
      .foregroundColor(.white)

    HStack(spacing: 10) {
      VStack {
        Rectangle()
          .fill(Color.tinted)
          .frame(width: 80, height: 80)
        Text("Tinted")
          .font(.caption)
      }
      VStack {
        Rectangle()
          .fill(Color.highlight)
          .frame(width: 80, height: 80)
        Text("Highlight")
          .font(.caption)
      }
      VStack {
        Rectangle()
          .fill(Color.translucent)
          .frame(width: 80, height: 80)
        Text("Translucent")
          .font(.caption)
      }
    }
    .foregroundColor(.white)

    VStack(spacing: 10) {
      Rectangle()
        .fill(Color.backgroundGradient)
        .frame(height: 100)
        .overlay(Text("Background Gradient").foregroundColor(.white))

      Rectangle()
        .fill(Color.buttonGradient)
        .frame(height: 60)
        .overlay(Text("Button Gradient").foregroundColor(.white))
    }
  }
  .padding()
  .background(Color.black)
}
