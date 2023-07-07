//
//  MediaRowViewModel.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-07-07.
//

import Foundation

struct MediaLibrary: Identifiable {
    var id = UUID().uuidString
    var features: Features = Features()
    var items: [NFTModel] = []
    var mediaRows: [MediaRowViewModel] = []
}

enum MediaRowFilter {case all; case video; case images; case apps; case books; case albums; case items}

struct MediaRowViewModel: Identifiable {
    var id = UUID().uuidString
    var name: String = ""
    var features: Features = Features()
    var videos: [MediaItem] = []
    var books: [MediaItem] = []
    var albums: [NFTModel] = []
    var liveStreams: [MediaItem] = []
    var images: [MediaItem] = []
    var galleries: [MediaItem] = []
    var apps: [MediaItem] = []
    var item: NFTModel = NFTModel()
    var filter: MediaRowFilter = .all
    
    var collection: MediaCollection {
        var collection = MediaCollection(name:name)
        var media : [MediaItem] = []
        if filter == .all{
            media.append(contentsOf: liveStreams)
            media.append(contentsOf: videos)
           //media.append(contentsOf: albums) //TODO: support albums
            media.append(contentsOf: images)
            media.append(contentsOf: galleries)
            media.append(contentsOf: books)
            //media.append(contentsOf: item)
        }else if filter == .video{
            media.append(contentsOf: liveStreams)
            media.append(contentsOf: videos)
        }else if filter == .images{
            media.append(contentsOf: galleries)
            media.append(contentsOf: images)
        }else if filter == .apps{
            media = apps
        }
        collection.media = media
        return collection
    }
}
