package com.bookstore.bookapp.presentation.ui

import android.Manifest
import android.content.pm.PackageManager
import androidx.activity.compose.rememberLauncherForActivityResult
import androidx.activity.result.contract.ActivityResultContracts
import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.rememberScrollState
import androidx.compose.foundation.text.KeyboardOptions
import androidx.compose.foundation.verticalScroll
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.filled.ArrowBack
import androidx.compose.material.icons.filled.CameraAlt
import androidx.compose.material3.Button
import androidx.compose.material3.Card
import androidx.compose.material3.CardDefaults
import androidx.compose.material3.Checkbox
import androidx.compose.material3.CircularProgressIndicator
import androidx.compose.material3.DropdownMenuItem
import androidx.compose.material3.ExperimentalMaterial3Api
import androidx.compose.material3.ExposedDropdownMenuBox
import androidx.compose.material3.ExposedDropdownMenuDefaults
import androidx.compose.material3.Icon
import androidx.compose.material3.IconButton
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.OutlinedTextField
import androidx.compose.material3.Scaffold
import androidx.compose.material3.Switch
import androidx.compose.material3.Text
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
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.input.KeyboardType
import androidx.compose.ui.unit.dp
import androidx.core.content.ContextCompat
import androidx.hilt.navigation.compose.hiltViewModel
import com.bookstore.bookapp.domain.model.BookCondition
import com.bookstore.bookapp.presentation.viewmodel.AddBookViewModel

