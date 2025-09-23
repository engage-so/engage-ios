//
//  HomeView.swift
//  Engage
//
//  Created by Ifeanyi Onuoha on 23/09/2025.
//

import SwiftUI
import Combine

let blue = Color(hex: 0xFF3264F3)

struct HomeView: View {
    @EnvironmentObject private var viewModel: EngageWidgetModel
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                /// Header Section
                ZStack(alignment: .leading) {
                    blue
                        .ignoresSafeArea(edges: .top)
                    VStack(alignment: .leading, spacing: 30) {
                        Spacer()
                        Text("Hello :)")
                            .font(.largeTitle)
                            .fontWeight(.black)
                            .foregroundColor(.white)
                        
                        Text("Questions, feedback, hi?\nSend us a message.")
                            .font(.title3)
                            .fontWeight(.bold)
                            .foregroundColor(.white)
                            .multilineTextAlignment(.leading)
                    }
                    .padding(45)
                }
                .frame(height: geometry.size.height / 2)
                
                /// Message Section
                VStack(alignment: .leading) {
                    Text("3 days ago")
                        .font(.caption)
                        .foregroundColor(.gray)
                        .padding(.bottom, 4)
                    Text("What's next? Don't tell me this is how we work now? You ain't responding to me guy why na?")
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(.bottom, 20)
                        .multilineTextAlignment(.leading)
                    NavigationLink(destination: ChatView(), label: {
                        HStack {
                            Text("Continue Conversation")
                            Spacer()
                            Image(systemName: "chevron.right")
                        }
                        .font(.headline)
                        .foregroundColor(.white)
                        .padding()
                        .frame(maxWidth: .infinity)
                        .background(blue)
                        .cornerRadius(10)
                    })
                    
                }
                .padding()
                .overlay(
                    RoundedRectangle(cornerRadius: 10)
                        .stroke(.gray.opacity(0.3), lineWidth: 1)
                )
                .padding()
            }
        }
    }
}

//#Preview {
//    return EngageWidget(userId: "")
//}
