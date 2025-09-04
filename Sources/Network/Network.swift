//
//  Network.swift
//
//
//  Created by Ifeanyi Onuoha on 28/03/2024.
//

import Foundation

final class Network: NetworkProtocol {
    static let shared = Network()
    
    func request(_ endpoint: Endpoint) async throws -> (Data, HTTPURLResponse) {
        let (data, response) = try await URLSession.shared.data(for: endpoint.request)
        guard let httpResponse = response as? HTTPURLResponse else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Invalid response"])
        }
        print("Engage: \(endpoint.url?.absoluteString ?? endpoint.path) - \(httpResponse.statusCode != 200 ? httpResponse.description : httpResponse.statusCode.description)")
        return (data, httpResponse)
    }
}
