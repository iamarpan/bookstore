import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var myLibraryViewModel = MyLibraryViewModel()
    @StateObject private var tabManager = TabManager()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var selectedTab = 0
    @State private var showEmergencyLogoutAlert = false

    var body: some View {
        ZStack(alignment: .bottom) {
            tabContent
                .safeAreaInset(edge: .bottom) {
                    if tabManager.isVisible {
                        Color.clear.frame(height: 80)
                    }
                }

            if tabManager.isVisible {
                FloatingDock(selectedTab: $selectedTab)
                    .padding(.bottom, 8)
            }
        }
        .environmentObject(tabManager)
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .onAppear(perform: startDataListening)
        .onShake { showEmergencyLogoutAlert = true }
        .alert("Emergency Logout", isPresented: $showEmergencyLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout Now", role: .destructive) { authViewModel.signOut() }
        } message: {
            Text("Detected shake gesture. Do you want to logout immediately for security?")
        }
    }

    @ViewBuilder
    private var tabContent: some View {
        switch selectedTab {
        case 0: HomeView().environmentObject(homeViewModel).environmentObject(themeManager).environmentObject(authViewModel)
        case 1: AddBookView().environmentObject(themeManager).environmentObject(authViewModel)
        case 2: MyGroupsView().environmentObject(themeManager).environmentObject(authViewModel)
        case 3: MyLibraryView().environmentObject(myLibraryViewModel).environmentObject(themeManager)
        case 4: ProfileView().environmentObject(themeManager).environmentObject(authViewModel)
        default: HomeView().environmentObject(homeViewModel).environmentObject(themeManager).environmentObject(authViewModel)
        }
    }

    private func startDataListening() {
        guard let user = authViewModel.currentUser else { return }
        let groupIds = (user.joinedGroupIds ?? []) + (user.createdGroupIds ?? [])
        Task {
            await homeViewModel.fetchBooks(for: groupIds)
            await myLibraryViewModel.fetchAllData(userId: user.id)
        }
    }
}

// MARK: - Floating Dock

struct FloatingDock: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    @Namespace private var pill

    private let tabs: [(icon: String, label: String)] = [
        ("house.fill",          "Home"),
        ("plus.square.fill",    "Add"),
        ("person.3.fill",       "Groups"),
        ("books.vertical.fill", "Library"),
        ("person.fill",         "Profile")
    ]

    var body: some View {
        HStack(spacing: 4) {
            ForEach(tabs.indices, id: \.self) { i in
                let active = selectedTab == i
                Button {
                    withAnimation(.spring(response: 0.4, dampingFraction: 0.72)) { selectedTab = i }
                } label: {
                    ZStack {
                        if active {
                            RoundedRectangle(cornerRadius: 14)
                                .fill(AppTheme.primaryAccent)
                                .matchedGeometryEffect(id: "pill", in: pill)
                                .shadow(color: AppTheme.primaryAccent.opacity(0.35), radius: 6, x: 0, y: 3)
                        }
                        VStack(spacing: 3) {
                            Image(systemName: tabs[i].icon)
                                .font(.system(size: 20, weight: active ? .semibold : .regular))
                                .symbolRenderingMode(.hierarchical)
                            Text(tabs[i].label)
                                .font(.system(size: 10, weight: active ? .semibold : .regular))
                        }
                        .foregroundColor(active ? .white : AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    }
                }
                .buttonStyle(.plain)
                .frame(maxWidth: .infinity, minHeight: 58, maxHeight: 58)
            }
        }
        .padding(.horizontal, 8)
        .padding(.vertical, 6)
        .background(RoundedRectangle(cornerRadius: 26).fill(.ultraThinMaterial))
        .overlay(RoundedRectangle(cornerRadius: 26).stroke(Color.white.opacity(themeManager.isDarkMode ? 0.14 : 0.4), lineWidth: 1))
        .shadow(color: .black.opacity(0.15), radius: 20, x: 0, y: 6)
        .padding(.horizontal, 20)
        .fixedSize(horizontal: false, vertical: true)
    }
}

// Shake gesture detection
extension UIDevice {
    static let deviceDidShakeNotification = Notification.Name(rawValue: "deviceDidShakeNotification")
}

extension UIWindow {
    override open func motionEnded(_ motion: UIEvent.EventSubtype, with event: UIEvent?) {
        if motion == .motionShake {
            NotificationCenter.default.post(name: UIDevice.deviceDidShakeNotification, object: nil)
        }
    }
}

struct DeviceShakeViewModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(DeviceShakeViewModifier(action: action))
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel())
    }
} 
