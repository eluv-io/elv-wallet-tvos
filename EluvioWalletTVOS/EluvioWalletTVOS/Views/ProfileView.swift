//
//  ProfileView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-03-31.
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @State var address : String = ""
    @State var userId : String = ""
    @State var network : String = ""
    @State var node : String = ""
    var logo = "e_logo"
    var logoUrl = ""
    var name = ""
    
    @State
    var locations : [String] = []
    @State private var selectedLocation = ""
    
    var body: some View {
        //ScrollView() {
        VStack() {
            HeaderView(logo:logo, logoUrl: logoUrl)
                .padding(.top,50)
                .padding(.leading,80)
                .padding(.bottom,80)
            
                VStack(alignment: .center){
                    Form {
                        Section(header: Text("Profile").foregroundColor(.white.opacity(0.6))) {
                            Text("Address:  \(address)")
                            Text("User Id:  \(userId)")
                            /*
                            Picker("Preferred location:", selection: $selectedLocation) {
                                ForEach(locations, id: \.self) {
                                    Text($0.uppercased())
                                }
                            }
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
                             */
                        }
                        .padding()
                        Section(header: Text("Fabric").foregroundColor(.white.opacity(0.6))) {
                            Text("Network:  \(network.localizedUppercase)")
                            Text("Fabric Node:  \(node)")
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
                
                self.locations = fabric.profile.profileData.locations ?? []
                self.selectedLocation = fabric.profile.profileData.preferredLocation ?? ""
            }catch {
                
            }
        }
    }
}

struct Profile_Previews: PreviewProvider {
    static var previews: some View {
        ProfileView()
            .preferredColorScheme(.dark)
            .environmentObject(Fabric())
    }
}
