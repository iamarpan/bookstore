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
import androidx.compose.ui.layout.ContentScale
import androidx.compose.ui.platform.LocalContext
import androidx.compose.ui.text.font.FontWeight
import androidx.compose.ui.text.style.TextAlign
import androidx.compose.ui.text.style.TextOverflow
import androidx.compose.ui.unit.Dp
import androidx.compose.ui.unit.dp
import androidx.compose.ui.unit.sp
import coil.compose.SubcomposeAsyncImage
import coil.request.ImageRequest
import coil.size.Scale

@Composable
fun BookCoverImage(
    imageUrl: String?,
    contentDescription: String,
    modifier: Modifier = Modifier,
    title: String = "",
    author: String = "",
    aspectRatio: Float = 0.65f,
    cornerRadius: Dp = 16.dp
) {
    val context = LocalContext.current

    if (imageUrl.isNullOrBlank()) {
        BookCoverPlaceholder(
            title = title,
            author = author,
            aspectRatio = aspectRatio,
            cornerRadius = cornerRadius,
            size = PlaceholderSize.LARGE,
            modifier = modifier
        )
        return
    }

    val imageRequest = ImageRequest.Builder(context)
        .data(imageUrl)
        .crossfade(true)
        .scale(Scale.FILL)
        .size(width = 400, height = 600)
        .build()

    SubcomposeAsyncImage(
        model = imageRequest,
        contentDescription = contentDescription,
        contentScale = ContentScale.Crop,
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(aspectRatio)
            .clip(RoundedCornerShape(cornerRadius)),
        loading = {
            LargePlaceholderContent(
                title = title,
                author = author,
                cornerRadius = cornerRadius
            )
        },
        error = {
            LargePlaceholderContent(
                title = title,
                author = author,
                cornerRadius = cornerRadius
            )
        }
    )
}

@Composable
private fun LargePlaceholderContent(
    title: String,
    author: String,
    cornerRadius: Dp
) {
    val gradientColors = remember(title) { 
        val hash = title.hashCode()
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
        palettes[index]
    }

    Box(
        modifier = Modifier
            .fillMaxSize()
            .clip(RoundedCornerShape(cornerRadius))
            .background(brush = Brush.verticalGradient(colors = gradientColors)),
        contentAlignment = Alignment.Center
    ) {
        Column(
            modifier = Modifier
                .fillMaxSize()
                .padding(12.dp),
            horizontalAlignment = Alignment.CenterHorizontally,
            verticalArrangement = Arrangement.Center
        ) {
            Icon(
                imageVector = Icons.Outlined.MenuBook,
                contentDescription = null,
                modifier = Modifier.size(36.dp),
                tint = Color.White.copy(alpha = 0.7f)
            )
            
            if (title.isNotBlank()) {
                Text(
                    text = title,
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontSize = 13.sp,
                        fontWeight = FontWeight.SemiBold,
                        lineHeight = 15.6.sp
                    ),
                    color = Color.White,
                    textAlign = TextAlign.Center,
                    maxLines = 2,
                    overflow = TextOverflow.Ellipsis,
                    modifier = Modifier.padding(top = 4.dp)
                )
            }
            
            if (author.isNotBlank()) {
                Text(
                    text = author,
                    style = MaterialTheme.typography.labelSmall.copy(
                        fontSize = 12.sp
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
