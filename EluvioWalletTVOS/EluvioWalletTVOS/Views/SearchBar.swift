//
//  SearchBar.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2024-10-10.
//

import SwiftUI
import TVUIKit
import SDWebImageSwiftUI

struct NativeSearchView: UIViewControllerRepresentable {

    func makeUIViewController(context: UIViewControllerRepresentableContext<NativeSearchView>) -> UINavigationController {
        let controller = UISearchController(searchResultsController: context.coordinator)
        controller.searchResultsUpdater = context.coordinator
        return UINavigationController(rootViewController: UISearchContainerViewController(searchController: controller))
    }

    func updateUIViewController(_ uiViewController: UINavigationController, context: UIViewControllerRepresentableContext<NativeSearchView>) {
    }

    func makeCoordinator() -> NativeSearchView.Coordinator {
        Coordinator()
    }

    typealias UIViewControllerType = UINavigationController

    class Coordinator: UIViewController, UISearchResultsUpdating {
        func updateSearchResults(for searchController: UISearchController) {
            // do here what's needed
        }
    }
}

struct SearchBar: View {
    @Binding var searchString : String
    var logoUrl = ""
    var logo = "e_logo"
    var name = ""
    var action: (String)->Void
    
    var body: some View {
        //ZStack(){
        /*
            HStack {
                if !logoUrl.isEmpty {
                    WebImage(url:URL(string:logoUrl))
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(width:140, height:180, alignment: .leading)
                    
                }else if !logo.isEmpty{
                    Image(logo)
                        .resizable()
                        .aspectRatio(contentMode: .fit)
                        .frame(height:50, alignment: .leading)
                }

            }
         */
            //.position(x:60,y:80)
            //.padding([.trailing],20)
            //.padding([.leading],80)
        HStack{}
            .searchable(text:$searchString, prompt: "Search \(name)", suggestions:{})
            .autocorrectionDisabled(true)
            //.scaleEffect(0.83)
            //.position(x:1000, y:100)
            .id("Search in " + name)

        //}
        .focusSection()
        .onChange(of:searchString) {
            action(searchString)
        }
    }
}


struct SearchBar_Previews: PreviewProvider {
    @State static var searchString = ""
    static var previews: some View {
        SearchBar(searchString: $searchString, logoUrl:"https://picsum.photos/200", name: "Lord of the Things", action:{ text in
            
        })
    }
}
