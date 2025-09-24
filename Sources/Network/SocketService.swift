//
//  SocketService.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 20/08/2025.
//

import Foundation
import SocketIO

class SocketService {
    let manager = SocketManager(socketURL: URL(string: "https://ws.engage.so")!, config: [.log(true), .compress, .reconnects(true), .forcePolling(false)])
    private var socket: SocketIOClient
    private var socketDisconnected = false
    private var allowChat = true
    private var onAgentsOnline: [(Int) -> Void] = []
    private var onWebpushNotification: [([String: Any]) -> Void] = []
    private var user = UserModel(id: "")
    private var account = AccountModel()
    private var activeMessageListeners: [(String) -> Void] = []
    
    init() {
        self.socket = manager.socket(forNamespace: "/webpush")
    }
    
    private func joinRoom() {
        guard let accountId = account.id else { return }
        socket.emit("room", accountId)
        socket.emit("room", "\(accountId):\(user.id)")
    }
    
    private func onSocketConnected() {
        Task {
            joinRoom()
            socketDisconnected = false
        }
    }
    
    private func onSocketDisconnected() {
        guard allowChat else { return }
        socketDisconnected = true
        var delay = 2000.0
        let maxDelay = 30000.0
        let jitterFactor = 0.1
        var attempts = 0
        let maxAttempts = 10
        
        func reconnect() {
            guard socketDisconnected, attempts < maxAttempts else { return }
            attempts += 1
            socket.connect()
            let jitter = delay * jitterFactor * Double.random(in: 0...1)
            delay = min(delay * 1.5 + jitter, maxDelay)
            Task {
                try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
                reconnect()
            }
        }
        Task {
            try await Task.sleep(nanoseconds: UInt64(delay * 1_000_000))
            reconnect()
        }
    }
    
    func initSocket(conf: [String: Any], userData: UserModel) {
        user = userData
        Task {
            do {
                let (data, _) = try await Network.shared.request(.account)
                account = try JSONMapper.decode(data)
            } catch {
                print("Init Socket Error \(error.localizedDescription)")
            }
        }
        
        
        
        if conf["no_chat"] as? Bool == true || (conf["ignore_anonymous"] as? Bool == true && !user.identified) {
            allowChat = false
            socket.disconnect()
            return
        }
        
        allowChat = true
        
        socket.on(clientEvent: .connect) {[weak self] data, ack in
            self?.onSocketConnected()
        }
        socket.on(clientEvent: .disconnect) {[weak self] data, ack in
            self?.onSocketDisconnected()
        }
        socket.on("agents_online") {[weak self] data, ack in
            if let count = data[0] as? Int {
                self?.onAgentsOnline.forEach { $0(count) }
            }
        }
        socket.on("webpush/notification") {[weak self] data, ack in
            print("WEB PUSH NOTIFICATION \(data)")
            if let dataDict = data[0] as? [String: Any] {
                Task { self?.onWebpushNotification.forEach { $0(dataDict) } }
            }
        }
        socket.onAny {print("Got event: \($0.event), with items: \($0.items!)")}
        socket.connect()
    }
    
    func getSocket() throws -> SocketIOClient {
        return socket
    }
    
    func onAgentsOnline(handler: @escaping (Int) -> Void) -> () -> Void {
        onAgentsOnline.append(handler)
        return { [weak self] in
            self?.onAgentsOnline.removeAll { $0 as AnyObject === handler as AnyObject }
        }
    }
    
    func onWebpushNotification(handler: @escaping ([String: Any]) -> Void) -> () -> Void {
        onWebpushNotification.append(handler)
        return { [weak self] in
            self?.onWebpushNotification.removeAll { $0 as AnyObject === handler as AnyObject }
        }
    }
    
    func emitTyping(threadId: String, isTyping: Bool) {
        socket.emit(isTyping ? "typing:start" : "typing:stop", [
            "parent_id": threadId,
            "user_id": user.id,
            "org_id": account.id ?? ""
        ])
    }
}
