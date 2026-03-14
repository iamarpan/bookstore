package com.bookstore.bookapp.presentation.ui

import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.verticalScroll
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.material3.Text
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import com.bookstore.bookapp.presentation.ui.components.HorizontalBookList
import com.bookstore.bookapp.presentation.ui.components.SearchBar
import com.bookstore.bookapp.presentation.ui.components.SectionHeader
import com.bookstore.bookapp.presentation.viewmodel.HomeViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun HomeScreen(
    onBookClick: (String) -> Unit,
    viewModel: HomeViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var searchQuery by remember { mutableStateOf("") }
    val scrollState = rememberScrollState()
    val pullRefreshState = rememberPullToRefreshState()

    if (pullRefreshState.isRefreshing) {
        LaunchedEffect(true) {
            viewModel.fetchHomeData(isRefresh = true)
        }
    }

    LaunchedEffect(uiState.refreshing) {
        if (uiState.refreshing) {
            pullRefreshState.startRefresh()
        } else {
            pullRefreshState.endRefresh()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("BookShare", style = MaterialTheme.typography.headlineMedium) },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .nestedScroll(pullRefreshState.nestedScrollConnection)
        ) {
            if (uiState.isLoading && !uiState.refreshing && uiState.featuredBooks.isEmpty()) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (uiState.error != null && uiState.featuredBooks.isEmpty()) {
                Text(
                    text = uiState.error!!,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.align(Alignment.Center)
                )
            } else {
                Column(
                    modifier = Modifier
                        .fillMaxSize()
                        .verticalScroll(scrollState)
                ) {
                    // 1. Persistent Search Bar
                    SearchBar(
                        query = searchQuery,
                        onQueryChange = { searchQuery = it },
                        modifier = Modifier.padding(horizontal = 16.dp, vertical = 8.dp)
                    )

                    Spacer(modifier = Modifier.height(16.dp))

                    // Group books for different sections to demonstrate the redesign
                    // In a real scenario, the ViewModel would provide these specific lists
                    val continueReading = uiState.featuredBooks.take(2)
                    val availableNearYou = uiState.featuredBooks.filter { it.isAvailable }
                    val recentlyAdded = uiState.featuredBooks

                    // 2. Continue Reading Section
                    if (continueReading.isNotEmpty()) {
                        SectionHeader(
                            title = "Continue Reading",
                            actionLabel = "See All",
                            onActionClick = { /* TODO: Navigate to active borrowed books */ }
                        )
                        HorizontalBookList(
                            books = continueReading,
                            onBookClick = onBookClick
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    // 3. Available Near You Section
                    if (availableNearYou.isNotEmpty()) {
                        SectionHeader(
                            title = "Available Near You",
                            actionLabel = "Explore",
                            onActionClick = { /* TODO: Navigate to map view or search with filter */ }
                        )
                        HorizontalBookList(
                            books = availableNearYou,
                            onBookClick = onBookClick
                        )
                        Spacer(modifier = Modifier.height(16.dp))
                    }

                    // 4. Recently Added Section
                    if (recentlyAdded.isNotEmpty()) {
                        SectionHeader(
                            title = "Recently Added",
                            actionLabel = "More",
                            onActionClick = { /* TODO: Navigate to all books feed */ }
                        )
                        HorizontalBookList(
                            books = recentlyAdded,
                            onBookClick = onBookClick
                        )
                        Spacer(modifier = Modifier.height(32.dp))
                    }
                }
            }
            
            PullToRefreshContainer(
                state = pullRefreshState,
                modifier = Modifier.align(Alignment.TopCenter)
            )
        }
    }
}
