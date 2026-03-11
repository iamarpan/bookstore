package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.remote.api.NotificationApi;
import com.bookstore.bookapp.data.repository.NotificationRepositoryImpl;
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
public final class RepositoryProviderModule_ProvideNotificationRepositoryImplFactory implements Factory<NotificationRepositoryImpl> {
  private final Provider<NotificationApi> apiProvider;

  public RepositoryProviderModule_ProvideNotificationRepositoryImplFactory(
      Provider<NotificationApi> apiProvider) {
    this.apiProvider = apiProvider;
  }

  @Override
  public NotificationRepositoryImpl get() {
    return provideNotificationRepositoryImpl(apiProvider.get());
  }

  public static RepositoryProviderModule_ProvideNotificationRepositoryImplFactory create(
      Provider<NotificationApi> apiProvider) {
    return new RepositoryProviderModule_ProvideNotificationRepositoryImplFactory(apiProvider);
  }

  public static NotificationRepositoryImpl provideNotificationRepositoryImpl(NotificationApi api) {
    return Preconditions.checkNotNullFromProvides(RepositoryProviderModule.INSTANCE.provideNotificationRepositoryImpl(api));
  }
}
