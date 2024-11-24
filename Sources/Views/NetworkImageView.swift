//
//  NetworkImageView.swift
//  
//
//  Created by Ifeanyi Onuoha on 16/11/2024.
//

import SwiftUI

struct NetworkImageView: View {
    let imageUrl: String
    let radius: CGFloat
    
    @State private var uiImage: UIImage? = nil
    @State private var isLoading = true
    
    var body: some View {
        ZStack {
            if let uiImage = uiImage {
                Image(uiImage: uiImage)
                    .resizable()
                    .scaledToFit()
                    .cornerRadius(radius)
            } else if isLoading {
                Rectangle()
                    .cornerRadius(radius)
            } else {
                Image(systemName: "exclamationmark.triangle")
                    .foregroundColor(.red)
            }
        }
        .onAppear {
            loadImage()
        }
    }
    
    private func loadImage() {
        guard let url = URL(string: imageUrl) else { return }
        
        URLSession.shared.dataTask(with: url) { data, response, error in
            if let data = data, let downloadedImage = UIImage(data: data) {
                DispatchQueue.main.async {
                    self.uiImage = downloadedImage
                    self.isLoading = false
                }
            } else {
                DispatchQueue.main.async {
                    self.isLoading = false
                }
            }
        }.resume()
    }
}
