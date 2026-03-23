import SwiftUI

// MARK: - AppTab Enum
// Replaces fragile raw integers with a type-safe, self-documenting enum.

enum AppTab: Int, CaseIterable, Identifiable {
    case home, add, groups, library, notifications, profile

    var id: Int { rawValue }

    var icon: String {
        switch self {
        case .home:    return "house.fill"
        case .add:     return "plus.square.fill"
        case .groups:  return "person.3.fill"
        case .library: return "books.vertical.fill"
        case .notifications: return "bell.fill"
        case .profile: return "person.fill"
        }
    }

    var label: String {
        switch self {
        case .home:    return "Home"
        case .add:     return "Add"
        case .groups:  return "Groups"
        case .library: return "Library"
        case .notifications: return "Alerts"
        case .profile: return "Profile"
        }
    }
}

// MARK: - MainTabView

struct MainTabView: View {
    @StateObject private var homeViewModel    = HomeViewModel()
    @StateObject private var libraryViewModel = MyLibraryViewModel()
    @StateObject private var tabManager       = TabManager()

    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel

    @State private var selectedTab: AppTab = .home
    @State private var visitedTabs: Set<AppTab> = [.home]   // lazy init tracker
    @State private var showEmergencyLogoutAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .safeAreaInset(edge: .bottom) {
                    if tabManager.isVisible {
                        Color.clear.frame(height: 70)
                    }
                }

            if tabManager.isVisible {
                FloatingDock(selectedTab: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
        .environmentObject(tabManager)
        .background(
            AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode)
                .ignoresSafeArea()
        )
        .onAppear(perform: startDataListening)
        .onShake { showEmergencyLogoutAlert = true }
        .alert("Emergency Logout", isPresented: $showEmergencyLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout Now", role: .destructive) { authViewModel.signOut() }
        } message: {
            Text("Shake gesture detected. Do you want to log out immediately for security?")
        }
    }

    // MARK: - Tab Content
    //
    // Uses a ZStack + opacity approach to preserve scroll position and @State across switches.
    // Views are only created once they've been visited (lazy via `visitedTabs`), reducing
    // the upfront memory cost of keeping all 5 views alive simultaneously.

    @ViewBuilder
    private var tabContent: some View {
        ZStack {
            ForEach(AppTab.allCases) { tab in
                if visitedTabs.contains(tab) {
                    view(for: tab)
                        .opacity(selectedTab == tab ? 1 : 0)
                        .allowsHitTesting(selectedTab == tab)
                }
            }
        }
        .onChange(of: selectedTab) { newTab in
            visitedTabs.insert(newTab)
        }
    }

    @ViewBuilder
    private func view(for tab: AppTab) -> some View {
        switch tab {
        case .home:
            HomeView()
                .environmentObject(homeViewModel)
                .environmentObject(libraryViewModel)
        case .add:
            AddBookView()
        case .groups:
            MyGroupsView()
        case .library:
            MyLibraryView()
                .environmentObject(libraryViewModel)
        case .notifications:
            NotificationsView()
        case .profile:
            ProfileView()
        }
    }

    // MARK: - Data Loading
    //
    // Fetches initial data concurrently. Kept here since it coordinates
    // two separate ViewModels; could be moved to a coordinator if this grows.

    private func startDataListening() {
        guard let user = authViewModel.currentUser else { return }
        let groupIds = (user.joinedGroupIds ?? []) + (user.createdGroupIds ?? [])

        Task {
            _ = await NotificationService.shared.requestNotificationPermission()
            
            async let books: Void   = homeViewModel.fetchBooks(for: groupIds)
            async let library: Void = libraryViewModel.fetchAllData(userId: user.id)
            _ = await (books, library)
        }
    }
}

// MARK: - Floating Dock

struct FloatingDock: View {
    @Binding var selectedTab: AppTab
    @EnvironmentObject var themeManager: ThemeManager
    @Namespace private var pill

    var body: some View {
        HStack(spacing: 4) {
            ForEach(AppTab.allCases) { tab in
                DockButton(
                    tab: tab,
                    isActive: selectedTab == tab,
                    namespace: pill
                ) {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) {
                        selectedTab = tab
                    }
                }
            }
        }
        .padding(.horizontal, 20)
        .background(dockBackground)
        .fixedSize(horizontal: false, vertical: true)
    }

    private var dockBackground: some View {
        RoundedRectangle(cornerRadius: 26)
            .fill(.ultraThinMaterial)
            .overlay(
                RoundedRectangle(cornerRadius: 26)
                    .stroke(
                        Color.white.opacity(themeManager.isDarkMode ? 0.14 : 0.4),
                        lineWidth: 1
                    )
            )
            .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 6)
    }
}

// MARK: - Dock Button
// Extracted from FloatingDock to keep each piece small and focused.

private struct DockButton: View {
    let tab: AppTab
    let isActive: Bool
    let namespace: Namespace.ID
    let action: () -> Void

    @EnvironmentObject var themeManager: ThemeManager
    @ObservedObject var notificationService = NotificationService.shared

    var body: some View {
        Button(action: action) {
            ZStack {
                if isActive {
                    RoundedRectangle(cornerRadius: 14)
                        .fill(AppTheme.primaryAccent)
                        .matchedGeometryEffect(id: "pill", in: namespace)
                        .shadow(
                            color: AppTheme.primaryAccent.opacity(0.35),
                            radius: 6, x: 0, y: 3
                        )
                }

                VStack(spacing: 3) {
                    Image(systemName: tab.icon)
                        .font(.system(size: 20, weight: isActive ? .semibold : .regular))
                        .symbolRenderingMode(.hierarchical)
                        .overlay(
                            Group {
                                if tab == .notifications && notificationService.unreadCount > 0 {
                                    Circle()
                                        .fill(Color.red)
                                        .frame(width: 8, height: 8)
                                        .offset(x: 10, y: -10)
                                }
                            }
                        )

                    Text(tab.label)
                        .font(.system(size: 10, weight: isActive ? .semibold : .regular))
                }
                .foregroundColor(
                    isActive
                        ? .white
                        : AppTheme.colorTertiaryText(for: themeManager.isDarkMode)
                )
            }
        }
        .buttonStyle(.plain)
        .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58)
        .accessibilityLabel(tab.label)
        .accessibilityAddTraits(isActive ? [.isSelected] : [])
    }
}

// MARK: - Shake Gesture

extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name("deviceDidShakeNotification")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        guard motion == .motionShake else { return }
        NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
    }
}

private struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void

    func body(content: Content) -> some View {
        content.onReceive(
            NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)
        ) { _ in action() }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        modifier(DeviceShakeViewModifier(action: action))
    }
}

// MARK: - Preview

#Preview {
    MainTabView()
        .environmentObject(ThemeManager()) // use a mock to get a meaningful preview
}
