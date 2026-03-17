package com.bookstore.bookapp.presentation.ui

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.WindowInsets
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.navigationBars
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.layout.windowInsetsPadding
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.automirrored.filled.ArrowBack
import androidx.compose.material.icons.automirrored.filled.Chat
import androidx.compose.material.icons.filled.Cancel
import androidx.compose.material.icons.filled.CheckCircle
import androidx.compose.material.icons.filled.Error
import androidx.compose.material.icons.filled.Schedule
import androidx.compose.material.icons.filled.Star
import androidx.compose.material3.AlertDialog
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
import androidx.compose.material3.OutlinedButton
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.SnackbarHost
import androidx.compose.material3.SnackbarHostState
import androidx.compose.material3.Surface
import androidx.compose.material3.Text
import androidx.compose.material3.TextButton
import androidx.compose.material3.TopAppBar
import androidx.compose.material3.TopAppBarDefaults
import androidx.compose.runtime.Composable
import androidx.compose.runtime.LaunchedEffect
import androidx.compose.runtime.collectAsState
import androidx.compose.runtime.getValue
import androidx.compose.runtime.mutableIntStateOf
import androidx.compose.runtime.mutableStateOf
import androidx.compose.runtime.remember
import androidx.compose.runtime.setValue
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.graphics.vector.ImageVector
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import androidx.hilt.navigation.compose.hiltViewModel
import com.bookstore.bookapp.domain.model.Transaction
import com.bookstore.bookapp.domain.model.TransactionStatus
import com.bookstore.bookapp.presentation.theme.AppColors
import com.bookstore.bookapp.presentation.ui.components.BookCoverImage
import com.bookstore.bookapp.presentation.ui.components.UserAvatar
import com.bookstore.bookapp.presentation.viewmodel.TransactionDetailState
import com.bookstore.bookapp.presentation.viewmodel.TransactionDetailViewModel
import java.text.SimpleDateFormat
import java.util.Date
import java.util.Locale

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun TransactionDetailScreen(
    onNavigateBack: () -> Unit,
    onNavigateToChat: (String) -> Unit,
    viewModel: TransactionDetailViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()
    val snackbarHostState = remember { SnackbarHostState() }

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

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Transaction Details") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(Icons.AutoMirrored.Filled.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background
                )
            )
        },
        snackbarHost = { SnackbarHost(snackbarHostState) },
        floatingActionButton = {
            val transaction = uiState.transaction
            if (transaction != null && 
                (transaction.status == TransactionStatus.APPROVED || transaction.status == TransactionStatus.ACTIVE)
            ) {
                FloatingActionButton(
                    onClick = { onNavigateToChat(transaction.id) },
                    containerColor = MaterialTheme.colorScheme.primary
                ) {
                    Icon(Icons.AutoMirrored.Filled.Chat, contentDescription = "Chat")
                }
            }
        },
        containerColor = MaterialTheme.colorScheme.background
    ) { padding ->
        Box(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
        ) {
            when {
                uiState.isLoading -> {
                    CircularProgressIndicator(modifier = Modifier.align(Alignment.Center))
                }
                uiState.transaction == null -> {
                    Text(
                        text = uiState.error ?: "Transaction not found",
                        color = MaterialTheme.colorScheme.error,
                        modifier = Modifier.align(Alignment.Center)
                    )
                }
                else -> {
                    TransactionDetailContent(
                        uiState = uiState,
                        onApprove = viewModel::approveRequest,
                        onReject = viewModel::showRejectDialog,
                        onCancel = viewModel::cancelRequest,
                        onGenerateHandoverOTP = viewModel::generateHandoverOTP,
                        onConfirmHandover = viewModel::confirmHandover,
                        onGenerateReturnOTP = viewModel::generateReturnOTP,
                        onConfirmReturn = viewModel::confirmReturn,
                        onRate = viewModel::showRatingDialog,
                        onClearOTP = viewModel::clearOTP
                    )
                }
            }

            if (uiState.isActionLoading) {
                Box(
                    modifier = Modifier
                        .fillMaxSize()
                        .background(Color.Black.copy(alpha = 0.3f)),
                    contentAlignment = Alignment.Center
                ) {
                    CircularProgressIndicator(color = MaterialTheme.colorScheme.primary)
                }
            }
        }
    }

    if (uiState.showRejectDialog) {
        RejectDialog(
            onDismiss = viewModel::dismissRejectDialog,
            onConfirm = viewModel::rejectRequest
        )
    }

    if (uiState.showRatingDialog) {
        RatingDialog(
            isOwner = uiState.isOwner,
            onDismiss = viewModel::dismissRatingDialog,
            onSubmit = viewModel::submitRating
        )
    }
}

