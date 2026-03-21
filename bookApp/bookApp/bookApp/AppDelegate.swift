import UIKit
import UserNotifications
import GoogleSignIn
import FirebaseCore
import FirebaseMessaging

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        print("📱 BookShare app initializing...")
        
        // Configure Firebase
        FirebaseApp.configure()
        
        // Configure Google Sign-In
        // TODO: Replace with your actual Google OAuth Client ID from Google Cloud Console
        GIDSignIn.sharedInstance.configuration = GIDConfiguration(
            clientID: "533747577822-5tqtnsmugo44ohbl7qm13ritlnms4f5f.apps.googleusercontent.com"
        )
        
        // Set up notification center and messaging delegates
        UNUserNotificationCenter.current().delegate = self
        Messaging.messaging().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Delay notification registration to prevent blocking the first frame
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            #if !targetEnvironment(simulator)
            application.registerForRemoteNotifications()
            #endif
        }
        
        return true
    }
    
    // Handle URL callback for Google Sign-In
    func application(_ app: UIApplication, open url: URL, options: [UIApplication.OpenURLOptionsKey : Any] = [:]) -> Bool {
        return GIDSignIn.sharedInstance.handle(url)
    }
    
    // MARK: - Remote Notifications (APNs)
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("📲 Registered for remote notifications")
        // Pass device token to Firebase Messaging
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("❌ Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - MessagingDelegate
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        guard let fcmToken = fcmToken else { return }
        print("Firebase registration token: \(fcmToken)")
        
        // Send device token to backend for push notifications
        Task { @MainActor in
            await NotificationService.shared.registerDeviceToken(fcmToken)
        }
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
 