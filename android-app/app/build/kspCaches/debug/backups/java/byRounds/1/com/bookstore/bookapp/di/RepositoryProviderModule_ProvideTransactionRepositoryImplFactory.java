package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.local.dao.TransactionDao;
import com.bookstore.bookapp.data.remote.api.TransactionApi;
import com.bookstore.bookapp.data.repository.TransactionRepositoryImpl;
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
public final class RepositoryProviderModule_ProvideTransactionRepositoryImplFactory implements Factory<TransactionRepositoryImpl> {
  private final Provider<TransactionApi> apiProvider;

  private final Provider<TransactionDao> daoProvider;

  public RepositoryProviderModule_ProvideTransactionRepositoryImplFactory(
      Provider<TransactionApi> apiProvider, Provider<TransactionDao> daoProvider) {
    this.apiProvider = apiProvider;
    this.daoProvider = daoProvider;
  }

  @Override
  public TransactionRepositoryImpl get() {
    return provideTransactionRepositoryImpl(apiProvider.get(), daoProvider.get());
  }

  public static RepositoryProviderModule_ProvideTransactionRepositoryImplFactory create(
      Provider<TransactionApi> apiProvider, Provider<TransactionDao> daoProvider) {
    return new RepositoryProviderModule_ProvideTransactionRepositoryImplFactory(apiProvider, daoProvider);
  }

  public static TransactionRepositoryImpl provideTransactionRepositoryImpl(TransactionApi api,
      TransactionDao dao) {
    return Preconditions.checkNotNullFromProvides(RepositoryProviderModule.INSTANCE.provideTransactionRepositoryImpl(api, dao));
  }
}
