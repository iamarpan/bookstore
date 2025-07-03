// ViewModels/NotificationViewModel.swift
import Foundation
import Combine
import FirebaseFirestore

@MainActor
class NotificationViewModel: ObservableObject {
    @Published var notifications: [BookNotification] = []
    @Published var unreadCount = 0
    
    private var notificationsListener: ListenerRegistration?
    private let db = Firestore.firestore()
    
    func startListening(for userId: String) {
        notificationsListener = db.collection("notifications")
            .whereField("userId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
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
    
    func markAsRead(_ notification: BookNotification) async {
        guard let id = notification.id else { return }
        
        do {
            try await db.collection("notifications").document(id).updateData([
                "isRead": true
            ])
        } catch {
            print("Error marking notification as read: \(error)")
        }
    }
    
    func stopListening() {
        notificationsListener?.remove()
        notificationsListener = nil
    }
}