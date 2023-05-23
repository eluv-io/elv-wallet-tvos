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
    
    var body: some View {
        VStack {
            HeaderView(logo:logo, logoUrl: logoUrl)
                .padding(.top,50)
                .padding(.leading,80)
                .padding(.bottom,80)
            
            VStack(alignment: .center){
                Form {
                    Section(header: Text("Profile").foregroundColor(.white.opacity(0.6))) {
                        Text("Address:  \(address)")
                        Text("User Id:  \(userId)")
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
        .ignoresSafeArea()

        .onAppear(){
            do {
                self.address = try fabric.getAccountAddress()
                self.userId = try fabric.getAccountId()
                self.network = fabric.network
                self.node = try fabric.getEndpoint()
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