@OptIn(ExperimentalMaterial3Api::class)
@Composable
fun AddBookScreen(
    onNavigateBack: () -> Unit,
    viewModel: AddBookViewModel = hiltViewModel()
) {
    val uiState by viewModel.uiState.collectAsState()

    LaunchedEffect(uiState.success) {
        if (uiState.success) {
            onNavigateBack()
        }
    }

    Scaffold(
        topBar = {
            TopAppBar(
                title = { Text("Add Book") },
                navigationIcon = {
                    IconButton(onClick = onNavigateBack) {
                        Icon(imageVector = Icons.Default.ArrowBack, contentDescription = "Back")
                    }
                },
                colors = TopAppBarDefaults.topAppBarColors(
                    containerColor = MaterialTheme.colorScheme.background,
                    titleContentColor = MaterialTheme.colorScheme.onBackground
                )
            )
        },
        containerColor = MaterialTheme.colorScheme.surfaceVariant.copy(alpha = 0.5f) // Subtle background to differentiate cards
    ) { padding ->
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding)
                .verticalScroll(rememberScrollState()),
            horizontalAlignment = Alignment.CenterHorizontally
        ) {
            if (uiState.isLoading) {
                Spacer(modifier = Modifier.height(32.dp))
                CircularProgressIndicator()
                Spacer(modifier = Modifier.height(16.dp))
                Text("Saving book...")
            } else {
                val context = LocalContext.current
                val permissionLauncher = rememberLauncherForActivityResult(
                    ActivityResultContracts.RequestPermission()
                ) { isGranted ->
                    if (isGranted) {
                        viewModel.toggleScanner()
                    }
                }

                if (uiState.isScanning) {
                    CameraPreview(
                        onBarcodeScanned = { barcode ->
                            viewModel.onIsbnQueryChange(barcode)
                            viewModel.toggleScanner()
                            viewModel.lookupIsbn(barcode)
                        },
                        modifier = Modifier
                            .fillMaxWidth()
                            .height(300.dp)
                    )
                    Spacer(modifier = Modifier.height(16.dp))
                    Button(onClick = { viewModel.toggleScanner() }) {
                        Text("Cancel Scan")
                    }
                    Spacer(modifier = Modifier.height(16.dp))
                }

                // --- Quick Add Section ---
                SectionCard(title = "Quick Add") {
                    Row(
                        modifier = Modifier.fillMaxWidth(),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        OutlinedTextField(
                            value = uiState.isbnQuery,
                            onValueChange = { viewModel.onIsbnQueryChange(it) },
                            label = { Text("ISBN (Optional)") },
                            modifier = Modifier.weight(1f),
                            keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Number)
                        )
                        IconButton(
                            onClick = {
                                val permissionCheckResult = ContextCompat.checkSelfPermission(context, Manifest.permission.CAMERA)
                                if (permissionCheckResult == PackageManager.PERMISSION_GRANTED) {
                                    viewModel.toggleScanner()
                                } else {
                                    permissionLauncher.launch(Manifest.permission.CAMERA)
                                }
                            },
                            modifier = Modifier.padding(start = 8.dp)
                        ) {
                            Icon(imageVector = Icons.Default.CameraAlt, contentDescription = "Scan Barcode")
                        }
                    }
                    Spacer(modifier = Modifier.height(8.dp))
                    Button(
                        onClick = { viewModel.lookupIsbn(uiState.isbnQuery) },
                        modifier = Modifier.fillMaxWidth(),
                        enabled = uiState.isbnQuery.isNotBlank()
                    ) {
                        Text("Lookup ISBN Details")
                    }
                }

                // --- Book Details Section ---
                SectionCard(title = "Book Details") {
                    OutlinedTextField(
                        value = uiState.title,
                        onValueChange = { viewModel.updateField(title = it) },
                        label = { Text("Title *") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = uiState.author,
                        onValueChange = { viewModel.updateField(author = it) },
                        label = { Text("Author *") },
                        modifier = Modifier.fillMaxWidth()
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    val genres = listOf("Fiction", "Biography", "Science", "History", "Technology", "Romance", "Mystery", "Other")
                    var genreExpanded by remember { mutableStateOf(false) }

                    ExposedDropdownMenuBox(
                        expanded = genreExpanded,
                        onExpandedChange = { genreExpanded = !genreExpanded },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        OutlinedTextField(
                            value = uiState.genre,
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Genre") },
                            trailingIcon = {
                                ExposedDropdownMenuDefaults.TrailingIcon(expanded = genreExpanded)
                            },
                            colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(),
                            modifier = Modifier
                                .menuAnchor()
                                .fillMaxWidth()
                        )
                        ExposedDropdownMenu(
                            expanded = genreExpanded,
                            onDismissRequest = { genreExpanded = false }
                        ) {
                            genres.forEach { selectionOption ->
                                DropdownMenuItem(
                                    text = { Text(selectionOption) },
                                    onClick = {
                                        viewModel.updateField(genre = selectionOption)
                                        genreExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                    OutlinedTextField(
                        value = uiState.description,
                        onValueChange = { viewModel.updateField(description = it) },
                        label = { Text("Description *") },
                        modifier = Modifier.fillMaxWidth(),
                        minLines = 3
                    )
                }

                // --- Lending Details Section ---
                SectionCard(title = "Lending Details") {
                    OutlinedTextField(
                        value = uiState.lendingPrice,
                        onValueChange = { viewModel.updateField(lendingPrice = it) },
                        label = { Text("Lending Price (per week)") },
                        modifier = Modifier.fillMaxWidth(),
                        keyboardOptions = KeyboardOptions(keyboardType = KeyboardType.Decimal)
                    )
                    Spacer(modifier = Modifier.height(8.dp))

                    val conditions = BookCondition.entries.toTypedArray()
                    var conditionExpanded by remember { mutableStateOf(false) }

                    ExposedDropdownMenuBox(
                        expanded = conditionExpanded,
                        onExpandedChange = { conditionExpanded = !conditionExpanded },
                        modifier = Modifier.fillMaxWidth()
                    ) {
                        OutlinedTextField(
                            value = uiState.condition.name.lowercase().replaceFirstChar { it.uppercase() },
                            onValueChange = {},
                            readOnly = true,
                            label = { Text("Condition") },
                            trailingIcon = {
                                ExposedDropdownMenuDefaults.TrailingIcon(expanded = conditionExpanded)
                            },
                            colors = ExposedDropdownMenuDefaults.outlinedTextFieldColors(),
                            modifier = Modifier
                                .menuAnchor()
                                .fillMaxWidth()
                        )
                        ExposedDropdownMenu(
                            expanded = conditionExpanded,
                            onDismissRequest = { conditionExpanded = false }
                        ) {
                            conditions.forEach { selectionOption ->
                                DropdownMenuItem(
                                    text = { Text(selectionOption.name.lowercase().replaceFirstChar { it.uppercase() }) },
                                    onClick = {
                                        viewModel.updateField(condition = selectionOption)
                                        conditionExpanded = false
                                    }
                                )
                            }
                        }
                    }

                    Spacer(modifier = Modifier.height(8.dp))
                    Row(
                        modifier = Modifier
                            .fillMaxWidth()
                            .clickable { viewModel.updateField(isAvailable = !uiState.isAvailable) }
                            .padding(vertical = 8.dp),
                        verticalAlignment = Alignment.CenterVertically
                    ) {
                        Text("Available for Lending", modifier = Modifier.weight(1f))
                        Switch(
                            checked = uiState.isAvailable,
                            onCheckedChange = { viewModel.updateField(isAvailable = it) }
                        )
                    }
                }

                // --- Visible In Groups Section ---
                SectionCard(title = "Visible In Groups") {
                    if (uiState.userGroups.isEmpty()) {
                        Text(
                            text = "No groups found. Join a group to share books.",
                            style = MaterialTheme.typography.bodySmall,
                            color = MaterialTheme.colorScheme.onSurfaceVariant
                        )
                    } else {
                        uiState.userGroups.forEach { group ->
                            Row(
                                modifier = Modifier
                                    .fillMaxWidth()
                                    .clickable { viewModel.toggleGroupSelection(group.id) }
                                    .padding(vertical = 4.dp),
                                verticalAlignment = Alignment.CenterVertically
                            ) {
                                Text(group.name, modifier = Modifier.weight(1f))
                                Checkbox(
                                    checked = uiState.selectedGroupIds.contains(group.id),
                                    onCheckedChange = { viewModel.toggleGroupSelection(group.id) }
                                )
                            }
                        }
                    }
                }

                if (uiState.errorMessage != null) {
                    Text(
                        text = uiState.errorMessage!!,
                        color = MaterialTheme.colorScheme.error,
                        style = MaterialTheme.typography.bodyMedium,
                        modifier = Modifier.padding(horizontal = 16.dp)
                    )
                    Spacer(modifier = Modifier.height(8.dp))
                }

                Button(
                    onClick = { viewModel.saveBook() },
                    modifier = Modifier
                        .fillMaxWidth()
                        .padding(16.dp)
                        .height(56.dp),
                    enabled = uiState.isFormValid && !uiState.isLoading
                ) {
                    Text("Add Book")
                }
                
                Spacer(modifier = Modifier.height(48.dp)) // Bottom padding
            }
        }
    }
}

@Composable
fun SectionCard(
    title: String,
    content: @Composable () -> Unit
) {
    Card(
        modifier = Modifier
            .fillMaxWidth()
            .padding(horizontal = 16.dp, vertical = 8.dp),
        colors = CardDefaults.cardColors(containerColor = MaterialTheme.colorScheme.surface),
        elevation = CardDefaults.cardElevation(defaultElevation = 0.dp)
    ) {
        Column(modifier = Modifier.padding(16.dp)) {
            Text(
                text = title,
                style = MaterialTheme.typography.titleMedium,
                fontWeight = FontWeight.Bold,
                color = MaterialTheme.colorScheme.primary,
                modifier = Modifier.padding(bottom = 16.dp)
            )
            content()
        }
    }
}
