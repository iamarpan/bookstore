package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.local.UserPreferences;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import okhttp3.Interceptor;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata
@DaggerGenerated
@Generated(
    value = "dagger.internal.codegen.ComponentProcessor",
    comments = "https://dagger.dev"
)
@SuppressWarnings({
    "unchecked",
    "rawtypes",
    "KotlinInternal",
    "KotlinInternalInJava",
    "cast"
})
public final class NetworkModule_ProvideAuthInterceptorFactory implements Factory<Interceptor> {
  private final Provider<UserPreferences> userPreferencesProvider;

  public NetworkModule_ProvideAuthInterceptorFactory(
      Provider<UserPreferences> userPreferencesProvider) {
    this.userPreferencesProvider = userPreferencesProvider;
  }

  @Override
  public Interceptor get() {
    return provideAuthInterceptor(userPreferencesProvider.get());
  }

  public static NetworkModule_ProvideAuthInterceptorFactory create(
      Provider<UserPreferences> userPreferencesProvider) {
    return new NetworkModule_ProvideAuthInterceptorFactory(userPreferencesProvider);
  }

  public static Interceptor provideAuthInterceptor(UserPreferences userPreferences) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideAuthInterceptor(userPreferences));
  }
}
