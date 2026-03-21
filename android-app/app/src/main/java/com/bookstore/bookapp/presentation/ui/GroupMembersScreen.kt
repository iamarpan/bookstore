package com.bookstore.bookapp.presentation.ui

import androidx.compose.foundation.background
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
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.LazyRow
import androidx.compose.foundation.lazy.items
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.filled.MoreVert
import androidx.compose.material.icons.filled.Person
import androidx.compose.material.icons.filled.PersonRemove
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenu
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.FilterChip
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
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
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.unit.dp
import androidx.hilt.navigation.compose.hiltViewModel
import coil.compose.AsyncImage
import com.bookstore.bookapp.domain.model.GroupMember
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.presentation.ui.components.EmptyState
import com.bookstore.bookapp.presentation.viewmodel.GroupMembersViewModel
import java.text.SimpleDateFormat
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun GroupMembersScreen(
    onNavigateBack: () -> Unit,
    viewModel: GroupMembersViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

    LaunchedEffect(uiState.error) {
        uiState.error?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearError()
        }
    }

    LaunchedEffect(uiState.actionSuccess) {
        uiState.actionSuccess?.let {
            snackbarHostState.showSnackbar(it)
            viewModel.clearActionSuccess()
        }
    }

    // Change Role Dialog
    uiState.memberToChangeRole?.let { member ->
        ChangeRoleDialog(
            member = member,
            currentUserCanManage = uiState.group?.canManageMembers == true,
            isLoading = uiState.isActionLoading,
            onDismiss = { viewModel.dismissChangeRoleDialog() },
            onRoleSelected = { newRole ->
                viewModel.updateMemberRole(member, newRole)
            }
        )
    }

    // Remove Member Dialog
    uiState.memberToRemove?.let { member ->
        AlertDialog(
            onDismissRequest = { viewModel.dismissRemoveMemberDialog() },
            title = { Text("Remove Member") },
            text = { 
                Text("Are you sure you want to remove ${member.user.name} from this group?") 
            },
            confirmButton = {
                TextButton(
                    onClick = { viewModel.removeMember(member) },
                    enabled = !uiState.isActionLoading
                ) {
                    if (uiState.isActionLoading) {
                        CircularProgressIndicator(modifier = Modifier.size(16.dp), strokeWidth = 2.dp)
                    } else {
                        Text("Remove", color = MaterialTheme.colorScheme.error)
                    }
                }
            },
            dismissButton = {
                TextButton(onClick = { viewModel.dismissRemoveMemberDialog() }) {
                    Text("Cancel")
                }
            }
        )
    }

    Scaffold(
        snackbarHost = { SnackbarHost(snackbarHostState) },
        topBar = {
            TopAppBar(
                title = { Text("Members (${uiState.members.size})") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                }
            )
        }
    ) { padding ->
        if (uiState.isLoading) {
            Box(
                modifier = Modifier.fillMaxSize().padding(padding),
                contentAlignment = Alignment.Center
            ) {
                CircularProgressIndicator()
            }
        } else {
            Column(
                modifier = Modifier
                    .fillMaxSize()
                    .padding(padding)
            ) {
                // Role Filter Chips
                if (uiState.group?.canManageMembers == true) {
                    RoleFilterChips(
                        selectedRole = uiState.selectedRoleFilter,
                        onRoleSelected = viewModel::onRoleFilterChange
                    )
                }

                if (uiState.filteredMembers.isEmpty()) {
                    EmptyState(
                        illustration = {
                            Icon(
                                imageVector = Icons.Default.Person,
                                contentDescription = null,
                                modifier = Modifier.size(80.dp),
                                tint = MaterialTheme.colorScheme.primary.copy(alpha = 0.5f)
                            )
                        },
                        title = "No Members Found",
                        description = if (uiState.selectedRoleFilter != null) 
                            "No members with the selected role" else "No members in this group"
                    )
                } else {
                    LazyColumn(
                        contentPadding = PaddingValues(16.dp),
                        verticalArrangement = Arrangement.spacedBy(12.dp)
                    ) {
                        items(uiState.filteredMembers, key = { it.id }) { member ->
                            MemberCard(
                                member = member,
                                canManage = uiState.group?.canManageMembers == true && 
                                           member.role != MemberRole.CREATOR,
                                onChangeRole = { viewModel.showChangeRoleDialog(member) },
                                onRemove = { viewModel.showRemoveMemberDialog(member) }
                            )
                        }
                    }
                }
            }
        }
    }
}

