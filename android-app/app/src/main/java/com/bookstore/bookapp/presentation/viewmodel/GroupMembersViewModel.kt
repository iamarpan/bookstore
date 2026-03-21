package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.SavedStateHandle
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.BookClub
import com.bookstore.bookapp.domain.model.GroupMember
import com.bookstore.bookapp.domain.model.MemberRole
import com.bookstore.bookapp.domain.repository.GroupRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class GroupMembersState(
    val isLoading: Boolean = true,
    val group: BookClub? = null,
    val members: List<GroupMember> = emptyList(),
    val filteredMembers: List<GroupMember> = emptyList(),
    val selectedRoleFilter: MemberRole? = null,
    val error: String? = null,
    val isActionLoading: Boolean = false,
    val actionSuccess: String? = null,
    val memberToChangeRole: GroupMember? = null,
    val memberToRemove: GroupMember? = null
)

@HiltViewModel
class GroupMembersViewModel @Inject constructor(
    private val groupRepository: GroupRepository,
    savedStateHandle: SavedStateHandle
) : ViewModel() {

    private val _uiState = MutableStateFlow(GroupMembersState())
    val uiState: StateFlow<GroupMembersState> = _uiState.asStateFlow()

    private val groupId: String? = savedStateHandle["groupId"]

    init {
        loadData()
    }

    private fun loadData() {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val group = groupRepository.fetchGroupDetails(id)
                val members = groupRepository.fetchGroupMembers(id)
                
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    group = group,
                    members = members,
                    filteredMembers = members
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load members"
                )
            }
        }
    }

    fun onRoleFilterChange(role: MemberRole?) {
        val allMembers = _uiState.value.members
        val filtered = if (role == null) {
            allMembers
        } else {
            allMembers.filter { it.role == role }
        }
        _uiState.value = _uiState.value.copy(
            selectedRoleFilter = role,
            filteredMembers = filtered
        )
    }

    fun showChangeRoleDialog(member: GroupMember) {
        _uiState.value = _uiState.value.copy(memberToChangeRole = member)
    }

    fun dismissChangeRoleDialog() {
        _uiState.value = _uiState.value.copy(memberToChangeRole = null)
    }

    fun showRemoveMemberDialog(member: GroupMember) {
        _uiState.value = _uiState.value.copy(memberToRemove = member)
    }

    fun dismissRemoveMemberDialog() {
        _uiState.value = _uiState.value.copy(memberToRemove = null)
    }

    fun updateMemberRole(member: GroupMember, newRole: MemberRole) {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true, error = null)
            try {
                val updatedMember = groupRepository.updateMemberRole(id, member.userId, newRole)
                
                val updatedMembers = _uiState.value.members.map { 
                    if (it.id == member.id) updatedMember else it 
                }
                val filteredMembers = applyFilter(updatedMembers, _uiState.value.selectedRoleFilter)
                
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    members = updatedMembers,
                    filteredMembers = filteredMembers,
                    memberToChangeRole = null,
                    actionSuccess = "Role updated successfully"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    memberToChangeRole = null,
                    error = e.localizedMessage ?: "Failed to update role"
                )
            }
        }
    }

    fun removeMember(member: GroupMember) {
        val id = groupId ?: return
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isActionLoading = true, error = null)
            try {
                groupRepository.removeMember(id, member.userId)
                
                val updatedMembers = _uiState.value.members.filter { it.id != member.id }
                val filteredMembers = applyFilter(updatedMembers, _uiState.value.selectedRoleFilter)
                
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    members = updatedMembers,
                    filteredMembers = filteredMembers,
                    memberToRemove = null,
                    actionSuccess = "Member removed successfully"
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isActionLoading = false,
                    memberToRemove = null,
                    error = e.localizedMessage ?: "Failed to remove member"
                )
            }
        }
    }

    private fun applyFilter(members: List<GroupMember>, roleFilter: MemberRole?): List<GroupMember> {
        return if (roleFilter == null) {
            members
        } else {
            members.filter { it.role == roleFilter }
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }

    fun clearActionSuccess() {
        _uiState.value = _uiState.value.copy(actionSuccess = null)
    }
}
