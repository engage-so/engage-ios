//
//  SocketService.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 20/08/2025.
//

import Foundation
import SocketIO

class SocketService: ObservableObject {
    private let socketUrl = "https://ws.engage.so/webpush"
    private var socket: SocketIOClient?
    private var socketDisconnected = false
    private var allowChat = true
    private var onMessageHandlers: [(MessageModel) -> Void] = []
    private var onTypingHandlers: [(Bool, [String: Any]) -> Void] = []
    private var user = UserModel(id: "")
    private var account = AccountModel()
    private var agentsOnlineCount = 0
    private var activeMessageListeners: [(String) -> Void] = []
    private var activeMessage: String?
    private let storageService: StorageService
    
    @Published var openThreadId: String = ""
    
    init(storageService: StorageService) {
        self.storageService = storageService
    }
    
    private func joinRoom() {
        guard let socket = socket, let accountId = account.id else { return }
        socket.emit("room", accountId)
        socket.emit("room", "\(accountId):\(user.id)")
    }
    
    func getOpenThreadId() -> String? { openThreadId }
    
    func getOnlineAgents() -> Int { agentsOnlineCount }
    
    func getActiveMessage() -> String? { activeMessage }
    
    func getMessages(threadId: String) async throws -> [MessageModel] {
        guard !threadId.isEmpty else { return [] }
        return try await storageService.loadMessages(threadId: "chat_threads_\(threadId)")
    }
    
    func loadMessages(_ id: String? = nil) async throws -> [MessageModel] {
        let threadId = id ?? openThreadId
        var messages = try await storageService.loadMessages(threadId: "chat_threads_\(threadId)")
        if messages.isEmpty {
            do {
                let (data, _) = try await Network.shared.request(.loadMessages(uid: user.id, threadId: threadId))
                let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
                guard let messagesData = jsonObject?["messages"] else {
                    throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No 'messages' key found"])
                }
                
                let messagesJSONData = try JSONSerialization.data(withJSONObject: messagesData)
                messages = try JSONMapper.decode(messagesJSONData)
                if (messages.isEmpty) {
                    try await storageService.clear("chat_threads_\(threadId)")
                    let _ = try await persistMessage(threadId: threadId, messages: messages)
                }
            } catch {}
        }
        
        return messages
    }
    
    func loadRecentThreads() async throws -> [ThreadModel] {
        let (data, _) = try await Network.shared.request(.loadThreads(uid: user.id))
        let threads: [ThreadModel] = try JSONMapper.decode(data)
        if (!threads.isEmpty) {
            for thread in threads {
                if thread.status == "open" {
                    openThreadId = thread.id
                    setActiveMessage(thread.excerpt)
                }
            }
            try await storageService.clear("chat_threads")
            try await storageService.saveThreads(key: "chat_threads", threads: threads)
        }
        return threads
    }
    
    private func cleanupOldThreads() async throws {
        let threads = try await storageService.loadThreads(key: "chat_threads_ids")
        if (threads.isEmpty) {
            return
        }
        let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
        
        for thread in threads {
            let formatter = DateFormatter()
            formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
            formatter.locale = Locale.current
            
            guard let parsedDate = formatter.date(from: thread.lastUpdated) else { return }
            
            if (parsedDate < thirtyDaysAgo) {
                try await storageService.clear("chat_threads_\(thread.id)")
            }
        }
        
    }
    
    private func persistMessage(threadId: String, messages: [MessageModel]) async throws -> [MessageModel] {
        let oldMsgs = try await storageService.loadMessages(threadId: "chat_threads_\(threadId)")
        let existingIds = Set(oldMsgs.map { $0.id })
        let filteredNew = messages.filter { !existingIds.contains($0.id) }
        let allMessages = (oldMsgs + filteredNew).sorted { (msg1: MessageModel, msg2: MessageModel) -> Bool in
            msg1.lastUpdated < msg2.lastUpdated
        }
        try await storageService.saveMessages(threadId: "chat_threads_\(threadId)", messages: allMessages)
        
        return allMessages
    }
    
