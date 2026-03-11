package com.bookstore.bookapp.presentation.viewmodel;

import com.bookstore.bookapp.domain.repository.BookRepository;
import com.bookstore.bookapp.domain.repository.GroupRepository;
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
public final class HomeViewModel_Factory implements Factory<HomeViewModel> {
  private final Provider<BookRepository> bookRepositoryProvider;

  private final Provider<GroupRepository> groupRepositoryProvider;

  public HomeViewModel_Factory(Provider<BookRepository> bookRepositoryProvider,
      Provider<GroupRepository> groupRepositoryProvider) {
    this.bookRepositoryProvider = bookRepositoryProvider;
    this.groupRepositoryProvider = groupRepositoryProvider;
  }

  @Override
  public HomeViewModel get() {
    return newInstance(bookRepositoryProvider.get(), groupRepositoryProvider.get());
  }

  public static HomeViewModel_Factory create(Provider<BookRepository> bookRepositoryProvider,
      Provider<GroupRepository> groupRepositoryProvider) {
    return new HomeViewModel_Factory(bookRepositoryProvider, groupRepositoryProvider);
  }

  public static HomeViewModel newInstance(BookRepository bookRepository,
      GroupRepository groupRepository) {
    return new HomeViewModel(bookRepository, groupRepository);
  }
}
