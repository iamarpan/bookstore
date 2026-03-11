package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.local.dao.BookClubDao;
import com.bookstore.bookapp.data.remote.api.GroupApi;
import com.bookstore.bookapp.data.repository.GroupRepositoryImpl;
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
public final class RepositoryProviderModule_ProvideGroupRepositoryImplFactory implements Factory<GroupRepositoryImpl> {
  private final Provider<GroupApi> apiProvider;

  private final Provider<BookClubDao> daoProvider;

  public RepositoryProviderModule_ProvideGroupRepositoryImplFactory(Provider<GroupApi> apiProvider,
      Provider<BookClubDao> daoProvider) {
    this.apiProvider = apiProvider;
    this.daoProvider = daoProvider;
  }

  @Override
  public GroupRepositoryImpl get() {
    return provideGroupRepositoryImpl(apiProvider.get(), daoProvider.get());
  }

  public static RepositoryProviderModule_ProvideGroupRepositoryImplFactory create(
      Provider<GroupApi> apiProvider, Provider<BookClubDao> daoProvider) {
    return new RepositoryProviderModule_ProvideGroupRepositoryImplFactory(apiProvider, daoProvider);
  }

  public static GroupRepositoryImpl provideGroupRepositoryImpl(GroupApi api, BookClubDao dao) {
    return Preconditions.checkNotNullFromProvides(RepositoryProviderModule.INSTANCE.provideGroupRepositoryImpl(api, dao));
  }
}
