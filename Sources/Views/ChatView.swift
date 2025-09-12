//
//  ChatView.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 21/08/2025.
//

import SwiftUI
import SocketIO
import Combine

struct ChatView: View {
    @ObservedObject private var viewModel: ChatViewModel
    @State private var input: String = ""
    private let socketService: SocketService
    
    init(socketService: SocketService, userId: String) {
        self.socketService = socketService
        self._viewModel = ObservedObject(wrappedValue: ChatViewModel(socketService: socketService, userId: userId))
    }
    
    var body: some View {
        VStack {
            // Offline message
            if socketService.getOnlineAgents() < 1 {
                Text("We are currently offline. Send us a message and we will respond soon.")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x374151))
                    .padding(12)
            }
            
            // Message List
            ScrollViewReader { proxy in
                List {
                    ForEach(viewModel.sections, id: \.title) { section in
                        Section(header: SectionHeader(title: section.title)) {
                            ForEach(section.data, id: \.id) { message in
                                MessageBubble(message: message, userId: viewModel.userId)
                            }
                        }
                    }
                }
                .listStyle(.plain)
                .onChange(of: viewModel.messages.count) { _ in
                    // Scroll to the last message when new message added
                    if let lastMessage = viewModel.messages.last {
                        withAnimation {
                            proxy.scrollTo(lastMessage.id, anchor: .bottom)
                        }
                    }
                }
            }
            
            // Typing indicator
            if viewModel.agentTyping {
                Text("...")
                    .font(.system(size: 14))
                    .foregroundColor(Color(hex: 0x777777))
                    .padding(.leading, 12)
            }
            
            // Input Area
            HStack(alignment: .center, spacing: 8) {
                HStack {
                    TextField("Type a message...", text: $input, onEditingChanged: { isEditing in
                        viewModel.handleTypingChange(isEditing: isEditing, text: input)
                    })
                    .padding(.horizontal, 16)
                    .padding(.vertical, 12)
                    .background(Color.white)
                    .clipShape(RoundedRectangle(cornerRadius: 24))
                    .overlay(
                        RoundedRectangle(cornerRadius: 24)
                            .stroke(Color(hex: 0xE5E7EB), lineWidth: 1)
                    )
                    
                    Button(action: {}) { Text("😊") }
                    Button(action: {}) { Text("📎") }
                }
                
                Button(action: {
                    viewModel.handleSend(input: input)
                    input = ""
                }) {
                    Text("Send")
                        .foregroundColor(.white)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 8)
                        .background(Color(hex: 0x0B93F6))
                        .clipShape(RoundedRectangle(cornerRadius: 6))
                }
            }
            .padding(.horizontal, 16)
            .padding(.vertical, 12)
            .background(Color(hex: 0xF8F9FA))
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(Color(hex: 0xE5E7EB)),
                alignment: .top
            )
        }
        .background(Color(hex: 0xF8F9FA))
        .onChange(of: viewModel.threadId, perform: { _ in
            Task {
                await viewModel.setup()
            }
        })
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        Text(title)
            .font(.system(size: 13, weight: .bold))
            .foregroundColor(Color(hex: 0x374151))
            .padding(.vertical, 6)
            .padding(.horizontal, 12)
            .background(Color(hex: 0xF3F4F6))
            .clipShape(RoundedRectangle(cornerRadius: 6))
            .padding(.top, 12)
            .padding(.bottom, 4)
    }
}

struct MessageBubble: View {
    let message: MessageModel
    let userId: String
    
    var body: some View {
        HStack {
            if message.outbound == true {
                Spacer()
            }
            VStack(alignment: message.outbound == true ? .trailing : .leading) {
                HtmlTextView(text: message.body)
                    .foregroundColor(.black)
                    .padding(10)
                    .background(message.outbound == true ? Color(hex: 0xE8EAED) :  Color(hex: 0xE8EAED))
                    .clipShape(RoundedRectangle(cornerRadius: 8))
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: message.outbound == true ? .trailing : .leading)
                
                
                Text(message.lastUpdated.formattedDate())
                    .foregroundColor(.black)
                    .font(.system(size: 12))
                    .padding(.top, 4)
            }
            .onTapGesture {
                print(message.body)
                print(message.lastUpdated)
            }
            if message.outbound != true {
                Spacer()
            }
        }
        .padding(.vertical, 6)
    }
}

@MainActor
class ChatViewModel: ObservableObject {
    @Published var messages: [MessageModel] = []
    @Published var sections: [(title: String, data: [MessageModel])] = []
    @Published var agentTyping: Bool = false
    @Published var isLoading: Bool = true
    @Published var threadId: String = ""
    @Published var agentsOnlineCount: Int = 0
    let socketService: SocketService
    let userId: String
    private var typingTimer: Timer?
    private let clientId = UUID().uuidString
    private var cancellables = Set<AnyCancellable>()
    
    init(socketService: SocketService, userId: String) {
        self.socketService = socketService
        self.userId = userId
        // Bind openThreadId to threadId on main thread
        socketService.$openThreadId
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.threadId = newValue ?? ""
            }
            .store(in: &cancellables)
        socketService.$agentsOnlineCount
            .receive(on: DispatchQueue.main)
            .sink { [weak self] newValue in
                self?.agentsOnlineCount = newValue ?? 0
            }
            .store(in: &cancellables)
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

extension Color {
    init(hex: UInt) {
        self.init(
            red: Double((hex >> 16) & 0xFF) / 255,
            green: Double((hex >> 8) & 0xFF) / 255,
            blue: Double(hex & 0xFF) / 255
        )
    }
}

extension String {
    func formattedDate(showTime: Bool = true) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        if let date = formatter.date(from: self) {
            return DateFormatter.localizedString(from: date, dateStyle: .medium, timeStyle: showTime ? .short : .none)
        }
        return ""
    }
    
    func toDate() -> Date? {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        return formatter.date(from: self)
    }
    
    func toSectionDate() -> Date? {
        let formatter = DateFormatter()
        formatter.dateFormat = "dd MMM yyyy"
        formatter.locale = Locale(identifier: "en_US_POSIX") // Ensures consistent month parsing
        return formatter.date(from: self)
    }
}

extension Date {
    func toISO8601String() -> String {
        let formatter = DateFormatter()
        formatter.dateFormat = "yyyy-MM-dd'T'HH:mm:ss.SSS'Z'"
        formatter.timeZone = TimeZone(identifier: "UTC")
        return formatter.string(from: self)
    }
}
