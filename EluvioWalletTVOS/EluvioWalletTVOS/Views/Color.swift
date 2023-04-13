//
//  Color.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-10-04.
//

import Foundation
import SwiftUI

extension Color {
    static let mainBackground = Color.black
    static let mainBackground2 = Color("MainBackground2")
    static let headerForeground = Color("headerForeground")
    static let profileHeader1 = Color("ProfileHeader1")
    static let profileHeader2 = Color("ProfileHeader2")
    static let tinted = Color.indigo.opacity(0.1)
    static let translucent = Color.indigo.opacity(0.1)
    static let highlight = Color.gray
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
