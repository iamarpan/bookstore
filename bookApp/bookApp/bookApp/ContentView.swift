import SwiftUI

struct ContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    
    var body: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
            .environmentObject(themeManager)
    }
}

#Preview {
    ContentView()
        .environmentObject(ThemeManager())
}
