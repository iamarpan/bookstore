package com.bookstore.bookapp.presentation.theme

import androidx.compose.ui.graphics.Color
import androidx.compose.foundation.isSystemInDarkTheme
import androidx.compose.runtime.Composable
import androidx.compose.runtime.ReadOnlyComposable

// Light Theme Colors
val primaryLight = Color(0xFFC2410C) // Burnt Orange/Terracotta
val onPrimaryLight = Color(0xFFFFFFFF)
val primaryContainerLight = Color(0xFFFFDBCE)
val onPrimaryContainerLight = Color(0xFF3B0900)
val secondaryLight = Color(0xFF334155) // Slate Blue
val onSecondaryLight = Color(0xFFFFFFFF)
val secondaryContainerLight = Color(0xFFD4E3FF)
val onSecondaryContainerLight = Color(0xFF001C38)
val errorLight = Color(0xFFDC2626) // Rose
val onErrorLight = Color(0xFFFFFFFF)
val errorContainerLight = Color(0xFFFFDAD6)
val onErrorContainerLight = Color(0xFF410002)
val backgroundLight = Color(0xFFF9F7F2) // Warm Alabaster
val onBackgroundLight = Color(0xFF1A1A1A) // Soft Black
val surfaceLight = Color(0xFFFFFFFF) // Pure White
val onSurfaceLight = Color(0xFF1A1A1A)
val surfaceVariantLight = Color(0xFFF2F2F7) // Secondary Background Light
val onSurfaceVariantLight = Color(0xFF585858) // Dark Grey
val outlineLight = Color(0xFFE5E5EA) // Separator Color

// Dark Theme Colors
val primaryDark = Color(0xFFFFB5A0)
val onPrimaryDark = Color(0xFF671A00)
val primaryContainerDark = Color(0xFF932B00)
val onPrimaryContainerDark = Color(0xFFFFDBCE)
val secondaryDark = Color(0xFFA5C8FF)
val onSecondaryDark = Color(0xFF00315F)
val secondaryContainerDark = Color(0xFF16497B)
val onSecondaryContainerDark = Color(0xFFD4E3FF)
val errorDark = Color(0xFFFFB4AB)
val onErrorDark = Color(0xFF690005)
val errorContainerDark = Color(0xFF93000A)
val onErrorContainerDark = Color(0xFFFFDAD6)
val backgroundDark = Color(0xFF1C1C1E)
val onBackgroundDark = Color(0xFFFFFFFF)
val surfaceDark = Color(0xFF2C2C2E) // Card Background Dark
val onSurfaceDark = Color(0xFFFFFFFF)
val surfaceVariantDark = Color(0xFF2C2C2E) // Secondary Background Dark
val onSurfaceVariantDark = Color(0xFFAEAEB2) // Secondary Text Dark
val outlineDark = Color(0xFF3A3A3C)

// Custom App Colors matching iOS AppTheme
object AppColors {
    // Redesign System Colors
    val Primary: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) primaryDark else primaryLight
        
    val PrimaryVariant: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) Color(0xFFFF8A50) else Color(0xFFE85D04)
        
    val Accent: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) Color(0xFF34D399) else Color(0xFF059669)
        
    val SurfaceElevated: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) surfaceDark else Color(0xFFFFFBF5)
    
    // Semantic Colors
    val Available: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) Color(0xFF0D946A) else Color(0xFF059669)
        
    val Borrowed: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) Color(0xFFB46506) else Color(0xFFD97706)
        
    val Unavailable: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) Color(0xFF6B7280) else Color(0xFF9CA3AF)
        
    val Overdue: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) errorDark else errorLight

    // Existing AppColors
    val successColor: Color
        @Composable
        @ReadOnlyComposable
        get() = Available
        
    val successBg: Color
        @Composable
        @ReadOnlyComposable
        get() = if (isSystemInDarkTheme()) Color(0xFF064E3B) else Color(0xFFECFDF5)
        
    val warningColor: Color
        @Composable
        @ReadOnlyComposable
        get() = Borrowed

    val tertiaryTextLight = Color(0xFF8A8A8A)
    val tertiaryTextDark = Color(0xFF636366)
}
