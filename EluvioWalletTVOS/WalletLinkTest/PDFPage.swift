//
//  PDFPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-16.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImagePDFCoder

struct PDFPage: View{
    var title = "Sample"
    var urlString = "https://www.thebookcollector.co.uk/sites/default/files/the-book-collector-example-2018-04.pdf"
    var description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    var coverArtUrl = ""
    var copyright = "2024 Eluvio Inc"
    var documentWidth = UIScreen.main.bounds.width
    
    init(title:String, urlString: String, description: String, copyright: String){
        self.title = title
        self.urlString = urlString
        self.description = description
        self.copyright = copyright
    }
    
    @State private var page = 1
    @State private var increment = 2
    @State private var coverArtImage : UIImage?
    @State private var leftPage : UIImage?
    @State private var rightPage :UIImage?
    @State private var document : CGPDFDocument?
    @State private var isLoading = true
    @FocusState private var progressFocused
    @FocusState private var infoFocused
    @FocusState private var thumbsFocused
    @FocusState private var titleFocused
    @FocusState private var l2Focused
    
    @State var thumbs : [ThumbnailItem] = []
    private var thumbWidth : CGFloat = 150
    
    
    var progress : Float {
        if let document = document {
            let numPages = Float(document.numberOfPages)
            if page > 0 && numPages > 0.0 {
                
                if Float(page + increment - 1) >= Float(document.numberOfPages) {
                    return 1.0
                }
                
                return Float(page) / Float(document.numberOfPages)
            }
        }
        
        return 0.0
    }
    
    var numPages : Int {
        if let document = document {
            return document.numberOfPages
        }

        return 0
    }
    
    init(){
        let PDFCoder = SDImagePDFCoder.shared
        SDImageCodersManager.shared.addCoder(PDFCoder)
    }
    
