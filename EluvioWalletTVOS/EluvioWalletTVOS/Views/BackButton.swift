//
//  BackButton.swift
//  FandangoWalletTVOS
//
//  Created by Wayne Tran on 2023-11-03.
//

import SwiftUI
import SDWebImageSwiftUI

struct BackButton: View {
    var buttonIcon = ""
    var buttonIconHighlighted = ""
    var buttonText = "Back to"
    var highlightColor : Color = Color(hex:0x2c59d3)
    var highlightTextColor = Color.white
    var width: CGFloat = 300
    var height: CGFloat = 80
    var action: ()->Void
    
    @State var imageLoaded = false
    
    @FocusState private var isFocused
    
    var body: some View {
        Button {
                action()
        } label: {
            HStack(spacing:20){
                if (buttonText != "") {
                    Text(buttonIcon == "" || !imageLoaded ? "Back" : buttonText)
                        .font(.system(size: 32))
                        .fontWeight(.medium)
                        .foregroundColor(isFocused ? highlightTextColor : Color.white)
                }
                
                if (isFocused && buttonIconHighlighted != ""){
                    if (buttonIconHighlighted.hasPrefix("http")){
                        WebImage(url: URL(string:buttonIconHighlighted))
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height:40)
                    }else {
                        Image(buttonIconHighlighted)
                            .resizable()
                            .frame(height:40)
                    }
                }else if (buttonIcon != "") {
                    if (buttonIcon.hasPrefix("http")){
                        WebImage(url: URL(string:buttonIcon))
                            .onSuccess{_, _, _ in
                                imageLoaded = true
                            }
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                            .frame(height: 40)

                    }else {
                        Image(buttonIcon)
                            .resizable()
                            .frame( height:40)
                    }
                }

            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width:width, height: height)
            .background(isFocused ? .black : Color(hex: 0, alpha: 0.2))
            .overlay(content: {
                    RoundedRectangle(cornerRadius:10)
                        .stroke(Color.white, lineWidth: 2)
            })
        }
        .buttonStyle(IconButtonStyle(focused:isFocused))
        .focused($isFocused)
        .opacity(imageLoaded ? 1.0 : 0.0)
        .disabled(!imageLoaded)
    }
}
