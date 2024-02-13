//
//  BooksGallery.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-21.
//

import SwiftUI
import TVUIKit
import AVFoundation

struct TextItem: Identifiable, Decodable {
    var id: String? = UUID().uuidString
    var title: String? = ""
    var description: String? = ""
    var label: String? = ""
    var text: String = ""
    var start: Int64? = 0
    var end: Int64? = 0
    var highlight: Bool? = true
}

struct PageOverride {
    var url : URL
    var page : Int
}

class BookItem: BooksDisplayItem {
    var copyright = ""
    var pdfLink = URL(string:"")
    var mainAudioLink : URL?
    var audioPages : [AudioPageModel] = []
    var interactiveItems : [InteractiveMediaItem] = []
    var pageOverrides: [Int : PageOverride] = [:]
    var animatePageTransitions = false
    var coverArtImageUrl : URL?
    
    init(id: String? = nil, image: UIImage? = nil, posterImage: UIImage? = nil, name: String = "", description: String = "", copyright: String = "", pdfLink: URL? = nil, mainAudioLink: URL? = nil, audioPages : [AudioPageModel] = [], pageOverrides: [Int : PageOverride] = [:], animatePageTransitions: Bool = false) {
        
        debugPrint(" BookItem \(name) poster: \(posterImage)")
        
        super.init(id:id,image:image, posterImage: posterImage, name:name,description:description)
        self.copyright = copyright
        self.pdfLink = pdfLink
        self.mainAudioLink = mainAudioLink
        self.type = .Book
        self.audioPages = audioPages
        self.pageOverrides = pageOverrides
        self.animatePageTransitions = animatePageTransitions
    }
}

class InteractiveAudioItem: InteractiveMediaItem {
    override init(id: String? = nil, image: UIImage? = nil, posterImage: UIImage? = nil, name: String = "", description: String = "", mainLink: URL? = nil, mainText : [TextItem] = []) {
        super.init(id:id,image:image,posterImage:posterImage, name:name,description:description, mainLink:mainLink, mainText:mainText)
        self.type = .InteractiveAudio
    }
}

class InteractiveVideoItem: InteractiveMediaItem {
    override init(id: String? = nil, image: UIImage? = nil, posterImage: UIImage? = nil, name: String = "", description: String = "", mainLink: URL? = nil, mainText : [TextItem] = []) {
        super.init(id:id,image:image,posterImage:posterImage, name:name,description:description, mainLink:mainLink, mainText:mainText)
        self.type = .InteractiveVideo
    }
}

class InteractiveMediaItem: BooksDisplayItem {
    var mainLink : URL?
    var mainText: [TextItem] = []
    
    init(id: String? = nil, image: UIImage? = nil, posterImage: UIImage? = nil, name: String = "", description: String = "", mainLink: URL? = nil, mainText : [TextItem] = []) {
        super.init(id:id,image:image,posterImage:posterImage, name:name,description:description)
        self.mainLink = mainLink
        self.mainText = mainText
    }
}

class BooksDisplayItem: Identifiable {
    enum ItemType {case None; case Book; case InteractiveVideo; case InteractiveAudio}
    
    var id: String? = UUID().uuidString
    var image : UIImage?
    var posterImage : UIImage?
    var name = ""
    var description = ""
    var type : ItemType = .Book
    
    init(id: String? = nil, image: UIImage? = nil, posterImage: UIImage? = nil, name: String = "", description: String = "") {
        debugPrint(" BooksDisplayItem \(name) poster: \(posterImage)")
        self.id = id
        self.image = image
        self.posterImage = posterImage
        self.name = name
        self.description = description
    }
}

struct TVPoster: UIViewRepresentable {
    var image: UIImage
    var title: String?
    var subtitle: String?
    var width: CGFloat = 0
    var height: CGFloat = 0

    func makeUIView(context: Context) -> TVPosterView {
        let view = TVPosterView(image:image)
        //view.frame = CGRect(x:0, y:0, width:width, height:height)
        view.contentSize = CGSize(width:width, height:height)
        //view.imageView.masksFocusEffectToContents = true
        view.imageView.clipsToBounds = true
        view.imageView.contentMode = .scaleAspectFit
        view.imageView.layer.cornerRadius = 10;
        view.imageView.layer.masksToBounds = true;

        //view.contentMode = .scaleAspectFit
        view.title = title
        view.subtitle = title
        view.clipsToBounds = true
        return view
    }

    func updateUIView(_ uiView: TVPosterView, context: Context) {
        uiView.contentSize = CGSize(width:40, height:40)
        uiView.image = image
        uiView.title = title
        uiView.subtitle = subtitle
    }
}

struct BooksGalleryItemView: View {
    @Binding var item : BooksDisplayItem
    @Binding var selected: Bool
    @Binding var selectedItem: BooksDisplayItem
    @FocusState var focused
    
