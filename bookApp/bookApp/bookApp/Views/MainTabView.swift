import SwiftUI

struct MainTabView: View {
    @StateObject private var homeViewModel = HomeViewModel()
    @StateObject private var myLibraryViewModel = MyLibraryViewModel()
    
    var body: some View {
        TabView {
            HomeView()
                .environmentObject(homeViewModel)
                .tabItem {
                    Image(systemName: "house")
                    Text("Home")
                }
            
            AddBookView()
                .tabItem {
                    Image(systemName: "plus.square")
                    Text("Add Book")
                }
            
            MyLibraryView()
                .environmentObject(myLibraryViewModel)
                .tabItem {
                    Image(systemName: "books.vertical")
                    Text("My Library")
                }
            
            ProfileView()
                .tabItem {
                    Image(systemName: "person.circle")
                    Text("Profile")
                }
        }
    }
}

struct MainTabView_Previews: PreviewProvider {
    static var previews: some View {
        MainTabView()
    }
} 