    var body: some View {
        ZStack {
            if (isLoading){
                ProgressView()
                    .edgesIgnoringSafeArea(.all)
            }else{
                ZStack{
                    HStack(spacing:0) {
                        if leftPage != nil {
                            Image(uiImage: leftPage ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        if leftPage != nil && rightPage != nil {
                            Divider()
                        }
                        if rightPage != nil {
                            Image(uiImage: rightPage ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    .padding(.bottom,20)
                    
                    ProgressControlView(title:title, description:description, copyright:copyright, thumbs:thumbs, page:$page, numPages: numPages, progress: progress, coverArtImage: coverArtImage)
                }
            }
        }
        .background(.ultraThickMaterial)
        .padding([.leading,.trailing],40)
        .padding([.top,.bottom],10)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: page){
            refreshPages()
        }
        .task {
            await MainActor.run {
                self.isLoading = true
            }
            
            guard let url = NSURL(string: urlString) else {
                print("Error creating NSURL from string ", urlString)
                self.isLoading = false
                return
            }
            
            guard let document = CGPDFDocument(url) else {
                print("Error creating CGPDFDocument from url ", urlString)
                self.isLoading = false
                return
            }
            
            await MainActor.run {
                self.document = document
                refreshPages()
                self.isLoading = false
            }
            
            if (coverArtUrl.isEmpty){
                coverArtImage = imageForPDF(document: document, pageNumber: 1, imageWidth: documentWidth)
            }else{
                
                do {
                    if let url = URL(string: coverArtUrl) {
                        let data = try? Data(contentsOf: url)
                        
                        if let imageData = data {
                            let coverArtImage = UIImage(data: imageData)
                        } else {
                            throw "Could not create image from data."
                        }
                    }else{
                        throw "Could not create url."
                    }
                }catch {
                    coverArtImage = imageForPDF(document: document, pageNumber: 1, imageWidth: documentWidth)
                }
            }
            
            for i in 0..<(self.document?.numberOfPages ?? 0) {
                if let image = imageForPDF(document:self.document!, pageNumber:i+1, imageWidth:thumbWidth*2) {
                    thumbs.append(ThumbnailItem(page:i+1, image:image))
                }else{
                    thumbs.append(ThumbnailItem(page: i+1, image: UIImage()))
                }
            }
        }

    }
    
    
    func refreshPages() {
        guard let document = self.document else {return}
        
        if page < 1 {
            page = 1
        }
        
        if let page1 = imageForPDF(document: document, pageNumber: page, imageWidth: documentWidth){
            leftPage = page1
        }else{
            print("Failed to load pdf page ", page)
            leftPage = nil
        }
        
        if page == 1 {
            rightPage = nil
            return
        }
        
        if (page + 1 <= document.numberOfPages){
            if let page2 = imageForPDF(document: document, pageNumber: page + 1, imageWidth: documentWidth){
                rightPage = page2
            }else{
                print("Failed to load pdf page ", page + 1)
            }
        }else {
            rightPage = nil
        }
    }
}

/*

struct PDFPage: View{
    var title = "Sample"
    var urlString = "https://www.thebookcollector.co.uk/sites/default/files/the-book-collector-example-2018-04.pdf"
    var description = "Lorem ipsum dolor sit amet, consectetur adipiscing elit, sed do eiusmod tempor incididunt ut labore et dolore magna aliqua. Ut enim ad minim veniam, quis nostrud exercitation ullamco laboris nisi ut aliquip ex ea commodo consequat. Duis aute irure dolor in reprehenderit in voluptate velit esse cillum dolore eu fugiat nulla pariatur. Excepteur sint occaecat cupidatat non proident, sunt in culpa qui officia deserunt mollit anim id est laborum."
    var coverArtUrl = ""
    var copyright = "2024 Eluvio Inc"
    var documentWidth = UIScreen.main.bounds.width
    
    init(title:String, urlString: String, description: String, copyright: String){
        self.title = title
        self.urlString = urlString
        self.description = description
        self.copyright = copyright
    }
    
    enum ControlsLevel {
        case l1, l2, l3
    }
    
    enum Tabs {
        case Info, Thumbs, Contents, Bookmarks
    }
    
    @State private var page = 1
    @State private var increment = 2
    @State private var controlsLayout : ControlsLevel = .l1
    @State private var selectedTab : Tabs = .Info
    @State private var coverArtImage : UIImage?
    @State private var leftPage : UIImage?
    @State private var rightPage :UIImage?
    @State private var document : CGPDFDocument?
    @State private var isLoading = true
    @FocusState private var progressFocused
    @FocusState private var infoFocused
    @FocusState private var thumbsFocused
    @FocusState private var titleFocused
    @FocusState private var l2Focused
    
    @State private var progressBarOpacity : CGFloat = 1.0
    
    @State var thumbs : [ThumbnailItem] = []
    private var thumbWidth : CGFloat = 150
    
    var gradientHeight: CGFloat {
        if controlsLayout == .l2 {
            return 330
        }
        
        return 60
    }
    
    var tabHeight: CGFloat {
        return gradientHeight - 80
    }
    
    var gradient: LinearGradient {
        if controlsLayout == .l1 {
            return LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom)
        }
        return LinearGradient(stops: [
            Gradient.Stop(color: .clear, location: 0.0),
                Gradient.Stop(color: .black.opacity(0.8), location: 0.5),
            ], startPoint: .top, endPoint: .bottom)
    }
    
    var progress : Float {
        if let document = document {
            let numPages = Float(document.numberOfPages)
            if page > 0 && numPages > 0.0 {
                
                if Float(page + increment - 1) >= Float(document.numberOfPages) {
                    return 1.0
                }
                
                return Float(page) / Float(document.numberOfPages)
            }
        }
        
        return 0.0
    }
    
    var numPages : Int {
        if let document = document {
            return document.numberOfPages
        }

        return 0
    }
    
    init(){
        let PDFCoder = SDImagePDFCoder.shared
        SDImageCodersManager.shared.addCoder(PDFCoder)
    }
    
    var body: some View {
        ZStack {
            if (isLoading){
                ProgressView()
                    .edgesIgnoringSafeArea(.all)
            }else{
                ZStack{
                    HStack(spacing:0) {
                        if leftPage != nil {
                            Image(uiImage: leftPage ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                        if leftPage != nil && rightPage != nil {
                            Divider()
                        }
                        if rightPage != nil {
                            Image(uiImage: rightPage ?? UIImage())
                                .resizable()
                                .aspectRatio(contentMode: .fit)
                        }
                    }
                    .padding(.bottom,20)
                    ZStack{
                        VStack{
                            Spacer()
                            Rectangle()                         // Shapes are resizable by default
                                .foregroundColor(.clear)        // Making rectangle transparent
                                .background(self.gradient)
                                .frame(height:gradientHeight)
                        }
                        
                        VStack(alignment:.leading, spacing:5) {
                            Spacer()

                            Group{
                                HStack(alignment:.center){
                                    Text("\(title)")
                                    Spacer()
                                    Text("Page \(self.page) of \(self.numPages)")
                                        .font(.system(size: 20))
                                }
                                .frame(maxWidth:.infinity)
                                
                                ProgressSlider(
                                    progress : progress,
                                    
                                    selectPressed: {
                                     controlsLayout = .l2
                                     infoFocused = true
                                    },
                                    
                                    leftPressed:{
                                        if (page == 2){
                                            page = page - 1
                                            return
                                        }
                                        page = page - increment
                                    },
                                    rightPressed: {
                                        if (page == 1){
                                            page = page + 1
                                            return
                                        }
                                        if (page + increment <= numPages){
                                            page = page + increment
                                        }
                                    },
                                    upPressed: {
                                        controlsLayout = .l1
                                    },
                                    downPressed: {
                                        controlsLayout = .l2
                                        infoFocused = true
                                    }
                                )
                                .focused($progressFocused)
                            }
                            .opacity(progressBarOpacity)
                            
                            if (controlsLayout == .l2){
                                Button{} label: {
                                    Color.clear
                                        .contentShape(Rectangle())
                                        .frame(maxWidth:.infinity, maxHeight:10)
                                }
                                .buttonStyle(.borderless)
                                .focused($progressFocused)
                                
                                HStack(spacing:10){
                                    Button{
                                    }label: {
                                        Text("Info")
                                            .font(.system(size: 30))
                                    }
                                    .buttonStyle(TextButtonStyle(focused:selectedTab == .Info))
                                    .focused($infoFocused)
                                    .opacity(infoFocused ? 1.0 : 0.5)
                                    .onChange(of:infoFocused) {
                                        if (infoFocused){
                                            selectedTab = .Info
                                        }
                                    }
                                    
                                    Button{
                                    }label: {
                                        Text("Thumbnails")
                                            .font(.system(size: 30))
                                    }
                                    .buttonStyle(TextButtonStyle(focused:selectedTab == .Thumbs))
                                    .focused($thumbsFocused)
                                    .onChange(of:thumbsFocused) {
                                        if (thumbsFocused){
                                            selectedTab = .Thumbs
                                        }
                                    }
                                    .opacity(thumbsFocused ? 1.0 : 0.5)
                                    Spacer()
                                }
                                .frame(maxWidth:.infinity)
                                .focusSection()
                                .padding(.top, 20)
                            
                                if (selectedTab == .Info) {
                                    PDFInfoTab(image:coverArtImage ?? UIImage(), title:title, description: description, copyright:copyright)
                                    .frame(maxWidth:.infinity, maxHeight: tabHeight)
                                }
                                if (selectedTab == .Thumbs) {
                                    ThumbnailRowView(thumbs:thumbs, page:$page, thumbWidth: thumbWidth, thumbHeight:tabHeight*0.8)
                                        .frame(maxWidth:.infinity, maxHeight: tabHeight)
                                }
                            }
                        }
                    }
                }
            }
        }
        .background(.ultraThickMaterial)
        .padding([.leading,.trailing],40)
        .padding([.top,.bottom],10)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: progressFocused){
            if progressFocused {
                controlsLayout = .l1
            }
        }
        .onChange(of: page){
            refreshPages()
        }
        .onChange(of: controlsLayout) {
            if (controlsLayout == .l1){
                withAnimation {
                    progressBarOpacity = 1.0
                }
            }else {
                withAnimation {
                    progressBarOpacity = 0.01
                }
            }
        }
        .task {
            await MainActor.run {
                self.isLoading = true
            }
            
            guard let url = NSURL(string: urlString) else {
                print("Error creating NSURL from string ", urlString)
                self.isLoading = false
                return
            }
            
            guard let document = CGPDFDocument(url) else {
                print("Error creating CGPDFDocument from url ", urlString)
                self.isLoading = false
                return
            }
            
            await MainActor.run {
                self.document = document
                refreshPages()
                self.isLoading = false
            }
            
            if (coverArtUrl.isEmpty){
                coverArtImage = imageForPDF(document: document, pageNumber: 1, imageWidth: documentWidth)
            }else{
                
                do {
                    if let url = URL(string: coverArtUrl) {
                        let data = try? Data(contentsOf: url)
                        
                        if let imageData = data {
                            let coverArtImage = UIImage(data: imageData)
                        } else {
                            throw "Could not create image from data."
                        }
                    }else{
                        throw "Could not create url."
                    }
                }catch {
                    coverArtImage = imageForPDF(document: document, pageNumber: 1, imageWidth: documentWidth)
                }
            }
            
            for i in 0..<(self.document?.numberOfPages ?? 0) {
                if let image = imageForPDF(document:self.document!, pageNumber:i+1, imageWidth:thumbWidth*2) {
                    thumbs.append(ThumbnailItem(page:i+1, image:image))
                }else{
                    thumbs.append(ThumbnailItem(page: i+1, image: UIImage()))
                }
            }
        }

    }
    
    
    func refreshPages() {
        guard let document = self.document else {return}
        
        if page < 1 {
            page = 1
        }
        
        if let page1 = imageForPDF(document: document, pageNumber: page, imageWidth: documentWidth){
            leftPage = page1
        }else{
            print("Failed to load pdf page ", page)
            leftPage = nil
        }
        
        if page == 1 {
            rightPage = nil
            return
        }
        
        if (page + 1 <= document.numberOfPages){
            if let page2 = imageForPDF(document: document, pageNumber: page + 1, imageWidth: documentWidth){
                rightPage = page2
            }else{
                print("Failed to load pdf page ", page + 1)
            }
        }else {
            rightPage = nil
        }
    }
}
*/
