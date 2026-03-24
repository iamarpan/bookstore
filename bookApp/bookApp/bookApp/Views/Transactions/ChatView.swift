import SwiftUI

struct ChatView: View {
    let transactionId: String
    @StateObject private var viewModel: ChatViewModel
    @EnvironmentObject var authViewModel: AuthViewModel
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var tabManager: TabManager
    
    init(transactionId: String) {
        self.transactionId = transactionId
        self._viewModel = StateObject(wrappedValue: ChatViewModel(transactionId: transactionId))
    }
    
    var body: some View {
        VStack(spacing: 0) {
            if viewModel.isLoading && viewModel.messages.isEmpty {
                VStack {
                    Spacer()
                    ProgressView("Loading chat...")
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else if !viewModel.chatAvailable {
                VStack(spacing: 16) {
                    Spacer()
                    Image(systemName: "lock.fill")
                        .font(.system(size: 48))
                        .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    Text("Chat Unavailable")
                        .font(.title3)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    Text("Chat is only available for pending, approved, or active transactions.")
                        .font(.subheadline)
                        .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal, 32)
                    Spacer()
                }
                .frame(maxWidth: .infinity, maxHeight: .infinity)
            } else {
                if let transaction = viewModel.transaction {
                    transactionBar(for: transaction)
                }
                
                ScrollViewReader { proxy in
                    ScrollView {
                        LazyVStack(spacing: 12) {
                            if viewModel.messages.isEmpty {
                                Text("No messages yet. Start the conversation!")
                                    .font(.caption)
                                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                                    .padding(.top, 40)
                            } else {
                                ForEach(viewModel.messages) { message in
                                    messagingBubble(for: message)
                                        .id(message.id)
                                }
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
                HStack(spacing: 12) {
                    TextField("Type a message...", text: $viewModel.newMessageText)
                        .padding(12)
                        .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                        .cornerRadius(20)
                    
                    Button(action: {
                        Task {
                            await viewModel.sendMessage()
                        }
                    }) {
                        if viewModel.isSending {
                            ProgressView()
                                .frame(width: 24, height: 24)
                        } else {
                            Image(systemName: "paperplane.fill")
                                .font(.system(size: 20))
                                .foregroundColor(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty ? .gray : AppTheme.primaryAccent)
                        }
                    }
                    .disabled(viewModel.newMessageText.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty || viewModel.isSending)
                }
                .padding()
                .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode))
                .shadow(color: Color.black.opacity(0.05), radius: 5, y: -2)
            }
        }
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .principal) {
                HStack(spacing: 10) {
                    if let imageUrl = viewModel.otherPartyImageUrl, let url = URL(string: imageUrl) {
                        AsyncImage(url: url) { image in
                            image.resizable().aspectRatio(contentMode: .fill)
                        } placeholder: {
                            Image(systemName: "person.circle.fill")
                                .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                        }
                        .frame(width: 32, height: 32)
                        .clipShape(Circle())
                    } else {
                        Image(systemName: "person.circle.fill")
                            .resizable()
                            .frame(width: 32, height: 32)
                            .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    }
                    
                    VStack(alignment: .leading, spacing: 0) {
                        Text(viewModel.otherPartyName)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                        
                        if let transaction = viewModel.transaction {
                            Text(transaction.bookTitle)
                                .font(.caption2)
                                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                                .lineLimit(1)
                        }
                    }
                    Spacer()
                }
            }
        }
        .onAppear {
            tabManager.hide()
            Task {
                await viewModel.fetchInitialData(currentUserId: authViewModel.currentUser?.id ?? "")
                viewModel.startPolling()
            }
        }
        .onDisappear {
            tabManager.show()
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
    
    @ViewBuilder
    private func transactionBar(for transaction: Transaction) -> some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                HStack(spacing: 4) {
                    Circle()
                        .fill(statusColor(for: transaction.status))
                        .frame(width: 8, height: 8)
                    Text(transaction.status.rawValue.capitalized)
                        .font(.caption)
                        .fontWeight(.bold)
                        .foregroundColor(statusColor(for: transaction.status))
                }
                Text(transaction.bookTitle)
                    .font(.caption2)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .lineLimit(1)
            }
            Spacer()
            NavigationLink(destination: TransactionDetailView(transaction: transaction)) {
                Text("Manage")
                    .font(.caption)
                    .fontWeight(.semibold)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 6)
                    .background(AppTheme.primaryAccent)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
            .buttonStyle(.plain)
        }
        .padding(.horizontal, 16)
        .padding(.vertical, 10)
        .background(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
        .overlay(
            Rectangle()
                .frame(height: 1)
                .foregroundColor(Color.gray.opacity(0.1)),
            alignment: .bottom
        )
    }
    
    private func statusColor(for status: TransactionStatus) -> Color {
        switch status {
        case .pending: return .orange
        case .approved: return .blue
        case .active: return .green
        case .returned: return .gray
        case .rejected, .cancelled: return .red
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


