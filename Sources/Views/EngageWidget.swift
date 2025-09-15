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
            NavigationLink(destination: ChatView(), label: {
                Text("Send a message")
            })
        }
        .onChange(of: viewModel.threadId, perform: { _ in
            Task {
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
    @Published var threadId: String = ""
    @Published var agentsOnlineCount: Int = 0
    let userId: String
    private let socketService: SocketService
    private var typingTimer: Timer?
    private let clientId = UUID().uuidString
    private var cancellables = Set<AnyCancellable>()
    
    init(userId: String) {
        let storageService = StorageService()
        self.socketService = SocketService(storageService: storageService)
        self.userId = userId
        // Bind openThreadId to threadId on main thread
        socketService.$openThreadId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.threadId = newValue
            }
            .store(in: &cancellables)
        socketService.$agentsOnlineCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.agentsOnlineCount = newValue
            }
            .store(in: &cancellables)
        
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
    }
    
    func setup() async {
        do {
            messages = []
            messages = try await socketService.loadMessages()
        } catch {
            print("Failed to load thread: \(error)")
        }
        await MainActor.run {
            isLoading = false
            updateSections()
        }
        
        let offMsg = socketService.onMessage { msg in
            if msg.parentId == self.threadId && msg.uid == self.userId {
                DispatchQueue.main.async {
                    self.messages.append(msg)
                    self.messages.sort { (msg1: MessageModel, msg2: MessageModel) -> Bool in
                        let formatter = ISO8601DateFormatter()
                        let date1 = formatter.date(from: msg1.lastUpdated) ?? Date.distantPast
                        let date2 = formatter.date(from: msg2.lastUpdated) ?? Date.distantPast
                        return date1 < date2
                    }
                    self.updateSections()
                }
            }
        }
        
        let offTyping = socketService.onTyping { isTyping, data in
            print("TYPING ==== \(data)")
            //            if (data["parent_id"] as? String) == self.threadId {
            DispatchQueue.main.async {
                self.agentTyping = isTyping
                if isTyping {
                    DispatchQueue.main.asyncAfter(deadline: .now() + 5) {
                        self.agentTyping = false
                    }
                }
            }
            //            }
        }
        
        // Cleanup is handled by SwiftUI's view lifecycle
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
        messages.append(optimistic)
        messages.sort { (msg1: MessageModel, msg2: MessageModel) -> Bool in
            let formatter = ISO8601DateFormatter()
            let date1 = formatter.date(from: msg1.lastUpdated) ?? Date.distantPast
            let date2 = formatter.date(from: msg2.lastUpdated) ?? Date.distantPast
            return date1 < date2
        }
        updateSections()
        
        Task {
            do {
                try await socketService.sendMessage(threadId: threadId, message: optimistic)
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
                self?.socketService.emitTyping(threadId: self?.threadId ?? "", isTyping: false)
                self?.typingTimer = nil
            }
        } else if isEditing {
            typingTimer?.invalidate()
            typingTimer = Timer.scheduledTimer(withTimeInterval: 4, repeats: false) { [weak self] _ in
                self?.socketService.emitTyping(threadId: self?.threadId ?? "", isTyping: false)
                self?.typingTimer = nil
            }
        }
    }
}
