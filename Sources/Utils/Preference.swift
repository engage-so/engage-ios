//
//  Preference.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 20/08/2025.
//

import Foundation

class StorageService {
    private let keyPrefix = "engage_rn:"
    
    func saveData<T: Encodable>(key: String, value: T) async throws {
        do {
            let data = try JSONMapper.encode(value)
            UserDefaults.standard.set(data, forKey: keyPrefix + key)
        } catch {
            print("Failed to save data: \(error)")
            throw error
        }
    }
    
    func getData<T: Decodable>(key: String) async throws -> T? {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + key) else { return nil }
        do {
            return try JSONMapper.decode(data)
        } catch {
            print("Failed to get data: \(error)")
            return nil
        }
    }
    
    func saveThreads(key: String, threads: [ThreadModel]) async throws {
        do {
            let data = try JSONMapper.encode(threads)
            UserDefaults.standard.set(data, forKey: keyPrefix + key)
        } catch {
            print("Failed to save threads: \(error)")
            throw error
        }
    }
    
    func loadThreads(key: String) async throws -> [ThreadModel] {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + key) else { return [] }
        do {
            return try JSONMapper.decode(data)
        } catch {
            print("Failed to load threads: \(error)")
            return []
        }
    }
    
    func saveMessages(threadId: String, messages: [MessageModel]) async throws {
        do {
            let data = try JSONMapper.encode(messages)
            UserDefaults.standard.set(data, forKey: keyPrefix + threadId)
        } catch {
            print("Failed to save messages: \(error)")
            throw error
        }
    }
    
    func loadMessages(threadId: String) async throws -> [MessageModel] {
        guard let data = UserDefaults.standard.data(forKey: keyPrefix + threadId) else { return [] }
        do {
            return try JSONMapper.decode(data)
        } catch {
            print("Failed to load messages: \(error)")
            return []
        }
    }
    
    func clear(_ key: String) async throws {
        UserDefaults.standard.removeObject(forKey: keyPrefix + key)
    }
}
