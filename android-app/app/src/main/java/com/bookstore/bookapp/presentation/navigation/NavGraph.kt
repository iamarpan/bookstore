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
import com.bookstore.bookapp.presentation.ui.AddBookScreen
import com.bookstore.bookapp.presentation.ui.AuthScreen
import com.bookstore.bookapp.presentation.ui.BookDetailScreen
import com.bookstore.bookapp.presentation.ui.OnboardingScreen
import com.bookstore.bookapp.presentation.ui.GroupDetailScreen
import com.bookstore.bookapp.presentation.ui.MainScreen

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
                onBookClick = { bookId -> navController.navigate(Screen.BookDetail.createRoute(bookId)) }
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
