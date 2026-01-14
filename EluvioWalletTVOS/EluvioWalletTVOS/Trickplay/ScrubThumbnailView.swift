//
//  ScrubThumbnailView.swift
//  EluvioWalletTVOS
//
//  SwiftUI view for displaying trickplay thumbnails during scrubbing
//

import SwiftUI
import UIKit

/// SwiftUI view that displays a thumbnail preview during video scrubbing
struct ScrubThumbnailView: View {
    let thumbnailImage: UIImage?
    let scrubFraction: CGFloat
    let isVisible: Bool
    let thumbnailWidth: CGFloat

    init(
        thumbnailImage: UIImage?,
        scrubFraction: CGFloat = 0.5,
        isVisible: Bool = false,
        thumbnailWidth: CGFloat = 320
    ) {
        self.thumbnailImage = thumbnailImage
        self.scrubFraction = scrubFraction
        self.isVisible = isVisible
        self.thumbnailWidth = thumbnailWidth
    }

    private var thumbnailHeight: CGFloat {
        guard let image = thumbnailImage else {
            return thumbnailWidth * 9 / 16 // Default 16:9 aspect ratio
        }
        let aspectRatio = image.size.width / image.size.height
        return thumbnailWidth / aspectRatio
    }

    var body: some View {
        GeometryReader { geometry in
            if isVisible, let image = thumbnailImage {
                let centerX = geometry.size.width * scrubFraction
                let halfWidth = thumbnailWidth / 2
                let padding: CGFloat = 20
                let left = min(max(centerX - halfWidth, padding), geometry.size.width - thumbnailWidth - padding)

                Image(uiImage: image)
                    .resizable()
                    .aspectRatio(contentMode: .fill)
                    .frame(width: thumbnailWidth, height: thumbnailHeight)
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .overlay(
                        RoundedRectangle(cornerRadius: 8)
                            .stroke(Color.white, lineWidth: 3)
                    )
                    .shadow(color: .black.opacity(0.5), radius: 10, x: 0, y: 5)
                    .position(x: left + halfWidth, y: thumbnailHeight / 2 + 20)
                    .transition(.opacity)
                    .animation(.easeInOut(duration: 0.15), value: isVisible)
            }
        }
        .allowsHitTesting(false)
    }
}

/// UIKit view for displaying trickplay thumbnails (for use with AVPlayerViewController)
class ScrubThumbnailUIView: UIView {

    private let imageView: UIImageView = {
        let view = UIImageView()
        view.contentMode = .scaleAspectFill
        view.clipsToBounds = true
        view.layer.cornerRadius = 8
        view.layer.borderWidth = 3
        view.layer.borderColor = UIColor.white.cgColor
        view.layer.shadowColor = UIColor.black.cgColor
        view.layer.shadowOffset = CGSize(width: 0, height: 5)
        view.layer.shadowOpacity = 0.5
        view.layer.shadowRadius = 10
        return view
    }()

    var thumbnailWidth: CGFloat = 320 {
        didSet { updateLayout() }
    }

    private var scrubFraction: CGFloat = 0.5
    private var aspectRatio: CGFloat = 16.0 / 9.0

    override init(frame: CGRect) {
        super.init(frame: frame)
        setup()
    }

    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setup()
    }

    private func setup() {
        addSubview(imageView)
        isHidden = true
        isUserInteractionEnabled = false
    }

    private func updateLayout() {
        let height = thumbnailWidth / aspectRatio
        let centerX = bounds.width * scrubFraction
        let halfWidth = thumbnailWidth / 2
        let padding: CGFloat = 20

        let left = min(max(centerX - halfWidth, padding), bounds.width - thumbnailWidth - padding)

        imageView.frame = CGRect(
            x: left,
            y: 20,
            width: thumbnailWidth,
            height: height
        )
    }

    override func layoutSubviews() {
        super.layoutSubviews()
        updateLayout()
    }

    /// Update the thumbnail display
    /// - Parameters:
    ///   - image: The thumbnail image to display
    ///   - fraction: The scrub position as a fraction (0-1)
    func updateThumbnail(image: UIImage?, fraction: CGFloat) {
        scrubFraction = fraction

        if let img = image {
            aspectRatio = img.size.width / img.size.height
            imageView.image = img
            isHidden = false
        } else {
            isHidden = true
        }

        updateLayout()
    }

    /// Hide the thumbnail
    func hide() {
        UIView.animate(withDuration: 0.15) {
            self.alpha = 0
        } completion: { _ in
            self.isHidden = true
            self.alpha = 1
        }
    }

    /// Show the thumbnail
    func show() {
        isHidden = false
        alpha = 0
        UIView.animate(withDuration: 0.15) {
            self.alpha = 1
        }
    }
}
