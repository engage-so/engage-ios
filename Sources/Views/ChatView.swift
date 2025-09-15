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
