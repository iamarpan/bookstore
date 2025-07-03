import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var myLibraryViewModel = MyLibraryViewModel()
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(homeViewModel)
                .environmentObject(themeManager)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            AddBookView()
                .environmentObject(themeManager)
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
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
        .background(AppTheme.dynamicPrimaryBackground(themeManager.isDarkMode).ignoresSafeArea())
        .accentColor(AppTheme.primaryGreen)
        .onAppear {
            setupTabBarAppearance()
        }
        .onChange(of: themeManager.isDarkMode) { _ in
            setupTabBarAppearance()
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

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
            .environmentObject(ThemeManager())
    }
} 