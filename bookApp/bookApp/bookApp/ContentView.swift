import SwiftUI

struct ContentView: View {
    var body: some View {
        MainTabView()
            .environmentObject(AuthViewModel())
    }
}

#Preview {
    ContentView()
}
