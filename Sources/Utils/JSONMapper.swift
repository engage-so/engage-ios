//
//  JSONMapper.swift
//
//
//  Created by Ifeanyi Onuoha on 10/11/2024.
//

import SwiftUI

struct JSONMapper {
    static func decode<T: Decodable>(_ data: Data) throws -> T {
        // 1. Create a decoder
        let decoder = JSONDecoder()
        decoder.keyDecodingStrategy = .useDefaultKeys
        
        // 2. Create a property for the decoded data
        return try decoder.decode(T.self, from: data)
    }
    
    static func encode<T: Encodable>(_ data: T) throws -> Data {
        // 1. Create an encoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .useDefaultKeys
        
        // 2. Create a property for the encoded data
        return try encoder.encode(data)
    }
}
