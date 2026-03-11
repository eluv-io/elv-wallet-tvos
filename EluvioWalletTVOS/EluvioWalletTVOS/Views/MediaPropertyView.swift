//
//  MediaPropertyView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-13.
//

import Foundation
import SwiftUI

struct MediaPropertyView: View {
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var router: Router
  var property: MediaProperty
  @FocusState private var focused: Bool
  @Binding var selected: MediaProperty?
  var isSimple = false
  var simpleText: String {
    AccountStore.shared.isLoggedOut ? "Sign In" : "Welcome Back"
  }

  var width: CGFloat = 330
  var height: CGFloat = 470

  var cornerRadius: CGFloat = 3

  @State var disabled = true

  var body: some View {
    VStack(spacing: 10) {
      if isSimple {
        Button(action: buttonPressed) {
          Text(simpleText)
        }
        .focused($focused)
        .onAppear {
          focused = true
        }
      } else {
        Button(action: buttonPressed) {
          if let image = property.image?.url?.nilIfEmpty() {
            ScaledWebImage(url: image, height: height)
              .resizable()
              .onSuccess { image, data, cacheType in
                self.disabled = false
              }
              .aspectRatio(contentMode: .fill)
              .frame(width: width, height: height)
              .cornerRadius(cornerRadius)
          } else {
            ZStack {
              if property.backgroundImage != "" {
                ScaledWebImage(url: property.backgroundImage, height: height)
                  .resizable()
                  .onSuccess { image, data, cacheType in
                    self.disabled = false
                  }
                  .aspectRatio(contentMode: .fill)
                  .frame(width: width, height: height)
                  .cornerRadius(3)

                Rectangle()
                  .fill(Color.black)
                  .opacity(focused ? 0.7 : 0.5)
                  .frame(width: width, height: height)
                  .cornerRadius(3)
              } else {
                Rectangle()
                  .fill(Color.secondaryBackground)
                  .frame(width: width, height: height)
                  .cornerRadius(3)
              }
              if property.displayName.isEmpty {
                //Text("Untitled").font(.largeTitle)
              } else {
                Text(property.displayName).font(.largeTitle.bold())
              }
            }
          }
        }
        .opacity(self.disabled ? 0 : 1)
        .buttonStyle(TitleButtonStyle(focused: focused, bordered: true, borderRadius: cornerRadius))
        .focused($focused)
        .accessibilityIdentifier("property_\(property.id ?? "unknown")")
      }

    }
    .accessibilityIdentifier("property_card_\(property.id ?? "unknown")")
    .onChange(of: focused) { _, focused in
      if focused {
        selected = property
      }
    }
  }

  private func buttonPressed() {
    debugPrint("propertyID clicked: ", property.id)

    let loggedInWithSameProvider =
      property.accountType == AccountStore.shared.account?.type
    let skipLogin = property.login?.settings?.disable_login == true
    debugPrint("disableLogin: ", skipLogin)

    if skipLogin || loggedInWithSameProvider {
      debugPrint("Going to property page ", property.id)
      let param = PropertyParam(propertyId: property.id)
      router.path.append(.property(param))
    } else {
      debugPrint("Not logged in with same account type as Property - navigating to Login.")
      router.push(to: .login(LoginParam(property: property)))
    }
  }
}

struct MediaPropertiesView: View {
  @Environment(\.colorScheme) var colorScheme

  var numColumns = 5
  var properties: [MediaProperty]
  var propertiesGroups: [[MediaProperty]] {
    properties.dividedIntoGroups(of: numColumns)
  }

  @Binding var selected: MediaProperty?

  var body: some View {
    VStack(alignment: .leading, spacing: 20) {
      ForEach(propertiesGroups, id: \.self) { groups in
        HStack(alignment: .center, spacing: 20) {
          ForEach(groups, id: \.self) { property in
            MediaPropertyView(property: property, selected: $selected)
              .fixedSize()
          }

        }
        .frame(maxWidth: .infinity, alignment: .leading)
      }
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
