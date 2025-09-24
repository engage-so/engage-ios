//
//  EngageWidget.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 15/09/2025.
//

import SwiftUI
import Combine

struct EngageWidget: View {
    @ObservedObject private var viewModel: EngageWidgetModel
    
    init(userId: String) {
        self._viewModel = ObservedObject(wrappedValue: EngageWidgetModel(userId: userId))
    }
    
    var body: some View {
        NavigationView {
            HomeView()
        }
        .onChange(of: viewModel.threadId, perform: { _ in
            Task {
                await viewModel.dispose()
                await viewModel.setup()
            }
        })
        .environmentObject(viewModel)
    }
}


@MainActor
class EngageWidgetModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var sections: [(title: String, data: [MessageModel])] = []
    @Published var agentTyping: Bool = false
    @Published var isLoading: Bool = true
    @Published var activeThread: ThreadModel?
    @Published var threadId: String = ""
    @Published var agentsOnlineCount: Int = 0
    let userId: String
    private let storageService: StorageService
    private let socketService: SocketService
    private var typingTimer: Timer?
    private let clientId = UUID().uuidString
    private var cleanUp: [() -> Void] = []
    
    init(userId: String) {
        self.storageService = StorageService()
        self.socketService = SocketService()
        self.userId = userId
        
        
        let conf = [
            "no_chat": false,
            "ignore_anonymous": false,
            // Not needed for now
            // autotrack: {
            //   pageviews: false,
            //   buttons: false,
            //   forms: false
            // }
        ]
        let user = UserModel(
            id: userId,
            identified: false
        )
        
        socketService.initSocket(conf: conf, userData: user)
        Task {
            await cleanupOldThreads()
            await loadRecentThreads()
        }
    }
    
    func setup() async {
        do {
            messages = []
            await loadMessages()
        } catch {
            print("Failed to load thread: \(error)")
        }
        await MainActor.run {
            isLoading = false
            updateSections()
        }
        
        let offAgentsOnline = socketService.onAgentsOnline { count in
            DispatchQueue.main.async {
                self.agentsOnlineCount = count
            }
        }
        
        let offNewWebpushNotification = socketService.onWebpushNotification { data in
            DispatchQueue.main.async {
                switch data["type"] as? String {
                case "chat":
                    do {
                        if data["parent_id"] as? String != self.threadId {
                            self.threadId = data["parent_id"] as? String ?? ""
                        }
                        let msg: MessageModel = try JSONMapper.decode(data.toData ?? Data())
                        
                        self.updateMessages(clear: false, newMessages: [msg])
                        
                        if let thread = self.activeThread {
                            self.setActiveThread(ThreadModel(id: thread.id, uid: thread.uid, excerpt: msg.body, inbound: thread.inbound, status: thread.status, read: thread.read, date: thread.date, lastUpdated: msg.lastUpdated))
                        }
                        
                        Task {
                            try await self.persistMessage(threadId: msg.parentId, messages: [msg])
                        }
                    } catch {
                        print("onNewNotification - chat \(error.localizedDescription)")
                    }
                case "typing:start":
                    self.agentTyping = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.agentTyping = false
                    }
                    
                case "typing:stop":
                    self.agentTyping = true
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.agentTyping = false
                    }
                default:
                    break
                }
            }
        }
        
        // Cleanup is handled by SwiftUI's view lifecycle
        cleanUp = [offAgentsOnline, offNewWebpushNotification]
    }
    
    private func updateSections() {
        if messages.isEmpty {
            sections = []
            return
        }
        // Replaced .formatted(.dateTime) with DateFormatter
        let dateFormatter = DateFormatter()
        dateFormatter.dateFormat = "yyyy-MM-dd"
        let groups = Dictionary(grouping: messages) { message in
            message.lastUpdated.formattedDate(showTime: false)
        }
        sections = groups.map { (title: $0.key, data: $0.value) }
            .sorted { (first, second) in
                guard let firstDate = first.title.toSectionDate(),
                      let secondDate = second.title.toSectionDate() else {
                    return first.title < second.title // Fallback to string comparison
                }
                return firstDate < secondDate
            }
    }
    
    private func updateMessages(clear: Bool = true, newMessages: [MessageModel]) {
        if clear {
            messages = []
        }
        messages.insert(contentsOf: newMessages, at: messages.endIndex)
        messages.sort { (msg1: MessageModel, msg2: MessageModel) -> Bool in
            let formatter = ISO8601DateFormatter()
            let date1 = formatter.date(from: msg1.lastUpdated) ?? Date.distantPast
            let date2 = formatter.date(from: msg2.lastUpdated) ?? Date.distantPast
            return date1 < date2
        }
        updateSections()
    }
    
    func handleSend(input: String) {
        guard !input.trimmingCharacters(in: .whitespaces).isEmpty else { return }
        let tempId = "temp-\(UUID().uuidString)"
        let optimistic = MessageModel(
            messageId: "",
            //            from: UserModel(id: userId),
            body: input,
            uid: userId,
            user: "",
            parentId: threadId,
            date: Date().toISO8601String(),
            lastUpdated: Date().toISO8601String(),
            id: tempId,
            outbound: true,
            read: false,
            cid: clientId,
            status: "sending"
        )
        updateMessages(clear: false, newMessages: [optimistic])
        
        Task {
            do {
                try await self.sendMessage(threadId: threadId, message: optimistic)
            } catch {
                await MainActor.run {
                    messages = messages.map { $0.id == tempId ? MessageModel(
                        messageId: $0.messageId,
                        //                        from: $0.from,
                        body: $0.body,
                        uid: $0.uid,
                        user: $0.user,
                        parentId: $0.parentId,
                        date: $0.date,
                        lastUpdated: $0.lastUpdated,
                        id: $0.id,
                        outbound: $0.outbound,
                        read: $0.read,
                        cid: $0.cid,
                        status: "failed"
                    ): $0 }
                    updateSections()
                }
            }
        }
    }
    
    func handleTypingChange(isEditing: Bool, text: String) {
        if (threadId.isEmpty) {
            return
        }
        if typingTimer == nil && isEditing {
            socketService.emitTyping(threadId: threadId, isTyping: true)
            typingTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.socketService.emitTyping(threadId: self.threadId, isTyping: false)
                    self.typingTimer = nil
                }
            }
        } else if isEditing {
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                Task { @MainActor in
                    guard let self = self else { return }
                    self.socketService.emitTyping(threadId: self.threadId, isTyping: false)
                    self.typingTimer = nil
                }
            }
        }
    }
    
    func getMessages(threadId: String) async throws -> [MessageModel] {
        guard !threadId.isEmpty else { return [] }
        return try await storageService.loadMessages(threadId: "chat_threads_\(threadId)")
    }
    
    func loadMessages() async {
        guard !threadId.isEmpty else { return }
        
        do {
            messages = try await storageService.loadMessages(threadId: "chat_threads_\(threadId)")
            
            let (data, _) = try await Network.shared.request(.loadMessages(uid: userId, threadId: threadId))
            let jsonObject = try JSONSerialization.jsonObject(with: data) as? [String: Any]
            guard let messagesData = jsonObject?["messages"] else {
                throw NSError(domain: "", code: -1, userInfo: [NSLocalizedDescriptionKey: "No 'messages' key found"])
            }
            
            let chatsJSONData = try JSONSerialization.data(withJSONObject: messagesData)
            let chats: [MessageModel] = try JSONMapper.decode(chatsJSONData)
            if (!chats.isEmpty) {
                try await storageService.clear("chat_threads_\(threadId)")
                let _ = try await persistMessage(threadId: threadId, messages: chats)
            }
            updateMessages(newMessages: chats)
        } catch {
            print("ERROR \(error.localizedDescription)")
        }
    }
    
    func loadRecentThreads() async {
        do {
            let (data, _) = try await Network.shared.request(.loadThreads(uid: userId))
            let threads: [ThreadModel] = try JSONMapper.decode(data)
            if (!threads.isEmpty) {
                for thread in threads {
                    if thread.status == "open" {
                        threadId = thread.id
                        setActiveThread(thread)
                    }
                }
                try await storageService.clear("chat_threads")
                try await storageService.saveThreads(key: "chat_threads", threads: threads)
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func cleanupOldThreads() async {
        do {
            let threads = try await storageService.loadThreads(key: "chat_threads_ids")
            if (threads.isEmpty) {
                return
            }
            let thirtyDaysAgo = Calendar.current.date(byAdding: .day, value: -30, to: Date()) ?? Date()
            
            for thread in threads {
                let formatter = DateFormatter()
                formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
                formatter.locale = Locale.current
                
                guard let parsedDate = formatter.date(from: thread.lastUpdated ?? "") else { return }
                
                if (parsedDate < thirtyDaysAgo) {
                    try await storageService.clear("chat_threads_\(thread.id)")
                }
            }
        } catch {
            print(error.localizedDescription)
        }
    }
    
    private func persistMessage(threadId: String, messages: [MessageModel]) async throws {
        let oldMsgs = try await storageService.loadMessages(threadId: "chat_threads_\(threadId)")
        let existingIds = Set(oldMsgs.map { $0.id })
        let filteredNew = messages.filter { !existingIds.contains($0.id) }
        let allMessages = (oldMsgs + filteredNew).sorted { (msg1: MessageModel, msg2: MessageModel) -> Bool in
            msg1.lastUpdated < msg2.lastUpdated
        }
        try await storageService.saveMessages(threadId: "chat_threads_\(threadId)", messages: allMessages)
    }
    
    private func setActiveThread(_ thread: ThreadModel?) {
        activeThread = thread
    }
    
    func sendMessage(threadId: String, message: MessageModel) async throws {
        let dictionary = ["body": message.body, "uid": message.uid, "cid": message.cid]
        let _ = try await Network.shared.request(.sendMessage(data: dictionary.toData))
    }
    
    func dispose() async {
        do {
            cleanUp.forEach( { $0() } )
            //            try socketService.closeSocket()
            try await storageService.clear("user")
            try await storageService.clear("chat_threads")
        } catch {
            print(error.localizedDescription)
        }
    }
}
