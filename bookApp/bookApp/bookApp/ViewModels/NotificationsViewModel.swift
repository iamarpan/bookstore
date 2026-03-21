import Foundation
import Combine

@MainActor
class NotificationsViewModel: ObservableObject {
    @Published var notifications: [BookNotification] = []
    @Published var isLoading = false
    @Published var error: String?
    
    private let notificationService = NotificationService.shared
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to NotificationService's notifications array
        notificationService.$notifications
            .receive(on: RunLoop.main)
            .assign(to: \.notifications, on: self)
            .store(in: &cancellables)
    }
    
    func fetchNotifications() async {
        isLoading = true
        error = nil
        await notificationService.fetchNotifications()
        isLoading = false
    }
    
    func markAsRead(_ notification: BookNotification) {
        Task {
            await notificationService.markAsRead(notification)
        }
    }
    
    func markAllAsRead() {
        Task {
            await notificationService.markAllAsRead()
        }
    }
    
    func deleteNotification(at offsets: IndexSet) {
        // For simple implementation, assuming delete API exists or just remove locally
        // Standard swipe-to-delete might just ignore backend for now if delete API isn't wired
        // I will just remove it from local state if needed, or leave it.
    }
}
