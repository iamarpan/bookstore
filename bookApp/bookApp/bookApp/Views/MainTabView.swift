import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var myLibraryViewModel = MyLibraryViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authViewModel: AuthViewModel
    @State private var showEmergencyLogoutAlert = false
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(homeViewModel)
                .environmentObject(themeManager)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            AddBookView()
                .environmentObject(themeManager)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "plus.square")
                    Text("Add Book")
                }
            
            MyLibraryView()
                .environmentObject(myLibraryViewModel)
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("My Library")
                }
            
            ProfileView()
                .environmentObject(themeManager)
                .environmentObject(authViewModel)
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
        .accentColor(AppTheme.primaryGreen)
        .onAppear {
            setupTabBarAppearance()
            startDataListening()
        }
        .onChange(of: themeManager.isDarkMode) { _, _ in
            setupTabBarAppearance()
        }
        .onShake {
            // Emergency logout on shake gesture
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
        // Get current user and load initial data
        if let user = authViewModel.currentUser {
            let groupIds = user.joinedGroupIds + user.createdGroupIds
            
            Task {
                await homeViewModel.fetchBooks(for: groupIds)
                await myLibraryViewModel.fetchAllData(userId: user.id)
            }
        }
    }
    
    private func setupTabBarAppearance() {
        // Customize tab bar appearance based on theme
        let appearance = UITabBarAppearance()
        appearance.configureWithOpaqueBackground()
        appearance.backgroundColor = UIColor(AppTheme.dynamicSecondaryBackground(themeManager.isDarkMode))
        
        // Selected tab color
        appearance.selectionIndicatorTintColor = UIColor(AppTheme.primaryGreen)
        
        // Tab item colors
        appearance.stackedLayoutAppearance.selected.iconColor = UIColor(AppTheme.primaryGreen)
        appearance.stackedLayoutAppearance.selected.titleTextAttributes = [
            .foregroundColor: UIColor(AppTheme.primaryGreen)
        ]
        
        let normalColor = UIColor(AppTheme.dynamicTertiaryText(themeManager.isDarkMode))
        appearance.stackedLayoutAppearance.normal.iconColor = normalColor
        appearance.stackedLayoutAppearance.normal.titleTextAttributes = [
            .foregroundColor: normalColor
        ]
        
        UITabBar.appearance().standardAppearance = appearance
        UITabBar.appearance().scrollEdgeAppearance = appearance
    }
}

// MARK: - Shake Gesture Extension
extension View {
    func onShake(perform action: @escaping () -> Void) -> some View {
        self.modifier(ShakeGestureModifier(action: action))
    }
}

struct ShakeGestureModifier: ViewModifier {
    let action: () -> Void
    
    func body(content: Content) -> some View {
        content
            .onReceive(NotificationCenter.default.publisher(for: UIDevice.deviceDidShakeNotification)) { _ in
                action()
            }
    }
}

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

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(ThemeManager())
            .environmentObject(AuthViewModel())
    }
} 