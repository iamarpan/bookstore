import SwiftUI

struct BookClubHomeView: View {
    let bookClub: BookClub
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 16) {
            // Header
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(bookClub.name)
                        .font(.title2)
                        .fontWeight(.bold)
                        .foregroundColor(AppTheme.colorPrimaryText(for: themeManager.isDarkMode))
                    
                    if !bookClub.description.isEmpty {
                        Text(bookClub.description)
                            .font(.subheadline)
                            .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                // Invite Button
                Button {
                    shareInviteCode()
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: "square.and.arrow.up")
                            .font(.system(size: 20))
                        Text("Invite")
                            .font(.caption)
                            .fontWeight(.medium)
                    }
                    .foregroundColor(AppTheme.primaryAccent)
                    .padding(8)
                    .background(AppTheme.primaryAccent.opacity(0.1))
                    .cornerRadius(8)
                }
            }
            
            // Stats / Info Row
            HStack(spacing: 24) {
                Label {
                    Text("\(bookClub.memberIds.count) Members")
                        .font(.caption)
                        .fontWeight(.medium)
                } icon: {
                    Image(systemName: "person.2.fill")
                }
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                
                Label {
                    Text("Code: \(bookClub.inviteCode)")
                        .font(.caption)
                        .fontWeight(.medium)
                        .monospacedDigit()
                } icon: {
                    Image(systemName: "number")
                }
                .foregroundColor(AppTheme.colorSecondaryText(for: themeManager.isDarkMode))
                .onTapGesture {
                    UIPasteboard.general.string = bookClub.inviteCode
                }
            }
        }
        .padding()
        .background(AppTheme.colorCardBackground(for: themeManager.isDarkMode))
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
    }
    
    private func shareInviteCode() {
        let text = "Join my book club '\(bookClub.name)' on Book Club App! Use invite code: \(bookClub.inviteCode)"
        let av = UIActivityViewController(activityItems: [text], applicationActivities: nil)
        
        // Find the window scene to present
        if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
           let window = windowScene.windows.first,
           let rootVC = window.rootViewController {
            
            // For iPad support
            if let popover = av.popoverPresentationController {
                popover.sourceView = rootVC.view
                popover.sourceRect = CGRect(x: UIScreen.main.bounds.width / 2, y: UIScreen.main.bounds.height / 2, width: 0, height: 0)
                popover.permittedArrowDirections = []
            }
            
            rootVC.present(av, animated: true, completion: nil)
        }
    }
}
