//
//  AskMayaView.swift
//  PreCare
//
 
//

import SwiftUI

struct AskMayaView: View {

    @StateObject private var vm = ChatViewModel()
    private let calendar = Calendar.current

    var body: some View {
        VStack {
            Text(vm.isRealtimeConnected ? "Realtime connected" : "Realtime disconnected")
                .font(.caption)
                .foregroundColor(vm.isRealtimeConnected ? .green : .orange)
                .padding(.top, 6)

            if vm.isLoading {
                ProgressView("Loading chat history...")
                    .padding(.top, 8)
            }

            if let errorMessage = vm.errorMessage {
                Text(errorMessage)
                    .font(.footnote)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }

            ScrollView {
                VStack(spacing: 12) {
                    ForEach(groupedMessages, id: \.title) { section in
                        VStack(alignment: .leading, spacing: 10) {
                            Text(section.title)
                                .font(.caption)
                                .foregroundColor(.gray)
                                .frame(maxWidth: .infinity, alignment: .center)

                            ForEach(section.messages) { message in
                                HStack {
                                    if message.isUser {
                                        Spacer()
                                        VStack(alignment: .trailing, spacing: 4) {
                                            Text(message.text)
                                                .padding()
                                                .background(Color(hex: "#FF2D6F"))
                                                .foregroundColor(.white)
                                                .cornerRadius(14)

                                            Text(timeText(message.createdAt))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                    } else {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(message.text)
                                                .padding()
                                                .background(Color.gray.opacity(0.1))
                                                .cornerRadius(14)

                                            Text(timeText(message.createdAt))
                                                .font(.caption2)
                                                .foregroundColor(.gray)
                                        }
                                        Spacer()
                                    }
                                }
                            }
                        }
                        .padding(.top, 4)
                    }
                }
                .padding()
            }

            HStack {
                TextField("Ask Maya...", text: $vm.inputText)
                    .textFieldStyle(RoundedBorderTextFieldStyle())

                Button {
                    vm.sendMessage()
                } label: {
                    Image(systemName: "paperplane.fill")
                        .foregroundColor(Color(hex: "#FF2D6F"))
                }
                .disabled(vm.isSending || vm.inputText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
            }
            .padding()
        }
        .navigationTitle("Ask Maya")
        .navigationBarTitleDisplayMode(.inline)
        .task {
            await vm.loadHistory(limit: 20)
            vm.connectRealtime()
        }
        .onDisappear {
            vm.disconnectRealtime()
        }
    }

    private var groupedMessages: [(title: String, messages: [ChatMessage])] {
        let sorted = vm.messages.sorted { $0.createdAt < $1.createdAt }
        let buckets = Dictionary(grouping: sorted) { sectionTitle(for: $0.createdAt) }
        let order = ["Today", "Yesterday", "Earlier"]

        return order.compactMap { title in
            guard let values = buckets[title], !values.isEmpty else { return nil }
            return (title, values)
        }
    }

    private func sectionTitle(for date: Date) -> String {
        if calendar.isDateInToday(date) {
            return "Today"
        }
        if calendar.isDateInYesterday(date) {
            return "Yesterday"
        }
        return "Earlier"
    }

    private func timeText(_ date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        formatter.dateStyle = .none
        return formatter.string(from: date)
    }
}
