//
//  InfoTab.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-02-01.
//

import SwiftUI

struct InfoTab: View {
    var image: UIImage
    var title = ""
    var description = ""
    var copyright = ""
    
    var body: some View {
        HStack(alignment:.top) {
            Image(uiImage: image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width: 250, height: 250, alignment: .top)
                .clipped()
                .layoutPriority(1)
                .padding(.top, 10)
            
            VStack(alignment:.leading) {
                Text(title)
                    .font(.title2)
                Text(description)
                    .opacity(0.8)
                    .lineLimit(4)
                Spacer()
                if (!copyright.isEmpty){
                    Text("Copyright © \(copyright)")
                        .font(.footnote)
                }
            }
            .frame(maxWidth:.infinity, alignment: .leading)
        }
        .padding(.top,20)
    }
}
