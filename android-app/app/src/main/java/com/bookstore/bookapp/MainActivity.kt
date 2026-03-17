package com.bookstore.bookapp

import android.os.Bundle
import androidx.activity.ComponentActivity
import androidx.activity.compose.setContent
import androidx.activity.enableEdgeToEdge
import androidx.compose.foundation.layout.fillMaxSize
import androidx.compose.material3.MaterialTheme
import androidx.compose.material3.Surface
import androidx.compose.ui.Modifier
import androidx.navigation.compose.rememberNavController
import com.bookstore.bookapp.presentation.navigation.AppNavGraph
import com.bookstore.bookapp.presentation.navigation.Screen
import com.bookstore.bookapp.presentation.theme.BookShareTheme
import dagger.hilt.android.AndroidEntryPoint
import androidx.compose.ui.platform.LocalContext
import android.content.Context

@AndroidEntryPoint
class MainActivity : ComponentActivity() {
    override fun onCreate(savedInstanceState: Bundle?) {
        super.onCreate(savedInstanceState)
        enableEdgeToEdge()
        setContent {
            BookShareTheme {
                Surface(
                    modifier = Modifier.fillMaxSize(),
                    color = MaterialTheme.colorScheme.background
                ) {
                    val context = LocalContext.current
                    val sharedPreferences = context.getSharedPreferences("bookshare_prefs", Context.MODE_PRIVATE)
                    val onboardingCompleted = sharedPreferences.getBoolean("onboarding_completed", false)
                    
                    val startDest = if (onboardingCompleted) {
                        Screen.Auth.route
                    } else {
                        Screen.Onboarding.route
                    }

                    val navController = rememberNavController()
                    AppNavGraph(navController = navController, startDestination = startDest)
                }
            }
        }
    }
}
