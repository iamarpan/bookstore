package com.bookstore.bookapp.presentation.viewmodel;

import com.bookstore.bookapp.domain.repository.BookRepository;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata
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
public final class AddBookViewModel_Factory implements Factory<AddBookViewModel> {
  private final Provider<BookRepository> bookRepositoryProvider;

  public AddBookViewModel_Factory(Provider<BookRepository> bookRepositoryProvider) {
    this.bookRepositoryProvider = bookRepositoryProvider;
  }

  @Override
  public AddBookViewModel get() {
    return newInstance(bookRepositoryProvider.get());
  }

  public static AddBookViewModel_Factory create(Provider<BookRepository> bookRepositoryProvider) {
    return new AddBookViewModel_Factory(bookRepositoryProvider);
  }

  public static AddBookViewModel newInstance(BookRepository bookRepository) {
    return new AddBookViewModel(bookRepository);
  }
}
