//
//  NFTDetail.swift
//  NFTDetail
//
//  Created by Wayne Tran on 2021-09-27.
//

import SwiftUI
import SwiftyJSON
import AVKit

struct MediaView: View {
    @EnvironmentObject var fabric: Fabric
    @State var media: MediaItem? = nil
    @Binding var showPlayer : Bool
    @Binding var playerItem : AVPlayerItem?
    @FocusState var isFocused
    @State var showGallery = false
    @State var gallery: [GalleryItem] = []
    
    var body: some View {
        HStack(alignment: .top, spacing: 40) {
            Button(action: {
                if media?.media_type == "Video" {
                        Task {
                            do {
                                let optionsUrl = try fabric.getUrlFromLink(link: media?.media_link?["sources"]["default"], params: media?.parameters ?? [] )
                                print("options url \(optionsUrl)")
                                guard let hash = FindContentHash(uri: optionsUrl) else {
                                    throw RuntimeError("Could not find hash from \(optionsUrl)")
                                }
                                
                                let optionsJson = try await fabric.getJsonRequest(url: optionsUrl)
                                print("options json \(optionsJson)")
                                
                                let licenseServer = optionsJson["hls-fairplay"]["properties"]["license_servers"][0].stringValue
                                
                                if(licenseServer.isEmpty)
                                {
                                    throw RuntimeError("Error getting licenseServer")
                                }
                                print("license_server \(licenseServer)")
                                
                                let hlsPlaylistUrl = try fabric.getHlsPlaylistFromOptions(optionsJson: optionsJson, hash: hash)
                                
                                print("Playlist URL \(hlsPlaylistUrl)")
                                
                                let urlAsset = AVURLAsset(url: URL(string: hlsPlaylistUrl)!)
                                ContentKeyManager.shared.contentKeySession.addContentKeyRecipient(urlAsset)
                                ContentKeyManager.shared.contentKeyDelegate.setDRM(licenseServer:licenseServer, authToken: fabric.fabricToken)
                                
                                self.playerItem = AVPlayerItem(asset: urlAsset)
                                self.showPlayer = true
                                
                            } catch {
                                print("Error getting Options url from link \(error)")
                            }
                        }
                    }
                else if media?.media_type == "HTML" {
                    do {
                        let htmlUrl = try fabric.getUrlFromLink(link: media?.media_file, params: media?.parameters ?? [])
                        print("url \(htmlUrl)")
                        
                    } catch {
                        print("Error getting Options url from link \(error)")
                    }
                }
                else if media?.media_type == "Gallery" {
                    if media?.gallery != nil {
                        self.gallery = media?.gallery ?? []
                        self.showGallery = true
                    }
                }
 
            }) {
                CacheAsyncImage(url: URL(string: media?.image ?? "")) { image in
                    image.resizable()
                        .aspectRatio(contentMode: .fill)
                        .frame( width: 200, height: 200)
                        .cornerRadius(15)
                } placeholder: {
                    ProgressView()
                }
            }
            .buttonStyle(DetailButtonStyle(focused: isFocused))
            .focused($isFocused)
            .overlay(content: {
                if (media?.media_type == "Video"){
                    Image(systemName: "play.fill")
                        .font(.system(size: 80))
                        .foregroundColor(.white)
                        .opacity(0.7)
                }
            })
            
            Text(media?.name ?? "")
                .foregroundColor(Color.white)
                .lineLimit(3)
                .frame(width:300, alignment: .leading)
            
        }
        .fullScreenCover(isPresented: $showGallery) {
            GalleryView(gallery: $gallery)
                .environmentObject(self.fabric)
                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
                .edgesIgnoringSafeArea(.all)
        }
    }
}

struct MediaCollectionView: View {
    @EnvironmentObject var fabric: Fabric
    @State var mediaCollection: MediaCollection
    @Binding var showPlayer : Bool
    @Binding var playerItem : AVPlayerItem?
    
    var body: some View {
        ScrollView(.horizontal) {
            LazyHStack(alignment: .top, spacing: 20) {
                ForEach(self.mediaCollection.media) {media in
                    MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem)
                }
            }
            .padding(20)
        }
    }
}

