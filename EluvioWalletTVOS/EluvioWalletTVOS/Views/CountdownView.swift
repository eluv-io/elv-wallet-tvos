//
//  PlayerCountdownView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-08-20.
//

import SwiftUI
import SDWebImageSwiftUI

struct PlayerErrorView: View {
    var backgroundImageUrl : String = "https://picsum.photos/1920/1080"
    var title: String = "The media is not available"
    
    var body: some View {
        ZStack(alignment:.center){
            
            WebImage(url:URL(string:backgroundImageUrl))
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment:.center, spacing:0){
                Spacer()
                Image(systemName:"lock")
                    .resizable()
                    .scaledToFit()
                    .frame(width:100, height:100)
                    .padding(.bottom, 52)

                Text(title).font(.system(size:32, weight:.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 52)

                Spacer()
            }
        }
    }
}

struct CountDownView: View {
    var backgroundImageUrl : String = "https://picsum.photos/1920/1080"
    var images : [String] = []
    var imageUrl : String = "https://picsum.photos/300/200"
    var title: String = "Solvenia vs Denmark"
    var infoText: String = "16 Jun, 9:00 CET Group F Matchday 1"
    var startDateTime : String = ""
    
    @State var timeRemaining : String = ""
    
    @State var timer:Timer?
    
    var body: some View {
        ZStack(alignment:.center){
            
            WebImage(url:URL(string:backgroundImageUrl))
                .resizable()
                .edgesIgnoringSafeArea(.all)
            
            Color.black.opacity(0.5)
                .edgesIgnoringSafeArea(.all)
            
            VStack(alignment:.center, spacing:0){
                Spacer()
                if images.isEmpty {
                    WebImage(url:URL(string:imageUrl))
                        .resizable()
                        .scaledToFit()
                        .frame(width:600, height:300)
                        .padding(.bottom, 52)
                }else if !images.isEmpty {
                    HStack(spacing:52) {
                        ForEach(0..<images.count, id:\.self) { index in
                            WebImage(url:URL(string:images[index]))
                                .resizable()
                                .scaledToFit()
                                .frame(width:200, height:200)
                                .padding(.bottom, 52)
                        }
                    }
                }
                
                Text(infoText).font(.system(size:32))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .padding(.bottom, 28)
                
                Text(title).font(.system(size:32, weight:.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .multilineTextAlignment(.center)
                    .padding(.bottom, 52)
                
                Text(timeRemaining).font(.system(size:62, weight:.semibold))
                    .lineLimit(1)
                    .frame(maxWidth: 1600)
                    .multilineTextAlignment(.center)
                    .padding()
                Spacer()
            }
        }
        .onAppear(){
            
            timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { timer in
                let dateFormatter = ISO8601DateFormatter()
                dateFormatter.formatOptions = [
                    .withFractionalSeconds,
                    .withFullDate,
                    .withTime, // without time zone
                    .withColonSeparatorInTime,
                    .withDashSeparatorInDate
                ]
                
                if let startDate = dateFormatter.date(from:startDateTime) {
                    if startDate > Date() {
                        let formatter = DateComponentsFormatter()
                        formatter.unitsStyle = .full
                        formatter.allowedUnits = [.day, .hour, .minute, .second]
                        formatter.zeroFormattingBehavior = .pad
                        
                        let remainingTime: TimeInterval = startDate.timeIntervalSince(Date())
                        timeRemaining = formatter.string(from: remainingTime) ?? ""
                    }else{
                        timeRemaining = "Starting soon"
                    }
                }
            }
        }
    }
}

struct CountDownView_Previews: PreviewProvider {
    static var previews: some View {
        CountDownView()
    }
}
