//
//  PDFPage.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-16.
//

import SwiftUI
import SDWebImageSwiftUI
import SDWebImagePDFCoder
import AVKit

struct PDFPage: View{
    var title = ""
    var url : URL?
    var audioUrl : URL?
    var description = ""
    var coverArtUrl = ""
    var copyright = ""
    var documentHeight = UIScreen.main.bounds.height - 20
    var mediaItems : [InteractiveMediaItem] = []
    var audioPages : [AudioPageModel] = []
    
    init(title:String, url: URL? = nil, audioUrl: URL? = nil, description: String, copyright: String, mediaItems: [InteractiveMediaItem] = [], audioPages : [AudioPageModel] = []){
        self.title = title
        self.url = url
        self.audioUrl = audioUrl
        self.description = description
        self.copyright = copyright
        self.mediaItems = mediaItems
        self.audioPages = audioPages
    }
    
    @State var audioPlayer :AVAudioPlayer?
    @State private var previousPage = 0
    @State private var page = 1
    @State private var increment = 2
    @State private var coverArtImage : UIImage?
    @State private var leftPage : UIImage?
    @State private var rightPage :UIImage?
    @State private var centerPage :UIImage?
    
    @State private var document : CGPDFDocument?
    @State private var isLoading = true
    @FocusState private var progressFocused
    @FocusState private var infoFocused
    @FocusState private var thumbsFocused
    @FocusState private var titleFocused
    @FocusState private var l2Focused

    @State var thumbs : [ThumbnailItem] = []
    private var thumbWidth : CGFloat = 150
    
    @State private var pageCurl: PageCurl = .none
    @State private var playAudio = false
    @State private var currentAudioTime : TimeInterval = 0.0
    
    var leftPageCurl: PageCurl {
        if page < previousPage{
            return .left
        }
        
        return .none
    }
    
    var leftPageFade: Bool {
        debugPrint("leftPageFade pageCurl \(pageCurl) rightPage \(rightPage)")
        if (pageCurl == .right || pageCurl == .none) && rightPage == nil{
            debugPrint("Return false")
            return false
        }
        
        debugPrint("Return true")
        return true
    }
    
    var rightPageCurl: PageCurl {
        if page > previousPage {
            return .right
        }
        
        return .none
    }
    
