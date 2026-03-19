package com.bookstore.bookapp.presentation.viewmodel

import android.app.Activity
import android.util.Log
import androidx.credentials.CredentialManager
import androidx.credentials.CustomCredential
import androidx.credentials.GetCredentialRequest
import androidx.credentials.GetCredentialResponse
import androidx.credentials.exceptions.GetCredentialException
import androidx.lifecycle.ViewModel
import androidx.lifecycle.viewModelScope
import com.bookstore.bookapp.R
import com.bookstore.bookapp.domain.model.User
import com.bookstore.bookapp.domain.repository.AuthRepository
import com.google.android.libraries.identity.googleid.GetGoogleIdOption
import com.google.android.libraries.identity.googleid.GoogleIdTokenCredential
import com.google.android.libraries.identity.googleid.GoogleIdTokenParsingException
import dagger.hilt.android.lifecycle.HiltViewModel
import kotlinx.coroutines.flow.MutableStateFlow
import kotlinx.coroutines.flow.SharingStarted
import kotlinx.coroutines.flow.StateFlow
import kotlinx.coroutines.flow.asStateFlow
import kotlinx.coroutines.flow.stateIn
import kotlinx.coroutines.launch
import javax.inject.Inject

data class AuthState(
    val isLoading: Boolean = false,
    val isGoogleLoading: Boolean = false,
    val error: String? = null,
    val isOtpSent: Boolean = false,
    val phoneNumber: String = ""
)

@HiltViewModel
class AuthViewModel @Inject constructor(
    private val authRepository: AuthRepository
) : ViewModel() {

    private val _uiState = MutableStateFlow(AuthState())
    val uiState: StateFlow<AuthState> = _uiState.asStateFlow()

    val isAuthenticated: StateFlow<Boolean> = authRepository.isAuthenticated
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), false)

    val currentUser: StateFlow<User?> = authRepository.currentUser
        .stateIn(viewModelScope, SharingStarted.WhileSubscribed(5000), null)

    fun onPhoneNumberChanged(number: String) {
        _uiState.value = _uiState.value.copy(phoneNumber = number, error = null)
    }

    fun sendOTP() {
        val phone = _uiState.value.phoneNumber
        if (phone.isBlank()) {
            _uiState.value = _uiState.value.copy(error = "Phone number cannot be empty")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.sendOTP(phone)
                _uiState.value = _uiState.value.copy(isLoading = false, isOtpSent = true)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.localizedMessage)
            }
        }
    }

    fun verifyOTP(otp: String, name: String? = null, bio: String? = null) {
        val phone = _uiState.value.phoneNumber
        if (otp.isBlank()) {
            _uiState.value = _uiState.value.copy(error = "OTP cannot be empty")
            return
        }

        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isLoading = true, error = null)
            try {
                authRepository.verifyOTP(phone, otp, name, bio)
                _uiState.value = _uiState.value.copy(isLoading = false)
            } catch (e: Exception) {
                _uiState.value = _uiState.value.copy(isLoading = false, error = e.localizedMessage)
            }
        }
    }

    fun signInWithGoogle(activity: Activity) {
        viewModelScope.launch {
            _uiState.value = _uiState.value.copy(isGoogleLoading = true, error = null)
            
            try {
                val credentialManager = CredentialManager.create(activity)
                
                val googleIdOption = GetGoogleIdOption.Builder()
                    .setFilterByAuthorizedAccounts(false)
                    .setServerClientId(activity.getString(R.string.google_client_id))
                    .setAutoSelectEnabled(false)
                    .build()
                
                val request = GetCredentialRequest.Builder()
                    .addCredentialOption(googleIdOption)
                    .build()
                
                val result = credentialManager.getCredential(
                    request = request,
                    context = activity
                )
                
                handleGoogleSignInResult(result)
            } catch (e: GetCredentialException) {
                Log.e("AuthViewModel", "Google Sign-In failed", e)
                _uiState.value = _uiState.value.copy(
                    isGoogleLoading = false,
                    error = "Google Sign-In failed: ${e.message}"
                )
            } catch (e: Exception) {
                Log.e("AuthViewModel", "Unexpected error during Google Sign-In", e)
                _uiState.value = _uiState.value.copy(
                    isGoogleLoading = false,
                    error = e.localizedMessage ?: "An unexpected error occurred"
                )
            }
        }
    }
    
    private suspend fun handleGoogleSignInResult(result: GetCredentialResponse) {
        val credential = result.credential
        
        when (credential) {
            is CustomCredential -> {
                if (credential.type == GoogleIdTokenCredential.TYPE_GOOGLE_ID_TOKEN_CREDENTIAL) {
                    try {
                        val googleIdTokenCredential = GoogleIdTokenCredential.createFrom(credential.data)
                        val idToken = googleIdTokenCredential.idToken
                        
                        authRepository.signInWithGoogle(idToken)
                        _uiState.value = _uiState.value.copy(isGoogleLoading = false)
                    } catch (e: GoogleIdTokenParsingException) {
                        Log.e("AuthViewModel", "Failed to parse Google ID Token", e)
                        _uiState.value = _uiState.value.copy(
                            isGoogleLoading = false,
                            error = "Failed to parse Google credentials"
                        )
                    }
                } else {
                    _uiState.value = _uiState.value.copy(
                        isGoogleLoading = false,
                        error = "Unexpected credential type"
                    )
                }
            }
            else -> {
                _uiState.value = _uiState.value.copy(
                    isGoogleLoading = false,
                    error = "Unexpected credential type"
                )
            }
        }
    }

    fun logout() {
        viewModelScope.launch {
            authRepository.logout()
            _uiState.value = AuthState()
        }
    }

    fun clearError() {
        _uiState.value = _uiState.value.copy(error = null)
    }
}
