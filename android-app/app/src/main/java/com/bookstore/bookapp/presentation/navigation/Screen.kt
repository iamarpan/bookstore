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

    object CreateGroup : Screen("create_group")

    object GroupSettings : Screen("group_settings/{groupId}") {
        fun createRoute(groupId: String) = "group_settings/$groupId"
    }

    object GroupMembers : Screen("group_members/{groupId}") {
        fun createRoute(groupId: String) = "group_members/$groupId"
    }

    // Transaction screens
    object Transactions : Screen("transactions")

    object TransactionDetail : Screen("transaction_detail/{transactionId}") {
        fun createRoute(transactionId: String) = "transaction_detail/$transactionId"
    }

    object TransactionChat : Screen("transaction_chat/{transactionId}") {
        fun createRoute(transactionId: String) = "transaction_chat/$transactionId"
    }

    // Notifications
    object Notifications : Screen("notifications")

    // Tab routes (for bottom navigation)
    object MainScreen : Screen("main_screen")
}
