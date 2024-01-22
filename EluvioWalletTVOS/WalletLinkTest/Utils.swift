//
//  Utils.swift
//  WalletLinkTest
//
//  Created by Wayne Tran on 2023-11-29.
//

import Foundation
import UIKit

func GenerateQRCode(from string: String) -> UIImage {
    let context = CIContext()
    let filter = CIFilter.qrCodeGenerator()
    filter.message = Data(string.utf8)

    if let outputImage = filter.outputImage {
        if let cgimg = context.createCGImage(outputImage, from: outputImage.extent) {
            return UIImage(cgImage: cgimg)
        }
    }

    return UIImage(systemName: "xmark.circle") ?? UIImage()
}

func imageForPDF(document : CGPDFDocument, pageNumber: Int, imageWidth: CGFloat) -> UIImage? {

    guard let page = document.page(at: pageNumber) else { return nil }

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

extension String: LocalizedError {
    public var errorDescription: String? { return self }
}
