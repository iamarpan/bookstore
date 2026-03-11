package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.remote.api.UserApi;
import com.bookstore.bookapp.data.repository.UserRepositoryImpl;
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
public final class RepositoryProviderModule_ProvideUserRepositoryImplFactory implements Factory<UserRepositoryImpl> {
  private final Provider<UserApi> apiProvider;

  public RepositoryProviderModule_ProvideUserRepositoryImplFactory(Provider<UserApi> apiProvider) {
    this.apiProvider = apiProvider;
  }

  @Override
  public UserRepositoryImpl get() {
    return provideUserRepositoryImpl(apiProvider.get());
  }

  public static RepositoryProviderModule_ProvideUserRepositoryImplFactory create(
      Provider<UserApi> apiProvider) {
    return new RepositoryProviderModule_ProvideUserRepositoryImplFactory(apiProvider);
  }

  public static UserRepositoryImpl provideUserRepositoryImpl(UserApi api) {
    return Preconditions.checkNotNullFromProvides(RepositoryProviderModule.INSTANCE.provideUserRepositoryImpl(api));
  }
}