struct NFTDetailView: View {
    @Environment(\.presentationMode) var presentationMode: Binding<PresentationMode>
    @Environment(\.colorScheme) var colorScheme
    @Namespace var nftDetails
    @EnvironmentObject var fabric: Fabric
    @State var search = false
    @State var searchText = ""
    @State var showPlayer = false
    @State var playerItem : AVPlayerItem? = nil
    var title = ""
    @Binding var nft: NFTModel
    @Binding var featuredMedia: [MediaItem]
    @Binding var collections: [MediaCollection]
    @Binding var richText : AttributedString
    @FocusState var isFocused
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading) {
                HStack(alignment: .top, spacing: 40) {
                    Button(action: {
                    }) {
                        AsyncImage(url: URL(string: nft.meta.image)) { image in
                            image.resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame( width: 400, height: 400, alignment: .topLeading)
                                .cornerRadius(15)
                        } placeholder: {
                            ProgressView()
                        }
                    }
                    .buttonStyle(PrimaryButtonStyle(focused: isFocused))
                    .focused($isFocused)
                    
                    VStack(alignment: .leading, spacing: 20)  {
                        Text(nft.meta.displayName).font(.title2)
                            .foregroundColor(Color.white)
                            .fontWeight(.bold)
                        HStack {
                            Text(nft.meta.editionName)
                                .font(.headline)
                                .foregroundColor(Color.white)
                            Text("# \(nft.token_id_str)")
                                .font(.headline)
                                .foregroundColor(Color.yellow)
                        }
                        if nft.meta_full != nil {
                            if(self.richText.description.isEmpty) {
                                Text(nft.meta_full?["description"].stringValue ?? "")
                                    .foregroundColor(Color.white)
                                    .padding(.top)
                            }else {
                                Text(self.richText)
                                    .foregroundColor(Color.white)
                                    .padding(.top)
                            }
                        }else{
                            Text(nft.meta.description)
                                .foregroundColor(Color.white)
                        }
                    }
                    Spacer()
                }
                
                if self.featuredMedia.count > 0 {
                    VStack(alignment: .leading, spacing: 20)  {
                        Text("FEATURED MEDIA")
                        ScrollView(.horizontal) {
                            LazyHStack(alignment: .top, spacing: 20) {
                                ForEach(self.featuredMedia) {media in
                                    MediaView(media: media, showPlayer: $showPlayer, playerItem: $playerItem)
                                }
                            }
                            .padding(20)
                        }
                    }
                }
                
                LazyVStack(alignment: .leading, spacing: 20)  {
                    ForEach(collections) { collection in
                        Text(collection.name)
                        MediaCollectionView(mediaCollection: collection, showPlayer: $showPlayer, playerItem: $playerItem)
                    }
                }
                .padding(.top, 20)
            }
            .fullScreenCover(isPresented: $showPlayer) {
                PlayerView(playerItem:self.$playerItem)
                    .environmentObject(self.fabric)
                    .preferredColorScheme(colorScheme)
                    .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .topLeading)
            }
        }
    }
}



struct NFTDetail: View {
    @EnvironmentObject var fabric: Fabric
    @State var nft : NFTModel
    @State var featuredMedia: [MediaItem] = []
    @State var collections: [MediaCollection] = []
    @State var richText: AttributedString = ""
    
    var body: some View {
        VStack{
            NFTDetailView(nft:$nft, featuredMedia: $featuredMedia, collections:$collections, richText: $richText)
                .padding()
        }
        .task(){
            do{
                /*
                var mediaSections = nft.meta_full?["additional_media_sections"]

                let decoder = JSONDecoder()
                if let featured_media = mediaSections?["featured_media"] {
                    do {
                        self.featuredMedia = try decoder.decode([MediaItem].self, from: featured_media.rawData())
                    } catch {
                        print(error.localizedDescription)
                    }
                } */
                
                
                
            /*
                if let sections = mediaSections?["sections"] {
                    for section in sections.arrayValue {
                        let mediaCollections = section["collections"]
                        do {
                            self.collections = try decoder.decode([MediaCollection].self, from: mediaCollections.rawData())
                            print ("Media Collections \(self.collections.count)")
                        } catch {
                            print(error.localizedDescription)
                        }
                    }
                }
             */
                
                
                 
                if let additions = nft.additional_media_sections {
                    self.featuredMedia = additions.featured_media
                    
                    var collections: [MediaCollection] = []
                    for section in additions.sections {
                        for collection in section.collections {
                            collections.append(collection)
                        }
                    }
                    
                    self.collections = collections
                    print(self.collections)
                }
                
                let data = Data(nft.meta_full?["description_rich_text"].stringValue.utf8 ?? "".utf8)
                if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                    self.richText = AttributedString(attributedString)
                    self.richText.foregroundColor = .white
                    self.richText.font = .body
                }
                
            }catch {
                print("Fetching nft data failed with error \(error)")
            }
            
        }
    }
    
}

struct NFTDetail_Previews: PreviewProvider {
    static var previews: some View {
        NFTDetail(nft: test_NFTs[0])
                .listRowInsets(EdgeInsets())
    }
}
