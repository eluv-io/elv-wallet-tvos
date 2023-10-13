//
//  ProfileView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-31.
//

import SwiftUI

struct FormEntry : View {
    var message: String
    init(_ message:String = ""){
        self.message = message
    }
    
    var body: some View {
        Button{} label: {
            Text(message)  // <<: Do anything you want with your imported View here.
                .font(.small)
                .frame(maxWidth:.infinity, alignment: .leading)
        }.buttonStyle(.plain)
    }
}

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var address : String = ""
    @State var userId : String = ""
    @State var network : String = ""
    @State var node : String = ""
    @State var asNode : String = ""
    @State var ethNode : String = ""
    
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    
    var locations : [String] {
        return fabric.profile.profileData.locations ?? []
    }
    
    @State
    var selectedLocation : String = ""
    
    @State var initialized = false
    
    var body: some View {
    //    NavigationStack {
            VStack() {
                HeaderView(logo:logo, logoUrl: logoUrl)
                    .padding(.top,50)
                    .padding(.leading,80)
                    .padding(.bottom,80)
                
                VStack(alignment: .center){
                    Form {
                        Section(header:Text("Profile").foregroundColor(.white.opacity(0.6)))
                        {
                            FormEntry("Address:  \(address)")
                            FormEntry("User Id:  \(userId)")
                            
                        }
                        .padding()
                        if IsDemoMode()  {
                            Section(header:Text("Preferred location").foregroundColor(.white.opacity(0.6))){

                                Picker("",selection: $selectedLocation) {
                                    ForEach(locations, id: \.self) {
                                        FormEntry($0.uppercased())
                                    }
                                }
                                //FIX: The highlight foreground color doesn't change from white, setting it to gray so it shows up all the time
                                .accentColor(.gray)
                                .onChange(of: selectedLocation) { selected in
                                    print("Selected location: ", selected)
                                    Task{
                                        do{
                                            try await fabric.profile.setPreferredLocation(location: selected)
                                        }catch{
                                            print("Error setting preferred location", error)
                                        }
                                    }
                                }
                                
                            }
                            .padding()
                        }

                    
                        Section(header: Text("Fabric").foregroundColor(.white.opacity(0.6))) {
                            FormEntry("Network:  \(network.localizedUppercase)")
                            FormEntry("Fabric Node:  \(node)")
                            FormEntry("Authority Service:  \(asNode)")
                            FormEntry("Eth Service:  \(ethNode)")
                        }
                        .padding()
                    }
                    .frame(width:1200)
                    
                    Button("Sign Out") {
                        fabric.signOut()
                    }
                }
                .padding([.leading,.trailing,.bottom],80)
            }
            //}
            .ignoresSafeArea()
            .onAppear(){
                do {
                    self.address = try fabric.getAccountAddress()
                    self.userId = try fabric.getAccountId()
                    self.network = fabric.network
                    self.node = try fabric.getEndpoint()
                    self.asNode = try fabric.signer?.getAuthEndpoint() ?? ""
                    self.ethNode = try fabric.signer?.getEthEndpoint() ?? ""
                    
                    if !initialized {
                        
                        self.selectedLocation = fabric.profile.profileData.preferredLocation ?? ""
                        
                        debugPrint("ProfileView OnAppear - locations", self.locations)
                        debugPrint("ProfileView OnAppear - selectedLocation", self.selectedLocation)
                        initialized = true
                    }
                }catch {
                    
                }
            }
        }
  //  }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
