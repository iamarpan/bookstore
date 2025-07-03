import UIKit
import FirebaseMessaging
import UserNotifications
import FirebaseAuth
import FirebaseFirestore

class AppDelegate: NSObject, UIApplicationDelegate, UNUserNotificationCenterDelegate, MessagingDelegate {
    
    func application(_ application: UIApplication, didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey : Any]? = nil) -> Bool {
        
        // Set up notification center delegate
        UNUserNotificationCenter.current().delegate = self
        
        // Request notification permissions
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .badge, .sound]) { granted, error in
            print("Notification permission granted: \(granted)")
            if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
        
        // Register for remote notifications
        application.registerForRemoteNotifications()
        
        // Set FCM messaging delegate
        Messaging.messaging().delegate = self
        
        return true
    }
    
    // MARK: - FCM Token Management
    func messaging(_ messaging: Messaging, didReceiveRegistrationToken fcmToken: String?) {
        print("FCM Token received: \(fcmToken ?? "nil")")
        
        // Save token to user profile if user is authenticated
        if let token = fcmToken {
            saveFCMToken(token)
        }
    }
    
    private func saveFCMToken(_ token: String) {
        guard let userId = Auth.auth().currentUser?.uid else {
            print("No authenticated user to save FCM token")
            return
        }
        
        let db = Firestore.firestore()
        db.collection("users").document(userId).updateData([
            "fcmToken": token,
            "lastTokenUpdate": FieldValue.serverTimestamp()
        ]) { error in
            if let error = error {
                print("Error saving FCM token: \(error.localizedDescription)")
            } else {
                print("FCM token saved successfully for user: \(userId)")
            }
        }
    }
    
    // MARK: - Remote Notifications
    func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        print("Registered for remote notifications with device token")
        Messaging.messaging().apnsToken = deviceToken
    }
    
    func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }
    
    // MARK: - UNUserNotificationCenterDelegate
    
    // Handle notifications when app is in foreground
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              willPresent notification: UNNotification, 
                              withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        
        let userInfo = notification.request.content.userInfo
        print("Received notification in foreground: \(userInfo)")
        
        // Show notification even when app is in foreground
        completionHandler([.alert, .badge, .sound])
    }
    
    // Handle notification tap/interaction
    func userNotificationCenter(_ center: UNUserNotificationCenter, 
                              didReceive response: UNNotificationResponse, 
                              withCompletionHandler completionHandler: @escaping () -> Void) {
        
        let userInfo = response.notification.request.content.userInfo
        print("User tapped notification: \(userInfo)")
        
        // Handle notification actions based on type
        handleNotificationAction(userInfo: userInfo)
        
        completionHandler()
    }
    
    // MARK: - Notification Action Handling
    private func handleNotificationAction(userInfo: [AnyHashable: Any]) {
        // Extract notification type and relevant data
        if let notificationType = userInfo["type"] as? String {
            switch notificationType {
            case "book_request":
                // Handle book request notification
                if let requestId = userInfo["requestId"] as? String {
                    print("Navigate to book request: \(requestId)")
                    // TODO: Navigate to specific book request
                }
                
            case "request_approved":
                // Handle request approval notification
                if let bookId = userInfo["bookId"] as? String {
                    print("Navigate to approved book: \(bookId)")
                    // TODO: Navigate to book details
                }
                
            case "return_reminder":
                // Handle return reminder notification
                if let requestId = userInfo["requestId"] as? String {
                    print("Navigate to return reminder: \(requestId)")
                    // TODO: Navigate to my borrowed books
                }
                
            default:
                print("Unknown notification type: \(notificationType)")
            }
        }
    }
    
    // MARK: - Public Methods for Token Management
    func refreshFCMToken() {
        Messaging.messaging().token { token, error in
            if let error = error {
                print("Error fetching FCM registration token: \(error)")
            } else if let token = token {
                print("FCM registration token: \(token)")
                self.saveFCMToken(token)
            }
        }
    }
    
    func deleteFCMToken() {
        Messaging.messaging().deleteToken { error in
            if let error = error {
                print("Error deleting FCM token: \(error)")
            } else {
                print("FCM token deleted successfully")
            }
        }
    }
} 