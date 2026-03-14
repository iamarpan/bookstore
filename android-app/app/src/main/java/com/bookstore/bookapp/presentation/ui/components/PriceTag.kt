package com.bookstore.bookapp.presentation.ui.components

import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.text.font.FontWeight
import com.bookstore.bookapp.presentation.theme.AppColors

@Composable
fun PriceTag(
    price: String,
    modifier: Modifier = Modifier
) {
    Text(
        text = price,
        style = MaterialTheme.typography.titleMedium,
        fontWeight = FontWeight.Bold,
        color = AppColors.Primary,
        modifier = modifier
    )
}
