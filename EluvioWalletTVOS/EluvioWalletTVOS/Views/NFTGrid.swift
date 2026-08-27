//
//  NFTGrid.swift
//  NFTList
//
//  Created by Wayne Tran on 2021-09-27.
//

import EluvioCore
import QGrid
import SwiftUI

struct NFTGrid: View {
  var title: String = ""
  var nfts: [NFTModel]
  var drops: [ProjectModel] = []

  @State private var editMode = EditMode.inactive

  private var columns: [GridItem] {
    return [
      .init(.adaptive(minimum: 260, maximum: 280))
    ]
  }

  @State var search = false
  @State var searchText = ""
  @State var gridOption = false
  var body: some View {
    // Leading, not centre: adaptive columns otherwise centre the whole block, which leaves a
    // gap on the left that doesn't line up with anything else on the screen.
    LazyVGrid(columns: columns, alignment: .leading, spacing: 0) {
      ForEach(nfts) { nft in
        NFTView(
          nft: nft,
          scale: 0.5
        )
        .padding(.bottom, 70)
      }
    }
  }
}

// MARK: - SwiftUI Previews

#Preview("NFT Grid - Empty") {
  NFTGrid(title: "My NFTs", nfts: [])
}
