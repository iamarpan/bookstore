package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.remote.api.TransactionApi;
import dagger.internal.DaggerGenerated;
import dagger.internal.Factory;
import dagger.internal.Preconditions;
import dagger.internal.QualifierMetadata;
import dagger.internal.ScopeMetadata;
import javax.annotation.processing.Generated;
import javax.inject.Provider;
import retrofit2.Retrofit;

@ScopeMetadata("javax.inject.Singleton")
@QualifierMetadata("javax.inject.Named")
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
public final class NetworkModule_ProvideTransactionApiFactory implements Factory<TransactionApi> {
  private final Provider<Retrofit> retrofitProvider;

  public NetworkModule_ProvideTransactionApiFactory(Provider<Retrofit> retrofitProvider) {
    this.retrofitProvider = retrofitProvider;
  }

  @Override
  public TransactionApi get() {
    return provideTransactionApi(retrofitProvider.get());
  }

  public static NetworkModule_ProvideTransactionApiFactory create(
      Provider<Retrofit> retrofitProvider) {
    return new NetworkModule_ProvideTransactionApiFactory(retrofitProvider);
  }

  public static TransactionApi provideTransactionApi(Retrofit retrofit) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideTransactionApi(retrofit));
  }
}
