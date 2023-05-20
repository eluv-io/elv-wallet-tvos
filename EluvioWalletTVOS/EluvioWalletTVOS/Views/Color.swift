//
//  Color.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-04.
//

import Foundation
import SwiftUI

extension Color {
    static let mainBackground = LinearGradient(gradient: Gradient(colors:
                                                                    [Color(red: 0.12, green: 0.12, blue: 0.12),
                                                                     Color(red: 0.05, green: 0.05, blue: 0.05)]),
                                                startPoint: .top, endPoint: .bottom)
    static let secondaryBackground = LinearGradient(gradient: Gradient(colors:
                                                                    [Color(red: 0.14, green: 0.14, blue: 0.14),
                                                                     Color(red: 0.05, green: 0.05, blue: 0.05)]),
                                                startPoint: .top, endPoint: .bottom)
    static let headerForeground = Color("headerForeground")
    static let profileHeader1 = Color("ProfileHeader1")
    static let profileHeader2 = Color("ProfileHeader2")
    static let tinted = Color.indigo.opacity(0.1)
    static let translucent = Color.indigo.opacity(0.1)
    static let highlight = Color.white.opacity(0.7)
    static let backgroundGradient = LinearGradient(gradient: Gradient(colors: [Color(red: 0.2, green: 0.2, blue: 0.35), Color.black]), startPoint: .top, endPoint: .bottom)
}

extension View {
    func selfSizeMask<T: View>(_ mask: T) -> some View {
        ZStack {
            self.opacity(0)
            mask.mask(self)
        }.fixedSize()
    }
}
