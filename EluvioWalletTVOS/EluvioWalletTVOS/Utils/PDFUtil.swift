import UIKit

func imageForPDF(
  document: CGPDFDocument, pageNumber: Int, imageWidth: CGFloat = 0, imageHeight: CGFloat = 0
) -> UIImage? {
  guard let page = document.page(at: pageNumber) else { return nil }

  var pageRect = page.getBoxRect(.mediaBox)

  var scale = 1.0

  if imageWidth > 0 {
    scale = imageWidth / pageRect.size.width
  } else if imageHeight > 0 {
    scale = imageHeight / pageRect.size.height
  }

  // Clamp the scale because a larger scale just shrinks the content int the frame
  /* if scale > 1 {
       scale = 1.0
   } */

  pageRect.size = CGSize(
    width: pageRect.size.width * scale,
    height: pageRect.size.height * scale)
  pageRect.origin = CGPoint.zero

  UIGraphicsBeginImageContext(pageRect.size)
  guard let context = UIGraphicsGetCurrentContext() else { return nil }
  context.setFillColor(red: 1.0, green: 1.0, blue: 1.0, alpha: 1.0)
  context.fill(pageRect)
  context.saveGState()

  // Rotate the PDF so that it’s the right way around
  context.translateBy(x: 0.0, y: pageRect.size.height)
  context.scaleBy(x: 1.0, y: -1.0)
  context.scaleBy(x: scale, y: scale)
  // context.concatenate(page.getDrawingTransform(.mediaBox, rect: pageRect, rotate: 0, preserveAspectRatio: true))

  context.drawPDFPage(page)
  context.restoreGState()

  let image = UIGraphicsGetImageFromCurrentImageContext()
  UIGraphicsEndImageContext()
  return image
}