@Composable
private fun RoleFilterChips(
    selectedRole: MemberRole?,
    onRoleSelected: (MemberRole?) -> Unit
) {
    LazyRow(
        contentPadding = PaddingValues(horizontal = 16.dp, vertical = 8.dp),
        horizontalArrangement = Arrangement.spacedBy(8.dp)
    ) {
        item {
            FilterChip(
                selected = selectedRole == null,
                onClick = { onRoleSelected(null) },
                label = { Text("All") }
            )
        }
        items(MemberRole.entries.toList()) { role ->
            FilterChip(
                selected = selectedRole == role,
                onClick = { onRoleSelected(role) },
                label = { Text(role.name.lowercase().replaceFirstChar { it.uppercase() }) }
            )
        }
    }
}

@Composable
private fun MemberCard(
    member: GroupMember,
    canManage: Boolean,
    onChangeRole: () -> Unit,
    onRemove: () -> Unit
) {
    var showMenu by remember { mutableStateOf(false) }
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        colors = CardDefaults.cardColors(
            containerColor = MaterialTheme.colorScheme.surface
        )
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            // Avatar
            if (member.user.profileImageUrl != null) {
                AsyncImage(
                    model = member.user.profileImageUrl,
                    contentDescription = member.user.name,
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                )
            } else {
                Box(
                    modifier = Modifier
                        .size(56.dp)
                        .clip(CircleShape)
                        .background(MaterialTheme.colorScheme.primaryContainer),
                    contentAlignment = Alignment.Center
                ) {
                    Text(
                        text = member.user.name.take(1).uppercase(),
                        style = MaterialTheme.typography.titleLarge,
                        color = MaterialTheme.colorScheme.onPrimaryContainer
                    )
                }
            }

            Spacer(modifier = Modifier.width(16.dp))

            // Member Info
            Column(modifier = Modifier.weight(1f)) {
                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = member.user.name,
                        style = MaterialTheme.typography.titleMedium,
                        fontWeight = FontWeight.SemiBold
                    )
                    Spacer(modifier = Modifier.width(8.dp))
                    MemberRoleBadge(role = member.role)
                }

                Spacer(modifier = Modifier.height(4.dp))

                Row(verticalAlignment = Alignment.CenterVertically) {
                    Text(
                        text = "${member.user.booksShared} books shared",
                        style = MaterialTheme.typography.bodySmall,
                        color = MaterialTheme.colorScheme.onSurfaceVariant
                    )
                    member.user.averageRating?.let { rating ->
                        Spacer(modifier = Modifier.width(8.dp))
                        Icon(
                            imageVector = Icons.Default.Star,
                            contentDescription = null,
                            modifier = Modifier.size(14.dp),
                            tint = MaterialTheme.colorScheme.secondary
                        )
                        Text(
                            text = String.format("%.1f", rating),
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.secondary
                        )
                    }
                }

                Spacer(modifier = Modifier.height(2.dp))

                Text(
                    text = "Joined ${dateFormat.format(member.joinedAt)}",
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
                )
            }

            // Actions Menu
            if (canManage) {
                Box {
                    IconButton(onClick = { showMenu = true }) {
                        Icon(Icons.Default.MoreVert, contentDescription = "Actions")
                    }

                    DropdownMenu(
                        expanded = showMenu,
                        onDismissRequest = { showMenu = false }
                    ) {
                        DropdownMenuItem(
                            text = { Text("Change Role") },
                            onClick = {
                                showMenu = false
                                onChangeRole()
                            }
                        )
                        DropdownMenuItem(
                            text = { Text("Remove", color = MaterialTheme.colorScheme.error) },
                            leadingIcon = {
                                Icon(
                                    Icons.Default.PersonRemove,
                                    contentDescription = null,
                                    tint = MaterialTheme.colorScheme.error
                                )
                            },
                            onClick = {
                                showMenu = false
                                onRemove()
                            }
                        )
                    }
                }
            }
        }
    }
}