@Composable
private fun TransactionDetailContent(
    uiState: TransactionDetailState,
    onApprove: () -> Unit,
    onReject: () -> Unit,
    onCancel: () -> Unit,
    onGenerateHandoverOTP: () -> Unit,
    onConfirmHandover: (String) -> Unit,
    onGenerateReturnOTP: () -> Unit,
    onConfirmReturn: (String) -> Unit,
    onRate: () -> Unit,
    onClearOTP: () -> Unit
) {
    val transaction = uiState.transaction ?: return

    Column(
        modifier = Modifier
            .fillMaxSize()
            .verticalScroll(rememberScrollState())
            .padding(16.dp)
            .windowInsetsPadding(WindowInsets.navigationBars)
    ) {
        StatusBanner(status = transaction.status)

        Spacer(modifier = Modifier.height(16.dp))

        BookInfoCard(transaction = transaction)

        Spacer(modifier = Modifier.height(16.dp))

        OtherPartyCard(
            name = uiState.otherPartyName,
            imageUrl = uiState.otherPartyImageUrl,
            roleLabel = uiState.roleLabel
        )

        Spacer(modifier = Modifier.height(16.dp))

        TransactionTimeline(transaction = transaction)

        Spacer(modifier = Modifier.height(16.dp))

        TransactionDetailsCard(transaction = transaction)

        if (transaction.requestMessage != null) {
            Spacer(modifier = Modifier.height(16.dp))
            MessageCard(
                title = "Request Message",
                message = transaction.requestMessage
            )
        }

        if (transaction.rejectionReason != null) {
            Spacer(modifier = Modifier.height(16.dp))
            MessageCard(
                title = "Rejection Reason",
                message = transaction.rejectionReason,
                isError = true
            )
        }

        if (uiState.generatedOTP != null) {
            Spacer(modifier = Modifier.height(16.dp))
            OTPDisplayCard(
                otp = uiState.generatedOTP,
                onDismiss = onClearOTP
            )
        }

        Spacer(modifier = Modifier.height(24.dp))

        ActionButtons(
            uiState = uiState,
            onApprove = onApprove,
            onReject = onReject,
            onCancel = onCancel,
            onGenerateHandoverOTP = onGenerateHandoverOTP,
            onConfirmHandover = onConfirmHandover,
            onGenerateReturnOTP = onGenerateReturnOTP,
            onConfirmReturn = onConfirmReturn,
            onRate = onRate
        )

        Spacer(modifier = Modifier.height(80.dp))
    }
}

@Composable
private fun StatusBanner(status: TransactionStatus) {
    val (backgroundColor, textColor, icon) = when (status) {
        TransactionStatus.PENDING -> Triple(
            Color(0xFFFFF3CD),
            Color(0xFF856404),
            Icons.Default.Schedule
        )
        TransactionStatus.APPROVED -> Triple(
            Color(0xFFD4EDDA),
            Color(0xFF155724),
            Icons.Default.CheckCircle
        )
        TransactionStatus.ACTIVE -> Triple(
            Color(0xFFCCE5FF),
            Color(0xFF004085),
            Icons.Default.CheckCircle
        )
        TransactionStatus.RETURNED -> Triple(
            Color(0xFFD1ECF1),
            Color(0xFF0C5460),
            Icons.Default.CheckCircle
        )
        TransactionStatus.REJECTED -> Triple(
            Color(0xFFF8D7DA),
            Color(0xFF721C24),
            Icons.Default.Cancel
        )
        TransactionStatus.CANCELLED -> Triple(
            Color(0xFFF8D7DA),
            Color(0xFF721C24),
            Icons.Default.Cancel
        )
    }

    Surface(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        color = backgroundColor
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            Icon(
                imageVector = icon,
                contentDescription = null,
                tint = textColor,
                modifier = Modifier.size(24.dp)
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = when (status) {
                    TransactionStatus.PENDING -> "Waiting for approval"
                    TransactionStatus.APPROVED -> "Approved - Waiting for handover"
                    TransactionStatus.ACTIVE -> "Currently borrowed"
                    TransactionStatus.RETURNED -> "Completed"
                    TransactionStatus.REJECTED -> "Request rejected"
                    TransactionStatus.CANCELLED -> "Request cancelled"
                },
                style = MaterialTheme.typography.titleMedium,
                color = textColor,
                fontWeight = FontWeight.Bold
            )
        }
    }
}

