import SwiftUI
import SwiftyJSON
import AVKit
import SDWebImageSwiftUI

struct MediaItemView: View {
    @EnvironmentObject var eluvio: EluvioAPI
    var media: GalleryItem? = nil
    var url: String = ""
    var title: String = ""
    
    var body: some View {
        ZStack{
            HStack(alignment:.center){
                Spacer()
                WebImage(url: URL(string:url))
                    .resizable()
                    .scaledToFit()
                    .background(.black)
                Spacer()
            }

            
            if !title.isEmpty {
                VStack(){
                    Spacer()
                    VStack(alignment:.center){
                        Text(title).font(.title3)
                            .lineLimit(2)
                            .padding(40)
                            .padding([.leading, .trailing],80)
                    }
                    .frame(maxWidth:.infinity)
                    .edgesIgnoringSafeArea(.all)
                    .background(.black.opacity(0.6))
                }
                .frame(width:UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
            }
        }
        .frame(width:UIScreen.main.bounds.width, height: UIScreen.main.bounds.height)
        .edgesIgnoringSafeArea(.all)
    }
}

