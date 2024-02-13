//
//  InteractiveMediaView.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2024-01-29.
//

import SwiftUI

extension Font {
    
    /// Create a font with the large title text style.
    public static var scriptTitle: Font {
        return Font.system(size: 24)
            .bold()
            .monospaced()
    }
    
    /// Create a font with the title text style.
    public static var scriptLabel: Font {
        return Font.system(size: 20)
            .bold()
            .monospaced()
    }
    
    public static var scriptText: Font {
        return Font.system(size: 20)
            .monospaced()
    }
    
    public static var scriptTimeStart: Font {
        return Font.system(size: 18)
            .monospaced()
    }
}


struct TextItemView: View {
    var isSelected = false
    var item: TextItem
    var body: some View {
        ZStack(alignment:.leading){
            if isSelected {
                RoundedRectangle(cornerRadius: 20, style: .continuous)
                    .fill(.gray.opacity(0.4))
                    .frame(maxWidth:.infinity)
            }
            HStack(alignment: .top){
                VStack(alignment:.leading){
                    if let start = item.start  {
                        Text("\(start.msToSeconds.hourMinuteSecond)")
                            .font(.scriptTimeStart)
                        Spacer()
                    }
                }
                .frame(minWidth:100)
                
                VStack(alignment:.leading,spacing:5) {
                    if let title = item.title{
                        Text(title)
                            .font(.scriptTitle)
                    }
                    
                    if let label = item.label{
                        Text(label)
                            .font(.scriptLabel)
                    }
                    Text(item.text)
                        .font(.scriptText)
                        .frame(maxWidth:.infinity, alignment:.leading)
                    Spacer()
                }
                .frame(maxWidth:.infinity)
            }
            .padding()
        }
        .frame(maxWidth:.infinity)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        .padding()
        
    }
}

struct SyncedTextView: View {
    var textItems : [TextItem] = []
    @Binding var currentTimeMS : Int64
    var selectedIndex: Int
    
    var body: some View {
        ScrollViewReader { value in
            ScrollView {
                LazyVStack(alignment:.leading, spacing:0) {
                    Spacer(minLength: 40)
                    ForEach(0..<textItems.count, id: \.self) { index in
                        TextItemView(isSelected: index == selectedIndex, item:textItems[index])
                            .padding(.bottom, index == textItems.count - 1 ? 500 : 0)
                    }
                    TextItemView(item:TextItem())
                }
                .onChange(of:currentTimeMS) { [currentTimeMS] newTime in
                    if newTime - currentTimeMS > 0 {
                        value.scrollTo(selectedIndex+1)
                    }else {
                        value.scrollTo(selectedIndex-2)
                    }
                }
            }
            .scrollClipDisabled()
        }
        .frame(maxWidth:.infinity)
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
    }
}


struct InteractiveMediaView: View {
    var item: InteractiveMediaItem
    @State var finished: Bool = false
    @State var currentTimeMS: Int64 = 0
    @State var durationMS: Int64 = 0
    @State var seekTimeMS: Int64 = 0
    @State var playPause: Bool = false
    @State var showControls = true
    
    @Namespace var interactiveMedia
    
    @State private var timeRemaining = 5
    let timer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()
    
    var index: Int {
        var index = 0
        
        if !item.mainText.isEmpty {
            for item in item.mainText {
                if let start = item.start {
                    if start < currentTimeMS {
                        index+=1
                    }else {
                        return index-1
                    }
                } else {
                    index += 1
                }
            }
        }
        
        return index - 1
    }
    
    var numIndices: Int {
        item.mainText.count
    }
    
    @FocusState private var progressFocused
    
    var progress : Float {
        if durationMS > 0 {
                return Float(currentTimeMS) / Float(durationMS)
        }
        return 0.0
    }
    
    func findPreviousStartTime() -> Int64? {
        for i in stride(from: index - 1, to: 0, by: -1) {
            if let start = item.mainText[i].start {
                return start
            }
        }
        
        return nil
    }
    
    func findNextStartTime() -> Int64? {
        for i in stride(from: index+1, to: item.mainText.count, by: 1) {
            if let start = item.mainText[i].start {
                return start
            }
        }
        
        return nil
    }
    
    var gradientHeight: CGFloat {
        return 150
    }
    
    var tabHeight: CGFloat {
        return gradientHeight - 50
    }
    
    var gradient: LinearGradient {
        return LinearGradient(gradient: Gradient(colors: [.black.opacity(0.5),.black.opacity(0.9), .black.opacity(0.95), .black.opacity(1.0)]), startPoint: .top, endPoint: .bottom)
    }
    
