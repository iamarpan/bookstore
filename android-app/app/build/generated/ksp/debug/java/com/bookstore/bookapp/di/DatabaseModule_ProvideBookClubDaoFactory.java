package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.local.BookShareDatabase;
import com.bookstore.bookapp.data.local.dao.BookClubDao;
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
public final class DatabaseModule_ProvideBookClubDaoFactory implements Factory<BookClubDao> {
  private final Provider<BookShareDatabase> databaseProvider;

  public DatabaseModule_ProvideBookClubDaoFactory(Provider<BookShareDatabase> databaseProvider) {
    this.databaseProvider = databaseProvider;
  }

  @Override
  public BookClubDao get() {
    return provideBookClubDao(databaseProvider.get());
  }

  public static DatabaseModule_ProvideBookClubDaoFactory create(
      Provider<BookShareDatabase> databaseProvider) {
    return new DatabaseModule_ProvideBookClubDaoFactory(databaseProvider);
  }

  public static BookClubDao provideBookClubDao(BookShareDatabase database) {
    return Preconditions.checkNotNullFromProvides(DatabaseModule.INSTANCE.provideBookClubDao(database));
  }
}