    private func setActiveMessage(_ msg: String) {
        activeMessage = msg
        activeMessageListeners.forEach { $0(msg) }
    }
    
    private func onSocketConnected() {
        Task {
            joinRoom()
            socketDisconnected = false
            try await cleanupOldThreads()
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
            socket?.connect()
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
    
    private func onAgentsOnline(count: Int) {
        agentsOnlineCount = count
    }
    
    private func onNewNotification(data: [String: Any]) async throws {
        switch data["type"] as? String {
        case "chat":
            if data["parent_id"] as? String != openThreadId {
                openThreadId = data["parent_id"] as? String ?? ""
            }
            let msg: MessageModel = try JSONMapper.decode(data.toData ?? Data())
            onMessageHandlers.forEach { $0(msg) }
            setActiveMessage(msg.body)
            do {
                let _ = try await persistMessage(threadId: msg.parentId, messages: [msg])
            } catch {}
        case "typing:start":
            onTypingHandlers.forEach { $0(true, data) }
        case "typing:stop":
            onTypingHandlers.forEach { $0(false, data) }
        default:
            break
        }
    }
    
    func initSocket(conf: [String: Any], userData: UserModel) {
        user = userData
        
        
        openThreadId = ""
        Task {
            do {
                let (data, _) = try await Network.shared.request(.account)
                let _ = try await loadRecentThreads()
                account = try JSONMapper.decode(data)
            } catch {
                print("Init Socket Error \(error.localizedDescription)")
            }
        }
        
        
        
        if conf["no_chat"] as? Bool == true || (conf["ignore_anonymous"] as? Bool == true && !user.identified) {
            allowChat = false
            socket?.disconnect()
            return
        }
        
        allowChat = true
        let manager = SocketManager(socketURL: URL(string: socketUrl)!, config: [.log(true), .compress])
        socket = manager.defaultSocket
        socket?.on(clientEvent: .connect) { _, _ in self.onSocketConnected() }
        socket?.on(clientEvent: .disconnect) { _, _ in self.onSocketDisconnected() }
        socket?.on("agents_online") { data, _ in
            if let count = data[0] as? Int {
                self.onAgentsOnline(count: count)
            }
        }
        socket?.on("webpush/notification") { data, _ in
            if let dataDict = data[0] as? [String: Any] {
                Task { try await self.onNewNotification(data: dataDict) }
            }
        }
        socket?.connect()
    }
    
    func closeSocket() async throws {
        socket?.disconnect()
        try await storageService.clear("user")
        try await storageService.clear("chat_threads")
    }
    
    func getSocket() throws -> SocketIOClient {
        guard let socket = socket else {
            throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "Socket not initialized. Call initSocket() first."])
        }
        return socket
    }
    
    func sendMessage(threadId: String, message: MessageModel) async {
        setActiveMessage(message.body)
        let dictionary = ["body": message.body, "uid": message.uid, "cid": message.cid]
        let _ = try? await Network.shared.request(.sendMessage(data: dictionary.toData))
    }
    
    func onMessage(handler: @escaping (MessageModel) -> Void) -> () -> Void {
        onMessageHandlers.append(handler)
        return { [weak self] in
            self?.onMessageHandlers.removeAll { $0 as AnyObject === handler as AnyObject }
        }
    }
    
    func onTyping(handler: @escaping (Bool, [String: Any]) -> Void) -> () -> Void {
        onTypingHandlers.append(handler)
        return { [weak self] in
            self?.onTypingHandlers.removeAll { $0 as AnyObject === handler as AnyObject }
        }
    }
    
    func emitTyping(threadId: String, isTyping: Bool) {
        socket?.emit(isTyping ? "typing:start" : "typing:stop", [
            "parent_id": threadId,
            "user_id": user.id,
            "org_id": account.id ?? ""
        ])
    }
}
