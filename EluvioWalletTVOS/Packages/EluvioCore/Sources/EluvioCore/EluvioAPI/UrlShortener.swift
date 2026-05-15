//
//  UrlShortener.swift
//  EluvioWalletTVOS
//
//  Created by Stav Raviv on 2/11/26.
//

import Alamofire
import Foundation
import SwiftyJSON

public enum UrlShortener {
  // Tries to shorten the URL.
  // Fails silently and returns original url if not sucessful
  public static func shortenUrl(_ longUrl: String) async -> String {
    print("****** shortenUrl ******")
    var endpoint = "https://elv.lv/tiny/create"

    let headers: HTTPHeaders = [
      "Accept": "application/json",
      "Content-Type": "application/json",
    ]
    let response = await AF.request(
      endpoint, method: .post, parameters: [:], encoding: longUrl, headers: headers
    )
    .serializingDecodable(JSON.self)
    .response

    switch response.result {
    case .success(let value):
      let final = value["url_mapping"]["shortened_url"].stringValue
      return value["url_mapping"]["shortened_url"].string ?? longUrl
    case .failure(let error):
      debugPrint("Failed to shorten url: \(error)")
      return longUrl
    }
  }
}
