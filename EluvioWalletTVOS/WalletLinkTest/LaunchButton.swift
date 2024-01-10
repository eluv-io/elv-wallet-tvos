//
//  LaunchButton.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-10-13.
//
import SwiftUI

struct LaunchButton: View {
    var buttonIcon = ""
    var buttonIconHighlighted = ""
    var buttonText = ""
    var highlightColor : Color = Color(hex:0x2c59d3)
    var highlightTextColor = Color.white
    var width: CGFloat = 380
    var height: CGFloat = 80
    var action: ()->Void
    
    @FocusState private var isFocused
    
    
    var body: some View {
        Button {
                action()
        } label: {
            HStack(spacing:20){
                if (isFocused && buttonIconHighlighted != ""){
                    Image(buttonIconHighlighted)
                        .resizable()
                        .frame(width:40, height:40)
                }else if (buttonIcon != "") {
                    Image(buttonIcon)
                        .resizable()
                        .frame(width:40, height:40)
                }
                if (buttonText != "") {
                    Text(buttonText)
                        .font(.system(size: 32))
                        .fontWeight(.medium)
                        .foregroundColor(isFocused ? highlightTextColor : Color.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width:width, height: height)
            .overlay(content: {
                if (!isFocused) {
                    RoundedRectangle(cornerRadius:10)
                        .stroke(Color.white, lineWidth: 4)
                }
            })
        }
        .buttonStyle(IconButtonStyle(focused:isFocused, highlightColor: highlightColor))
        .focused($isFocused)
    }
}

//This button has the outline as the selection mode
struct LaunchButton2: View {
    var buttonIcon = ""
    var buttonIconHighlighted = ""
    var buttonText = ""
    var highlightColor : Color = Color(hex:0x2c59d3)
    var buttonColor : Color = Color(hex:0x2c59d3)
    var highlightTextColor = Color.white
    var width: CGFloat = 380
    var height: CGFloat = 80
    var action: ()->Void
    
    @FocusState private var isFocused
    
    
    var body: some View {
        Button {
                action()
        } label: {
            HStack(spacing:20){
                if (isFocused && buttonIconHighlighted != ""){
                    Image(buttonIconHighlighted)
                        .resizable()
                        .frame(width:40, height:40)
                }else if (buttonIcon != "") {
                    Image(buttonIcon)
                        .resizable()
                        .frame(width:40, height:40)
                }
                if (buttonText != "") {
                    Text(buttonText)
                        .font(.system(size: 32))
                        .fontWeight(.medium)
                        .foregroundColor(isFocused ? highlightTextColor : Color.white)
                }
            }
            .padding(.horizontal, 20)
            .padding(.vertical, 20)
            .frame(width:width, height: height)
            .overlay(content: {
                if (isFocused) {
                    RoundedRectangle(cornerRadius:10)
                        .stroke(Color.white, lineWidth: 4)
                }
            })
        }
        .buttonStyle(IconButtonStyle(focused:isFocused, highlightColor: highlightColor, buttonColor: buttonColor))
        .focused($isFocused)
    }
}
