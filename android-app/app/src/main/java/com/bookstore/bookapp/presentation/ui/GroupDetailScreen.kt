package com.bookstore.bookapp.presentation.ui

import android.content.Intent
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.ExitToApp
import androidx.compose.material.icons.filled.ChevronRight
import androidx.compose.material.icons.filled.Delete
import androidx.compose.material.icons.filled.Group
import androidx.compose.material.icons.filled.Lock
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.Public
import androidx.compose.material.icons.filled.Settings
import androidx.compose.material.icons.filled.Share
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Button
import androidx.compose.material3.ButtonDefaults
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.dp
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.bookstore.bookapp.domain.model.GroupMember
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.domain.model.PrivacySetting
import com.bookstore.bookapp.presentation.ui.components.BookItemSize
import com.bookstore.bookapp.presentation.ui.components.CompactBookItem
import com.bookstore.bookapp.presentation.viewmodel.GroupDetailViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupDetailScreen(
    onNavigateBack: () -> Unit,
    onBookClick: (String) -> Unit,
    onNavigateToSettings: (String) -> Unit = {},
    onNavigateToMembers: (String) -> Unit = {},
    viewModel: GroupDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val context = LocalContext.current
    val snackbarHostState = remember { SnackbarHostState() }
    
    var showLeaveDialog by remember { mutableStateOf(false) }
    var showDeleteDialog by remember { mutableStateOf(false) }

    LaunchedEffect(uiState.isDeleted, uiState.hasLeft) {
        if (uiState.isDeleted || uiState.hasLeft) {
            onNavigateBack()
        }
    }

    LaunchedEffect(uiState.actionSuccess) {
        uiState.actionSuccess?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearActionSuccess()
        }
    }

    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    if (showLeaveDialog) {
        AlertDialog(
            onDismissRequest = { showLeaveDialog = false },
            title = { Text("Leave Group") },
            text = { Text("Are you sure you want to leave this group? You will need to rejoin using an invite code if the group is private.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showLeaveDialog = false
                        viewModel.leaveGroup()
                    }
                ) {
                    Text("Leave", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showLeaveDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    if (showDeleteDialog) {
        AlertDialog(
            onDismissRequest = { showDeleteDialog = false },
            title = { Text("Delete Group") },
            text = { Text("Are you sure you want to delete this group? This action cannot be undone and all members will be removed.") },
            confirmButton = {
                TextButton(
                    onClick = {
                        showDeleteDialog = false
                        viewModel.deleteGroup()
                    }
                ) {
                    Text("Delete", color = MaterialTheme.colorScheme.error)
                }
            },
            dismissButton = {
                TextButton(onClick = { showDeleteDialog = false }) {
                    Text("Cancel")
                }
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text(uiState.group?.name ?: "Group Profile") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Go back to previous screen")
                    }
                },
                actions = {
                    uiState.group?.let { group ->
                        if (group.canUpdateSettings) {
                            IconButton(onClick = { onNavigateToSettings(group.id) }) {
                                Icon(Icons.Default.Settings, contentDescription = "Group Settings")
                            }
                        }
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.primary
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Box(modifier = Modifier.fillMaxSize().padding(padding)) {
            if (uiState.isLoading) {
                CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
            } else if (uiState.error != null) {
                Text(
                    text = uiState.error!!,
                    color = MaterialTheme.colorScheme.error,
                    modifier = Modifier.align(Alignment.Center)
                )
            } else if (uiState.group != null) {
                val group = uiState.group!!
                LazyColumn(
                    modifier = Modifier.fillMaxSize(),
                    contentPadding = PaddingValues(16.dp)
                ) {
                    item {
                        Column(horizontalAlignment = Alignment.CenterHorizontally, modifier = Modifier.fillMaxWidth()) {
                            Icon(
                                imageVector = Icons.Default.Group,
                                contentDescription = "Group Icon",
                                modifier = Modifier.padding(24.dp).height(100.dp),
                                tint = MaterialTheme.colorScheme.primary
                            )
                            
                            Row(verticalAlignment = Alignment.CenterVertically) {
                                Text(
                                    text = group.name,
                                    style = MaterialTheme.typography.headlineMedium,
                                    fontWeight = FontWeight.Bold
                                )
                                Spacer(modifier = Modifier.width(8.dp))
                                Icon(
                                    imageVector = if (group.privacy == PrivacySetting.PUBLIC) 
                                        Icons.Default.Public else Icons.Default.Lock,
                                    contentDescription = if (group.privacy == PrivacySetting.PUBLIC) 
                                        "Public" else "Private",
                                    modifier = Modifier.size(20.dp),
                                    tint = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            
                            Spacer(modifier = Modifier.height(4.dp))
                            
                            // Role badge
                            group.role?.let { role ->
                                RoleBadge(role = role)
                            }
                            
                            Spacer(modifier = Modifier.height(8.dp))
                            
                            Text(
                                text = "${group.memberCount} Members • ${group.booksCount} Books",
                                style = MaterialTheme.typography.bodyMedium,
                                color = MaterialTheme.colorScheme.onSurfaceVariant
                            )
                            Spacer(modifier = Modifier.height(16.dp))
                            Text(
                                text = group.description,
                                style = MaterialTheme.typography.bodyMedium,
                                modifier = Modifier.fillMaxWidth(),
                                textAlign = TextAlign.Center
                            )
                            Spacer(modifier = Modifier.height(24.dp))
                        }
                    }

                    // Action buttons
                    item {
                        GroupActionButtons(
                            group = group,
                            isLoading = uiState.isActionLoading,
                            onShareInvite = {
                                val shareIntent = Intent(Intent.ACTION_SEND).apply {
                                    type = "text/plain"
                                    putExtra(Intent.EXTRA_TEXT, "Join my group \"${group.name}\" on BookShare! Use invite code: ${group.inviteCode}")
                                }
                                context.startActivity(Intent.createChooser(shareIntent, "Share Invite Code"))
                            },
                            onLeave = { showLeaveDialog = true },
                            onDelete = { showDeleteDialog = true }
                        )
                        Spacer(modifier = Modifier.height(24.dp))
                    }

                    // Rules section
                    if (!group.rules.isNullOrBlank()) {
                        item {
                            GroupRulesSection(rules = group.rules!!)
                            Spacer(modifier = Modifier.height(24.dp))
                        }
                    }

                    // Members preview
                    if (uiState.members.isNotEmpty()) {
                        item {
                            MembersPreviewSection(
                                members = uiState.members,
                                totalCount = group.memberCount,
                                onSeeAllClick = { onNavigateToMembers(group.id) }
                            )
                            Spacer(modifier = Modifier.height(24.dp))
                        }
                    }

                    item {
                        Text(
                            text = "Group Books (${uiState.books.size})",
                            style = MaterialTheme.typography.titleLarge,
                            fontWeight = FontWeight.Bold,
                            modifier = Modifier.padding(bottom = 16.dp)
                        )
                    }

                    if (uiState.books.isEmpty()) {
                        item {
                            Box(modifier = Modifier.fillMaxWidth().padding(48.dp), contentAlignment = Alignment.Center) {
                                Text("No books shared in this group yet.", color = MaterialTheme.colorScheme.onSurfaceVariant)
                            }
                        }
                    } else {
                        item {
                            LazyVerticalGrid(
                                columns = GridCells.Adaptive(minSize = 100.dp),
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .height((((uiState.books.size + 2) / 3) * 180).dp),
                                horizontalArrangement = Arrangement.spacedBy(8.dp),
                                verticalArrangement = Arrangement.spacedBy(12.dp),
                                userScrollEnabled = false
                            ) {
                                items(uiState.books, key = { it.id }) { book ->
                                    CompactBookItem(
                                        book = book,
                                        onClick = { onBookClick(book.id) },
                                        size = BookItemSize.COMPACT
                                    )
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RoleBadge(role: MemberRole) {
    val (color, text) = when (role) {
        MemberRole.CREATOR -> MaterialTheme.colorScheme.primary to "Creator"
        MemberRole.ADMIN -> MaterialTheme.colorScheme.tertiary to "Admin"
        MemberRole.MODERATOR -> MaterialTheme.colorScheme.secondary to "Moderator"
        MemberRole.MEMBER -> MaterialTheme.colorScheme.outline to "Member"
    }
    
    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.1f), RoundedCornerShape(4.dp))
            .padding(horizontal = 8.dp, vertical = 2.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = color
        )
    }
}

@Composable
private fun GroupActionButtons(
    group: com.bookstore.bookapp.domain.model.BookClub,
    isLoading: Boolean,
    onShareInvite: () -> Unit,
    onLeave: () -> Unit,
    onDelete: () -> Unit
) {
    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        // Share invite code button (for admin/creator)
        if (group.canManageMembers) {
            OutlinedButton(
                onClick = onShareInvite,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Share, contentDescription = null, modifier = Modifier.size(18.dp))
                Spacer(modifier = Modifier.width(8.dp))
                Text("Share Invite Code")
            }
        }

        // Leave group button (for non-creators)
        if (!group.isCreator && group.isMember) {
            OutlinedButton(
                onClick = onLeave,
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                if (isLoading) {
                    CircularProgressIndicator(modifier = Modifier.size(18.dp), strokeWidth = 2.dp)
                } else {
                    Icon(Icons.AutoMirrored.Filled.ExitToApp, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Leave Group")
                }
            }
        }

        // Delete group button (for creators only)
        if (group.isCreator) {
            Button(
                onClick = onDelete,
                enabled = !isLoading,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.buttonColors(
                    containerColor = MaterialTheme.colorScheme.error
                )
            ) {
                if (isLoading) {
                    CircularProgressIndicator(
                        modifier = Modifier.size(18.dp),
                        strokeWidth = 2.dp,
                        color = MaterialTheme.colorScheme.onError
                    )
                } else {
                    Icon(Icons.Default.Delete, contentDescription = null, modifier = Modifier.size(18.dp))
                    Spacer(modifier = Modifier.width(8.dp))
                    Text("Delete Group")
                }
            }
        }
    }
}

@Composable
private fun GroupRulesSection(rules: String) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surfaceVariant
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Group Rules",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = rules,
                style = MaterialTheme.typography.bodyMedium,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
        }
    }
}

@Composable
private fun MembersPreviewSection(
    members: List<GroupMember>,
    totalCount: Int,
    onSeeAllClick: () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .clickable(onClick = onSeeAllClick),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.SpaceBetween,
                verticalAlignment = Alignment.CenterVertically
            ) {
                Text(
                    text = "Members ($totalCount)",
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "See All",
                        style = MaterialTheme.typography.labelMedium,
                        color = MaterialTheme.colorScheme.primary
                    )
                    Icon(
                        imageVector = Icons.Default.ChevronRight,
                        contentDescription = null,
                        modifier = Modifier.size(20.dp),
                        tint = MaterialTheme.colorScheme.primary
                    )
                }
            }
            
            Spacer(modifier = Modifier.height(16.dp))
            
            LazyRow(
                horizontalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(members) { member ->
                    MemberPreviewItem(member = member)
                }
            }
        }
    }
}

@Composable
private fun MemberPreviewItem(member: GroupMember) {
    Column(
        horizontalAlignment = Alignment.CenterHorizontally,
        modifier = Modifier.width(60.dp)
    ) {
        if (member.user.profileImageUrl != null) {
            AsyncImage(
                model = member.user.profileImageUrl,
                contentDescription = member.user.name,
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
            )
        } else {
            Box(
                modifier = Modifier
                    .size(48.dp)
                    .clip(CircleShape)
                    .background(MaterialTheme.colorScheme.primaryContainer),
                contentAlignment = Alignment.Center
            ) {
                Icon(
                    imageVector = Icons.Default.Person,
                    contentDescription = null,
                    tint = MaterialTheme.colorScheme.onPrimaryContainer
                )
            }
        }
        Spacer(modifier = Modifier.height(4.dp))
        Text(
            text = member.user.name.split(" ").first(),
            style = MaterialTheme.typography.labelSmall,
            maxLines = 1,
            overflow = TextOverflow.Ellipsis
        )
    }
}
