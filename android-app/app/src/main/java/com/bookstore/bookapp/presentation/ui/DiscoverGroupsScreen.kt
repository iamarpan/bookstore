package com.bookstore.bookapp.presentation.ui

import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.items
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.Add
import androidx.compose.material.icons.filled.Book
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.QrCode
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FloatingActionButton
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.ModalBottomSheet
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SheetState
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.pulltorefresh.PullToRefreshContainer
import androidx.compose.material3.pulltorefresh.rememberPullToRefreshState
import androidx.compose.material3.rememberModalBottomSheetState
import androidx.compose.ui.input.nestedscroll.nestedScroll
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.material3.Tab
import androidx.compose.material3.TabRow
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.rememberCoroutineScope
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.size
import androidx.hilt.navigation.compose.hiltViewModel
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.PrivacySetting
import com.bookstore.bookapp.presentation.ui.components.EmptyState
import com.bookstore.bookapp.presentation.ui.components.SearchBar
import com.bookstore.bookapp.presentation.viewmodel.DiscoverGroupsViewModel
import kotlinx.coroutines.launch

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun DiscoverGroupsScreen(
    onGroupClick: (String) -> Unit,
    onCreateGroupClick: () -> Unit = {},
    viewModel: DiscoverGroupsViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    var selectedTabIndex by remember { mutableIntStateOf(0) }
    val tabs = listOf("Discover", "My Groups")
    
    val pullRefreshState = rememberPullToRefreshState()
    val snackbarHostState = remember { SnackbarHostState() }
    val scope = rememberCoroutineScope()
    
    var showInviteCodeSheet by remember { mutableStateOf(false) }
    val inviteCodeSheetState = rememberModalBottomSheetState()

    if (pullRefreshState.isRefreshing) {
        LaunchedEffect(true) {
            viewModel.searchGroups(isRefresh = true)
        }
    }

    LaunchedEffect(uiState.refreshing) {
        if (uiState.refreshing) {
            pullRefreshState.startRefresh()
        } else {
            pullRefreshState.endRefresh()
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    LaunchedEffect(uiState.joinedGroupId) {
        uiState.joinedGroupId?.let { groupId ->
            snackbarHostState.showSnackbar("Successfully joined the group!")
            viewModel.clearJoinedGroup()
        }
    }

    if (showInviteCodeSheet) {
        JoinByInviteCodeSheet(
            sheetState = inviteCodeSheetState,
            isLoading = uiState.isLoading,
            onDismiss = { showInviteCodeSheet = false },
            onJoin = { code ->
                viewModel.joinViaInvite(code) { group ->
                    scope.launch {
                        inviteCodeSheetState.hide()
                        showInviteCodeSheet = false
                        onGroupClick(group.id)
                    }
                }
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        containerColor = MaterialTheme.colorScheme.background,
        floatingActionButton = {
            FloatingActionButton(
                onClick = onCreateGroupClick,
                containerColor = MaterialTheme.colorScheme.primary
            ) {
                Icon(
                    imageVector = Icons.Default.Add,
                    contentDescription = "Create Group"
                )
            }
        }
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            TabRow(selectedTabIndex = selectedTabIndex) {
                tabs.forEachIndexed { index, title ->
                    Tab(
                        selected = selectedTabIndex == index,
                        onClick = { selectedTabIndex = index },
                        text = { Text(title) }
                    )
                }
            }

            if (selectedTabIndex == 0) {
                Row(
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(horizontal = 16.dp, vertical = 8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    SearchBar(
                        query = uiState.searchQuery,
                        onQueryChange = { viewModel.onSearchQueryChanged(it) },
                        modifier = Modifier.weight(1f)
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    IconButton(onClick = { showInviteCodeSheet = true }) {
                        Icon(
                            imageVector = Icons.Default.QrCode,
                            contentDescription = "Join with invite code",
                            tint = MaterialTheme.colorScheme.primary
                        )
                    }
                }
            }

            Box(
                modifier = Modifier
                    .fillMaxSize()
                    .nestedScroll(pullRefreshState.nestedScrollConnection)
            ) {
                if (uiState.isLoading && selectedTabIndex == 0 && !uiState.refreshing) {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                } else if (uiState.error != null) {
                    Text(
                        text = uiState.error!!,
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                } else {
                    val groupsToShow = if (selectedTabIndex == 0) uiState.discoveredGroups else uiState.myGroups
                    if (groupsToShow.isEmpty()) {
                        EmptyState(
                            illustration = {
                                Icon(
                                    imageVector = Icons.Default.Group,
                                    contentDescription = null,
                                    modifier = Modifier.size(120.dp),
                                    tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                                )
                            },
                            title = if (selectedTabIndex == 0) "No Groups Found" else "No Groups Yet",
                            description = if (selectedTabIndex == 0) "Try adjusting your search query." else "You haven't joined any groups yet. Discover and join groups to start sharing books!"
                        )
                    } else {
                        LazyColumn(
                            contentPadding = PaddingValues(16.dp),
                            modifier = Modifier.fillMaxSize()
                        ) {
                            items(groupsToShow, key = { it.id }) { group ->
                                GroupCard(
                                    group = group,
                                    onClick = { onGroupClick(group.id) },
                                    showJoinButton = selectedTabIndex == 0 && !group.isMember,
                                    isJoining = uiState.joiningGroupId == group.id,
                                    onJoinClick = {
                                        if (group.privacy == PrivacySetting.PUBLIC) {
                                            viewModel.joinPublicGroup(group.id)
                                        }
                                    }
                                )
                                Spacer(modifier = Modifier.height(12.dp))
                            }
                        }
                    }
                }
                
                if (uiState.refreshing || pullRefreshState.progress > 0f) {
                    PullToRefreshContainer(
                        state = pullRefreshState,
                        modifier = Modifier.align(Alignment.TopCenter)
                    )
                }
            }
        }
    }
}

@Composable
fun GroupCard(
    group: BookClub,
    onClick: () -> Unit,
    onJoinClick: (() -> Unit)? = null,
    showJoinButton: Boolean = false,
    isJoining: Boolean = false
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 2.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = group.name,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.SemiBold,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.weight(1f)
                )
                Icon(
                    imageVector = if (group.privacy == PrivacySetting.PUBLIC) 
                        Icons.Default.Public else Icons.Default.Lock,
                    contentDescription = if (group.privacy == PrivacySetting.PUBLIC) 
                        "Public" else "Private",
                    modifier = Modifier.size(18.dp),
                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Spacer(modifier = Modifier.height(4.dp))
            
            Text(
                text = group.description,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                maxLines = 2,
                overflow = TextOverflow.Ellipsis
            )
            
            Spacer(modifier = Modifier.height(12.dp))
            
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Icon(
                        imageVector = Icons.Default.Group,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${group.memberCount}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Spacer(modifier = Modifier.width(16.dp))
                    Icon(
                        imageVector = Icons.Default.Book,
                        contentDescription = null,
                        modifier = Modifier.size(16.dp),
                        tint = MaterialTheme.colorScheme.secondary
                    )
                    Spacer(modifier = Modifier.width(4.dp))
                    Text(
                        text = "${group.booksCount}",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.secondary
                    )
                }
                
                if (showJoinButton && onJoinClick != null && !group.isMember) {
                    Button(
                        onClick = onJoinClick,
                        enabled = !isJoining,
                        colors = ButtonDefaults.buttonColors(
                            containerColor = MaterialTheme.colorScheme.primary
                        ),
                        modifier = Modifier.height(32.dp),
                        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 0.dp)
                    ) {
                        if (isJoining) {
                            CircularProgressIndicator(
                                modifier = Modifier.size(16.dp),
                                strokeWidth = 2.dp,
                                color = MaterialTheme.colorScheme.onPrimary
                            )
                        } else {
                            Text(
                                text = "Join",
                                style = MaterialTheme.typography.labelMedium
                            )
                        }
                    }
                }
            }
        }
    }
}

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun JoinByInviteCodeSheet(
    sheetState: SheetState,
    isLoading: Boolean,
    onDismiss: () -> Unit,
    onJoin: (String) -> Unit
) {
    var inviteCode by remember { mutableStateOf("") }

    ModalBottomSheet(
        onDismissRequest = onDismiss,
        sheetState = sheetState
    ) {
        Column(
            modifier = Modifier
                .fillMaxWidth()
                .padding(24.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Icon(
                imageVector = Icons.Default.QrCode,
                contentDescription = null,
                modifier = Modifier.size(48.dp),
                tint = MaterialTheme.colorScheme.primary
            )
            
            Spacer(modifier = Modifier.height(16.dp))
            
            Text(
                text = "Join with Invite Code",
                style = MaterialTheme.typography.titleLarge,
                fontWeight = FontWeight.Bold
            )
            
            Spacer(modifier = Modifier.height(8.dp))
            
            Text(
                text = "Enter the invite code shared by a group member to join a private group",
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant,
                textAlign = TextAlign.Center
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            OutlinedTextField(
                value = inviteCode,
                onValueChange = { inviteCode = it.uppercase() },
                label = { Text("Invite Code") },
                placeholder = { Text("e.g., ABC123XY") },
                modifier = Modifier.fillMaxWidth(),
                singleLine = true
            )
            
            Spacer(modifier = Modifier.height(24.dp))
            
            Button(
                onClick = { onJoin(inviteCode.trim()) },
                modifier = Modifier
                    .fillMaxWidth()
                    .height(56.dp),
                enabled = inviteCode.isNotBlank() && !isLoading,
                shape = MaterialTheme.shapes.medium
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(24.dp),
                        color = MaterialTheme.colorScheme.onPrimary,
                        strokeWidth = 2.dp
                    )
                } else {
                    Text("Join Group", style = MaterialTheme.typography.titleMedium)
                }
            }
            
            Spacer(modifier = Modifier.height(32.dp))
        }
    }
}
