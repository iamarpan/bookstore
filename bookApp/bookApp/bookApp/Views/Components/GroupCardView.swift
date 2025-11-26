import SwiftUI

/// Reusable card component for displaying group information
struct GroupCardView: View {
    let group: BookClub
    let isDarkMode: Bool
    let showJoinButton: Bool
    let onTap: () -> Void
    let onJoin: (() -> Void)?
    
    init(
        group: BookClub,
        isDarkMode: Bool,
        showJoinButton: Bool = false,
        onTap: @escaping () -> Void,
        onJoin: (() -> Void)? = nil
    ) {
        self.group = group
        self.isDarkMode = isDarkMode
        self.showJoinButton = showJoinButton
        self.onTap = onTap
        self.onJoin = onJoin
    }
    
    var body: some View {
        Button(action: onTap) {
            VStack(alignment: .leading, spacing: 12) {
                // Header
                HStack {
                    // Group icon
                    Image(systemName: group.privacy == .public_ ? "person.3.fill" : "lock.fill")
                        .font(.title2)
                        .foregroundColor(AppTheme.primaryGreen)
                        .frame(width: 50, height: 50)
                        .background(AppTheme.lightGreen)
                        .clipShape(Circle())
                    
                    VStack(alignment: .leading, spacing: 4) {
                        Text(group.name)
                            .font(.headline)
                            .fontWeight(.semibold)
                            .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
                            .lineLimit(1)
                        
                        HStack(spacing: 4) {
                            Image(systemName: group.privacy == .public_ ? "globe" : "lock.fill")
                                .font(.caption2)
                            Text(group.privacy == .public_ ? "Public" : "Private")
                                .font(.caption)
                        }
                        .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
                    }
                    
                    Spacer()
                    
                    if showJoinButton {
                        Button(action: { onJoin?() }) {
                            Text("Join")
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(.white)
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                                .background(AppTheme.primaryGreen)
                                .cornerRadius(8)
                        }
                        .buttonStyle(PlainButtonStyle())
                    } else {
                        Image(systemName: "chevron.right")
                            .font(.caption)
                            .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
                    }
                }
                
                // Description
                if !group.description.isEmpty {
                    Text(group.description)
                        .font(.caption)
                        .foregroundColor(AppTheme.dynamicSecondaryText(isDarkMode))
                        .lineLimit(2)
                }
                
                // Stats
                HStack(spacing: 20) {
                    StatItem(
                        icon: "person.2.fill",
                        value: "\(group.memberCount)",
                        label: "Members",
                        isDarkMode: isDarkMode
                    )
                    
                    StatItem(
                        icon: "books.vertical.fill",
                        value: "\(group.booksCount)",
                        label: "Books",
                        isDarkMode: isDarkMode
                    )
                    
                    if let distance = group.distance {
                        StatItem(
                            icon: "location.fill",
                            value: String(format: "%.1f km", distance),
                            label: "Away",
                            isDarkMode: isDarkMode
                        )
                    }
                }
            }
            .padding(16)
            .background(AppTheme.dynamicCardBackground(isDarkMode))
            .cornerRadius(12)
            .shadow(color: Color.black.opacity(isDarkMode ? 0.3 : 0.1), radius: 4, x: 0, y: 2)
        }
        .buttonStyle(.plain)
    }
}

/// Small stat display component
struct StatItem: View {
    let icon: String
    let value: String
    let label: String
    let isDarkMode: Bool
    
    var body: some View {
        HStack(spacing: 4) {
            Image(systemName: icon)
                .font(.caption2)
                .foregroundColor(AppTheme.primaryGreen)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.caption)
                    .fontWeight(.semibold)
                    .foregroundColor(AppTheme.dynamicPrimaryText(isDarkMode))
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(AppTheme.dynamicTertiaryText(isDarkMode))
            }
        }
    }
}

// MARK: - Preview
struct GroupCardView_Previews: PreviewProvider {
    static var previews: some View {
        VStack(spacing: 16) {
            GroupCardView(
                group: BookClub.mockClubs[0],
                isDarkMode: false,
                showJoinButton: false,
                onTap: { },
                onJoin: nil
            )
            
            GroupCardView(
                group: BookClub.mockClubs[1],
                isDarkMode: false,
                showJoinButton: true,
                onTap: { },
                onJoin: { }
            )
        }
        .padding()
        .background(Color(.systemGroupedBackground))
    }
}
