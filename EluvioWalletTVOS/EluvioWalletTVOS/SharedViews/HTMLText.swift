//
//  HTMLText.swift
//  EluvioWalletTVOS
//
//  Created by Wayne Tran on 2023-04-11.
//

import EluvioCore
import Foundation
import SwiftUI

struct HTMLText: UIViewRepresentable {
  let html: String

  func makeUIView(context _: UIViewRepresentableContext<Self>) -> UILabel {
    let label = UILabel()
    DispatchQueue.main.async {
      let data = Data(self.html.utf8)
      if let attributedString = try? NSAttributedString(
        data: data, options: [.documentType: NSAttributedString.DocumentType.html],
        documentAttributes: nil)
      {
        label.attributedText = attributedString
      }
    }

    return label
  }

  func updateUIView(_: UILabel, context _: Context) {}
}

// MARK: - SwiftUI Previews

#Preview("HTML Text - Basic") {
  HTMLText(html: "<h1>Hello World</h1><p>This is <b>bold</b> and <i>italic</i> text.</p>")
    .frame(width: 400, height: 200)
}

#Preview("HTML Text - Styled") {
  HTMLText(
    html:
      "<p style='color: white; font-size: 24px;'>Styled HTML content with <span style='color: cyan;'>colored text</span></p>"
  )
  .frame(width: 500, height: 100)
}
