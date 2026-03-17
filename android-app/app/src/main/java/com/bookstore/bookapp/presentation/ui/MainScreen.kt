package com.bookstore.bookapp.presentation.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Home
import androidx.compose.material.icons.filled.List
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Groups
import androidx.compose.material.icons.filled.LocalLibrary
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Notifications
import androidx.compose.material.icons.filled.SwapHoriz
import androidx.compose.material3.Badge
import androidx.compose.material3.BadgedBox
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.NavigationBar
import androidx.compose.material3.NavigationBarItem
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import androidx.navigation.NavDestination.Companion.hierarchy
import androidx.navigation.NavGraph.Companion.findStartDestination
import androidx.navigation.NavHostController
import androidx.navigation.compose.NavHost
import androidx.navigation.compose.composable
import androidx.navigation.compose.currentBackStackEntryAsState
import androidx.navigation.compose.rememberNavController
import com.bookstore.bookapp.presentation.navigation.Screen
import com.bookstore.bookapp.presentation.viewmodel.NotificationsViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun MainScreen(
    onNavigateToBookDetail: (String) -> Unit,
    onNavigateToGroupDetail: (String) -> Unit,
    onNavigateToTransactions: () -> Unit = {},
    onNavigateToTransactionDetail: (String) -> Unit = {},
    onNavigateToNotifications: () -> Unit = {},
    notificationsViewModel: NotificationsViewModel = hiltViewModel()
) {
    val bottomNavController = rememberNavController()
    val notificationsState by notificationsViewModel.uiState.collectAsState()
    val navBackStackEntry by bottomNavController.currentBackStackEntryAsState()
    val currentRoute = navBackStackEntry?.destination?.route
    
    val items = listOf(
        Screen.Home,
        Screen.Groups,
        Screen.AddBook,
        Screen.MyLibrary,
        Screen.Profile
    )
    
    val titles = listOf("Home", "Groups", "Add", "Library", "Profile")
    val icons = listOf(Icons.Default.Home, Icons.Default.Groups, Icons.Default.Add, Icons.Default.LocalLibrary, Icons.Default.Person)

    val currentTitle = when (currentRoute) {
        Screen.Home.route -> "Home"
        Screen.Groups.route -> "Groups"
        Screen.AddBook.route -> "Add Book"
        Screen.MyLibrary.route -> "My Library"
        Screen.Profile.route -> "Profile"
        else -> "BookShare"
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text(currentTitle) },
                actions = {
                    IconButton(onClick = onNavigateToTransactions) {
                        Icon(
                            imageVector = Icons.Default.SwapHoriz,
                            contentDescription = "Transactions"
                        )
                    }
                    IconButton(onClick = onNavigateToNotifications) {
                        BadgedBox(
                            badge = {
                                if (notificationsState.unreadCount > 0) {
                                    Badge {
                                        Text(
                                            text = if (notificationsState.unreadCount > 99) "99+"
                                                   else notificationsState.unreadCount.toString()
                                        )
                                    }
                                }
                            }
                        ) {
                            Icon(
                                imageVector = Icons.Default.Notifications,
                                contentDescription = "Notifications"
                            )
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        bottomBar = {
            NavigationBar(
                modifier = Modifier.windowInsetsPadding(WindowInsets.navigationBars)
            ) {
                val currentDestination = navBackStackEntry?.destination
                
                items.forEachIndexed { index, screen ->
                    NavigationBarItem(
                        icon = { Icon(icons[index], contentDescription = titles[index]) },
                        label = { Text(titles[index]) },
                        selected = currentDestination?.hierarchy?.any { it.route == screen.route } == true,
                        onClick = {
                            bottomNavController.navigate(screen.route) {
                                popUpTo(bottomNavController.graph.findStartDestination().id) {
                                    saveState = true
                                }
                                launchSingleTop = true
                                restoreState = true
                            }
                        }
                    )
                }
            }
        }
    ) { innerPadding ->
        Box(modifier = Modifier.padding(innerPadding)) {
            BottomNavGraph(
                navController = bottomNavController,
                onNavigateToBookDetail = onNavigateToBookDetail,
                onNavigateToGroupDetail = onNavigateToGroupDetail,
                onNavigateToTransactionDetail = onNavigateToTransactionDetail
            )
        }
    }
}

@Composable
fun BottomNavGraph(
    navController: NavHostController,
    onNavigateToBookDetail: (String) -> Unit,
    onNavigateToGroupDetail: (String) -> Unit,
    onNavigateToTransactionDetail: (String) -> Unit = {}
) {
    NavHost(
        navController = navController,
        startDestination = Screen.Home.route
    ) {
        composable(Screen.Home.route) {
            HomeScreen(onBookClick = onNavigateToBookDetail)
        }
        composable(Screen.Groups.route) {
            DiscoverGroupsScreen(onGroupClick = onNavigateToGroupDetail)
        }
        composable(Screen.AddBook.route) {
            AddBookScreen(onNavigateBack = { navController.popBackStack() })
        }
        composable(Screen.MyLibrary.route) {
            MyLibraryScreen(
                onBookClick = onNavigateToBookDetail,
                onTransactionClick = onNavigateToTransactionDetail
            )
        }
        composable(Screen.Profile.route) {
            ProfileScreen()
        }
    }
}