    var rightPageFade: Bool {
        if pageCurl == .right && leftPage == nil{
            return false
        }
        
        return true
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
    
    var body: some View {
        ZStack {
            GeometryReader { proxy in
                if (isLoading){
                    ProgressView()
                        .edgesIgnoringSafeArea(.all)
                }else{
                    ZStack{
                        HStack(spacing:0) {
                            if let page = centerPage {
                                BookPageView(uiImage: page, pageCurl:pageCurl, fadeAnimation: false)
                                .frame(width: page.size.width,  height:page.size.height)
                            }else {
                                if let page = leftPage {
                                    /*Image(uiImage: leftPage ?? UIImage())
                                     .resizable()
                                     .aspectRatio(contentMode: .fit)*/
                                    BookPageView(uiImage: page, pageCurl:leftPageCurl, fadeAnimation: leftPageFade)
                                        .frame(width: page.size.width,  height:page.size.height)
                                        .zIndex(pageCurl == .left ? 1 : 0)
                                }
                                if leftPage != nil && rightPage != nil {
                                    Divider()
                                }
                                if let page = rightPage {
                                    /*Image(uiImage: rightPage ?? UIImage())
                                     .resizable()
                                     .aspectRatio(contentMode: .fit)*/
                                    BookPageView(uiImage: page, pageCurl:rightPageCurl, fadeAnimation: rightPageFade)
                                        .frame(width: page.size.width,  height:page.size.height)
                                        .zIndex(pageCurl == .right ? 1 : 0)
                                }
                            }
                        }
                        
                        ProgressControlView(title:title, description:description, copyright:copyright, thumbs:thumbs, mediaItems: mediaItems, page:$page, numPages: numPages, progress: progress, coverArtImage: coverArtImage,
                                            next: onNextPage, previous: onPreviousPage, playAudio: $playAudio
                        )
                    }
                }
            }
        }
        .background(.ultraThickMaterial)
        .padding([.leading,.trailing],40)
        .padding([.top,.bottom],10)
        .edgesIgnoringSafeArea(.all)
        .onChange(of: page){ oldState, newState in
            previousPage = oldState
            refreshPages()
        }
        .onChange(of: playAudio) {
            playAudioDictation()
        }
        .onDisappear(){
            AudioPlayer.stop()
        }
        .task {
            await MainActor.run {
                self.isLoading = true
            }
            
            guard let nsurl = NSURL(string: url?.absoluteString ?? "") else {
                print("Error creating NSURL from string ", url)
                self.isLoading = false
                return
            }
            
            guard let document = CGPDFDocument(nsurl) else {
                print("Error creating CGPDFDocument from nsurl ", nsurl)
                self.isLoading = false
                return
            }
            
            await MainActor.run {
                self.document = document
                refreshPages()
                self.isLoading = false
            }
            
            if (coverArtUrl.isEmpty){
                coverArtImage = imageForPDF(document: document, pageNumber: 1, imageHeight: documentHeight)
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
                    coverArtImage = imageForPDF(document: document, pageNumber: 1, imageHeight: documentHeight)
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
    
    func playAudioDictation() {
        if playAudio {
            if let audioUrl = audioUrl {
                if let time = getAudioTimeForPage(page:page) {
                    //Fixes playing the audio twice on auto page flip
                    if AudioPlayer.isPlaying &&  abs(time/1000 - currentAudioTime) < 2 {
                        return
                    }
                    AudioPlayer.play(url:audioUrl, seekS: time / 1000) { current, duration in
                        debugPrint("AudioProgress: current \(current) duration \(duration)")
                        self.currentAudioTime = current
                        var latestPage = 0
                        for p in audioPages {
                            //debugPrint("page \(p.page) start \(p.startSeconds)")
                            if (current < p.startSeconds) {
                                //debugPrint("Found p!! ", p.page)
                                if latestPage == 2 || latestPage - page > 1 {
                                    page = latestPage
                                }
                                return
                            }
                            latestPage = p.page
                        }
                    }
                }
            }
        }else {
            AudioPlayer.pause()
        }
    }
    
    func onNextPage() {
        debugPrint("onNextPage()")
        //pageCurl = .right
        //refreshPages()

    }
    
    func onPreviousPage(){
        debugPrint("onPreviousPage()")
        //pageCurl = .left
        //refreshPages()
    }
    
    func getAudioTimeForPage(page: Int) -> TimeInterval?{
        debugPrint("getAudioTimeForPage \(page)")
        for pageItem in audioPages {
            if pageItem.page == page {
                debugPrint("found start \(pageItem.start)")
                return pageItem.start
            }
        }
        debugPrint("Could not find page.")
        return nil
    }
    
    func refreshPages() {
        debugPrint("PDFPage refreshPages() page: \(page) previousPage: \(previousPage)")
        if page < previousPage{
            pageCurl =  .left
        }
        
        
        if page > previousPage{
            pageCurl =  .right
        }
        
        if page == previousPage{
            pageCurl =  .none
            debugPrint("same page!")
            return
        }
        
        guard let document = self.document else {return}
        Task{
            if page < 1 {
                page = 1
            }
            
            var page1 : UIImage?
            if let _page1 = imageForPDF(document: document, pageNumber: page, imageHeight: documentHeight){
                page1 = _page1
            }else{
                print("Failed to load pdf page ", page)
                page1 = nil
            }
            
            if page == 1 {
                withAnimation(.easeInOut(duration: 0.5)) {
                    centerPage = page1
                    rightPage = nil
                }
                playAudioDictation()
                return
            }
            
            withAnimation(.easeInOut(duration: 0.5)) {
                centerPage = nil
            }
            
            var page2 : UIImage?
            if (page + 1 <= document.numberOfPages){
                if let _page2 = imageForPDF(document: document, pageNumber: page + 1, imageHeight: documentHeight){
                    page2 = _page2
                }else{
                    print("Failed to load pdf page ", page + 1)
                    page2 = nil
                }
            }else {
                page2 = nil
            }

            withAnimation(.easeInOut(duration: 1.0)) {
                if pageCurl == .left {
                    leftPage = page1
                    rightPage = page2
                }else{
                    rightPage = page2
                    leftPage = page1
                }
                
                playAudioDictation()
            }
        }
    }
}

extension Task where Success == Never, Failure == Never {
    static func sleep(seconds: Double) async {
        let duration = UInt64(seconds * 1_000_000_000)
        do {
            try await Task.sleep(nanoseconds: duration)
        }catch{}
    }
}

enum PageCurl { case none; case left; case right; case up; case down }

struct BookPageView: UIViewRepresentable {

    var uiImage: UIImage?
    var pageCurl: PageCurl = .none
    var animationDuration = 0.5
    var fadeAnimation = true
    
    func makeUIView(context: UIViewRepresentableContext<BookPageView>) -> UIImageView {
        let view = UIImageView(image: uiImage)
        view.contentMode = .scaleAspectFit
        view.setContentHuggingPriority(.defaultLow, for: .vertical)
        view.setContentHuggingPriority(.defaultLow, for: .horizontal)
        view.setContentCompressionResistancePriority(.defaultLow, for: .vertical)
        view.setContentCompressionResistancePriority(.defaultLow, for: .horizontal)
        return view
    }
    
    func updateUIView(_ uiView: UIImageView, context: UIViewRepresentableContext<BookPageView>) {
        setImage(uiView, uiImage, animated: fadeAnimation)
        animatePage(side:pageCurl, view: uiView)
    }
    
    func setImage(_ uiView: UIImageView, _ image: UIImage?, animated: Bool = true) {
        debugPrint("BookPageView setImage animated: ", animated)
        if uiView.image == image {
            return
        }
        
        if !animated {
            uiView.image = image
            return
        }
        
        let duration = self.animationDuration * 2.0
        UIView.transition(with: uiView, duration: duration, options: .transitionCrossDissolve, animations: {
            uiView.image = image
        }, completion: nil)
    }
    
    func animatePage(side: PageCurl, view: UIView) {
        if side == .none {
            return
        }
        
        UIView.animate(withDuration: animationDuration, animations: {
            let animation = CATransition()
            animation.duration = animationDuration
            animation.startProgress = 0.0
            animation.endProgress = 1.0
            animation.timingFunction = CAMediaTimingFunction(name: CAMediaTimingFunctionName.easeInEaseOut)
            animation.type = CATransitionType(rawValue: "pageCurl")
            if side == .left {
                animation.subtype = CATransitionSubtype(rawValue: "fromLeft")
            } else if side == .right {
                animation.subtype = CATransitionSubtype(rawValue: "fromRight")
            }else if side == .up {
                animation.subtype = CATransitionSubtype(rawValue: "fromUp")
            }else if side == .down {
                animation.subtype = CATransitionSubtype(rawValue: "fromDown")
            }
            animation.isRemovedOnCompletion = true
            animation.fillMode = .forwards
            view.layer.add(animation, forKey: "pageFlipAnimation")
        })
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