    func fadeInControls() {
        withAnimation(.easeInOut(duration: 1)) {
           showControls = true
        }
        timeRemaining = 5
    }
    
    func fadeOutControls() {
        withAnimation(.easeInOut(duration: 1)) {
           showControls = false
        }
    }
    
    var body: some View {
        ZStack{
            HStack(spacing:0) {
                SyncedTextView(textItems:item.mainText, currentTimeMS: $currentTimeMS, selectedIndex:index)
                if item.type == .InteractiveVideo {
                    PlayerView2(playoutUrl:item.mainLink,
                                finished: $finished,
                                currentTimeMS:$currentTimeMS,
                                durationMS:$durationMS,
                                seekTimeMS:$seekTimeMS,
                                playPause:$playPause
                    )
                }else if item.type == .InteractiveAudio {
                    VStack{
                        SoundPlayer(playoutUrl:item.mainLink,
                                    finished: $finished,
                                    currentTimeMS:$currentTimeMS,
                                    durationMS:$durationMS,
                                    seekTimeMS:$seekTimeMS,
                                    playPause:$playPause)
                        Spacer()
                    }
                    .padding()
                }
            }
            VStack() {
                Spacer()
                ZStack(alignment:.topLeading) {
                    VStack{
                        Rectangle()                         // Shapes are resizable by default
                            .foregroundColor(.clear)        // Making rectangle transparent
                            .background(self.gradient)
                            .frame(height:gradientHeight)
                    }
                    
                    
                    VStack{
                        HStack(alignment:.center){
                            Text("\(item.name)")
                            Spacer()
                        }
                        .frame(maxWidth:.infinity)
                        .padding([.leading,.trailing],40)
                        .padding(.top, 20)
                        
                        ProgressSlider(
                            progress : progress,
                            selectPressed: {
                                fadeInControls()
                                playPause.toggle()
                            },
                            leftPressed:{
                                fadeInControls()
                                if let time = findPreviousStartTime() {
                                    if abs(currentTimeMS - time) > 20000 {
                                        seekTimeMS = currentTimeMS - 20000
                                        return
                                    }
                                    
                                    if abs(currentTimeMS - time) < 5000 {
                                        seekTimeMS = currentTimeMS - 10000
                                        return
                                    }
                                    
                                    seekTimeMS = time
                                }else {
                                    seekTimeMS = currentTimeMS - 20000
                                }
                            },
                            rightPressed: {
                                fadeInControls()
                                if let time = findNextStartTime() {
                                    if abs(currentTimeMS - time) > 20000 {
                                        seekTimeMS = currentTimeMS + 20000
                                        return
                                    }
                                    seekTimeMS = time
                                }else {
                                    seekTimeMS = currentTimeMS + 20000
                                }
                            },
                            upPressed: {
                                fadeInControls()
                            },
                            downPressed: {
                                fadeInControls()
                            }
                        )
                        .zIndex(1)
                        .focused($progressFocused)
                        .prefersDefaultFocus(in: interactiveMedia)
                        .padding([.leading,.trailing],40) //Glitch with padding removes focus from the Slider if you used in the container
                        .focusSection()
                        
                        HStack(alignment:.center){
                            Text("\(currentTimeMS.msToSeconds.hourMinuteSecond)")
                                .font(.scriptText)
                            Spacer()
                            Text("\(durationMS.msToSeconds.hourMinuteSecond)")
                                .font(.scriptText)
                        }
                        .frame(maxWidth:.infinity)
                        .padding(.bottom, 20)
                        .padding([.leading,.trailing],40)
                    }
                    .focusScope(interactiveMedia)
                }
                .opacity(showControls ? 1 : 0.02)
            }
        }
        .edgesIgnoringSafeArea(/*@START_MENU_TOKEN@*/.all/*@END_MENU_TOKEN@*/)
        .background(Color(hex:0x252525))
        .preferredColorScheme(.dark)
        .onAppear() {
            progressFocused = true
            if item.type == .InteractiveAudio {
                playPause = true
            }
        }
        .onReceive(timer) { time in
            if timeRemaining > 0 {
                timeRemaining -= 1
            }else {
                fadeOutControls()
            }
        }
    }
}


struct SyncedTextView_Previews: PreviewProvider {
    @State static var textItems: [TextItem] = []
    
    static var previews: some View {
        SyncedTextView(textItems: textItems, currentTimeMS: .constant(0), selectedIndex: 0)
            .onAppear(){
                do {
                    textItems = try loadJsonFile("AQP-transcript.json")
                }catch{
                    debugPrint("Could not load json")
                }
            }
    }
}
