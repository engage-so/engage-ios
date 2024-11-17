//
//  SimpleDialogView.swift
//
//
//  Created by Ifeanyi Onuoha on 10/11/2024.
//

import SwiftUI

struct SimpleDialogView: View {
    var inAppPayload: InAppPayload
    var onDismissRequest: () -> Void
    
    var body: some View {
        GeometryReader { geometry in
            VStack {
                VStack {
                    if inAppPayload.closeBtn ?? false {
                        HStack {
                            Spacer()
                            Button(action: onDismissRequest, label: {
                                Image(systemName: "xmark")
                                    .resizable()
                                    .frame(width: 12, height: 12)
                                    .foregroundColor(inAppPayload.buttonColor)
                            })
                        }
                        
                    }
                    ForEach(inAppPayload.contents.first ?? [], id: \.self) { content in
                        switch content.type {
                        case .row:
                            Text("Row")
                        case .image:
                            GeometryReader { geometry in
                                NetworkImageView(
                                    imageUrl: content.url ?? "",
                                    radius: inAppPayload.radius
                                )
                                .frame(width: geometry.size.width * content.imageMaxWidth)
                            }
                            .aspectRatio(16/9, contentMode: .fit)
                        case .text:
                            Text(content.content ?? "")
                                .multilineTextAlignment(.center)
                        case .button:
                            GeometryReader { geometry in
                                Button(content.content ?? "") {
                                    onDismissRequest()
                                }
                                .padding()
                                .if(content.buttonFillWidth) { view in
                                    view.frame(width: geometry.size.width * content.buttonMaxWidth)
                                }
                                .background(inAppPayload.buttonColor)
                                .foregroundColor(inAppPayload.buttonTextColor)
                                .cornerRadius(content.butonRadius)
                                .frame(width: geometry.size.width, alignment: .center)
                            }
                            .frame(height: 50)
                        }
                    }
                }
                .padding()
                .frame(width: .infinity)
                .background(inAppPayload.backgroundColor)
                .cornerRadius(inAppPayload.radius)
                .padding()
                
            }
            .frame(height: geometry.size.height, alignment: inAppPayload.alignment)
        }
    }
}

#Preview {
    if let data = dialogMap.data(using: .utf8) {
        do {
            let inAppPayload: InAppPayload = try JSONMapper.decode(data)
            
          return SimpleDialogView(
                inAppPayload: inAppPayload,
                onDismissRequest: {
                    print("Dialog dismiss called")
                }
            )
        } catch {
            print("Error converting data to model class.\n\(error.localizedDescription)\n\(error)")
            return Rectangle()
        }
    } else {
        print("Failed to convert JSON string to Data")
        return Rectangle()
    }
}

