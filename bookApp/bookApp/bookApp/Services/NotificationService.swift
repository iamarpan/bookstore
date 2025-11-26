import Foundation
import UserNotifications
import FirebaseFirestore
import FirebaseMessaging

@MainActor
class NotificationService: ObservableObject {
    @Published var notificationPermissionStatus: UNAuthorizationStatus = .notDetermined
    @Published var notifications: [BookNotification] = []
    @Published var unreadCount = 0
    
    private let notificationCenter = UNUserNotificationCenter.current()
    private var db: Firestore { Firestore.firestore() }
    private var notificationListener: ListenerRegistration?
    
    init() {
        checkNotificationPermission()
    }
    
    // MARK: - Permission Management
    
    func checkNotificationPermission() {
        notificationCenter.getNotificationSettings { [weak self] settings in
            DispatchQueue.main.async {
                self?.notificationPermissionStatus = settings.authorizationStatus
            }
        }
    }
    
    func requestNotificationPermission() async -> Bool {
        do {
            let granted = try await notificationCenter.requestAuthorization(options: [.alert, .badge, .sound])
            await MainActor.run {
                notificationPermissionStatus = granted ? .authorized : .denied
            }
            return granted
        } catch {
            print("Failed to request notification permission: \(error)")
            return false
        }
    }
    
    // MARK: - Notification Listening
    
    func startListening(for userId: String) {
        notificationListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "timestamp", descending: true)
            .addSnapshotListener { [weak self] snapshot, error in
                guard let documents = snapshot?.documents else { return }
                
                let notifications = documents.compactMap { document in
                    BookNotification.fromDictionary(document.data(), id: document.documentID)
                }
                
                Task { @MainActor in
                    self?.notifications = notifications
                    self?.unreadCount = notifications.filter { !$0.isRead }.count
                }
            }
    }
    
    func stopListening() {
        notificationListener?.remove()
    }
    
    // MARK: - Notification Actions
    
    func markAsRead(_ notification: BookNotification) {
        guard let notificationId = notification.id else { return }
        
        db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ]) { error in
            if let error = error {
                print("Error marking notification as read: \(error)")
            }
        }
    }
    
    func markAllAsRead(for userId: String) {
        let batch = db.batch()
        
        notifications.filter { !$0.isRead }.forEach { notification in
            if let notificationId = notification.id {
                let docRef = db.collection("notifications").document(notificationId)
                batch.updateData(["isRead": true], forDocument: docRef)
            }
        }
        
        batch.commit { error in
            if let error = error {
                print("Error marking all notifications as read: \(error)")
            }
        }
    }
    
    // MARK: - Local Notification Handling
    
    func scheduleLocalNotification(title: String, body: String, userInfo: [String: Any] = [:]) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        content.userInfo = userInfo
        
        let trigger = UNTimeIntervalNotificationTrigger(timeInterval: 0.1, repeats: false)
        let request = UNNotificationRequest(identifier: UUID().uuidString, content: content, trigger: trigger)
        
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling local notification: \(error)")
            }
        }
    }
    
    // MARK: - Notification Creation Helpers
    
    // MARK: - Notification Creation Helpers
    
    func createBookRequestNotification(for ownerId: String, book: Book, requester: User, bookClubId: String) {
        let notification = BookNotification(
            userId: ownerId,
            title: "New Book Request",
            message: "\(requester.name) wants to borrow '\(book.title)'",
            type: .bookRequest,
            relatedBookId: book.id,
            bookClubId: bookClubId
        )
        
        saveNotification(notification)
    }
    
    func createRequestStatusNotification(for borrowerId: String, book: Book, status: RequestStatus, bookClubId: String) {
        let notification = BookNotification(
            userId: borrowerId,
            title: "Request \(status.displayName)",
            message: "Your request for '\(book.title)' has been \(status.displayName.lowercased())",
            type: status == .approved ? .requestApproved : .requestRejected,
            relatedBookId: book.id,
            bookClubId: bookClubId
        )
        
        saveNotification(notification)
    }
    
    func createReturnReminderNotification(for borrowerId: String, book: Book, bookClubId: String) {
        let notification = BookNotification(
            userId: borrowerId,
            title: "Return Reminder",
            message: "Please return '\(book.title)' to \(book.ownerName)",
            type: .returnReminder,
            relatedBookId: book.id,
            bookClubId: bookClubId
        )
        
        saveNotification(notification)
    }
    
    private func saveNotification(_ notification: BookNotification) {
        do {
            try db.collection("notifications").addDocument(data: notification.toDictionary())
        } catch {
            print("Error saving notification: \(error)")
        }
    }
    
    // MARK: - Do Not Disturb Settings
    
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