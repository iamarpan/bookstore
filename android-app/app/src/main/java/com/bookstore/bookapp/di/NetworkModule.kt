package com.bookstore.bookapp.di

import com.bookstore.bookapp.data.local.UserPreferences
import com.bookstore.bookapp.data.remote.api.AuthApi
import com.bookstore.bookapp.data.remote.api.BookApi
import com.bookstore.bookapp.data.remote.api.GoogleBooksApi
import com.bookstore.bookapp.data.remote.api.GroupApi
import com.bookstore.bookapp.data.remote.api.NotificationApi
import com.bookstore.bookapp.data.remote.api.TransactionApi
import com.bookstore.bookapp.data.remote.api.UserApi
import dagger.Module
import dagger.Provides
import dagger.hilt.InstallIn
import dagger.hilt.components.SingletonComponent
import kotlinx.coroutines.flow.firstOrNull
import kotlinx.coroutines.runBlocking
import okhttp3.Interceptor
import okhttp3.OkHttpClient
import okhttp3.logging.HttpLoggingInterceptor
import retrofit2.Retrofit
import retrofit2.converter.gson.GsonConverterFactory
import java.util.concurrent.TimeUnit
import javax.inject.Named
import javax.inject.Singleton
@Module
@InstallIn(SingletonComponent::class)
object NetworkModule {

    private const val BASE_URL = "https://api-book-club.zenith-techsphere.com/api/v1/"
    private const val GOOGLE_BOOKS_BASE_URL = "https://www.googleapis.com/"

    @Provides
    @Singleton
    fun provideTokenHolder(userPreferences: UserPreferences): TokenHolder {
        return TokenHolder(userPreferences)
    }

    @Provides
    @Singleton
    fun provideAuthInterceptor(tokenHolder: TokenHolder): Interceptor {
        return Interceptor { chain ->
            val requestBuilder = chain.request().newBuilder()
            
            // Read from in-memory cache
            val token = tokenHolder.accessToken
            
            if (!token.isNullOrEmpty()) {
                requestBuilder.addHeader("Authorization", "Bearer $token")
            }
            chain.proceed(requestBuilder.build())
        }
    }

    @Provides
    @Singleton
    fun provideOkHttpClient(
        authInterceptor: Interceptor,
        tokenAuthenticator: TokenAuthenticator
    ): OkHttpClient {
        val loggingInterceptor = HttpLoggingInterceptor().apply {
            level = if (com.bookstore.bookapp.BuildConfig.DEBUG) {
                HttpLoggingInterceptor.Level.BODY
            } else {
                HttpLoggingInterceptor.Level.NONE
            }
            redactHeader("Authorization")
            redactHeader("Cookie")
            redactHeader("Set-Cookie")
        }
        
        return OkHttpClient.Builder()
            .connectTimeout(30, TimeUnit.SECONDS)
            .readTimeout(30, TimeUnit.SECONDS)
            .writeTimeout(30, TimeUnit.SECONDS)
            .callTimeout(60, TimeUnit.SECONDS)
            .authenticator(tokenAuthenticator)
            .addInterceptor(loggingInterceptor)
            .addInterceptor(authInterceptor)
            .build()
    }

    @Provides
    @Singleton
    @Named("MainRetrofit")
    fun provideRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(BASE_URL)
            .client(okHttpClient)
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    @Named("GoogleBooksRetrofit")
    fun provideGoogleBooksRetrofit(okHttpClient: OkHttpClient): Retrofit {
        return Retrofit.Builder()
            .baseUrl(GOOGLE_BOOKS_BASE_URL)
            .client(okHttpClient) // Ok with auth interceptor; google ignores Authorization headers
            .addConverterFactory(GsonConverterFactory.create())
            .build()
    }

    @Provides
    @Singleton
    fun provideAuthApi(@Named("MainRetrofit") retrofit: Retrofit): AuthApi = retrofit.create(AuthApi::class.java)

    @Provides
    @Singleton
    fun provideBookApi(@Named("MainRetrofit") retrofit: Retrofit): BookApi = retrofit.create(BookApi::class.java)

    @Provides
    @Singleton
    fun provideGroupApi(@Named("MainRetrofit") retrofit: Retrofit): GroupApi = retrofit.create(GroupApi::class.java)

    @Provides
    @Singleton
    fun provideTransactionApi(@Named("MainRetrofit") retrofit: Retrofit): TransactionApi = retrofit.create(TransactionApi::class.java)

    @Provides
    @Singleton
    fun provideUserApi(@Named("MainRetrofit") retrofit: Retrofit): UserApi = retrofit.create(UserApi::class.java)

    @Provides
    @Singleton
    fun provideNotificationApi(@Named("MainRetrofit") retrofit: Retrofit): NotificationApi = retrofit.create(NotificationApi::class.java)

    @Provides
    @Singleton
    fun provideGoogleBooksApi(@Named("GoogleBooksRetrofit") retrofit: Retrofit): GoogleBooksApi = retrofit.create(GoogleBooksApi::class.java)
}
