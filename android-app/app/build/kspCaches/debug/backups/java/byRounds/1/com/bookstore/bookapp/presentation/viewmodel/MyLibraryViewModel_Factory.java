package com.bookstore.bookapp.presentation.viewmodel;

import com.bookstore.bookapp.domain.repository.BookRepository;
import com.bookstore.bookapp.domain.repository.TransactionRepository;
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
public final class MyLibraryViewModel_Factory implements Factory<MyLibraryViewModel> {
  private final Provider<BookRepository> bookRepositoryProvider;

  private final Provider<TransactionRepository> transactionRepositoryProvider;

  public MyLibraryViewModel_Factory(Provider<BookRepository> bookRepositoryProvider,
      Provider<TransactionRepository> transactionRepositoryProvider) {
    this.bookRepositoryProvider = bookRepositoryProvider;
    this.transactionRepositoryProvider = transactionRepositoryProvider;
  }

  @Override
  public MyLibraryViewModel get() {
    return newInstance(bookRepositoryProvider.get(), transactionRepositoryProvider.get());
  }

  public static MyLibraryViewModel_Factory create(Provider<BookRepository> bookRepositoryProvider,
      Provider<TransactionRepository> transactionRepositoryProvider) {
    return new MyLibraryViewModel_Factory(bookRepositoryProvider, transactionRepositoryProvider);
  }

  public static MyLibraryViewModel newInstance(BookRepository bookRepository,
      TransactionRepository transactionRepository) {
    return new MyLibraryViewModel(bookRepository, transactionRepository);
  }
}
