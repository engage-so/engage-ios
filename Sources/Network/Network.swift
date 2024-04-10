//
//  Network.swift
//
//
//  Created by Ifeanyi Onuoha on 28/03/2024.
//

import Foundation

final class Network: NetworkProtocol {
    static let shared = Network()
    
    func request(_ endpoint: Endpoint) throws -> Void {
        URLSession.shared.dataTask(with: endpoint.request) { data, response, error in
            if let error = error {
                print("Engage: \(error.localizedDescription)")
                return
            }
            if let response = response as? HTTPURLResponse {
                print("Engage: \(response.statusCode)")
                return
            }
        }.resume()
    }
}
