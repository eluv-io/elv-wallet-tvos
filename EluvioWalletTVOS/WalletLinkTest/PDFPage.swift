//
//  PDFPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-16.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImagePDFCoder

struct ThumbnailItem: Identifiable {
    var id: String? = UUID().uuidString
    var page: Int = 0
    var image: UIImage
}

struct ThumbnailItemView: View {
    @State var item1: ThumbnailItem? = nil
    @State var item2: ThumbnailItem? = nil
    @FocusState var isFocused
    @Binding var page: Int
    var width: CGFloat = 80
    var height: CGFloat = 80
    var selected : Bool {
        if let item = self.item1 {
            return page == item.page
        }
        return false
    }
    
    var body: some View {
        Button(action: {

        }) {
            HStack(spacing:0){
                Image(uiImage: item1?.image ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame( width: width, height: height, alignment: .trailing)
                Image(uiImage: item2?.image ?? UIImage())
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame( width: width, height: height, alignment:.leading)
            }
        }
        .buttonStyle(ThumbnailButtonStyle(focused: isFocused, selected: selected))
        .focused($isFocused)
        .onChange(of: isFocused) {
            if (isFocused){
                if let item = self.item1 {
                    debugPrint("page ", page)
                    debugPrint("item.page", item.page)
                    page = item.page
                    //}
                }
            }
        }
 /*       .onChange(of:page) {
            debugPrint("ThumbnailItemView onChange page: ", page)
            if let item = self.item1 {
                if page == item.page && !selected{
                    //isFocused = true
                }
            }
        }*/
        .onAppear(){
            if selected {
                debugPrint("ThumbnailItemView onAppear page: ", page)
                //isFocused = true
            }
        }
    }
}

struct ThumbnailRowView: View {
    @State var thumbs : [ThumbnailItem] = []
    @Binding var page : Int
    var thumbWidth : CGFloat = 50
    var thumbHeight: CGFloat = 80

    var body: some View {
        ScrollViewReader { value in
            ScrollView(.horizontal) {
                LazyHStack(spacing:10) {
                    ForEach(Array(stride(from: 0, to: thumbs.count, by: 2)), id: \.self) { index in
                        HStack(spacing:0){
                            ThumbnailItemView(item1:thumbs[index], item2:thumbs[index+1], page:$page, width:thumbWidth, height:80)
                        }
                        .id(index)
                    }
                }
            }
            .onChange(of:page) {
                debugPrint("ThumbnailRowView onChange page ", page)
                withAnimation {
                    value.scrollTo(page-1)
                }
            }
            .onAppear(){
                debugPrint("ThumbnailRowView onAppear ", page)
                withAnimation {
                    value.scrollTo((page-1))
                }
            }
        }
    }
}

struct PDFPage: View{
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

    let title = "Sample"
    let pdfUrlString = "https://www.thebookcollector.co.uk/sites/default/files/the-book-collector-example-2018-04.pdf"
    @State private var leftPage : UIImage = UIImage()
    @State private var rightPage :UIImage = UIImage()
    @State private var document : CGPDFDocument?
    @State private var isLoading = true
    @FocusState var progressFocused
    @FocusState var infoFocused
    @FocusState var thumbsFocused
    @FocusState var titleFocused
    @FocusState var l2Focused
    
    @State private var progressBarOpacity : CGFloat = 1.0
    
    @State var thumbs : [ThumbnailItem] = []
    private var thumbWidth : CGFloat = 50
    
    var gradientHeight: CGFloat {
        if controlsLayout == .l2 {
            return 200
        }
        
        return 60
    }
    
    
    var progress : Float {
        if let document = document {
            let numPages = Float(document.numberOfPages)
            if page > 0 && numPages > 0.0 {
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
                        Image(uiImage: leftPage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                        Divider()
                        Image(uiImage: rightPage)
                            .resizable()
                            .aspectRatio(contentMode: .fit)
                    }
                    .padding(.bottom,20)
                    ZStack{
                        VStack{
                            Spacer()
                            Rectangle()                         // Shapes are resizable by default
                                .foregroundColor(.clear)        // Making rectangle transparent
                                .background(LinearGradient(gradient: Gradient(colors: [.clear, .black.opacity(0.8)]), startPoint: .top, endPoint: .bottom))
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
                                    /* selectPressed: {
                                     controlsLayout = .l2
                                     infoFocused = true
                                     },*/
                                    leftPressed:{
                                        page = page - increment
                                    },
                                    rightPressed: {
                                        page = page + increment
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
                                            .font(.system(size: 20))
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
                                            .font(.system(size: 20))
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
                                    HStack {
                                        
                                    }
                                    .frame(maxWidth:.infinity, maxHeight: 100)
                                }
                                if (selectedTab == .Thumbs) {
                                    ThumbnailRowView(thumbs:thumbs, page:$page, thumbWidth: thumbWidth, thumbHeight:80)
                                        .frame(maxWidth:.infinity, maxHeight: 100)
                                }
                            }
                        }
                    }
                }
            }
        }
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
            
            guard let url = NSURL(string: pdfUrlString) else {
                print("Error creating NSURL from string ", pdfUrlString)
                return
            }
            
            guard let document = CGPDFDocument(url) else {
                print("Error creating CGPDFDocument from url ", url)
                return
            }
            
            await MainActor.run {
                self.document = document
                self.isLoading = false
                refreshPages()
            }
            
            for i in 0...(self.document?.numberOfPages ?? 0) {
                if let image = imageForPDF(document:self.document!, pageNumber:i+1, imageWidth:thumbWidth) {
                    thumbs.append(ThumbnailItem(page:i+1, image:image))
                }else{
                    thumbs.append(ThumbnailItem(page: i+1, image:UIImage(systemName:"exclamationmark.circle") ?? UIImage()))
                }
            }
        }

    }
    
    func refreshPages() {
        guard let document = self.document else {return}
        
        if page < 1 {
            page = 1
        }
        
        if let page1 = imageForPDF(document: document, pageNumber: page, imageWidth: 400){
            leftPage = page1
        }else{
            print("Failed to load pdf page ", page)
        }
        
        if (page + 1 <= document.numberOfPages){
            if let page2 = imageForPDF(document: document, pageNumber: page + 1, imageWidth: 400){
                rightPage = page2
            }else{
                print("Failed to load pdf page ", page + 1)
            }
        }else {
            rightPage = UIImage()
        }
    }
    
    func imageForPDF(document : CGPDFDocument, pageNumber: Int, imageWidth: CGFloat) -> UIImage? {
        debugPrint("imageForPDF")
        
        guard let document = self.document else { return nil }
        guard let page = document.page(at: pageNumber) else { return nil }
        
        debugPrint("got page ", pageNumber)
        
        var pageRect = page.getBoxRect(.mediaBox)
        let scale = imageWidth / pageRect.size.width
        pageRect.size = CGSize(width: pageRect.size.width * scale,
                               height: pageRect.size.height * scale)
        pageRect.origin = CGPoint.zero
        
        UIGraphicsBeginImageContext(pageRect.size)
        guard let context = UIGraphicsGetCurrentContext()  else { return nil }
        context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
        context.fill(pageRect)
        context.saveGState()
        
        // Rotate the PDF so that it’s the right way around
        context.translateBy(x: 0.0, y: pageRect.size.height)
        context.scaleBy(x: 1.0, y: -1.0)
        context.concatenate(page.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))
        
        context.drawPDFPage(page)
        context.restoreGState()
        
        let image = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        return image
    }
}
