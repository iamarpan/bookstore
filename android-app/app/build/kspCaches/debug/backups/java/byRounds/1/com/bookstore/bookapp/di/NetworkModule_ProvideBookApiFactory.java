package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.remote.api.BookApi;
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
public final class NetworkModule_ProvideBookApiFactory implements Factory<BookApi> {
  private final Provider<Retrofit> retrofitProvider;

  public NetworkModule_ProvideBookApiFactory(Provider<Retrofit> retrofitProvider) {
    this.retrofitProvider = retrofitProvider;
  }

  @Override
  public BookApi get() {
    return provideBookApi(retrofitProvider.get());
  }

  public static NetworkModule_ProvideBookApiFactory create(Provider<Retrofit> retrofitProvider) {
    return new NetworkModule_ProvideBookApiFactory(retrofitProvider);
  }

  public static BookApi provideBookApi(Retrofit retrofit) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideBookApi(retrofit));
  }
}
