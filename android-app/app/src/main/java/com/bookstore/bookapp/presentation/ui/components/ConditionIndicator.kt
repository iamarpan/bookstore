package com.bookstore.bookapp.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.unit.dp
import com.bookstore.bookapp.domain.model.BookCondition
import com.bookstore.bookapp.presentation.theme.AppColors

@Composable
fun ConditionDots(
    condition: BookCondition,
    modifier: Modifier = Modifier,
    activeColor: Color = AppColors.Primary,
    inactiveColor: Color = Color.White.copy(alpha = 0.5f)
) {
    Row(modifier = modifier, horizontalArrangement = Arrangement.spacedBy(2.dp)) {
        val filledDots = when (condition) {
            BookCondition.NEW -> 5
            BookCondition.LIKE_NEW -> 4
            BookCondition.GOOD -> 3
            BookCondition.FAIR -> 2
            BookCondition.POOR -> 1
        }
        repeat(5) { index ->
            Box(
                modifier = Modifier
                    .size(6.dp)
                    .background(
                        color = if (index < filledDots) activeColor else inactiveColor,
                        shape = CircleShape
                    )
            )
        }
    }
}
