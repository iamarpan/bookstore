package com.bookstore.bookapp.presentation.ui.components

import androidx.compose.foundation.background
import androidx.compose.foundation.clickable
import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.Column
import androidx.compose.foundation.layout.Row
import androidx.compose.foundation.layout.Spacer
import androidx.compose.foundation.layout.aspectRatio
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.layout.height
import androidx.compose.foundation.layout.padding
import androidx.compose.foundation.layout.size
import androidx.compose.foundation.layout.width
import androidx.compose.foundation.shape.CircleShape
import androidx.compose.foundation.shape.RoundedCornerShape
import androidx.compose.material.icons.Icons
import androidx.compose.material.icons.outlined.MenuBook
import androidx.compose.material3.Icon
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
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
import com.bookstore.bookapp.domain.model.Book
import com.bookstore.bookapp.presentation.theme.AppColors

enum class BookItemSize {
    COMPACT,
    STANDARD,
    LARGE
}

@Composable
fun CompactBookItem(
    book: Book,
    onClick: () -> Unit,
    modifier: Modifier = Modifier,
    size: BookItemSize = BookItemSize.COMPACT
) {
    val (width, imageHeight, cornerRadius, titleStyle, showAuthor, showPrice) = when (size) {
        BookItemSize.COMPACT -> BookItemDimensions(
            width = 100.dp,
            imageAspectRatio = 0.7f,
            cornerRadius = 8.dp,
            titleFontSize = 11.sp,
            showAuthor = false,
            showPrice = false
        )
        BookItemSize.STANDARD -> BookItemDimensions(
            width = 120.dp,
            imageAspectRatio = 0.65f,
            cornerRadius = 10.dp,
            titleFontSize = 12.sp,
            showAuthor = true,
            showPrice = false
        )
        BookItemSize.LARGE -> BookItemDimensions(
            width = 140.dp,
            imageAspectRatio = 0.65f,
            cornerRadius = 12.dp,
            titleFontSize = 13.sp,
            showAuthor = true,
            showPrice = true
        )
    }

    val placeholderSize = when (size) {
        BookItemSize.COMPACT -> PlaceholderSize.SMALL
        BookItemSize.STANDARD -> PlaceholderSize.MEDIUM
        BookItemSize.LARGE -> PlaceholderSize.LARGE
    }

    Column(
        modifier = modifier
            .width(width)
            .clip(RoundedCornerShape(cornerRadius))
            .clickable(onClick = onClick)
    ) {
        Box {
            CompactBookCover(
                imageUrl = book.imageUrl,
                title = book.title,
                author = book.author,
                aspectRatio = imageHeight,
                cornerRadius = cornerRadius,
                placeholderSize = placeholderSize
            )
            
            AvailabilityDot(
                isAvailable = book.isAvailable,
                modifier = Modifier
                    .align(Alignment.TopEnd)
                    .padding(4.dp)
            )
        }
        
        Spacer(modifier = Modifier.height(4.dp))
        
        Text(
            text = book.title,
            style = MaterialTheme.typography.bodySmall.copy(
                fontSize = titleStyle,
                fontWeight = FontWeight.Medium,
                lineHeight = titleStyle * 1.2
            ),
            maxLines = 1,
            overflow = TextOverflow.Ellipsis,
            color = MaterialTheme.colorScheme.onSurface
        )
        
        if (showAuthor) {
            Text(
                text = book.author,
                style = MaterialTheme.typography.bodySmall.copy(
                    fontSize = (titleStyle.value - 1).sp
                ),
                maxLines = 1,
                overflow = TextOverflow.Ellipsis,
                color = MaterialTheme.colorScheme.onSurfaceVariant.copy(alpha = 0.7f)
            )
        }
        
        if (showPrice) {
            Text(
                text = book.formattedPrice,
                style = MaterialTheme.typography.labelSmall.copy(
                    fontWeight = FontWeight.SemiBold
                ),
                color = MaterialTheme.colorScheme.primary
            )
        }
    }
}

