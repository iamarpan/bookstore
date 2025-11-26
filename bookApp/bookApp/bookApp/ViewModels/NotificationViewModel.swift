// ViewModels/NotificationViewModel.swift
import Foundation
import Combine

@MainActor
class NotificationViewModel: ObservableObject {
    // MARK: - Published Properties
    @Published var notifications: [BookNotification] = []
    @Published var unreadCount: Int = 0
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil
    
    // MARK: - Services
    private let notificationService: NotificationService
    
    // MARK: - Computed Properties
    
    var unreadNotifications: [BookNotification] {
        notifications.filter { !$0.isRead }
    }
    
    var readNotifications: [BookNotification] {
        notifications.filter { $0.isRead }
    }
    
    var hasUnread: Bool {
        unreadCount > 0
    }
    
    // MARK: - Initialization
    
    init(notificationService: NotificationService = NotificationService()) {
        self.notificationService = notificationService
        
        // Observe service updates
        notificationService.$notifications
            .assign(to: &$notifications)
        
        notificationService.$unreadCount
            .assign(to: &$unreadCount)
    }
    
    // MARK: - Fetch Methods
    
    /// Fetch all notifications
    func fetchNotifications(for userId: String, unreadOnly: Bool = false) async {
        isLoading = true
        errorMessage = nil
        
        await notificationService.fetchNotifications(
            userId: userId,
            unreadOnly: unreadOnly
        )
        
        isLoading = false
    }
    
    /// Refresh notifications
    func refreshNotifications(for userId: String) async {
        await fetchNotifications(for: userId)
    }
    
    // MARK: - Notification Actions
    
    /// Mark a notification as read
    func markAsRead(_ notification: BookNotification) async {
        await notificationService.markAsRead(notification)
    }
    
    /// Mark all notifications as read
    func markAllAsRead(userId: String) async {
        await notificationService.markAllAsRead(userId: userId)
    }
    
    /// Delete a notification
    func deleteNotification(_ notification: BookNotification) async {
        await notificationService.deleteNotification(notification)
    }
    
    /// Clear badge count
    func clearBadge() {
        notificationService.clearBadge()
    }
    
    // MARK: - Permission Management
    
    /// Request notification permissions
    func requestPermissions() async -> Bool {
        return await notificationService.requestNotificationPermission()
    }
    
    /// Check permission status
    func checkPermissions() {
        notificationService.checkNotificationPermission()
    }
    
    // MARK: - Mock Data
    
    /// Load mock notifications for development
    func loadMockNotifications() {
        notificationService.loadMockNotifications()
        print("✅ Loaded mock notifications")
    }
}