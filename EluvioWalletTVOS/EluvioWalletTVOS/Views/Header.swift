//
//  Header.swift
//  Header
//
//  Created by Wayne Tran on 2021-09-29.
//

import SwiftUI

struct HeaderView: View {
    var logo = "header_logo"
    var logoUrl = ""
    var body: some View {
        VStack {
            HStack(spacing:20) {
                Image(logo)
                    .resizable()
                    .aspectRatio(contentMode: .fit)
                    .frame(width:350)
            }
            .frame(maxWidth:.infinity, alignment: .leading)
        }
    }
}
