import SwiftUI

struct RequestNotificationView: View {
    let notification: RequestNotification
    let onDismiss: () -> Void
    
    var body: some View {
        HStack {
            Image(systemName: notification.icon)
                .font(.title2)
                .foregroundColor(notification.color)
            
            VStack(alignment: .leading, spacing: 4) {
                Text(notification.title)
                    .font(.headline)
                    .fontWeight(.semibold)
                
                Text(notification.message)
                    .font(.subheadline)
                    .foregroundColor(.secondary)
                    .lineLimit(2)
            }
            
            Spacer()
            
            Button("Dismiss") {
                onDismiss()
            }
            .font(.caption)
            .foregroundColor(.blue)
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(12)
        .overlay(
            RoundedRectangle(cornerRadius: 12)
                .stroke(notification.color.opacity(0.3), lineWidth: 1)
        )
    }
}

struct RequestNotification: Identifiable {
    let id = UUID()
    let title: String
    let message: String
    let type: NotificationType
    let timestamp: Date
    
    enum NotificationType {
        case requestReceived
        case requestApproved
        case requestRejected
        case bookReturned
        case reminder
        
        var icon: String {
            switch self {
            case .requestReceived:
                return "hand.raised.circle.fill"
            case .requestApproved:
                return "checkmark.circle.fill"
            case .requestRejected:
                return "xmark.circle.fill"
            case .bookReturned:
                return "arrow.uturn.left.circle.fill"
            case .reminder:
                return "bell.circle.fill"
            }
        }
        
        var color: Color {
            switch self {
            case .requestReceived:
                return .orange
            case .requestApproved:
                return .green
            case .requestRejected:
                return .red
            case .bookReturned:
                return .blue
            case .reminder:
                return .purple
            }
        }
    }
    
    var icon: String { type.icon }
    var color: Color { type.color }
}

// MARK: - Mock Data
extension RequestNotification {
    static let mockNotifications: [RequestNotification] = [
        RequestNotification(
            title: "New Request",
            message: "Jane Smith wants to borrow 'The Great Gatsby'",
            type: .requestReceived,
            timestamp: Date()
        ),
        RequestNotification(
            title: "Request Approved",
            message: "Your request for 'Becoming' has been approved!",
            type: .requestApproved,
            timestamp: Date().addingTimeInterval(-3600)
        )
    ]
} 