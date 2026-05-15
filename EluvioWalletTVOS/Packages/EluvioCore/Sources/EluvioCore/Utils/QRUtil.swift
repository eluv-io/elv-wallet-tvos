import CoreImage.CIFilterBuiltins
import SwiftUI

public func GenerateQRCode(from string: String) -> UIImage {
  let ciContext = CIContext()

  guard let data = string.data(using: .ascii, allowLossyConversion: false) else {
    return UIImage()
  }
  let filter = CIFilter.qrCodeGenerator()
  filter.message = data

  if let ciImage = filter.outputImage {
    if let cgImage = ciContext.createCGImage(
      ciImage,
      from: ciImage.extent
    ) {
      return UIImage(cgImage: cgImage)
    }
  }

  return UIImage()
}
