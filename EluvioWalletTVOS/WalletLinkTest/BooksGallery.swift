//
//  BooksGallery.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-21.
//

import SwiftUI

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

class BookItem: BooksDisplayItem {
    var copyright = ""
    var pdfLink = URL(string:"")
    var interactiveItems : [InteractiveMediaItem] = []
    
    init(id: String? = nil, image: UIImage = UIImage (), name: String = "", description: String = "", copyright: String = "", pdfLink: URL? = nil) {
        super.init(id:id,image:image,name:name,description:description)
        self.copyright = copyright
        self.pdfLink = pdfLink
        self.type = .Book
    }
}

class InteractiveMediaItem: BooksDisplayItem {
    var mainVideoLink = URL(string:"")
    var secondaryVideos : [URL] = []
    var mainVideoText : [TextItem] = []
    
    init(id: String? = nil, image: UIImage = UIImage (), name: String = "", description: String = "", mainVideoLink: URL, secondaryVideos: [URL] = [], mainVideoText : [TextItem] = []) {
        super.init(id:id,image:image,name:name,description:description)
        self.mainVideoLink = mainVideoLink
        self.secondaryVideos = secondaryVideos
        self.mainVideoText = mainVideoText
        self.type = .Interactive
    }
}

class BooksDisplayItem: Identifiable {
    enum ItemType {case Book; case Interactive}
    
    var id: String? = UUID().uuidString
    var image = UIImage ()
    var name = ""
    var description = ""
    var type : ItemType = .Book
    
    init(id: String? = nil, image: UIImage = UIImage (), name: String = "", description: String = "") {
        self.id = id
        self.image = image
        self.name = name
        self.description = description
    }
}

struct BooksGalleryItemView: View {
    @Binding var item : BooksDisplayItem
    @Binding var selected: Bool
    @Binding var selectedItem: BooksDisplayItem
    var width : CGFloat = 400
    var body: some View {
        Button{
            selectedItem = item
            selected = true
        } label: {
            Image(uiImage: item.image)
                .resizable()
                .aspectRatio(contentMode: .fill)
                .frame(width:width, height:width*2)
                .padding()
        }
        .buttonStyle(.borderless)
        .frame(width:width, height:width*2)
    }
}


struct BooksGallery: View {
    @State var books : [BooksDisplayItem] = []
    @State var selectedItem = BooksDisplayItem()
    @State var showBook = false
    var imageWidth : CGFloat = 250
    
