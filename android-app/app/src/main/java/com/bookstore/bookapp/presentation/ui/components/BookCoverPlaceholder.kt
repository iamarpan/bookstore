package com.bookstore.bookapp.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Text
import androidx.compose.runtime.Composable
import androidx.compose.runtime.remember
import androidx.compose.ui.Alignment
import androidx.compose.ui.Modifier
import androidx.compose.ui.draw.clip
import androidx.compose.ui.graphics.Brush
import androidx.compose.ui.graphics.Color
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp

@Composable
fun BookCoverPlaceholder(
    title: String,
    author: String = "",
    modifier: Modifier = Modifier,
    aspectRatio: Float = 0.65f,
    cornerRadius: Dp = 8.dp,
    size: PlaceholderSize = PlaceholderSize.MEDIUM
) {
    val gradientColors = remember(title) { generateGradientForTitle(title) }
    
    val (iconSize, titleFontSize, showAuthor, padding) = when (size) {
        PlaceholderSize.SMALL -> PlaceholderDimensions(
            iconSize = 20.dp,
            titleFontSize = 9.sp,
            showAuthor = false,
            padding = 6.dp
        )
        PlaceholderSize.MEDIUM -> PlaceholderDimensions(
            iconSize = 28.dp,
            titleFontSize = 11.sp,
            showAuthor = true,
            padding = 8.dp
        )
        PlaceholderSize.LARGE -> PlaceholderDimensions(
            iconSize = 36.dp,
            titleFontSize = 13.sp,
            showAuthor = true,
            padding = 12.dp
        )
    }

    Box(
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(aspectRatio)
            .clip(RoundedCornerShape(cornerRadius))
            .background(
                brush = Brush.verticalGradient(colors = gradientColors)
            ),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(padding),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Outlined.MenuBook,
                contentDescription = null,
                modifier = Modifier.size(iconSize),
                tint = Color.White.copy(alpha = 0.7f)
            )
            
            if (title.isNotBlank()) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontSize = titleFontSize,
                        fontWeight = FontWeight.SemiBold,
                        lineHeight = titleFontSize * 1.2
                    ),
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
            
            if (showAuthor && author.isNotBlank()) {
                Text(
                    text = author,
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontSize = (titleFontSize.value - 1).sp
                    ),
                    color = Color.White.copy(alpha = 0.7f),
                    textAlign = TextAlign.Center,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 2.dp)
                )
            }
        }
    }
}

enum class PlaceholderSize {
    SMALL,
    MEDIUM,
    LARGE
}

private data class PlaceholderDimensions(
    val iconSize: Dp,
    val titleFontSize: androidx.compose.ui.unit.TextUnit,
    val showAuthor: Boolean,
    val padding: Dp
)

private fun generateGradientForTitle(title: String): List<Color> {
    val hash = title.hashCode()
    val hue = ((hash and 0xFF) / 255f) * 360f
    
    val palettes = listOf(
        listOf(Color(0xFF667eea), Color(0xFF764ba2)),
        listOf(Color(0xFF11998e), Color(0xFF38ef7d)),
        listOf(Color(0xFFfc5c7d), Color(0xFF6a82fb)),
        listOf(Color(0xFFee0979), Color(0xFFff6a00)),
        listOf(Color(0xFF56ab2f), Color(0xFFa8e6cf)),
        listOf(Color(0xFF614385), Color(0xFF516395)),
        listOf(Color(0xFFeb3349), Color(0xFFf45c43)),
        listOf(Color(0xFF00b4db), Color(0xFF0083b0)),
        listOf(Color(0xFFf857a6), Color(0xFFff5858)),
        listOf(Color(0xFF4776E6), Color(0xFF8E54E9)),
        listOf(Color(0xFFFFAFBD), Color(0xFFffc3a0)),
        listOf(Color(0xFF2193b0), Color(0xFF6dd5ed)),
    )
    
    val index = (hash.toUInt() % palettes.size.toUInt()).toInt()
    return palettes[index]
}
