import UIKit
import UserNotifications

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("📱 BookShare app initializing...")
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        #if !targetEnvironment(simulator)
        // Register for remote notifications only on real devices
        application.registerForRemoteNotifications()
        #endif
        
        return true
    }
    
    // MARK: - Remote Notifications (APNs)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📲 Registered for remote notifications")
        let tokenParts = deviceToken.map { data in String(format: "%02.2hhx", data) }
        let token = tokenParts.joined()
        print("Device Token: \(token)")
        
        // TODO: Send token to backend API
        // POST /notifications/register with { "deviceToken": token, "platform": "IOS" }
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("📬 Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.banner, .badge, .sound])
    }
    
    // Handle notification tap/interaction
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("👆 User tapped notification: \(userInfo)")
        
        // Handle notification actions based on type
        handleNotificationAction(userInfo: userInfo)
        
        completionHandler()
    }
    
    // MARK: - Notification Action Handling
    private func handleNotificationAction(userInfo: [AnyHashable: Any]) {
        // Extract notification type and relevant data from backend payload
        guard let notificationType = userInfo["type"] as? String else {
            print("⚠️ No notification type found")
            return
        }
        
        switch notificationType {
        case "BORROW_REQUEST":
            if let transactionId = userInfo["transactionId"] as? String {
                print("📚 Navigate to borrow request: \(transactionId)")
                // TODO: Navigate to transaction details
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTransaction"),
                    object: nil,
                    userInfo: ["transactionId": transactionId]
                )
            }
            
        case "REQUEST_APPROVED":
            if let transactionId = userInfo["transactionId"] as? String {
                print("✅ Navigate to approved request: \(transactionId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTransaction"),
                    object: nil,
                    userInfo: ["transactionId": transactionId]
                )
            }
            
        case "REQUEST_REJECTED":
            if let transactionId = userInfo["transactionId"] as? String {
                print("❌ Request rejected: \(transactionId)")
                // Could show an alert
            }
            
        case "DUE_SOON":
            if let transactionId = userInfo["transactionId"] as? String {
                print("⏰ Book due soon: \(transactionId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToBorrowedBooks"),
                    object: nil
                )
            }
            
        case "OVERDUE":
            if let transactionId = userInfo["transactionId"] as? String {
                print("🚨 Book overdue: \(transactionId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTransaction"),
                    object: nil,
                    userInfo: ["transactionId": transactionId]
                )
            }
            
        case "RETURN_REQUESTED":
            if let transactionId = userInfo["transactionId"] as? String {
                print("📦 Return requested: \(transactionId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToTransaction"),
                    object: nil,
                    userInfo: ["transactionId": transactionId]
                )
            }
            
        case "NEW_BOOK_IN_GROUP":
            if let bookId = userInfo["bookId"] as? String {
                print("📖 New book in group: \(bookId)")
                NotificationCenter.default.post(
                    name: NSNotification.Name("NavigateToBook"),
                    object: nil,
                    userInfo: ["bookId": bookId]
                )
            }
            
        default:
            print("⚠️ Unknown notification type: \(notificationType)")
        }
    }
}
 