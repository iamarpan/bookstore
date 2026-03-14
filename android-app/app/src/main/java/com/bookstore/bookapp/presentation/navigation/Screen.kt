package com.bookstore.bookapp.presentation.navigation

sealed class Screen(val route: String) {
    object Onboarding : Screen("onboarding")
    object Auth : Screen("auth")
    object Home : Screen("home")
    object Discover : Screen("discover")
    object MyLibrary : Screen("my_library")
    object Groups : Screen("groups")
    object Profile : Screen("profile")
    object AddBook : Screen("add_book")
    
    // Parameterized routes
    object BookDetail : Screen("book_detail/{bookId}") {
        fun createRoute(bookId: String) = "book_detail/$bookId"
    }
    
    object GroupDetail : Screen("group_detail/{groupId}") {
        fun createRoute(groupId: String) = "group_detail/$groupId"
    }

    // Tab routes (for bottom navigation)
    object MainScreen : Screen("main_screen")
}
