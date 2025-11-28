import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var myLibraryViewModel = MyLibraryViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmergencyLogoutAlert = false
    @StateObject private var tabManager = TabManager()
    @State private var selectedTab = 0
    
    var body: some View {
        ZStack(alignment: .bottom) {
            // Main Content
            Group {
                switch selectedTab {
                case 0:
                    HomeView()
                        .environmentObject(homeViewModel)
                        .environmentObject(themeManager)
                        .environmentObject(authViewModel)
                case 1:
                    AddBookView()
                        .environmentObject(themeManager)
                        .environmentObject(authViewModel)
                case 2:
                    MyGroupsView()
                        .environmentObject(themeManager)
                        .environmentObject(authViewModel)
                case 3:
                    MyLibraryView()
                        .environmentObject(myLibraryViewModel)
                        .environmentObject(themeManager)
                case 4:
                    ProfileView()
                        .environmentObject(themeManager)
                        .environmentObject(authViewModel)
                default:
                    HomeView()
                        .environmentObject(homeViewModel)
                        .environmentObject(themeManager)
                        .environmentObject(authViewModel)
                }
            }
            .frame(maxWidth: .infinity, maxHeight: .infinity)
            
            // Floating Dock
            if tabManager.isVisible {
                FloatingDock(selectedTab: $selectedTab)
                    .padding(.bottom, 30)
                    .transition(.move(edge: .bottom).combined(with: .opacity))
            }
        }
        .environmentObject(tabManager)
        .background(AppTheme.colorPrimaryBackground(for: themeManager.isDarkMode).ignoresSafeArea())
        .onAppear {
            startDataListening()
        }
        .onShake {
            showEmergencyLogoutAlert = true
        }
        .alert("Emergency Logout", isPresented: $showEmergencyLogoutAlert) {
            Button("Cancel", role: .cancel) { }
            Button("Logout Now", role: .destructive) {
                authViewModel.signOut()
            }
        } message: {
            Text("Detected shake gesture. Do you want to logout immediately for security?")
        }
    }
    
    private func startDataListening() {
        if let user = authViewModel.currentUser {
            let groupIds = user.joinedGroupIds + user.createdGroupIds
            
            Task {
                await homeViewModel.fetchBooks(for: groupIds)
                await myLibraryViewModel.fetchAllData(userId: user.id)
            }
        }
    }
}

struct FloatingDock: View {
    @Binding var selectedTab: Int
    @EnvironmentObject var themeManager: ThemeManager
    
    let tabs = [
        ("house.fill", "Home"),
        ("plus.square.fill", "Add"),
        ("person.3.fill", "Groups"),
        ("books.vertical.fill", "Library"),
        ("person.circle.fill", "Profile")
    ]
    
    var body: some View {
        HStack(spacing: 0) {
            ForEach(0..<tabs.count, id: \.self) { index in
                Button(action: {
                    withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) {
                        selectedTab = index
                    }
                }) {
                    VStack(spacing: 4) {
                        Image(systemName: tabs[index].0)
                            .font(.system(size: 20, weight: selectedTab == index ? .bold : .regular))
                        
                        if selectedTab == index {
                            Circle()
                                .fill(AppTheme.primaryAccent)
                                .frame(width: 4, height: 4)
                                .matchedGeometryEffect(id: "tab_dot", in: namespace)
                        } else {
                            Circle()
                                .fill(Color.clear)
                                .frame(width: 4, height: 4)
                        }
                    }
                    .frame(maxWidth: .infinity)
                    .foregroundColor(selectedTab == index ? AppTheme.primaryAccent : AppTheme.colorTertiaryText(for: themeManager.isDarkMode))
                    .padding(.vertical, 12)
                }
            }
        }
        .padding(.horizontal, 16)
        .background(AppTheme.glassBackground)
        .glassmorphic()
        .cornerRadius(AppTheme.buttonRadius)
        .shadow(color: AppTheme.shadowFloating, radius: 20, x: 0, y: 10)
        .padding(.horizontal, 24)
    }
    
    @Namespace private var namespace
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