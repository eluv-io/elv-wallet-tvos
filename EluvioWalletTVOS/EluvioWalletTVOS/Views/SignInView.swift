//
//  SignInView.swift
//  EluvioLiveIOS
//
//  Created by Wayne Tran on 2021-08-10.
//

import SwiftUI
import AuthenticationServices
import SwiftEventBus
import CoreImage.CIFilterBuiltins
import AVKit

class Subscriber {
    var view : Any
    init(view: Any){
        self.view = view
    }
}

struct SignInView: View {
    @Environment(\.presentationMode) var presentationMode
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var viewState: ViewState
    
    var subscriber : Subscriber?
    @State var url :String = ""
    @State var code :String = ""
    @State var showDeviceFlow = false
    
    @FocusState private var signInFocus: Bool
    @FocusState var titleFocused: Bool
    @State var clickedNumber = 0
    
    enum Networks: String, CaseIterable, Identifiable {
        case main="main", demo="demo"
        var name: String {
            get { return String(describing: self) }
        }
        var id: Self { self }
    }
    
    @State var showNetworks = false
    @State private var networkSelection: Networks = .main
    
    @State
    private var playerItem : AVPlayerItem? = nil
    
    @State var backgroundUrl = Bundle.main.url(forResource: "start-screen-bg", withExtension: "mp4")
    
    init(){
        //print("SignInView init()")
        self.subscriber = Subscriber(view:self)
        UISegmentedControl.appearance().setTitleTextAttributes([.font : UIFont.preferredFont(forTextStyle: .body)], for: .normal)
    }


    var body: some View {
        if !showDeviceFlow {
            ZStack {
                viewState.signInBackground.edgesIgnoringSafeArea(.all)
                LoopingVideoPlayer(urls:[backgroundUrl!], endAction: .loop)
                    .edgesIgnoringSafeArea(.all)

                VStack() {
                    Spacer()
                    HStack(alignment: .center, spacing: 30){
                        VStack(alignment: .center, spacing:10){
                            if !viewState.isBranded {
                                Image("start-screen-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:700)
                                    //.focusable(true)
                                    //.focused($titleFocused)
                                    /*.onTapGesture {
                                        print("clicked 1")
                                        clickedNumber += 1
                                        if (!showNetworks && clickedNumber > 4) {
                                            showNetworks = true
                                        }
                                    }*/
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
                            }else{
                                Image("start-screen-logo")
                                    .resizable()
                                    .aspectRatio(contentMode: .fit)
                                    .frame(width:700)
                                    .padding(.bottom, 80)
                            }
                        }
                        .padding(80)
                        
                        Spacer()
                        
                        if fabric.signingIn {
                            ProgressView()
                        }else {
                            VStack{
#if DEBUG
                                Picker("Networks", selection: $networkSelection) {
                                    ForEach(Networks.allCases) { network in
                                        Text("\(network.name.capitalizingFirstLetter())")
                                            .font(.custom("Helvetica Neue", size: 10))
                                    }
                                }
                                .frame(width:300)
#endif
                                
                                Button(action: {
                                    self.showDeviceFlow = true
                                    Task {
                                        do {
                                            try await fabric.connect(network:networkSelection.name)
                                        } catch {
                                            print("Request failed with error: \(error)")
                                        }
                                    }
                                }) {
                                    Text("Sign In")
                                }
                                .focused($signInFocus)
                            }
                            .padding([.trailing,.bottom],120)
                            
                        }
                    }
                }
            }.onAppear(){
                //if (playerItem == nil){
                    playerItem = AVPlayerItem(url: Bundle.main.url(forResource: "start-screen-bg", withExtension: "mp4")!)
                //}
                DispatchQueue.main.asyncAfter(deadline: .now()+0.7) {
                    //signInFocus = true
                }
            }
        } else {
            DeviceFlowView(showDeviceFlow:$showDeviceFlow)
                .preferredColorScheme(colorScheme)
        }
    }
}

struct SignInView_Previews: PreviewProvider {
    static var previews: some View {
        SignInView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