@Composable
private fun BookInfoCard(transaction: Transaction) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f))
    ) {
        Row(
            modifier = Modifier
                .padding(16.dp)
                .fillMaxWidth(),
            verticalAlignment = Alignment.CenterVertically
        ) {
            BookCoverImage(
                imageUrl = transaction.bookImageUrl,
                contentDescription = "Book Cover",
                modifier = Modifier
                    .size(80.dp, 120.dp)
                    .clip(RoundedCornerShape(8.dp))
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = transaction.bookTitle,
                    style = MaterialTheme.typography.titleLarge,
                    fontWeight = FontWeight.Bold
                )
            }
        }
    }
}

@Composable
private fun OtherPartyCard(
    name: String,
    imageUrl: String?,
    roleLabel: String
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Row(
            modifier = Modifier.padding(16.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            UserAvatar(
                imageUrl = imageUrl,
                size = 48.dp
            )
            Spacer(modifier = Modifier.width(16.dp))
            Column {
                Text(
                    text = roleLabel,
                    style = MaterialTheme.typography.labelSmall,
                    color = MaterialTheme.colorScheme.primary
                )
                Text(
                    text = name,
                    style = MaterialTheme.typography.titleMedium,
                    fontWeight = FontWeight.Bold
                )
            }
            Spacer(modifier = Modifier.weight(1f))
            Icon(
                imageVector = Icons.AutoMirrored.Filled.Chat,
                contentDescription = null,
                tint = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
private fun TransactionTimeline(transaction: Transaction) {
    val dateFormat = remember { SimpleDateFormat("MMM dd, yyyy", Locale.getDefault()) }

    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Timeline",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(16.dp))

            TimelineItem(
                label = "Requested on",
                date = dateFormat.format(transaction.requestedAt),
                isCompleted = true
            )

            if (transaction.approvedAt != null) {
                TimelineItem(
                    label = "Approved on",
                    date = dateFormat.format(transaction.approvedAt),
                    isCompleted = true
                )
            }

            if (transaction.handoverAt != null) {
                TimelineItem(
                    label = "Handed over on",
                    date = dateFormat.format(transaction.handoverAt),
                    isCompleted = true
                )
            }

            if (transaction.returnedAt != null) {
                TimelineItem(
                    label = "Returned on",
                    date = dateFormat.format(transaction.returnedAt),
                    isCompleted = true
                )
            } else if (transaction.dueDate != null) {
                TimelineItem(
                    label = "Due date",
                    date = dateFormat.format(transaction.dueDate),
                    isCompleted = false,
                    isHighlight = true
                )
            }
        }
    }
}

@Composable
private fun TimelineItem(
    label: String,
    date: String,
    isCompleted: Boolean,
    isHighlight: Boolean = false
) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Row(verticalAlignment = Alignment.CenterVertically) {
            Box(
                modifier = Modifier
                    .size(8.dp)
                    .clip(CircleShape)
                    .background(
                        if (isCompleted) MaterialTheme.colorScheme.primary
                        else if (isHighlight) MaterialTheme.colorScheme.error
                        else MaterialTheme.colorScheme.outline
                    )
            )
            Spacer(modifier = Modifier.width(12.dp))
            Text(
                text = label,
                style = MaterialTheme.typography.bodyMedium,
                color = if (isHighlight) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurface
            )
        }
        Text(
            text = date,
            style = MaterialTheme.typography.bodyMedium,
            fontWeight = FontWeight.Medium,
            color = if (isHighlight) MaterialTheme.colorScheme.error else MaterialTheme.colorScheme.onSurfaceVariant
        )
    }
}

@Composable
private fun TransactionDetailsCard(transaction: Transaction) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = "Transaction Details",
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(12.dp))
            
            DetailRow(label = "Transaction ID", value = "#${transaction.id.takeLast(8).uppercase()}")
            DetailRow(label = "Duration", value = "${transaction.durationDays} days")
        }
    }
}

