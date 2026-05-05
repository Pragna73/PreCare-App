//
//  ChatMessage.swift
//  PreCare
//
 
//


import Foundation

struct ChatMessage: Identifiable {
    let id = UUID()
    let text: String
    let isUser: Bool
    let createdAt: Date

    init(text: String, isUser: Bool, createdAt: Date = Date()) {
        self.text = text
        self.isUser = isUser
        self.createdAt = createdAt
    }
}
