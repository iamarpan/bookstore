package com.bookstore.bookapp

import android.app.Application
import dagger.hilt.android.HiltAndroidApp

@HiltAndroidApp
class BookClubApp : Application() {
    override fun onCreate() {
        super.onCreate()
        println("🚀 BookShare Android app starting up...")
    }
}
