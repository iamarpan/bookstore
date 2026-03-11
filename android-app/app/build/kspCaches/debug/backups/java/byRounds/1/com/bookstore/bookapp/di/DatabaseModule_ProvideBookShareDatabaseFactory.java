package com.bookstore.bookapp.di;

import android.content.Context;
import com.bookstore.bookapp.data.local.BookShareDatabase;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata("dagger.hilt.android.qualifiers.ApplicationContext")
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
public final class DatabaseModule_ProvideBookShareDatabaseFactory implements Factory<BookShareDatabase> {
  private final Provider<Context> contextProvider;

  public DatabaseModule_ProvideBookShareDatabaseFactory(Provider<Context> contextProvider) {
    this.contextProvider = contextProvider;
  }

  @Override
  public BookShareDatabase get() {
    return provideBookShareDatabase(contextProvider.get());
  }

  public static DatabaseModule_ProvideBookShareDatabaseFactory create(
      Provider<Context> contextProvider) {
    return new DatabaseModule_ProvideBookShareDatabaseFactory(contextProvider);
  }

  public static BookShareDatabase provideBookShareDatabase(Context context) {
    return Preconditions.checkNotNullFromProvides(DatabaseModule.INSTANCE.provideBookShareDatabase(context));
  }
}
