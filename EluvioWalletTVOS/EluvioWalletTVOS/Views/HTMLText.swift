//
//  HTMLView.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-11.
//

import Foundation
import SwiftUI

struct HTMLText: UIViewRepresentable {

   let html: String
    
   func makeUIView(context: UIViewRepresentableContext<Self>) -> UILabel {
        let label = UILabel()
        DispatchQueue.main.async {
            let data = Data(self.html.utf8)
            if let attributedString = try? NSAttributedString(data: data, options: [.documentType: NSAttributedString.DocumentType.html], documentAttributes: nil) {
                label.attributedText = attributedString
            }
        }

        return label
    }
    
    func updateUIView(_ uiView: UILabel, context: Context) {}
}
