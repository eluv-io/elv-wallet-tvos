//
//  MediaPropertyDetailView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-06-14.
//

import SwiftUI
import SDWebImageSwiftUI

struct MediaPropertySectionView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    @EnvironmentObject var viewState: ViewState
    var propertyId: String
    var section: MediaPropertySection

    var body: some View {
        VStack(alignment: .leading, spacing: 10)  {
            if let display = section.display {
                Text(display["title"].stringValue).font(.rowTitle).foregroundColor(Color.white)
            }
            
            ScrollView(.horizontal) {
                HStack(alignment: .top, spacing: 50) {
                    ForEach(section.content ?? []) {item in
                        /*if item.media_type == "list" {
                            SectionItemListView(propertyId: propertyId, item:item)
                                .environmentObject(self.pathState)
                                .environmentObject(self.fabric)
                                .environmentObject(self.viewState)
                        }else {*/
                        if item.type == "item_purchase" {
                            //Skip for now
                        }else{
                            SectionItemView(item: item, propertyId: propertyId)
                                .environmentObject(self.pathState)
                                .environmentObject(self.fabric)
                                .environmentObject(self.viewState)
                        }
                    }
                }
            }
            .scrollClipDisabled()
            
        }
        .padding(.top)
    }
}

struct MediaPropertyDetailView: View {
    @Environment(\.colorScheme) var colorScheme
    @EnvironmentObject var fabric: Fabric
    @EnvironmentObject var pathState: PathState
    @EnvironmentObject var viewState: ViewState
    var property: MediaPropertyViewModel
    @State var sections : [MediaPropertySection] = []
    
    var body: some View {
        VStack(alignment:.leading) {
            ScrollView() {
                MediaPropertyHeader(logo: property.logo, title: property.logoAlt, description: property.description, descriptionRichText: property.descriptionRichText)
                
                ForEach(sections) {section in
                    if let propertyId = property.id {
                        MediaPropertySectionView(propertyId: propertyId, section: section)
                    }
                }
                
            }
            .scrollClipDisabled()
        }
        .frame(maxWidth: .infinity, alignment: .center)
        .padding(.top, 10)
        .background(
            ZStack {
                Color.black.edgesIgnoringSafeArea(.all)
                if (property.backgroundImage.hasPrefix("http")){
                    WebImage(url: URL(string: property.backgroundImage))
                        .resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth:.infinity, maxHeight:.infinity)
                        .frame(alignment: .topLeading)
                        .clipped()
                }else if(property.backgroundImage != "") {
                    Image(property.backgroundImage)
                        .resizable()
                        .transition(.fade(duration: 0.5))
                        .aspectRatio(contentMode: .fill)
                        .frame(maxWidth:.infinity, maxHeight:.infinity)
                        .frame(alignment: .topLeading)
                        .clipped()
                }
            }
            .edgesIgnoringSafeArea(.all)
        )
        .onAppear(){
            debugPrint("MediaPropertyDetailView onAppear")
            
            Task {
                do {
                    guard let id = property.id else {
                        return
                    }
                    self.sections = try await  fabric.getPropertySections(property: id, sections: property.sections)
                    //let sectionsJSON = try await fabric.getPropertySectionsJSON(property: id, sections: property.sections)
                    //debugPrint("Sections ", sectionsJSON)
                }catch {
                    print("Error getting property sections ", error.localizedDescription)
                }
            }
        }
    }
}


struct MediaPropertyHeader: View {
    @EnvironmentObject var fabric: Fabric
    var logo: String = ""
    var title: String = ""
    var description: String = ""
    var descriptionRichText: AttributedString = ""
    
    var body: some View {
        VStack(alignment:.leading, spacing: 10) {
            
            if (logo.isEmpty) {
                Text(title).font(.title3)
                    .foregroundColor(Color.white)
                    .fontWeight(.bold)
                    .frame(maxWidth:1500, alignment:.leading)
            }else{
                WebImage(url: URL(string: logo))
                    .resizable()
                    .transition(.fade(duration: 0.5))
                    .aspectRatio(contentMode: .fit)
                    .frame(width:800, height:400, alignment: .leading)
                    .clipped()
            }
            
            if (!description.isEmpty) {
                Text(description)
                    .foregroundColor(Color.white)
                    //.padding(.top)
                    .font(.propertyDescription)
                    .frame(maxWidth:1200, alignment:.leading)
                    .lineLimit(3)
            }else {
                Text(self.descriptionRichText)
                .foregroundColor(Color.white)
                //.padding(.top)
                .font(.propertyDescription)
                .frame(maxWidth:1200, alignment:.leading)
                .lineLimit(10)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(.top, 10)
    }
}
