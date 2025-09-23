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
    @EnvironmentObject private var viewModel: EngageWidgetModel
    @State private var input: String = ""
    
    var body: some View {
        VStack {
            // Offline message
            if viewModel.agentsOnlineCount < 1 {
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
                                MessageBubble(message: message)
                            }
                        }
                        .listRowInsets(EdgeInsets())
                        .background(.background)
                    }
                    .listRowSeparator(.hidden)
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
                    TextField("Send a message...", text: $input, onEditingChanged: { isEditing in
                        viewModel.handleTypingChange(isEditing: isEditing, text: input)
                    })
                    .padding(.vertical, 12)
                    
                    Button(action: {}) { Text("📎") }
                }
                
                Button(action: {
                    viewModel.handleSend(input: input)
                    input = ""
                }) {
                    Image(systemName: "paperplane")
                        .foregroundColor(.white)
                        .padding(12)
                        .background(blue)
                        .clipShape(RoundedRectangle(cornerRadius: 8))
                }
            }
            .padding()
            .overlay(
                Rectangle()
                    .frame(height: 1)
                    .foregroundColor(.gray.opacity(0.3)),
                alignment: .top
            )
        }
    }
}

struct SectionHeader: View {
    let title: String
    
    var body: some View {
        HStack {
            VStack { Divider() }
            Text(title)
                .font(.system(size: 12, weight: .bold))
                .foregroundColor(.black)
                .padding(.vertical, 6)
                .padding(.horizontal, 12)
                .overlay(
                    RoundedRectangle(cornerRadius: 100)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
                .padding(.top, 12)
                .padding(.bottom, 4)
            VStack { Divider() }
        }
        .padding(.horizontal, 16)
    }
}

struct MessageBubble: View {
    let message: MessageModel
    
    var body: some View {
        HStack {
            if message.outbound == true {
                Spacer()
            }
            VStack(alignment: message.outbound == true ? .trailing : .leading) {
                HtmlTextView(text: message.body)
                    .foregroundColor(.black)
                    .padding(12)
                    .background(message.outbound == true ? Color(hex: 0xE8EAED) :  .clear)
                    .clipShape(RoundedRectangle(cornerRadius: 18))
                    .overlay(
                        RoundedRectangle(cornerRadius: 18)
                            .stroke(.gray.opacity(0.3), lineWidth: 1)
                    )
                    .frame(maxWidth: UIScreen.main.bounds.width * 0.8, alignment: message.outbound == true ? .trailing : .leading)
                
                
                Text(message.lastUpdated.formattedDate())
                    .foregroundColor(.black)
                    .font(.system(size: 10))
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
        .padding(.horizontal, 16)
    }
}

//#Preview {
//    VStack(spacing: 20) {
//        SectionHeader(
//            title: Date().toISO8601String().formattedDate(showTime: false)
//        )
//        MessageBubble(message: MessageModel(
//                messageId: "",
//                body: "input",
//                uid: "userId",
//                user: "",
//                parentId: "threadId",
//                date: Date().toISO8601String(),
//                lastUpdated: Date().toISO8601String(),
//                id: "tempId",
//                outbound: true,
//                read: false,
//                cid: "clientId",
//                status: "sending"
//            ))
//    }
//}
