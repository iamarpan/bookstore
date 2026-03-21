import SwiftUI

struct NotificationsView: View {
    @StateObject private var viewModel = NotificationsViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        NavigationView {
            ZStack {
                AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                    .ignoresSafeArea()
                
                if viewModel.isLoading && viewModel.notifications.isEmpty {
                    ProgressView("Loading notifications...")
                } else if viewModel.notifications.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bell.slash")
                            .font(.system(size: 60))
                            .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                        Text("No notifications yet")
                            .font(.headline)
                            .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    }
                } else {
                    List {
                        ForEach(viewModel.notifications) { notification in
                            notificationRow(notification)
                                .listRowBackground(AppTheme.colorSecondaryBackground(for: themeManager.isDarkMode))
                                .onTapGesture {
                                    viewModel.markAsRead(notification)
                                }
                        }
                    }
                    .listStyle(PlainListStyle())
                    .refreshable {
                        await viewModel.fetchNotifications()
                    }
                }
            }
            .navigationTitle("Notifications")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    if !viewModel.notifications.isEmpty {
                        Button("Mark All Read") {
                            viewModel.markAllAsRead()
                        }
                        .foregroundColor(AppTheme.primaryAccent)
                    }
                }
            }
            .onAppear {
                Task {
                    await viewModel.fetchNotifications()
                }
            }
        }
    }
    
    @ViewBuilder
    private func notificationRow(_ notification: BookNotification) -> some View {
        HStack(alignment: .top, spacing: 12) {
            Circle()
                .fill(notification.isRead ? Color.clear : AppTheme.primaryAccent)
                .frame(width: 8, height: 8)
                .padding(.top, 6)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                    .lineLimit(2)
                
                Text(formatDate(notification.createdAt))
                    .font(.caption2)
                    .foregroundColor(AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
            }
        }
        .padding(.vertical, 4)
    }
    
    private func formatDate(_ date: Date) -> String {
        let displayFormatter = DateFormatter()
        displayFormatter.dateStyle = .medium
        displayFormatter.timeStyle = .short
        return displayFormatter.string(from: date)
    }
}
