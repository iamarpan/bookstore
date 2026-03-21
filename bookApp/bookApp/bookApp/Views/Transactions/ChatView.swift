import SwiftUI

struct ChatView: View {
    let transactionId: String
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    
    init(transactionId: String) {
        self.transactionId = transactionId
        self._viewModel = StateObject(wrappedValue: ChatViewModel(transactionId: transactionId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            ScrollViewReader { proxy in
                ScrollView {
                    LazyVStack(spacing: 12) {
                        ForEach(viewModel.messages) { message in
                            messagingBubble(for: message)
                                .id(message.id)
                        }
                    }
                    .padding()
                }
                .onChange(of: viewModel.messages.count) { _ in
                    if let lastId = viewModel.messages.last?.id {
                        withAnimation {
                            proxy.scrollTo(lastId, anchor: .bottom)
                        }
                    }
                }
            }
            .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
            
            // Input Area
            HStack {
                TextField("Type a message...", text: $viewModel.newMessageText)
                    .padding(12)
                    .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .cornerRadius(20)
                
                Button(action: {
                    Task {
                        await viewModel.sendMessage()
                    }
                }) {
                    Image(systemName: "paperplane.fill")
                        .font(.system(size: 20))
                        .foregroundColor(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : AppTheme.primaryAccent)
                }
                .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty)
                .padding(.leading, 8)
            }
            .padding()
            .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
            .shadow(color: Color.black.opacity(0.05), radius: 5, y: -2)
        }
        .navigationTitle("Chat")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            Task {
                await viewModel.fetchMessages()
                viewModel.startPolling()
            }
        }
        .onDisappear {
            viewModel.stopPolling()
        }
    }
    
    @ViewBuilder
    private func messagingBubble(for message: Message) -> some View {
        let isCurrentUser = message.senderId == authViewModel.currentUser?.id
        
        HStack {
            if isCurrentUser { Spacer() }
            
            VStack(alignment: isCurrentUser ? .trailing : .leading, spacing: 4) {
                Text(message.content)
                    .padding(12)
                    .background(isCurrentUser ? AppTheme.primaryAccent : AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                    .foregroundColor(isCurrentUser ? .white : AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    .cornerRadius(isCurrentUser ? 16 : 0, corners: .topLeft)
                    .cornerRadius(isCurrentUser ? 0 : 16, corners: .topRight)
                    .cornerRadius(16, corners: .bottomLeft)
                    .cornerRadius(16, corners: .bottomRight)
                
                Text(formatDate(message.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
            }
            
            if !isCurrentUser { Spacer() }
        }
    }
    
    private func formatDate(_ dateString: String) -> String {
        let formatter = ISO8601DateFormatter()
        formatter.formatOptions = [.withInternetDateTime, .withFractionalSeconds]
        guard let date = formatter.date(from: dateString) else { return "" }
        
        let displayFormatter = DateFormatter()
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}


