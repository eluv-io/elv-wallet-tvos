//
//  RemoteSigner.swift
//  EluvioWalletIOS
//
//  Created by Wayne Tran on 2021-11-14.
//

import Alamofire
import CryptoKit
import Foundation
import SwiftyJSON

enum APIEnvironment: String {
  case prod = ""
  case staging
}

class RemoteSigner {
  var currentEthIndex = 0
  var currentAuthIndex = 0

  private var environment: APIEnvironment {
    NetworkStore.shared.environment
  }

  // TODO: implement fail over
  func getEthEndpoint() throws -> String {
    return FabricConfigStore.shared.config.getEthereumAPI()[currentEthIndex]
  }

  func getAuthEndpoint() throws -> String {
    return FabricConfigStore.shared.config.getAuthServices()[currentAuthIndex]
  }

  // TODO: Convert this to responseDecodable
  func getWalletData(
    accountAddress _: String, propertyId: String, description: String = "", name: String = "",
    accessCode: String, parameters: [String: String] = [:]
  ) async throws -> (result: JSON, hash: SHA256Digest) {
    return try await withCheckedThrowingContinuation { continuation in
      do {
        var endpoint = try self.getAuthEndpoint()

        // get all the tenants
        /* if IsDemoMode() {
             endpoint = endpoint.appending("/wlt/").appending(accountAddress).appending("?limit=100")
         } else { */
        // apigw should have only tenants returned that are configured
        endpoint = endpoint.appending("/apigw").appending("/nfts").appending("?limit=100")
        // }

        if environment != .prod {
          endpoint = endpoint.appending("&env=\(environment)")
        }

        if !propertyId.isEmpty {
          endpoint = endpoint.appending("&property_id=\(propertyId)")
        }

        if !description.isEmpty {
          endpoint = endpoint.appending("&filter=meta/description:co:\(description)")
        }

        if !name.isEmpty {
          endpoint = endpoint.appending("&name_like=\(name)")
        }

        print("getWalletData Request: \(endpoint)")
        // print("Params: \(parameters)")
        let headers: HTTPHeaders = [
          "Authorization": "Bearer \(accessCode)",
          "Accept": "application/json",
        ]
        // print("Headers: \(headers)")

        AF.request(
          endpoint, parameters: parameters, encoding: URLEncoding.default, headers: headers
        )
        .debugLog()
        .responseJSON { response in
          var respJSON = JSON()
          do {
            respJSON = try JSON(data: response.data ?? Data())
          } catch {}

          switch response.result {
          case .success(let result):
            if respJSON["errors"].exists() {
              continuation.resume(
                throwing: FabricError.apiError(
                  code: response.response?.statusCode ?? 0,
                  response: respJSON, error: FabricError.unexpectedResponse("")))
            } else {
              let hash = SHA256.hash(data: response.data ?? Data())
              continuation.resume(returning: (JSON(result), hash))
            }
          case .failure(let error):
            var respJSON = JSON()
            do {
              respJSON = try JSON(data: response.data ?? Data())
            } catch {}
            continuation.resume(
              throwing: FabricError.apiError(
                code: response.response?.statusCode ?? 0,
                response: respJSON, error: error))
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  // TODO: Convert this to responseDecodable
  func createAuthLogin(redirectUrl: String) async throws -> JSON {
    return try await withCheckedThrowingContinuation { continuation in
      print("****** createMetaMaskLogin ******")
      do {
        var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask")
        if environment != .prod {
          endpoint = endpoint.appending("?env=\(environment)")
        }

        let headers: HTTPHeaders = [
          "Accept": "application/json",
          "Content-Type": "application/json",
        ]

        let parameters: [String: Any] = ["op": "create", "dest": redirectUrl]

        AF.request(
          endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default,
          headers: headers
        )
        .responseJSON { response in
          switch response.result {
          case .success(let result):
            continuation.resume(returning: JSON(result))
          case .failure(let error):
            var respJSON = JSON()
            do {
              respJSON = try JSON(data: response.data ?? Data())
            } catch {}
            continuation.resume(
              throwing: FabricError.apiError(
                code: response.response?.statusCode ?? 0,
                response: respJSON, error: error))
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  /// Pass in the response JSON of createMetaMaskLogin
  func checkAuthLogin(createResponse: JSON) async throws -> JSON {
    return try await withCheckedThrowingContinuation { continuation in
      print("****** checkMetaMaskLogin ******")
      do {
        let id = createResponse["id"].stringValue
        let pass = createResponse["passcode"].stringValue

        if id == "" {
          continuation.resume(
            throwing: FabricError.badInput("checkMetaMaskLogin failed. ID is empty"))
        }

        if pass == "" {
          continuation.resume(
            throwing: FabricError.badInput("checkMetaMaskLogin failed. passcode is empty"))
        }

        var endpoint = try self.getAuthEndpoint().appending("/wlt/login/redirect/metamask/")
          .appending(id).appending("/").appending(pass)

        if environment != .prod {
          endpoint = endpoint.appending("?env=\(environment)")
        }

        let headers: HTTPHeaders = [
          "Accept": "application/json",
          "Content-Type": "application/json",
        ]

        AF.request(endpoint, encoding: JSONEncoding.default, headers: headers)
          .debugLog()
          .responseJSON { response in
            switch response.result {
            case .success(let result):
              continuation.resume(returning: JSON(result))
            case .failure(let error):
              var respJSON = JSON()
              do {
                respJSON = try JSON(data: response.data ?? Data())
              } catch {}
              continuation.resume(
                throwing: FabricError.apiError(
                  code: response.response?.statusCode ?? 0,
                  response: respJSON, error: error))
            }
          }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  func getNftInfo(
    nftAddress: String, tokenId: String = "", accessCode: String, parameters: [String: String] = [:]
  ) async throws -> JSON {
    return try await withCheckedThrowingContinuation { continuation in
      print("****** getNftInfo ******")
      do {
        var endpoint: String = try self.getAuthEndpoint().appending("/nft/info/\(nftAddress)")
        if !tokenId.isEmpty {
          endpoint = endpoint.appending("/\(tokenId)")
        }
        if environment != .prod {
          endpoint = endpoint.appending("?env=\(environment)")
        }
        let headers: HTTPHeaders = [
          "Authorization": "Bearer \(accessCode)",
          "Accept": "application/json",
        ]

        AF.request(
          endpoint, parameters: parameters, encoding: URLEncoding.default, headers: headers
        )
        .debugLog()
        .responseJSON { response in
          switch response.result {
          case .success(let result):
            continuation.resume(returning: JSON(result))
          case .failure(let error):
            var respJSON = JSON()
            do {
              respJSON = try JSON(data: response.data ?? Data())
            } catch {}
            continuation.resume(
              throwing: FabricError.apiError(
                code: response.response?.statusCode ?? 0,
                response: respJSON, error: error))
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  func getWalletStatus(tenantId: String, accessCode: String, parameters: [String: String] = [:])
    async throws -> JSON
  {
    return try await withCheckedThrowingContinuation { continuation in
      do {
        debugPrint("****** getWalletStatus ******")
        var endpoint: String = try self.getAuthEndpoint().appending("/wlt/status/act/\(tenantId)")
        if environment != .prod {
          endpoint = endpoint.appending("?env=\(environment)")
        }

        debugPrint("Request: \(endpoint)")
        debugPrint("Params: \(parameters)")
        let headers: HTTPHeaders = [
          "Authorization": "Bearer \(accessCode)",
          "Accept": "application/json",
        ]
        debugPrint("Headers: \(headers)")

        AF.request(
          endpoint, parameters: parameters, encoding: URLEncoding.default, headers: headers
        ).responseJSON { response in
          // print("Response : \(response)")
          var respJSON = JSON()
          do {
            respJSON = try JSON(data: response.data ?? Data())
          } catch {}

          switch response.result {
          case .success(let result):
            if respJSON["errors"].exists() {
              continuation.resume(
                throwing: FabricError.apiError(
                  code: response.response?.statusCode ?? 0,
                  response: respJSON, error: FabricError.unexpectedResponse("")))
            } else {
              continuation.resume(returning: respJSON)
            }

          case .failure(let error):
            var respJSON = JSON()
            do {
              respJSON = try JSON(data: response.data ?? Data())
            } catch {}
            continuation.resume(
              throwing: FabricError.apiError(
                code: response.response?.statusCode ?? 0,
                response: respJSON, error: error))
          }
        }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  func postWalletStatus(
    tenantId: String, accessCode: String, query: [String: String], body: [String: Any] = [:],
    bodyData: Data? = nil
  ) async throws -> JSON {
    return try await withCheckedThrowingContinuation { continuation in
      do {
        debugPrint("****** postWalletStatus ******")
        var endpoint: String = try self.getAuthEndpoint().appending("/wlt/act/\(tenantId)")
        if environment != .prod {
          endpoint = endpoint.appending("?env=\(environment)")
        }

        debugPrint("Request: \(endpoint)")
        debugPrint("Body: \(body)")
        debugPrint("Query: \(query)")

        let headers: HTTPHeaders = [
          "Authorization": "Bearer \(accessCode)",
          "Accept": "application/json",
        ]
        debugPrint("Headers: \(headers)")

        guard let url = URL(string: endpoint) else {
          continuation.resume(throwing: FabricError.badInput("Could not form url from \(endpoint)"))
          return
        }

        var urlRequest = URLRequest(url: url)
        var encodedURLRequest = try URLEncoding.queryString.encode(urlRequest, with: query)

        encodedURLRequest.httpMethod = "POST"

        encodedURLRequest.headers = headers

        let data = bodyData == nil ? try JSONSerialization.data(withJSONObject: body) : bodyData

        encodedURLRequest.httpBody = data

        print("Request: ", encodedURLRequest)

        AF.request(encodedURLRequest)
          .debugLog()
          .response { response in
            print("Response : \(response)")

            switch response.result {
            case .success:
              if let value = response.value {
                continuation.resume(returning: JSON(value))
              } else {
                continuation.resume(
                  throwing: FabricError.unexpectedResponse(
                    "postWalletStatus: could not get value from response \(response)"))
              }
            case .failure(let error):
              var respJSON = JSON()
              do {
                respJSON = try JSON(data: response.data ?? Data())
              } catch {}
              continuation.resume(
                throwing: FabricError.apiError(
                  code: response.response?.statusCode ?? 0,
                  response: respJSON, error: error))
            }
          }
      } catch {
        continuation.resume(throwing: error)
      }
    }
  }

  func createEntitlement(
    tenantId: String, marketplace: String, sku: String, purchaseId: String, authToken: String
  ) async throws -> JSON {
    return try await withCheckedThrowingContinuation { continuation in
      debugPrint("****** checkAuthLogin ******")
      var endpoint = "https://appsvc.svc.eluv.io/sample-purchase/gen-entitlement"
      endpoint = endpoint.appending("?env=\(environment)")

      let headers: HTTPHeaders = [
        "Accept": "application/json",
        "Content-Type": "application/json",
        "Authorization": "Bearer \(authToken)",
      ]

      let parameters: [String: Any] = [
        "tenant_id": tenantId,
        "marketplace_id": marketplace,
        "sku": sku,
        "purchase_id": purchaseId,
      ]

      AF.request(
        endpoint, method: .post, parameters: parameters, encoding: JSONEncoding.default,
        headers: headers
      )
      .responseJSON { response in
        var respJSON = JSON()
        do {
          respJSON = try JSON(data: response.data ?? Data())
        } catch {}

        switch response.result {
        case .success(let result):
          if respJSON["errors"].exists() {
            continuation.resume(
              throwing: FabricError.apiError(
                code: response.response?.statusCode ?? 0,
                response: respJSON, error: FabricError.unexpectedResponse("")))
          } else {
            continuation.resume(returning: respJSON)
          }

        case .failure(let error):
          var respJSON = JSON()
          do {
            respJSON = try JSON(data: response.data ?? Data())
          } catch {}
          continuation.resume(
            throwing: FabricError.apiError(
              code: response.response?.statusCode ?? 0,
              response: respJSON, error: error))
        }
      }
    }
  }
}
