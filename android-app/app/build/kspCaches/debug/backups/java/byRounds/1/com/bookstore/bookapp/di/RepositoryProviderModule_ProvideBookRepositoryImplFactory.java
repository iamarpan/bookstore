package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.local.dao.BookDao;
import com.bookstore.bookapp.data.remote.api.BookApi;
import com.bookstore.bookapp.data.remote.api.GoogleBooksApi;
import com.bookstore.bookapp.data.repository.BookRepositoryImpl;
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
public final class RepositoryProviderModule_ProvideBookRepositoryImplFactory implements Factory<BookRepositoryImpl> {
  private final Provider<BookApi> apiProvider;

  private final Provider<BookDao> daoProvider;

  private final Provider<GoogleBooksApi> googleApiProvider;

  public RepositoryProviderModule_ProvideBookRepositoryImplFactory(Provider<BookApi> apiProvider,
      Provider<BookDao> daoProvider, Provider<GoogleBooksApi> googleApiProvider) {
    this.apiProvider = apiProvider;
    this.daoProvider = daoProvider;
    this.googleApiProvider = googleApiProvider;
  }

  @Override
  public BookRepositoryImpl get() {
    return provideBookRepositoryImpl(apiProvider.get(), daoProvider.get(), googleApiProvider.get());
  }

  public static RepositoryProviderModule_ProvideBookRepositoryImplFactory create(
      Provider<BookApi> apiProvider, Provider<BookDao> daoProvider,
      Provider<GoogleBooksApi> googleApiProvider) {
    return new RepositoryProviderModule_ProvideBookRepositoryImplFactory(apiProvider, daoProvider, googleApiProvider);
  }

  public static BookRepositoryImpl provideBookRepositoryImpl(BookApi api, BookDao dao,
      GoogleBooksApi googleApi) {
    return Preconditions.checkNotNullFromProvides(RepositoryProviderModule.INSTANCE.provideBookRepositoryImpl(api, dao, googleApi));
  }
}
