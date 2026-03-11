package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.local.UserPreferences;
import com.bookstore.bookapp.data.remote.api.AuthApi;
import com.bookstore.bookapp.data.repository.AuthRepositoryImpl;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

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
public final class RepositoryProviderModule_ProvideAuthRepositoryImplFactory implements Factory<AuthRepositoryImpl> {
  private final Provider<AuthApi> apiProvider;

  private final Provider<UserPreferences> prefsProvider;

  public RepositoryProviderModule_ProvideAuthRepositoryImplFactory(Provider<AuthApi> apiProvider,
      Provider<UserPreferences> prefsProvider) {
    this.apiProvider = apiProvider;
    this.prefsProvider = prefsProvider;
  }

  @Override
  public AuthRepositoryImpl get() {
    return provideAuthRepositoryImpl(apiProvider.get(), prefsProvider.get());
  }

  public static RepositoryProviderModule_ProvideAuthRepositoryImplFactory create(
      Provider<AuthApi> apiProvider, Provider<UserPreferences> prefsProvider) {
    return new RepositoryProviderModule_ProvideAuthRepositoryImplFactory(apiProvider, prefsProvider);
  }

  public static AuthRepositoryImpl provideAuthRepositoryImpl(AuthApi api, UserPreferences prefs) {
    return Preconditions.checkNotNullFromProvides(RepositoryProviderModule.INSTANCE.provideAuthRepositoryImpl(api, prefs));
  }
}
