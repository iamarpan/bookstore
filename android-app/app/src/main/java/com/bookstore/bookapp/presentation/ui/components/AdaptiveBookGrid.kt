package com.bookstore.bookapp.presentation.ui.components

import androidx.compose.foundation.layout.Arrangement
import androidx.compose.foundation.layout.Box
import androidx.compose.foundation.layout.PaddingValues
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.foundation.layout.fillMaxWidth
import androidx.compose.foundation.lazy.LazyColumn
import androidx.compose.foundation.lazy.grid.GridCells
import androidx.compose.foundation.lazy.grid.LazyVerticalGrid
import androidx.compose.foundation.lazy.grid.items
import androidx.compose.foundation.lazy.items
import androidx.compose.runtime.Composable
import androidx.compose.ui.Modifier
import androidx.compose.ui.unit.dp
import com.bookstore.bookapp.domain.model.Book

enum class BookGridMode {
    COMPACT_GRID,
    STANDARD_GRID,
    LIST
}

@Composable
fun AdaptiveBookGrid(
    books: List<Book>,
    onBookClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    mode: BookGridMode = BookGridMode.COMPACT_GRID,
    contentPadding: PaddingValues = PaddingValues(12.dp)
) {
    when (mode) {
        BookGridMode.COMPACT_GRID -> {
            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 100.dp),
                modifier = modifier.fillMaxSize(),
                contentPadding = contentPadding,
                horizontalArrangement = Arrangement.spacedBy(8.dp),
                verticalArrangement = Arrangement.spacedBy(12.dp)
            ) {
                items(books, key = { it.id }) { book ->
                    CompactBookItem(
                        book = book,
                        onClick = { onBookClick(book.id) },
                        size = BookItemSize.COMPACT
                    )
                }
            }
        }
        BookGridMode.STANDARD_GRID -> {
            LazyVerticalGrid(
                columns = GridCells.Adaptive(minSize = 120.dp),
                modifier = modifier.fillMaxSize(),
                contentPadding = contentPadding,
                horizontalArrangement = Arrangement.spacedBy(12.dp),
                verticalArrangement = Arrangement.spacedBy(16.dp)
            ) {
                items(books, key = { it.id }) { book ->
                    CompactBookItem(
                        book = book,
                        onClick = { onBookClick(book.id) },
                        size = BookItemSize.STANDARD
                    )
                }
            }
        }
        BookGridMode.LIST -> {
            LazyColumn(
                modifier = modifier.fillMaxSize(),
                contentPadding = contentPadding,
                verticalArrangement = Arrangement.spacedBy(8.dp)
            ) {
                items(books, key = { it.id }) { book ->
                    BookListItem(
                        book = book,
                        onClick = { onBookClick(book.id) },
                        modifier = Modifier.fillMaxWidth()
                    )
                }
            }
        }
    }
}

@Composable
fun CompactHorizontalBookList(
    books: List<Book>,
    onBookClick: (String) -> Unit,
    modifier: Modifier = Modifier,
    size: BookItemSize = BookItemSize.COMPACT,
    contentPadding: PaddingValues = PaddingValues(horizontal = 12.dp, vertical = 8.dp)
) {
    val spacing = when (size) {
        BookItemSize.COMPACT -> 8.dp
        BookItemSize.STANDARD -> 10.dp
        BookItemSize.LARGE -> 12.dp
    }
    
    androidx.compose.foundation.lazy.LazyRow(
        modifier = modifier,
        contentPadding = contentPadding,
        horizontalArrangement = Arrangement.spacedBy(spacing)
    ) {
        items(books, key = { it.id }) { book ->
            CompactBookItem(
                book = book,
                onClick = { onBookClick(book.id) },
                size = size
            )
        }
    }
}