    var body: some View {
        VStack(alignment:.center){
            Text("Ebooks and Interactive Media").font(.title)
            VStack(alignment:.center){
                ScrollView(.horizontal) {
                    LazyHStack(spacing:imageWidth * 0.7) {
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
                        urlString: book.pdfLink?.absoluteString ?? "",
                        description: book.description,
                        copyright: book.copyright
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
                    
                    guard let videoUrl = Bundle.main.url(forResource: "A Quiet Place - Opening" , withExtension: "mp4") else {
                        throw ("Could not get A Quiet Place - Opening")
                    }
                    
                    let aqpBook = try createBookItem(
                        "A Quiet Place Script",
                        "If they hear you, they hunt you. A family must live in silence to avoid mysterious creatures that hunt by sound. Knowing that even the slightest whisper or footstep can bring death, Evelyn and Lee are determined to find a way to protect their children while desperately searching for a way to fight back.",
                        "2018",
                        pdfUrl
                    )
                    let aqpItem = try createInteractiveItem(
                        "A Quiet Place Interactive Script",
                        "If they hear you, they hunt you. A family must live in silence to avoid mysterious creatures that hunt by sound. Knowing that even the slightest whisper or footstep can bring death, Evelyn and Lee are determined to find a way to protect their children while desperately searching for a way to fight back.",
                        "A-Quiet-Place-Poster.jpg",
                        videoUrl,
                        "AQP-transcript.json"
                    )

                    aqpBook.interactiveItems.append(aqpItem)
                    
                    await MainActor.run {
                        books.append(aqpBook)
                        books.append(aqpItem)
                    }
                    
                }catch{
                    print(error)
                }
                
                
                do {
                    guard let url = Bundle.main.url(forResource: "Entertainment Weekly - 05 July 2015" , withExtension: "pdf") else {
                        throw ("Could not get Entertainment Weekly - 05 July 2015 url")
                    
                    }
                    let EWItem = try createBookItem(
                        "Entertainment Weekly - 05 July 2015",
                        "Entertainment Weekly invades Hall H with a pair of starry panels. First off, Outlander’s Sam Heughan and other hot young actors from some of the buzziest TV series talk about the thrills and fears of tackling iconic roles at our “Brave New Warriors” session (July 10, 4 p.m.). Then, Game of Thrones’ Gwendoline Christie is among the awesome females taking the stage as part of our annual salute to “Women Who Kick Ass” (July 11, 3:45 p.m.). You won’t want to miss out!.",
                        "2015",
                        url
                    )
                    
                    await MainActor.run {
                        books.append(EWItem)
                    }
                }catch{
                    print(error)
                }
                
                /*
                guard let url = Bundle.main.url(forResource: "Flash_Comic_PDF_demo" , withExtension: "pdf") else {
                    debugPrint("Could not get Flash_Comic_PDF_demo url")
                    return
                }
                let flashItem = createItem(
                    "The Flash Comic Example",
                    "The Flash, The Fast Man Alive. This is the official movie tie-in comic!",
                    "2023",
                    url
                )
                
                */
                
                do {
                    guard let url = Bundle.main.url(forResource: "the-war-of-the-worlds" , withExtension: "pdf") else {
                        debugPrint("Could not get the-war-of-the-worlds url")
                        return
                    }
                    
                    let worldsItem = try createBookItem(
                        "H.G. Wells - War of the Worlds",
                        "The War of the Worlds is one of the earliest stories to detail a conflict between humankind and an extraterrestrial race. The novel is the first-person narrative of an unnamed protagonist in Surrey and his younger brother in London as southern England is invaded by Martians.",
                        "1898",
                        url
                    )
                    
                    await MainActor.run {
                        books.append(worldsItem)
                    }
                }catch {
                    print(error)
                }
            }
        }
    }
    
    func createBookItem(_ name:String,_ description:String,_ copyright:String,_ pdfLink: URL ) throws -> BookItem {
        guard let document = CGPDFDocument(NSURL(string: pdfLink.absoluteString)!) else {
            throw "Error creating CGPDFDocument from url \(pdfLink.absoluteString)"
            
        }
        
        if let image = imageForPDF(document: document, pageNumber: 1, imageWidth: imageWidth) {
            return BookItem(image:image, name:name,description: description, copyright: copyright, pdfLink: pdfLink)
        }
        
        throw "Error creating book \(name)"
    }
    
    func createInteractiveItem(_ name:String,_ description:String,
                               _ image:String,
                               _ mainVideoLink: URL, _ videoTextFile: String) throws -> InteractiveMediaItem {
        
        let videoText: [TextItem] = try loadJsonFile(videoTextFile)
        
        let split = image.split(separator:".")
        var imageName = image
        var imageExt = ""
        if split.count >= 2 {
            imageName = String(split[0])
            imageExt = String(split[split.count - 1])
        }
        if let img = getImage(named: imageName, ext: imageExt) {
            let item = InteractiveMediaItem(image:img, name:name, description: description, mainVideoLink: mainVideoLink, mainVideoText: videoText)
            
            return item
        }else {
            throw "Could not get image \(image)"
        }
    }
    
    func getImage (named name : String, ext : String) -> UIImage?
    {
        if let imgPath = Bundle.main.path(forResource: name, ofType: ext)
        {
            return UIImage(contentsOfFile: imgPath)
        }
        return nil
    }
}
