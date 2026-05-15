//
//  SignInView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import AVKit
import AuthenticationServices
import CoreImage.CIFilterBuiltins
import EluvioCore
import SwiftUI

class Subscriber {
  var view: Any
  init(view: Any) {
    self.view = view
  }
}

struct SignInView: View {
  @Environment(\.presentationMode) var presentationMode
  @Environment(\.colorScheme) var colorScheme
  @EnvironmentObject var eluvio: EluvioAPI

  var subscriber: Subscriber?
  @State var url: String = ""
  @State var code: String = ""
  @State var showDeviceFlow = false

  @FocusState private var signInFocus: Bool
  @FocusState var titleFocused: Bool
  @State var clickedNumber = 0

  enum Networks: String, CaseIterable, Identifiable {
    case main, demo
    var name: String {
      return String(describing: self)
    }

    var id: Self {
      self
    }
  }

  @State var showNetworks = false
  @State private var networkSelection: Networks = .main

  @State
  private var playerItem: AVPlayerItem? = nil

  @State var backgroundUrl = Bundle.main.url(forResource: "start-screen-bg", withExtension: "mp4")

  init() {
    // print("SignInView init()")
    subscriber = Subscriber(view: self)
    UISegmentedControl.appearance().setTitleTextAttributes(
      [.font: UIFont.preferredFont(forTextStyle: .body)], for: .normal)
  }

  var body: some View {
    if !showDeviceFlow {
      ZStack {
        eluvio.viewState.signInBackground.edgesIgnoringSafeArea(.all)
        LoopingVideoPlayer(urls: [backgroundUrl!], endAction: .loop)
          .edgesIgnoringSafeArea(.all)

        VStack {
          Spacer()
          HStack(alignment: .center, spacing: 30) {
            VStack(alignment: .center, spacing: 10) {
              if !eluvio.viewState.isBranded {
                Image("start-screen-logo")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 700)
                // .focusable(true)
                // .focused($titleFocused)
                /* .onTapGesture {
                     print("clicked 1")
                     clickedNumber += 1
                     if (!showNetworks && clickedNumber > 4) {
                         showNetworks = true
                     }
                 } */
                /*
                 if IsDemoMode() || showNetworks {
                     Picker("Networks", selection: $networkSelection) {
                         ForEach(Networks.allCases) { network in
                             Text("\(network.name.capitalizingFirstLetter())")
                                 .font(.custom("Helvetica Neue", size: 10))
                         }
                     }
                     .frame(width:300)
                 }
                  */
              } else {
                Image("start-screen-logo")
                  .resizable()
                  .aspectRatio(contentMode: .fit)
                  .frame(width: 700)
                  .padding(.bottom, 80)
              }
            }
            .padding(80)

            Spacer()

            /* if eluvio.fabric.signingIn {
                 ProgressView()
                     .padding([.trailing,.bottom],120)
             }else { */
            VStack {
              #if DEBUG
//                Picker("Networks", selection: $networkSelection) {
//                  ForEach(Networks.allCases) { network in
//                    Text("\(network.name.capitalizingFirstLetter())")
//                      .font(.custom("Helvetica Neue", size: 10))
//                  }
//                }
//                .frame(width: 300)
              #endif

              Button(action: {
                self.showDeviceFlow = true
              }) {
                Text("Sign In")
              }
              .focused($signInFocus)
            }
            .padding([.trailing, .bottom], 120)

            // }
          }
        }
      }.onAppear {
        // playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "start-screen-bg", withExtension: "mp4")!)
      }
    } else {
      /* DeviceFlowView(showDeviceFlow:$showDeviceFlow)
       .preferredColorScheme(colorScheme) */
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("Sign In View") {
  SignInView()
    .preferredColorScheme(.dark)
    .environmentObject(EluvioAPI())
}
