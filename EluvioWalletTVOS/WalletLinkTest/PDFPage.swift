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
    var coverArtUrl : URL?
    var copyright = ""
    var documentHeight = UIScreen.main.bounds.height - 20
    var mediaItems : [InteractiveMediaItem] = []
    var audioPages : [AudioPageModel] = []
    var enablePageTransitions = false
    
    var hasAudio: Bool {
        return audioUrl != nil
    }
    
    init(title:String, url: URL? = nil, audioUrl: URL? = nil, description: String, copyright: String, coverArtUrl : URL?, mediaItems: [InteractiveMediaItem] = [], audioPages : [AudioPageModel] = [], enablePageTransitions: Bool = false){
        self.title = title
        self.url = url
        self.audioUrl = audioUrl
        self.description = description
        self.copyright = copyright
        self.coverArtUrl = coverArtUrl
        self.mediaItems = mediaItems
        self.audioPages = audioPages
        self.enablePageTransitions = enablePageTransitions
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
        if !enablePageTransitions {
            return .none
        }
            
        if page < previousPage{
            return .left
        }
        
        return .none
    }
    
    var leftPageFade: Bool {
        if !enablePageTransitions {
            return false
        }
        
        debugPrint("leftPageFade pageCurl \(pageCurl) rightPage \(rightPage)")
        if (pageCurl == .right || pageCurl == .none) && rightPage == nil{
            debugPrint("Return false")
            return false
        }
        
        debugPrint("Return true")
        return true
    }
    
    var rightPageCurl: PageCurl {
        if !enablePageTransitions {
            return .none
        }
            
        if page > previousPage {
            return .right
        }
        
        return .none
    }
    
    var rightPageFade: Bool {
        if !enablePageTransitions {
            return false
        }
        
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
                            if let page = leftPage {
                                /*Image(uiImage: leftPage ?? UIImage())
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)*/
                                BookPageView(uiImage: page, pageCurl:leftPageCurl, fadeAnimation: leftPageFade)
                                    .frame(width: page.size.width,  height:page.size.height)
                                    .zIndex(pageCurl == .left ? 1 : 0)
                            }else{
                                Spacer()
                            }
                            if let page = rightPage {
                                /*Image(uiImage: rightPage ?? UIImage())
                                 .resizable()
                                 .aspectRatio(contentMode: .fit)*/
                                BookPageView(uiImage: page, pageCurl:rightPageCurl, fadeAnimation: rightPageFade)
                                    .frame(width: page.size.width,  height:page.size.height)
                                    .zIndex(pageCurl == .right ? 1 : 0)
                            }else{
                                Spacer()
                            }
                        }
                        
                        if leftPage != nil || rightPage != nil {
                            HStack(alignment:.center){
                                ZStack{
                                    Image("center-shadow")
                                        .resizable()
                                        .aspectRatio(contentMode: .fill)
                                        .frame(width: 100, height:documentHeight)
                                    HStack{
                                        Divider()
                                    }
                                    
                                }
                            }
                        }
                        
                        if let page = centerPage {
                            BookPageView(uiImage: page, pageCurl:pageCurl, fadeAnimation: true)
                            .frame(width: page.size.width,  height:page.size.height)
                            .zIndex(2)
                        }
                        
                        ProgressControlView(title:title, description:description, copyright:copyright, thumbs:thumbs, mediaItems: mediaItems, page:$page, numPages: numPages, progress: progress, coverArtImage: coverArtImage,
                                            next: onNextPage, previous: onPreviousPage, playAudio: $playAudio, hasAudio:hasAudio
                        )
                        .zIndex(3)
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
            
            if let url = coverArtUrl {
                do {
                    let data = try? Data(contentsOf: url)
                    
                    if let imageData = data {
                        coverArtImage = UIImage(data: imageData)
                    } else {
                        throw "Could not create image from data."
                    }
                }catch {
                    coverArtImage = imageForPDF(document: document, pageNumber: 1, imageHeight: documentHeight)
                }
            }else{
                coverArtImage = imageForPDF(document: document, pageNumber: 1, imageHeight: documentHeight)
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
            
            
            if page == 1 || (page + 1 > document.numberOfPages) {
                withAnimation(.easeInOut(duration: enablePageTransitions ? 1.0 : 0.0 )) {
                    centerPage = page1
                    rightPage = nil
                    leftPage = nil
                }
                playAudioDictation()
                return
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
            
            withAnimation(.easeOut(duration: enablePageTransitions ? 0.5 : 0.0 )) {
                centerPage = nil
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
