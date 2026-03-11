package com.bookstore.bookapp.presentation.viewmodel;

import androidx.lifecycle.SavedStateHandle;
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
public final class BookDetailViewModel_Factory implements Factory<BookDetailViewModel> {
  private final Provider<BookRepository> bookRepositoryProvider;

  private final Provider<TransactionRepository> transactionRepositoryProvider;

  private final Provider<SavedStateHandle> savedStateHandleProvider;

  public BookDetailViewModel_Factory(Provider<BookRepository> bookRepositoryProvider,
      Provider<TransactionRepository> transactionRepositoryProvider,
      Provider<SavedStateHandle> savedStateHandleProvider) {
    this.bookRepositoryProvider = bookRepositoryProvider;
    this.transactionRepositoryProvider = transactionRepositoryProvider;
    this.savedStateHandleProvider = savedStateHandleProvider;
  }

  @Override
  public BookDetailViewModel get() {
    return newInstance(bookRepositoryProvider.get(), transactionRepositoryProvider.get(), savedStateHandleProvider.get());
  }

  public static BookDetailViewModel_Factory create(Provider<BookRepository> bookRepositoryProvider,
      Provider<TransactionRepository> transactionRepositoryProvider,
      Provider<SavedStateHandle> savedStateHandleProvider) {
    return new BookDetailViewModel_Factory(bookRepositoryProvider, transactionRepositoryProvider, savedStateHandleProvider);
  }

  public static BookDetailViewModel newInstance(BookRepository bookRepository,
      TransactionRepository transactionRepository, SavedStateHandle savedStateHandle) {
    return new BookDetailViewModel(bookRepository, transactionRepository, savedStateHandle);
  }
}
