//
//  CameraView.swift
//  VerifAI
//
//  Created by Evan Boyle on 11/7/25.
//

import SwiftUI

struct CameraView: View {
    @StateObject private var viewModel = CameraViewModel()

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Chat Messages
                ScrollViewReader { scrollProxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            if viewModel.chatMessages.isEmpty {
                                VStack(spacing: 16) {
                                    Image(systemName: "message.badge")
                                        .font(.system(size: 48))
                                        .foregroundColor(.gray)
                                    Text("No messages yet")
                                        .font(.headline)
                                        .foregroundColor(.gray)
                                    Text("Start a conversation with Grok")
                                        .font(.caption)
                                        .foregroundColor(.gray)
                                }
                                .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .center)
                                .padding()
                            } else {
                                ForEach(viewModel.chatMessages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                        }
                        .padding()
                    }
                    .onChange(of: viewModel.chatMessages) { _ in
                        if let lastMessage = viewModel.chatMessages.last {
                            withAnimation {
                                scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                            }
                        }
                    }
                }

                Divider()

                // Error Message
                if let errorMessage = viewModel.errorMessage {
                    HStack {
                        Image(systemName: "exclamationmark.circle.fill")
                            .foregroundColor(.red)
                        Text(errorMessage)
                            .font(.caption)
                            .foregroundColor(.red)
                    }
                    .padding(.horizontal)
                    .padding(.vertical, 8)
                    .background(Color.red.opacity(0.1))
                }

                // Input Area
                HStack(spacing: 8) {
                    TextField("Type a message...", text: $viewModel.messageInput)
                        .textFieldStyle(.roundedBorder)
                        .disabled(viewModel.isLoading)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(width: 36, height: 36)
                    } else {
                        Button(action: viewModel.sendMessage) {
                            Image(systemName: "paperplane.fill")
                                .foregroundColor(.white)
                                .frame(width: 36, height: 36)
                                .background(Color.blue)
                                .clipShape(Circle())
                        }
                        .disabled(viewModel.messageInput.trimmingCharacters(in: .whitespaces).isEmpty)
                    }
                }
                .padding()
            }
            .navigationTitle("Grok Chat")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: viewModel.clearChat) {
                        Image(systemName: "trash")
                    }
                }
            }
        }
    }
}

struct ChatBubble: View {
    let message: ChatMessage

    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == .assistant {
                Image(systemName: "robot.fill")
                    .foregroundColor(.blue)
                    .font(.caption)

                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.blue.opacity(0.2))
                        .cornerRadius(8)

                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Spacer()
            } else {
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .padding(12)
                        .background(Color.green.opacity(0.7))
                        .foregroundColor(.white)
                        .cornerRadius(8)

                    Text(message.timestamp.formatted(date: .omitted, time: .shortened))
                        .font(.caption2)
                        .foregroundColor(.gray)
                }

                Image(systemName: "person.fill")
                    .foregroundColor(.green)
                    .font(.caption)
            }
        }
    }
}

#Preview {
    CameraView()
}