    var width : CGFloat = 400
    var body: some View {
        VStack(spacing:40){
            Button{
                selectedItem = item
                selected = true
            } label: {
                if let image = item.posterImage {
                    //TVPoster(image: image, title: item.name, width: width, height: width*1.5)
                    //.frame(width:width, height:width*1.5)
                        Image(uiImage: image)
                            .resizable()
                            .aspectRatio(contentMode: .fill)
                            .frame(width:width, height:width*1.5)
                            //.padding()
                            .clipped()
                }else{
                    ZStack{
                        Rectangle()
                            .background(.gray)
                            .frame(width:width, height:width*1.5)
                        VStack{
                            Image(systemName: "book")
                                .resizable()
                                .aspectRatio(contentMode: .fill)
                                .frame(width:width/2, height:width/2)
                                .padding()
                            
                        }
                    }
                }
            }
            .buttonStyle(.card)
            .focused($focused)
            
            //Spacer()
            
            Text(item.name)
                .padding()
                .frame(width:width)
                .lineLimit(2)
                .fixedSize(horizontal: false, vertical: true)
        }
        .frame(width:width, height:width*1.8)
    }
}


struct BooksGallery: View {
    @State var books : [BooksDisplayItem] = []
    @State var selectedItem = BooksDisplayItem()
    @State var showBook = false
    var imageWidth : CGFloat = 300
    // Create a speech synthesizer.
    var synthesizer = AVSpeechSynthesizer()

    var body: some View {
        VStack(alignment:.center){
            Text("Ebooks and Interactive Media").font(.title)
            VStack(alignment:.center){
                ScrollView(.horizontal) {
                    LazyHStack(spacing:40) {
                        //Spacer()
                        ForEach(0..<books.count, id: \.self) { index in
                            BooksGalleryItemView(item: $books[index], selected: $showBook, selectedItem: $selectedItem, width: imageWidth)
                                .padding()
                        }
                        
                        //Spacer()
                    }
                    .frame(maxWidth:.infinity)
                    .padding()
                }
                .scrollClipDisabled()
                .padding()
            }
        }
        .fullScreenCover(isPresented: $showBook){ [selectedItem] in
            if let book = selectedItem as? BookItem {
                PDFPage(title:book.name,
                        url: book.pdfLink,
                        audioUrl: book.mainAudioLink,
                        description: book.description,
                        copyright: book.copyright,
                        coverArtUrl: book.coverArtImageUrl,
                        mediaItems: book.interactiveItems,
                        audioPages: book.audioPages,
                        enablePageTransitions: book.animatePageTransitions
                )
            }else if let item = selectedItem as? InteractiveMediaItem{
                InteractiveMediaView(item: item)
            }
        }
        .onAppear() {
            Task{
                debugPrint("BooksGallery OnAppear")
                
                do {
                    
                    guard let pdfUrl = Bundle.main.url(forResource: "AQP - opening" , withExtension: "pdf") else {
                        throw ("Could not get a-quiet-place-2018 url")
                    }
                    
                    guard let audioUrl = Bundle.main.url(forResource: "AQP-audio" , withExtension: "wav") else {
                        throw ("Could not find: AQP-audio.wav")
                    }
                    
                    let audioPages: [AudioPageModel] = try loadJsonFile("AQP-audio-pages.json")
                    
                    
                    let aqpBook = try createBookItem(
                        name: "A Quiet Place Script",
                        description: "If they hear you, they hunt you. A family must live in silence to avoid mysterious creatures that hunt by sound. Knowing that even the slightest whisper or footstep can bring death, Evelyn and Lee are determined to find a way to protect their children while desperately searching for a way to fight back.",
                        posterImage: "A-Quiet-Place-Poster.jpg",
                        copyright:"2018",
                        pdfLink:pdfUrl,
                        mainAudioLink: audioUrl,
                        audioPages: audioPages
                    )
                    
                    guard let scriptCoverUrl = Bundle.main.url(forResource: "AQP-Script" , withExtension: "png") else {
                        throw ("Could not find: AQP-Script.png")
                    }
                    
                    aqpBook.coverArtImageUrl = scriptCoverUrl
                    
                    guard let videoUrl = Bundle.main.url(forResource: "A Quiet Place - Opening" , withExtension: "mp4") else {
                        throw ("Could not find: A Quiet Place - Opening.mp4")
                    }
                    let aqpItem = try createInteractiveItem(
                        name: "A Quiet Place Opening Scene",
                        description: "If they hear you, they hunt you. A family must live in silence to avoid mysterious creatures that hunt by sound. Knowing that even the slightest whisper or footstep can bring death, Evelyn and Lee are determined to find a way to protect their children while desperately searching for a way to fight back.",
                        image: "AQP-InteractiveVideo.png",
                        posterImage: "",
                        mainLink: videoUrl,
                        textFile: "AQP-video-transcript.json",
                        type: .InteractiveVideo
                    )
                    
                    
                    let aqpAudio = try createInteractiveItem(
                        name: "A Quiet Place Audio Dictation",
                        description: "If they hear you, they hunt you. A family must live in silence to avoid mysterious creatures that hunt by sound. Knowing that even the slightest whisper or footstep can bring death, Evelyn and Lee are determined to find a way to protect their children while desperately searching for a way to fight back.",
                        image: "AQP-Dictation.png",
                        posterImage: "",
                        mainLink: audioUrl,
                        textFile: "AQP-audio-sync.json",
                        type: .InteractiveAudio
                    )

                    aqpBook.interactiveItems.append(aqpItem)
                    aqpBook.interactiveItems.append(aqpAudio)

                    await MainActor.run {
                        books.append(aqpBook)
                    }
                    
                }catch{
                    print(error)
                }
                
                
                do {
                    guard let url = Bundle.main.url(forResource: "Flash-comic" , withExtension: "pdf") else {
                        debugPrint("Could not get Flash-comic url")
                        return
                    }
                    
                    
                    guard let page1Video = Bundle.main.url(forResource: "flash_page_1" , withExtension: "mp4") else {
                        debugPrint("Could not get flash_page_1 url")
                        return
                    }
                    
                    guard let page5Video = Bundle.main.url(forResource: "flash_page_5" , withExtension: "mp4") else {
                        debugPrint("Could not get flash_page_1 url")
                        return
                    }
                    
                    
                    
                    
                    let pageOverrides: [Int : PageOverride] = [1:PageOverride(url:page1Video, page:1), 5:PageOverride(url:page5Video, page:5)]
                    
                    let flashItem = try createBookItem(
                        name: "The Flash Interactive Comic",
                        description: "The Flash, The Fast Man Alive. This is the official movie tie-in comic!",
                        posterImage:"",
                        copyright: "2023",
                        pdfLink: url,
                        pageOverrides: pageOverrides
                    )
                    
                    flashItem.animatePageTransitions = true
                    
                    await MainActor.run {
                        books.append(flashItem)
                    }
                }catch{
                    print(error)
                }
                
                do {
                    guard let url = Bundle.main.url(forResource: "Entertainment Weekly - 05 July 2015" , withExtension: "pdf") else {
                        throw ("Could not get Entertainment Weekly - 05 July 2015 url")
                    
                    }
                    let EWItem = try createBookItem(
                        name: "Entertainment Weekly - 05 July 2015",
                        description: "Entertainment Weekly invades Hall H with a pair of starry panels. First off, Outlander’s Sam Heughan and other hot young actors from some of the buzziest TV series talk about the thrills and fears of tackling iconic roles at our “Brave New Warriors” session (July 10, 4 p.m.). Then, Game of Thrones’ Gwendoline Christie is among the awesome females taking the stage as part of our annual salute to “Women Who Kick Ass” (July 11, 3:45 p.m.). You won’t want to miss out!.",
                        posterImage:"",
                        copyright: "2015",
                        pdfLink: url
                    )
                    
                    EWItem.animatePageTransitions = true
                    
                    await MainActor.run {
                        books.append(EWItem)
                    }
                }catch{
                    print(error)
                }
                
            }
        }
    }
    
