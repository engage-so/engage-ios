//
//  ViewHandlerProtocol.swift
//  
//
//  Created by Ifeanyi Onuoha on 10/11/2024.
//

import Foundation

protocol DialogHandlerProtocol {
    func openChat(uid: String) -> Void
    func showDialog(isCarousel: Bool) -> Void
}