@Composable
private fun DetailRow(label: String, value: String) {
    Row(
        modifier = Modifier
            .fillMaxWidth()
            .padding(vertical = 4.dp),
        horizontalArrangement = Arrangement.SpaceBetween
    ) {
        Text(
            text = label,
            style = MaterialTheme.typography.bodySmall,
            color = MaterialTheme.colorScheme.onSurfaceVariant
        )
        Text(
            text = value,
            style = MaterialTheme.typography.bodySmall,
            fontWeight = FontWeight.Medium
        )
    }
}

@Composable
private fun MessageCard(
    title: String,
    message: String,
    isError: Boolean = false
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(
            containerColor = if (isError) Color(0xFFFFF1F0) else MaterialTheme.colorScheme.surface
        )
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleSmall,
                fontWeight = FontWeight.Bold,
                color = if (isError) Color(0xFFCF1322) else MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = message,
                style = MaterialTheme.typography.bodyMedium,
                fontStyle = androidx.compose.ui.text.font.FontStyle.Italic
            )
        }
    }
}

@Composable
private fun OTPDisplayCard(
    otp: String,
    onDismiss: () -> Unit
) {
    Card(
        modifier = Modifier.fillMaxWidth(),
        shape = RoundedCornerShape(12.dp),
        colors = CardDefaults.cardColors(containerColor = AppColors.successBg)
    ) {
        Column(
            modifier = Modifier.padding(16.dp),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            Text(
                text = "Share this OTP",
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.Available
            )
            Spacer(modifier = Modifier.height(12.dp))
            Text(
                text = otp,
                style = MaterialTheme.typography.displayMedium,
                fontWeight = FontWeight.Bold,
                color = AppColors.Available,
                letterSpacing = 8.sp
            )
            Spacer(modifier = Modifier.height(8.dp))
            Text(
                text = "Valid for 10 minutes",
                style = MaterialTheme.typography.bodySmall,
                color = MaterialTheme.colorScheme.onSurfaceVariant
            )
            Spacer(modifier = Modifier.height(12.dp))
            TextButton(onClick = onDismiss) {
                Text("Dismiss")
            }
        }
    }
}

@Composable
private fun ActionButtons(
    uiState: TransactionDetailState,
    onApprove: () -> Unit,
    onReject: () -> Unit,
    onCancel: () -> Unit,
    onGenerateHandoverOTP: () -> Unit,
    onConfirmHandover: (String) -> Unit,
    onGenerateReturnOTP: () -> Unit,
    onConfirmReturn: (String) -> Unit,
    onRate: () -> Unit
) {
    var otpInput by remember { mutableStateOf("") }

    Column(
        modifier = Modifier.fillMaxWidth(),
        verticalArrangement = Arrangement.spacedBy(12.dp)
    ) {
        if (uiState.canApprove) {
            Row(
                modifier = Modifier.fillMaxWidth(),
                horizontalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                OutlinedButton(
                    onClick = onReject,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.outlinedButtonColors(
                        contentColor = MaterialTheme.colorScheme.error
                    )
                ) {
                    Text("Reject")
                }
                Button(
                    onClick = onApprove,
                    modifier = Modifier.weight(1f),
                    colors = ButtonDefaults.buttonColors(
                        containerColor = AppColors.Available
                    )
                ) {
                    Text("Approve")
                }
            }
        }

        if (uiState.canCancel) {
            OutlinedButton(
                onClick = onCancel,
                modifier = Modifier.fillMaxWidth(),
                colors = ButtonDefaults.outlinedButtonColors(
                    contentColor = MaterialTheme.colorScheme.error
                )
            ) {
                Text("Cancel Request")
            }
        }

        if (uiState.canGenerateHandoverOTP) {
            Button(
                onClick = onGenerateHandoverOTP,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Generate Handover OTP")
            }
        }

        if (uiState.canConfirmHandover) {
            Column {
                Text(
                    text = "Enter OTP from owner to confirm handover",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = otpInput,
                        onValueChange = { if (it.length <= 6) otpInput = it },
                        modifier = Modifier.weight(1f),
                        label = { Text("OTP") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true
                    )
                    Button(
                        onClick = { onConfirmHandover(otpInput) },
                        enabled = otpInput.length >= 4
                    ) {
                        Text("Confirm")
                    }
                }
            }
        }

        if (uiState.canGenerateReturnOTP) {
            Button(
                onClick = onGenerateReturnOTP,
                modifier = Modifier.fillMaxWidth()
            ) {
                Text("Generate Return OTP")
            }
        }

        if (uiState.canConfirmReturn) {
            Column {
                Text(
                    text = "Enter OTP from owner to confirm return",
                    style = MaterialTheme.typography.bodySmall,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
                Spacer(modifier = Modifier.height(8.dp))
                Row(
                    modifier = Modifier.fillMaxWidth(),
                    horizontalArrangement = Arrangement.spacedBy(8.dp),
                    verticalAlignment = Alignment.CenterVertically
                ) {
                    OutlinedTextField(
                        value = otpInput,
                        onValueChange = { if (it.length <= 6) otpInput = it },
                        modifier = Modifier.weight(1f),
                        label = { Text("OTP") },
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number),
                        singleLine = true
                    )
                    Button(
                        onClick = { onConfirmReturn(otpInput) },
                        enabled = otpInput.length >= 4
                    ) {
                        Text("Confirm")
                    }
                }
            }
        }

        if (uiState.canRate) {
            Button(
                onClick = onRate,
                modifier = Modifier.fillMaxWidth()
            ) {
                Icon(Icons.Default.Star, contentDescription = null)
                Spacer(modifier = Modifier.width(8.dp))
                Text("Rate This Transaction")
            }
        }
    }
}