    func createBookItem(name:String,description:String,posterImage:String,copyright:String,pdfLink: URL, pageOverrides: [Int : PageOverride] = [:],mainAudioLink: URL? = nil, audioPages: [AudioPageModel] = []) throws -> BookItem {
        guard let document = CGPDFDocument(NSURL(string: pdfLink.absoluteString)!) else {
            throw "Error creating CGPDFDocument from url \(pdfLink.absoluteString)"
            
        }
        
        var img : UIImage? = nil
        
        if !posterImage.isEmpty {
            img = getImage(named: posterImage)
        }else{
            img = imageForPDF(document: document, pageNumber: 1, imageWidth: imageWidth)
        }
        
        return BookItem(posterImage:img, name:name,description: description, copyright: copyright, pdfLink: pdfLink, mainAudioLink: mainAudioLink, audioPages: audioPages, pageOverrides: pageOverrides)
    }
    
    func createInteractiveItem(name:String,description:String,
                               image:String,
                               posterImage:String,
                               mainLink: URL? = nil,
                               textFile: String = "",
                               type: BooksDisplayItem.ItemType
        ) throws -> InteractiveMediaItem {
        
        var textItems : [TextItem] = []
        if !textFile.isEmpty {
            textItems = try loadJsonFile(textFile)
        }
        
        var img : UIImage? = nil
        
        if !image.isEmpty {
            img = getImage(named: image)
        }
        
        var poster : UIImage? = nil
        
        if !posterImage.isEmpty {
            img = getImage(named: posterImage)
        }
        
        if type == .InteractiveVideo {
            return InteractiveVideoItem(image:img, posterImage:poster, name:name, description: description, mainLink:mainLink, mainText: textItems)
        }else if type == .InteractiveAudio {
            return InteractiveAudioItem(image:img, posterImage:poster, name:name, description: description, mainLink:mainLink, mainText: textItems)
        }
        
        throw "Could not create Interactive Item \(name). Unsupported type \(type)"
    }
    
    func getImage (named filename : String) -> UIImage?
    {
        let split = filename.split(separator:".")
        var imageName = filename
        var imageExt = ""
        if split.count >= 2 {
            imageName = String(split[0])
            imageExt = String(split[split.count - 1])
        }
        
        if let imgPath = Bundle.main.path(forResource: imageName, ofType: imageExt)
        {
            return UIImage(contentsOfFile: imgPath)
        }
        return nil
    }
}
