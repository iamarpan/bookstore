package com.bookstore.bookapp.presentation.viewmodel

import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.domain.repository.TransactionRepository
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.launch
import javax.inject.Inject

data class TransactionsState(
    val isLoading: Boolean = true,
    val borrowerTransactions: List<Transaction> = emptyList(),
    val ownerTransactions: List<Transaction> = emptyList(),
    val error: String? = null,
    val selectedTab: Int = 0
)

@HiltViewModel
class TransactionsViewModel @Inject constructor(
    private val transactionRepository: TransactionRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(TransactionsState())
    val uiState: StateFlow<TransactionsState> = _uiState.asStateFlow()

    init {
        loadTransactions()
    }

    fun loadTransactions() {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                val borrowerTxns = transactionRepository.fetchTransactions(
                    role = "BORROWER",
                    status = null,
                    page = 1,
                    limit = 50
                )
                val ownerTxns = transactionRepository.fetchTransactions(
                    role = "OWNER",
                    status = null,
                    page = 1,
                    limit = 50
                )
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    borrowerTransactions = borrowerTxns.sortedByDescending { it.requestedAt },
                    ownerTransactions = ownerTxns.sortedByDescending { it.requestedAt }
                )
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(
                    isLoading = false,
                    error = e.localizedMessage ?: "Failed to load transactions"
                )
            }
        }
    }

    fun selectTab(index: Int) {
        _uiState.value = _uiState.value.copy(selectedTab = index)
    }

    fun refresh() {
        loadTransactions()
    }
}