@Composable
private fun RejectDialog(
    onDismiss: () -> Unit,
    onConfirm: (String?) -> Unit
) {
    var reason by remember { mutableStateOf("") }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Reject Request") },
        text = {
            Column {
                Text("Are you sure you want to reject this borrow request?")
                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = reason,
                    onValueChange = { reason = it },
                    label = { Text("Reason (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2
                )
            }
        },
        confirmButton = {
            Button(
                onClick = { onConfirm(reason.takeIf { it.isNotBlank() }) },
                colors = ButtonDefaults.buttonColors(containerColor = MaterialTheme.colorScheme.error)
            ) {
                Text("Reject")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}

@Composable
private fun RatingDialog(
    isOwner: Boolean,
    onDismiss: () -> Unit,
    onSubmit: (Int, String?, Int?) -> Unit
) {
    var rating by remember { mutableIntStateOf(0) }
    var comment by remember { mutableStateOf("") }
    var bookConditionRating by remember { mutableIntStateOf(0) }

    AlertDialog(
        onDismissRequest = onDismiss,
        title = { Text("Rate Transaction") },
        text = {
            Column {
                Text(
                    text = if (isOwner) "Rate the borrower" else "Rate the lender",
                    style = MaterialTheme.typography.bodyMedium
                )
                Spacer(modifier = Modifier.height(12.dp))

                Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                    (1..5).forEach { star ->
                        IconButton(onClick = { rating = star }) {
                            Icon(
                                imageVector = Icons.Default.Star,
                                contentDescription = null,
                                tint = if (star <= rating) Color(0xFFFFB800) 
                                       else MaterialTheme.colorScheme.outlineVariant
                            )
                        }
                    }
                }

                if (isOwner) {
                    Spacer(modifier = Modifier.height(16.dp))
                    Text(
                        text = "Book condition on return",
                        style = MaterialTheme.typography.bodyMedium
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    Row(horizontalArrangement = Arrangement.spacedBy(4.dp)) {
                        (1..5).forEach { star ->
                            IconButton(onClick = { bookConditionRating = star }) {
                                Icon(
                                    imageVector = Icons.Default.Star,
                                    contentDescription = null,
                                    tint = if (star <= bookConditionRating) Color(0xFFFFB800)
                                           else MaterialTheme.colorScheme.outlineVariant
                                )
                            }
                        }
                    }
                }

                Spacer(modifier = Modifier.height(16.dp))
                OutlinedTextField(
                    value = comment,
                    onValueChange = { comment = it },
                    label = { Text("Comment (optional)") },
                    modifier = Modifier.fillMaxWidth(),
                    minLines = 2
                )
            }
        },
        confirmButton = {
            Button(
                onClick = {
                    onSubmit(
                        rating,
                        comment.takeIf { it.isNotBlank() },
                        if (isOwner && bookConditionRating > 0) bookConditionRating else null
                    )
                },
                enabled = rating > 0
            ) {
                Text("Submit")
            }
        },
        dismissButton = {
            TextButton(onClick = onDismiss) {
                Text("Cancel")
            }
        }
    )
}