@Composable
private fun MemberRoleBadge(role: MemberRole) {
    val (color, text) = when (role) {
        MemberRole.CREATOR -> MaterialTheme.colorScheme.primary to "Creator"
        MemberRole.ADMIN -> MaterialTheme.colorScheme.tertiary to "Admin"
        MemberRole.MODERATOR -> MaterialTheme.colorScheme.secondary to "Mod"
        MemberRole.MEMBER -> MaterialTheme.colorScheme.outline to "Member"
    }

    Box(
        modifier = Modifier
            .background(color.copy(alpha = 0.15f), RoundedCornerShape(4.dp))
            .padding(horizontal = 6.dp, vertical = 2.dp)
    ) {
        Text(
            text = text,
            style = MaterialTheme.typography.labelSmall,
            color = color,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun ChangeRoleDialog(
    member: GroupMember,
    currentUserCanManage: Boolean,
    isLoading: Boolean,
    onDismiss: () -> Unit,
    onRoleSelected: (MemberRole) -> Unit
) {
    val availableRoles = listOf(MemberRole.MEMBER, MemberRole.MODERATOR, MemberRole.ADMIN)

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Change Role") },
        text = {
            Column {
                Text(
                    text = "Select a new role for ${member.user.name}",
                    style = MaterialTheme.typography.bodyMedium
                )
                Spacer(modifier = Modifier.height(16.dp))
                
                availableRoles.forEach { role ->
                    Card(
                        modifier = Modifier
                            .fillMaxWidth()
                            .padding(vertical = 4.dp),
                        colors = CardDefaults.cardColors(
                            containerColor = if (role == member.role) 
                                MaterialTheme.colorScheme.primaryContainer.copy(alpha = 0.3f)
                            else MaterialTheme.colorScheme.surface
                        ),
                        onClick = { 
                            if (role != member.role && !isLoading) {
                                onRoleSelected(role) 
                            }
                        }
                    ) {
                        Row(
                            modifier = Modifier
                                .fillMaxWidth()
                                .padding(16.dp),
                            horizontalArrangement = Arrangement.SpaceBetween,
                            verticalAlignment = Alignment.CenterVertically
                        ) {
                            Column {
                                Text(
                                    text = role.name.lowercase().replaceFirstChar { it.uppercase() },
                                    style = MaterialTheme.typography.bodyLarge,
                                    fontWeight = FontWeight.Medium
                                )
                                Text(
                                    text = getRoleDescription(role),
                                    style = MaterialTheme.typography.bodySmall,
                                    color = MaterialTheme.colorScheme.onSurfaceVariant
                                )
                            }
                            if (role == member.role) {
                                Text(
                                    text = "Current",
                                    style = MaterialTheme.typography.labelSmall,
                                    color = MaterialTheme.colorScheme.primary
                                )
                            }
                        }
                    }
                }
            }
        },
        confirmButton = {},
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

private fun getRoleDescription(role: MemberRole): String {
    return when (role) {
        MemberRole.CREATOR -> "Full control over the group"
        MemberRole.ADMIN -> "Can manage members and settings"
        MemberRole.MODERATOR -> "Can moderate content"
        MemberRole.MEMBER -> "Standard member privileges"
    }
}
