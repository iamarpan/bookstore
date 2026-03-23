import Foundation
import UserNotifications
import UIKit
import Combine

/// Service for managing notifications and APNs integration
@MainActor
class NotificationService: ObservableObject {
    
    // MARK: - Singleton
    static let shared = NotificationService()
    
    // MARK: - Published Properties
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var notifications: [BookNotification] = []
    @Published var unreadCount = 0
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    private let apiClient: APIClient
    
    // MARK: - Initialization
    
    nonisolated init(apiClient: APIClient = .shared) {
        self.apiClient = apiClient
        
        // Sync internal notifications with store on MainActor
        Task { @MainActor in
            setupStoreSubscription()
        }
    }
    
    private func setupStoreSubscription() {
        AppDataStore.shared.$notifications
            .receive(on: RunLoop.main)
            .sink { [weak self] newNotifications in
                self?.notifications = newNotifications
                self?.updateUnreadCount()
            }
            .store(in: &storeCancellables)
    }
    
    private var storeCancellables = Set<AnyCancellable>()
    
    // MARK: - Permission Management
    
    /// Check current notification permission status
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            Task { @MainActor in
                self?.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    /// Request notification permissions from user
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(
                options: [.alert, .badge, .sound, .provisional]
            )
            
            await MainActor.run {
                notificationPermissionStatus = granted ? .authorized : .denied
            }
            
            if granted {
                Task { @MainActor in
                    UIApplication.shared.registerForRemoteNotifications()
                }
            }
            
            return granted
        } catch {
            print("❌ Failed to request notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Device Token Management
    
    /// Register device token with backend
    func registerDeviceToken(_ token: String) async {
        struct DeviceTokenRequest: Codable {
            let deviceToken: String
        }
        
        do {
            let _: [String: String] = try await apiClient.post(
                "/users/me/device-token",
                body: DeviceTokenRequest(deviceToken: token)
            )
            print("✅ Device token registered successfully")
        } catch {
            print("❌ Failed to register device token: \(error.localizedDescription)")
        }
    }
    
    // MARK: - Fetch Notifications
    
    /// Response model from GET /notifications
    private struct NotificationsResponse: Codable {
        let notifications: [BookNotification]
        let unreadCount: Int
    }
    
    /// Fetch notifications from backend
    @discardableResult
    func fetchNotifications(unreadOnly: Bool = false) async throws -> [BookNotification] {
        do {
            var queryParams: [String: Any] = [:]
            if unreadOnly {
                queryParams["unreadOnly"] = "true"
            }
            
            let response: NotificationsResponse = try await apiClient.get(
                "/notifications",
                queryParams: queryParams
            )
            
            // Unified Store update
            AppDataStore.shared.storeNotifications(response.notifications)
            
            self.unreadCount = response.unreadCount
            print("✅ Fetched \(response.notifications.count) notifications")
            return response.notifications
        } catch {
            print("❌ Failed to fetch notifications: \(error.localizedDescription)")
            throw error
        }
    }
    
    // MARK: - Notification Actions
    
    /// Mark a notification as read
    func markAsRead(_ notification: BookNotification) async {
        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
        }
        
        do {
            let _: [String: String] = try await apiClient.put(
                "/notifications/\(notification.id)/read",
                body: EmptyBody()
            )
        } catch {
            print("❌ Failed to mark notification as read: \(error.localizedDescription)")
            // Revert optimistic update
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = false
                updateUnreadCount()
            }
        }
    }
    
    /// Mark all notifications as read
    func markAllAsRead() async {
        // Optimistic update
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        
        do {
            let _: [String: String] = try await apiClient.put(
                "/notifications/mark-all-read",
                body: EmptyBody()
            )
        } catch {
            print("❌ Failed to mark all as read: \(error.localizedDescription)")
            // Re-fetch to restore correct state
            try? await fetchNotifications()
        }
    }
    
    /// Delete a notification
    func deleteNotification(_ notification: BookNotification) async {
        // Optimistic removal
        notifications.removeAll { $0.id == notification.id }
        updateUnreadCount()
        
        do {
            try await apiClient.delete("/notifications/\(notification.id)")
        } catch {
            print("❌ Failed to delete notification: \(error.localizedDescription)")
            // Re-fetch to restore correct state
            try? await fetchNotifications()
        }
    }
    
    // MARK: - Unread Count
    
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Badge Management
    
    func updateBadgeCount() {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
        }
    }
    
    func clearBadge() {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
    
    // MARK: - Remote Notification Handling
    
    /// Handle notification received from APNs
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("📨 Handling remote notification: \(userInfo)")
        
        guard let type = userInfo["type"] as? String,
              let notificationType = NotificationType(rawValue: type) else {
            print("⚠️ Invalid notification type")
            return
        }
        
        let notification = BookNotification(
            id: userInfo["id"] as? String ?? UUID().uuidString,
            type: notificationType,
            title: userInfo["title"] as? String ?? "",
            message: userInfo["message"] as? String ?? "",
            data: extractNotificationData(from: userInfo)
        )
        
        notifications.insert(notification, at: 0)
        updateUnreadCount()
        updateBadgeCount()
    }
    
    private func extractNotificationData(from userInfo: [AnyHashable: Any]) -> NotificationData? {
        var data = NotificationData()
        
        if let transactionId = userInfo["transactionId"] as? String {
            data.transactionId = transactionId
        }
        if let bookId = userInfo["bookId"] as? String {
            data.bookId = bookId
        }
        if let groupId = userInfo["groupId"] as? String {
            data.groupId = groupId
        }
        if let userId = userInfo["userId"] as? String {
            data.userId = userId
        }
        
        return data
    }
    
    // MARK: - Local Notifications (for testing)
    
    func scheduleLocalNotification(
        title: String,
        body: String,
        userInfo: [String: Any] = [:],
        delay: TimeInterval = 0.1
    ) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        content.badge = NSNumber(value: unreadCount + 1)
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: delay, repeats: false)
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: trigger
        )
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("❌ Error scheduling local notification: \(error)")
            } else {
                print("✅ Local notification scheduled: \(title)")
            }
        }
    }
    
    // MARK: - Do Not Disturb
    
    func shouldSendNotification(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        return !(hour >= 22 || hour < 8)
    }
}

// MARK: - Private Helpers

private struct EmptyBody: Codable {}

// MARK: - Response Models

struct NotificationResponse: Codable {
    let notifications: [BookNotification]
}