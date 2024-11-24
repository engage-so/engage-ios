//
//  NetworkProtocol.swift
//  
//
//  Created by Ifeanyi Onuoha on 29/03/2024.
//

import Foundation

protocol NetworkProtocol {
    func request(_ endpoint: Endpoint) throws -> Void
}
