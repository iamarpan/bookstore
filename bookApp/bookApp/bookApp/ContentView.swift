import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var authViewModel = AuthViewModel()
    
    var body: some View {
        Group {
            if authViewModel.isAuthenticated {
                MainTabView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            } else {
                AuthenticationView()
                    .environmentObject(authViewModel)
                    .environmentObject(themeManager)
            }
        }
        .preferredColorScheme(themeManager.colorScheme)
        .animation(.easeInOut(duration: 0.5), value: authViewModel.isAuthenticated)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
