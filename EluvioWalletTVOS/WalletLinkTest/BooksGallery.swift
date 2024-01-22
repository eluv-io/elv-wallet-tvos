//
//  BooksGallery.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-21.
//

import SwiftUI

struct GalleryItem: Identifiable {
    var id: String? = UUID().uuidString
    var image = UIImage ()
    var name = ""
    var description = ""
    var copyright = ""
    var pdfLink = URL(string:"")
}

struct GalleryItemView: View {
    @Binding var item : GalleryItem
    @Binding var selected: Bool
    @Binding var selectedItem: GalleryItem
    var width : CGFloat = 400
    var body: some View {
        Button{
            selectedItem = item
            selected = true
        } label: {
            Image(uiImage: item.image)
                .resizable()
                .aspectRatio(contentMode: .fit)
                .frame(width:width, height:width*2)
        }
        .buttonStyle(.borderless)
    }
}


struct BooksGallery: View {
    @State var books : [GalleryItem] = []
    @State var selectedItem = GalleryItem()
    @State var showBook = false
    var imageWidth : CGFloat = 400
    
    var body: some View {
        VStack(alignment:.center){
            Text("Ebooks and Interactive Media").font(.title)
            VStack(alignment:.center){
                LazyHStack(spacing:60) {
                    Spacer()
                    ForEach(0..<books.count, id: \.self) { index in
                        GalleryItemView(item: $books[index], selected: $showBook, selectedItem: $selectedItem, width: imageWidth)
                    }
                    Spacer()
                }
                .frame(maxWidth:.infinity)
            }
        }
        .fullScreenCover(isPresented: $showBook){ [selectedItem] in
            PDFPage(title:selectedItem.name,
                    urlString: selectedItem.pdfLink?.absoluteString ?? "",
                    description: selectedItem.description,
                    copyright: selectedItem.copyright
            )
        }
        .onAppear() {
            Task{
                debugPrint("BooksGallery OnAppear")
                guard let url = Bundle.main.url(forResource: "a-quiet-place-2018" , withExtension: "pdf") else {
                    debugPrint("Could not get a-quiet-place-2018 url")
                    return
                }
                
                let aqpItem = createItem(
                    "A Quiet Place Script",
                    "If they hear you, they hunt you. A family must live in silence to avoid mysterious creatures that hunt by sound. Knowing that even the slightest whisper or footstep can bring death, Evelyn and Lee are determined to find a way to protect their children while desperately searching for a way to fight back.",
                    "2018",
                    url
                )
                
                guard let url = Bundle.main.url(forResource: "Entertainment Weekly - 05 July 2015" , withExtension: "pdf") else {
                    debugPrint("Could not get Entertainment Weekly - 05 July 2015 url")
                    return
                }
                
                let EWItem = createItem(
                    "Entertainment Weekly - 05 July 2015",
                    "Entertainment Weekly invades Hall H with a pair of starry panels. First off, Outlander’s Sam Heughan and other hot young actors from some of the buzziest TV series talk about the thrills and fears of tackling iconic roles at our “Brave New Warriors” session (July 10, 4 p.m.). Then, Game of Thrones’ Gwendoline Christie is among the awesome females taking the stage as part of our annual salute to “Women Who Kick Ass” (July 11, 3:45 p.m.). You won’t want to miss out!.",
                    "2015",
                    url
                )
                
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
                guard let url = Bundle.main.url(forResource: "the-war-of-the-worlds" , withExtension: "pdf") else {
                    debugPrint("Could not get the-war-of-the-worlds url")
                    return
                }

                let worldsItem = createItem(
                    "H.G. Wells - War of the Worlds",
                    "The War of the Worlds is one of the earliest stories to detail a conflict between humankind and an extraterrestrial race. The novel is the first-person narrative of an unnamed protagonist in Surrey and his younger brother in London as southern England is invaded by Martians.",
                    "1898",
                    url
                )
                
                
                await MainActor.run {
                    books.append(aqpItem)
                    books.append(EWItem)
                    //books.append(flashItem)
                    books.append(worldsItem)
                }
            }
        }
    }
    
    func createItem(_ name:String,_ description:String,_ copyright:String,_ pdfLink: URL ) -> GalleryItem {
        guard let document = CGPDFDocument(NSURL(string: pdfLink.absoluteString)!) else {
            print("Error creating CGPDFDocument from url ", pdfLink.absoluteString)
            return GalleryItem()
        }
        
        if let image = imageForPDF(document: document, pageNumber: 1, imageWidth: imageWidth) {
            return GalleryItem(image:image, name:name,description: description, copyright: copyright, pdfLink: pdfLink)
        }
        
        return GalleryItem()
    }
}
