//
//  Network.swift
//
//
//  Created by Ifeanyi Onuoha on 28/03/2024.
//

import Foundation

final class Network: NetworkProtocol {
    static let shared = Network()
    
    func request(_ endpoint: Endpoint) async throws -> Void {
        URLSession.shared.dataTask(with: endpoint.request) { data, response, error in
            
        }.resume()
    }
}
