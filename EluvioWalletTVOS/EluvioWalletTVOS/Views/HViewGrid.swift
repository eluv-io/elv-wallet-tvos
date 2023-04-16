//
//  HViewGrid.swift
//  HViewGrid
//
//  Created by Wayne Tran on 2021-09-28.
//

import SwiftUI
import SDWebImageSwiftUI

struct HViewGrid: View {
    var title: String
    var subtitle: String
    var titleLink: AnyView?
    var titleImageUri: String
    @State var seeMore: Bool
    @State private var linkActive: Bool
    
    let rows = [
        GridItem(.flexible()),GridItem(.flexible())
    ]
    
    let row = [
        GridItem(.flexible())
    ]
    private static let initialColumns = 5
    @State private var gridColumns = Array(repeating: GridItem(.flexible()), count: initialColumns)

    @State private var numColumns = initialColumns
    
    var nfts : [NFTModel]
    
    var width : CGFloat
    var height : CGFloat
    
    init(title: String = "",
         subtitle: String = "",
         titleLink: AnyView? = nil,
         titleImageUri: String = "",
         seeMore: Bool = false,
         nfts: [NFTModel],
         width: CGFloat = 100,
         height: CGFloat = 150
    ){
        print("HViewGrid title: " + title)
        self.title = title
        self.subtitle = subtitle
        self.titleLink = titleLink
        self.titleImageUri = titleImageUri
        self.seeMore = seeMore
        self.nfts = nfts
        self.width = width
        self.height = height
        self.linkActive = false
    }
    
    var titleView: some View {
        Group {
            if(!titleImageUri.isEmpty){
                WebImage(url: URL(string: titleImageUri))
                    .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                /*
                AsyncImage(url: URL(string: titleImageUri)) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width: 30)
                } placeholder: {
                    ProgressView()
                }*/
            }
            
            VStack(spacing:20){
                if(!title.isEmpty){
                    Text(title).font(.title3).bold()
                }
                if(!subtitle.isEmpty){
                    Text(subtitle).font(.subheadline).bold().foregroundColor(.gray)
                }
            }
        }
    }
    
    var body: some View {
        VStack(alignment:.leading) {
            GeometryReader { geo in
                HStack {
                    titleView
                }.padding()
                
                ScrollView(.horizontal, showsIndicators: false) {
                    LazyVGrid(columns: gridColumns) {
                        ForEach(nfts) { nft in
                            NavigationLink(destination: NFTDetail(nft: nft)) {
                                NFTView(nft:nft)
                                    .frame(width:300, height: 180)
                            }
                        }
                    }
                }
                .padding(.leading)
                .frame(height: height + 20)
            }
            
            //Divider().padding()
        }
        .onAppear {
            if(titleLink != nil){
                self.linkActive = true
                print("linkActive = true")
            }
        }
    }
}

struct HView_Previews: PreviewProvider {
    static var previews: some View {
        HViewGrid(title: "Recent", titleLink:AnyView(Text("")),
                  nfts: CreateTestNFTs(num: 10))
    }
}
