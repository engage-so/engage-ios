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
        decoder.keyDecodingStrategy = .convertFromSnakeCase
        
        // Handle array types like [ThreadModel]
        if T.self is [ThreadModel].Type {
            do {
                
                // Try decoding as direct array
                let threadsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                if let threadsArray = threadsArray {
                    let threads = try threadsArray.map { jsonItem in
                        let itemData = try JSONSerialization.data(withJSONObject: jsonItem)
                        return try decoder.decode(ThreadModel.self, from: itemData)
                    }
                    return threads as! T
                }
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected array or dictionary with 'threads' key"))
            } catch {
                print("Invalid ThreadModel data")
                throw error
            }
        }
        // Handle array types like [MessageModel]
        if T.self is [MessageModel].Type {
            do {
                
                // Try decoding as direct array
                let threadsArray = try JSONSerialization.jsonObject(with: data) as? [[String: Any]]
                if let threadsArray = threadsArray {
                    let threads = try threadsArray.map { jsonItem in
                        let itemData = try JSONSerialization.data(withJSONObject: jsonItem)
                        return try decoder.decode(MessageModel.self, from: itemData)
                    }
                    return threads as! T
                }
                throw DecodingError.dataCorrupted(DecodingError.Context(codingPath: [], debugDescription: "Expected array or dictionary with 'threads' key"))
            } catch {
                print("Invalid MessageModel data")
                throw error
            }
        }
        
        // 2. Create a property for the decoded data
        return try decoder.decode(T.self, from: data)
    }
    
    static func encode<T: Encodable>(_ data: T) throws -> Data {
        // 1. Create an encoder
        let encoder = JSONEncoder()
        encoder.keyEncodingStrategy = .convertToSnakeCase
        
        // 2. Create a property for the encoded data
        return try encoder.encode(data)
    }
}
