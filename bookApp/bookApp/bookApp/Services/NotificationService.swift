import Foundation
import UserNotifications
import UIKit

/// Service for managing notifications and APNs integration
@MainActor
class NotificationService: ObservableObject {
    // MARK: - Published Properties
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var notifications: [BookNotification] = []
    @Published var unreadCount = 0
    
    // MARK: - Private Properties
    private let notificationCenter = UNUserNotificationCenter.current()
    
    // TODO: Inject API service when created
    // private let apiService: APIClient
    
    // MARK: - Initialization
    
    nonisolated init() {
        // Initialize notification center
        // Permission check and mock data loading will be done lazily
    }
    
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
                // Register for remote notifications (done in AppDelegate)
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
    func registerDeviceToken(_ token: String, userId: String) async {
        // TODO: Implement API call
        // POST /notifications/register
        // Body: { "deviceToken": token, "platform": "IOS" }
        
        print("📲 Would register device token for user \(userId): \(token)")
        
        // Example implementation:
        /*
        do {
            try await apiService.post(
                "/notifications/register",
                body: [
                    "deviceToken": token,
                    "platform": "IOS"
                ]
            )
            print("✅ Device token registered successfully")
        } catch {
            print("❌ Failed to register device token: \(error)")
        }
        */
    }
    
    // MARK: - Fetch Notifications
    
    /// Fetch notifications from backend
    func fetchNotifications(userId: String, unreadOnly: Bool = false) async {
        // TODO: Implement API call
        // GET /notifications?unreadOnly=true
        
        print("📬 Fetching notifications for user: \(userId)")
        
        // Example implementation:
        /*
        do {
            let params: [String: Any] = unreadOnly ? ["unreadOnly": true] : [:]
            let response: NotificationResponse = try await apiService.get(
                "/notifications",
                queryParams: params
            )
            
            await MainActor.run {
                self.notifications = response.notifications
                self.updateUnreadCount()
            }
        } catch {
            print("❌ Failed to fetch notifications: \(error)")
        }
        */
        
        // For now, load mock data
        loadMockNotifications()
    }
    
    /// Load mock notifications for testing
    func loadMockNotifications() {
        notifications = BookNotification.mockNotifications
        updateUnreadCount()
    }
    
    /// Update unread count
    private func updateUnreadCount() {
        unreadCount = notifications.filter { !$0.isRead }.count
    }
    
    // MARK: - Notification Actions
    
    /// Mark a notification as read
    func markAsRead(_ notification: BookNotification) async {
        // TODO: Implement API call
        // PUT /notifications/:id/read
        
        print("✅ Marking notification as read: \(notification.id)")
        
        // Optimistic update
        if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
            notifications[index].isRead = true
            updateUnreadCount()
        }
        
        // Example implementation:
        /*
        do {
            try await apiService.put("/notifications/\(notification.id)/read")
        } catch {
            print("❌ Failed to mark notification as read: \(error)")
            // Revert optimistic update
            if let index = notifications.firstIndex(where: { $0.id == notification.id }) {
                notifications[index].isRead = false
                updateUnreadCount()
            }
        }
        */
    }
    
    /// Mark all notifications as read
    func markAllAsRead(userId: String) async {
        print("✅ Marking all notifications as read for user: \(userId)")
        
        // Optimistic update
        for index in notifications.indices {
            notifications[index].isRead = true
        }
        updateUnreadCount()
        
        // TODO: Implement API call
        // PUT /notifications/mark-all-read
    }
    
    /// Delete a notification
    func deleteNotification(_ notification: BookNotification) async {
        print("🗑️ Deleting notification: \(notification.id)")
        
        // Optimistic removal
        notifications.removeAll { $0.id == notification.id }
        updateUnreadCount()
        
        // TODO: Implement API call
        // DELETE /notifications/:id
    }
    
    // MARK: - Local Notifications (for testing)
    
    /// Schedule a local notification (for testing/development)
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
    
    // MARK: - Badge Management
    
    /// Update app badge count
    func updateBadgeCount() {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(unreadCount)
        }
    }
    
    /// Clear app badge
    func clearBadge() {
        Task {
            try? await UNUserNotificationCenter.current().setBadgeCount(0)
        }
    }
    
    // MARK: - Notification Handling from Push
    
    /// Handle notification received from APNs
    func handleRemoteNotification(userInfo: [AnyHashable: Any]) {
        print("📨 Handling remote notification: \(userInfo)")
        
        // Extract notification data
        guard let type = userInfo["type"] as? String,
              let notificationType = NotificationType(rawValue: type) else {
            print("⚠️ Invalid notification type")
            return
        }
        
        // Create notification object from push payload
        let notification = BookNotification(
            id: userInfo["id"] as? String ?? UUID().uuidString,
            type: notificationType,
            title: userInfo["title"] as? String ?? "",
            message: userInfo["message"] as? String ?? "",
            data: extractNotificationData(from: userInfo)
        )
        
        // Add to local list
        notifications.insert(notification, at: 0)
        updateUnreadCount()
        updateBadgeCount()
    }
    
    /// Extract notification data from push payload
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
    
    // MARK: - Do Not Disturb
    
    /// Check if notifications should be sent based on time
    func shouldSendNotification(at date: Date = Date()) -> Bool {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: date)
        
        // Don't send notifications between 10 PM and 8 AM
        if hour >= 22 || hour < 8 {
            return false
        }
        
        return true
    }
}

// MARK: - Response Models (for API integration)

/// Response structure for fetching notifications
struct NotificationResponse: Codable {
    let notifications: [BookNotification]
}