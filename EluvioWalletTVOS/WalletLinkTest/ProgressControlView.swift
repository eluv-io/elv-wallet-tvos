//
//  ProgressControlView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-31.
//

import SwiftUI

struct ProgressControlView: View {
    var title = ""
    var description = ""
    var copyright = ""
    var thumbs : [ThumbnailItem] = []
    var mediaItems : [InteractiveMediaItem] = []
    var numPages: Int
    var progress: Float
    @Binding var page: Int
    var coverArtImage : UIImage?
    @Binding var playAudio: Bool
    
    var next: (()->())? = nil
    var previous: (()->())? = nil
    
    enum ControlsLevel {
        case l1, l2, l3
    }
    
    enum Tabs {
        case Info, Thumbs, Interactive, Contents, Bookmarks
    }
    
    @State private var increment = 2
    @State private var controlsLayout : ControlsLevel = .l1
    @State private var selectedTab : Tabs = .Info
    
    @FocusState private var progressFocused
    @FocusState private var infoFocused
    @FocusState private var thumbsFocused
    @FocusState private var interactiveFocused
    @FocusState private var titleFocused
    @FocusState private var l2Focused
    @FocusState private var audioFocused
    
    private var thumbWidth : CGFloat = 150
    @State private var progressBarOpacity : CGFloat = 1.0
    
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
    
    init(title:String="", description:String="", copyright:String="", thumbs:[ThumbnailItem] = [], mediaItems : [InteractiveMediaItem] = [], page: Binding<Int>, numPages: Int, progress: Float, coverArtImage: UIImage?, next: ((()->()))? = nil, previous: ((()->()))? = nil, playAudio: Binding<Bool>) {
        
        self.title = title
        self.description = description
        self.copyright = copyright
        self.thumbs = thumbs
        self.mediaItems = mediaItems
        self._page = page
        self.numPages = numPages
        self.progress = progress
        self.coverArtImage = coverArtImage
        self.next = next
        self.previous = previous
        self._playAudio = playAudio
    }
    
    
    var body: some View {
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
                    HStack(alignment:.center, spacing:30){
                        Text("\(title)")
                        Spacer()
                        Image(systemName: playAudio ? "speaker.wave.2.bubble.left.fill" : "speaker.wave.2.bubble.left")
                            .frame(width:48, height:48)
                            .foregroundColor(playAudio ? .blue : .white)
                        Text("Page \(self.page) of \(self.numPages)")
                            .font(.system(size: 24))
                            .frame(minWidth: 120, alignment:.trailing)
                            .padding(.bottom, 5)
                    }
                    .frame(maxWidth:.infinity)
                    
                    ProgressSlider(
                        progress : progress,
                        
                        selectPressed: {
                         controlsLayout = .l2
                         infoFocused = true
                        },
                        
                        leftPressed:{
                            if page <= 1 {
                                return
                            }
                            
                            defer {
                                if let callback = previous {
                                    callback()
                                }
                            }
                            
                            if (page == 2){
                                page = page - 1
                                return
                            }
                            page = page - increment
                        },
                        rightPressed: {
                            defer{
                                if let callback = next {
                                    callback()
                                }
                            }
                            
                            if (page == 1){
                                page = page + 1
                                return
                            }
                            if (page + increment <= numPages){
                                page = page + increment
                            }

                        },
                        upPressed: {
                            if controlsLayout == .l1 {
                                controlsLayout = .l2
                                infoFocused = true
                            }else {
                                controlsLayout = .l1
                            }
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
                        
                        if !thumbs.isEmpty {
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
                        }
                        
                        if !mediaItems.isEmpty {
                            Button{
                            }label: {
                                Text("Interactive")
                                    .font(.system(size: 30))
                            }
                            .buttonStyle(TextButtonStyle(focused:selectedTab == .Interactive))
                            .focused($interactiveFocused)
                            .onChange(of:interactiveFocused) {
                                if (interactiveFocused){
                                    selectedTab = .Interactive
                                }
                            }
                            .opacity(interactiveFocused ? 1.0 : 0.5)
                        }
                        
                        Spacer()
                        
                        Button{
                            playAudio.toggle()
                        }label: {
                            Image(systemName: playAudio ? "speaker.wave.2.bubble.left.fill" : "speaker.wave.2.bubble.left")
                                .frame(width:48, height:48)
                        }
                        .buttonStyle(IconButtonStyle(focused:audioFocused, initialOpacity:0.5, scale:1.5))
                        .focused($audioFocused)
                    }
                    .frame(maxWidth:.infinity)
                    .focusSection()
                    .padding(.top, 20)
                
                    if (selectedTab == .Info) {
                        InfoTab(image:coverArtImage ?? UIImage(), title:title, description: description, copyright:copyright)
                        .frame(maxWidth:.infinity, maxHeight: tabHeight)
                    }
                    if (selectedTab == .Thumbs) {
                        ThumbnailRowView(thumbs:thumbs, page:$page, thumbWidth: thumbWidth, thumbHeight:tabHeight*0.8)
                            .frame(maxWidth:.infinity, maxHeight: tabHeight)
                    }
                    if (selectedTab == .Interactive) {
                        InteractiveTab(items:mediaItems, imageWidth: thumbWidth)
                            .frame(maxWidth:.infinity, maxHeight: tabHeight)
                    }
                }
            }
        }
        .onChange(of: progressFocused){
            if progressFocused {
                controlsLayout = .l1
            }
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
    }
}