@Composable
fun BookListItem(
    book: Book,
    onClick: () -> Unit,
    modifier: Modifier = Modifier
) {
    Surface(
        modifier = modifier
            .fillMaxWidth()
            .clickable(onClick = onClick),
        shape = RoundedCornerShape(8.dp),
        color = MaterialTheme.colorScheme.surface,
        tonalElevation = 1.dp
    ) {
        Row(
            modifier = Modifier
                .fillMaxWidth()
                .padding(8.dp),
            verticalAlignment = Alignment.CenterVertically
        ) {
            CompactBookCover(
                imageUrl = book.imageUrl,
                title = book.title,
                author = book.author,
                aspectRatio = 0.7f,
                cornerRadius = 6.dp,
                placeholderSize = PlaceholderSize.SMALL,
                modifier = Modifier.width(48.dp)
            )
            
            Spacer(modifier = Modifier.width(12.dp))
            
            Column(
                modifier = Modifier.weight(1f),
                verticalArrangement = Arrangement.Center
            ) {
                Text(
                    text = book.title,
                    style = MaterialTheme.typography.bodyMedium.copy(
                        fontWeight = FontWeight.Medium
                    ),
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis
                )
                Text(
                    text = book.author,
                    style = MaterialTheme.typography.bodySmall,
                    maxLines = 1,
                    overflow = TextOverflow.Ellipsis,
                    color = MaterialTheme.colorScheme.onSurfaceVariant
                )
            }
            
            Spacer(modifier = Modifier.width(8.dp))
            
            Column(
                horizontalAlignment = Alignment.End
            ) {
                Text(
                    text = book.formattedPrice,
                    style = MaterialTheme.typography.labelMedium.copy(
                        fontWeight = FontWeight.SemiBold
                    ),
                    color = MaterialTheme.colorScheme.primary
                )
                Spacer(modifier = Modifier.height(2.dp))
                AvailabilityDot(isAvailable = book.isAvailable)
            }
        }
    }
}

@Composable
private fun CompactBookCover(
    imageUrl: String?,
    title: String,
    author: String = "",
    aspectRatio: Float,
    cornerRadius: Dp,
    placeholderSize: PlaceholderSize = PlaceholderSize.SMALL,
    modifier: Modifier = Modifier
) {
    val context = LocalContext.current
    
    if (imageUrl.isNullOrBlank()) {
        BookCoverPlaceholder(
            title = title,
            author = author,
            aspectRatio = aspectRatio,
            cornerRadius = cornerRadius,
            size = placeholderSize,
            modifier = modifier
        )
        return
    }
    
    val imageRequest = ImageRequest.Builder(context)
        .data(imageUrl)
        .crossfade(true)
        .scale(Scale.FILL)
        .size(width = 200, height = 300)
        .build()

    SubcomposeAsyncImage(
        model = imageRequest,
        contentDescription = "Cover of $title",
        contentScale = ContentScale.Crop,
        modifier = modifier
            .fillMaxWidth()
            .aspectRatio(aspectRatio)
            .clip(RoundedCornerShape(cornerRadius)),
        loading = {
            PlaceholderContent(
                title = title,
                author = author,
                cornerRadius = cornerRadius,
                placeholderSize = placeholderSize
            )
        },
        error = {
            PlaceholderContent(
                title = title,
                author = author,
                cornerRadius = cornerRadius,
                placeholderSize = placeholderSize
            )
        }
    )
}

@Composable
fun AvailabilityDot(
    isAvailable: Boolean,
    modifier: Modifier = Modifier
) {
    Box(
        modifier = modifier
            .size(8.dp)
            .background(
                color = if (isAvailable) AppColors.Available else AppColors.Unavailable,
                shape = CircleShape
            )
    )
}

@Composable
private fun PlaceholderContent(
    title: String,
    author: String,
    cornerRadius: Dp,
    placeholderSize: PlaceholderSize
) {
    val gradientColors = remember(title) { generateGradientForTitle(title) }
    
    val (iconSize, titleFontSize, showAuthor, padding) = when (placeholderSize) {
        PlaceholderSize.SMALL -> PlaceholderContentDimensions(20.dp, 9.sp, false, 6.dp)
        PlaceholderSize.MEDIUM -> PlaceholderContentDimensions(28.dp, 11.sp, true, 8.dp)
        PlaceholderSize.LARGE -> PlaceholderContentDimensions(36.dp, 13.sp, true, 12.dp)
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

private fun generateGradientForTitle(title: String): List<Color> {
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
    return palettes[index]
}

private data class PlaceholderContentDimensions(
    val iconSize: Dp,
    val titleFontSize: androidx.compose.ui.unit.TextUnit,
    val showAuthor: Boolean,
    val padding: Dp
)

private data class BookItemDimensions(
    val width: Dp,
    val imageAspectRatio: Float,
    val cornerRadius: Dp,
    val titleFontSize: androidx.compose.ui.unit.TextUnit,
    val showAuthor: Boolean,
    val showPrice: Boolean
)
