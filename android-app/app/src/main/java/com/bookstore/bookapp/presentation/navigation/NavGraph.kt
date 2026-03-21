package com.bookstore.bookapp.presentation.navigation

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.navigation.NavHostController
import androidx.navigation.NavType
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.navArgument
import com.bookstore.bookapp.domain.model.NotificationType
import com.bookstore.bookapp.presentation.ui.AddBookScreen
import com.bookstore.bookapp.presentation.ui.AuthScreen
import com.bookstore.bookapp.presentation.ui.BookDetailScreen
import com.bookstore.bookapp.presentation.ui.CreateGroupScreen
import com.bookstore.bookapp.presentation.ui.OnboardingScreen
import com.bookstore.bookapp.presentation.ui.GroupDetailScreen
import com.bookstore.bookapp.presentation.ui.GroupMembersScreen
import com.bookstore.bookapp.presentation.ui.GroupSettingsScreen
import com.bookstore.bookapp.presentation.ui.MainScreen
import com.bookstore.bookapp.presentation.ui.NotificationsScreen
import com.bookstore.bookapp.presentation.ui.TransactionChatScreen
import com.bookstore.bookapp.presentation.ui.TransactionDetailScreen
import com.bookstore.bookapp.presentation.ui.TransactionsScreen

@Composable
fun AppNavGraph(
    navController: NavHostController,
    startDestination: String = Screen.Auth.route
) {
    NavHost(
        navController = navController,
        startDestination = startDestination
    ) {
        composable(Screen.Onboarding.route) {
            OnboardingScreen(
                onFinishOnboarding = {
                    navController.navigate(Screen.Auth.route) {
                        popUpTo(Screen.Onboarding.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.Auth.route) {
            AuthScreen(
                onNavigateToMain = {
                    navController.navigate(Screen.MainScreen.route) {
                        popUpTo(Screen.Auth.route) { inclusive = true }
                    }
                }
            )
        }
        
        composable(Screen.MainScreen.route) {
            MainScreen(
                onNavigateToBookDetail = { bookId ->
                    navController.navigate(Screen.BookDetail.createRoute(bookId))
                },
                onNavigateToGroupDetail = { groupId ->
                    navController.navigate(Screen.GroupDetail.createRoute(groupId))
                },
                onNavigateToCreateGroup = {
                    navController.navigate(Screen.CreateGroup.route)
                },
                onNavigateToTransactions = {
                    navController.navigate(Screen.Transactions.route)
                },
                onNavigateToTransactionDetail = { transactionId ->
                    navController.navigate(Screen.TransactionDetail.createRoute(transactionId))
                },
                onNavigateToNotifications = {
                    navController.navigate(Screen.Notifications.route)
                }
            )
        }
        
        composable(Screen.AddBook.route) {
            AddBookScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(
            Screen.BookDetail.route,
            arguments = listOf(navArgument("bookId") { type = NavType.StringType })
        ) {
            BookDetailScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(
            Screen.GroupDetail.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) {
            GroupDetailScreen(
                onNavigateBack = { navController.popBackStack() },
                onBookClick = { bookId -> navController.navigate(Screen.BookDetail.createRoute(bookId)) },
                onNavigateToSettings = { groupId ->
                    navController.navigate(Screen.GroupSettings.createRoute(groupId))
                },
                onNavigateToMembers = { groupId ->
                    navController.navigate(Screen.GroupMembers.createRoute(groupId))
                }
            )
        }

        composable(Screen.CreateGroup.route) {
            CreateGroupScreen(
                onNavigateBack = { navController.popBackStack() },
                onGroupCreated = { groupId ->
                    navController.navigate(Screen.GroupDetail.createRoute(groupId)) {
                        popUpTo(Screen.CreateGroup.route) { inclusive = true }
                    }
                }
            )
        }

        composable(
            Screen.GroupSettings.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) {
            GroupSettingsScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(
            Screen.GroupMembers.route,
            arguments = listOf(navArgument("groupId") { type = NavType.StringType })
        ) {
            GroupMembersScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Transactions.route) {
            TransactionsScreen(
                onNavigateBack = { navController.popBackStack() },
                onTransactionClick = { transactionId ->
                    navController.navigate(Screen.TransactionDetail.createRoute(transactionId))
                }
            )
        }

        composable(
            Screen.TransactionDetail.route,
            arguments = listOf(navArgument("transactionId") { type = NavType.StringType })
        ) {
            TransactionDetailScreen(
                onNavigateBack = { navController.popBackStack() },
                onNavigateToChat = { transactionId ->
                    navController.navigate(Screen.TransactionChat.createRoute(transactionId))
                }
            )
        }

        composable(
            Screen.TransactionChat.route,
            arguments = listOf(navArgument("transactionId") { type = NavType.StringType })
        ) {
            TransactionChatScreen(
                onNavigateBack = { navController.popBackStack() }
            )
        }

        composable(Screen.Notifications.route) {
            NotificationsScreen(
                onNavigateBack = { navController.popBackStack() },
                onNotificationClick = { notification ->
                    val data = notification.data
                    when (notification.type) {
                        NotificationType.BORROW_REQUEST,
                        NotificationType.REQUEST_APPROVED,
                        NotificationType.REQUEST_REJECTED,
                        NotificationType.BOOK_HANDOVER_PENDING,
                        NotificationType.BOOK_HANDED_OVER,
                        NotificationType.RETURN_PENDING,
                        NotificationType.BOOK_RETURNED,
                        NotificationType.PAYMENT_COMPLETED,
                        NotificationType.TRANSACTION_CANCELLED -> {
                            data?.transactionId?.let { transactionId ->
                                navController.navigate(Screen.TransactionDetail.createRoute(transactionId))
                            }
                        }
                        NotificationType.NEW_MESSAGE -> {
                            data?.transactionId?.let { transactionId ->
                                navController.navigate(Screen.TransactionChat.createRoute(transactionId))
                            }
                        }
                        NotificationType.SYSTEM -> {
                            // No action for system notifications
                        }
                    }
                }
            )
        }
    }
}

@Composable
fun PlaceholderScreen(title: String) {
    Box(modifier = Modifier.fillMaxSize(), contentAlignment = Alignment.Center) {
        Text(text = title)
    }
}
