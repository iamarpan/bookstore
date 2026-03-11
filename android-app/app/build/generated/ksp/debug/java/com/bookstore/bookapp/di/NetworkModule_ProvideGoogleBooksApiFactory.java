package com.bookstore.bookapp.di;

import com.bookstore.bookapp.data.remote.api.GoogleBooksApi;
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
public final class NetworkModule_ProvideGoogleBooksApiFactory implements Factory<GoogleBooksApi> {
  private final Provider<Retrofit> retrofitProvider;

  public NetworkModule_ProvideGoogleBooksApiFactory(Provider<Retrofit> retrofitProvider) {
    this.retrofitProvider = retrofitProvider;
  }

  @Override
  public GoogleBooksApi get() {
    return provideGoogleBooksApi(retrofitProvider.get());
  }

  public static NetworkModule_ProvideGoogleBooksApiFactory create(
      Provider<Retrofit> retrofitProvider) {
    return new NetworkModule_ProvideGoogleBooksApiFactory(retrofitProvider);
  }

  public static GoogleBooksApi provideGoogleBooksApi(Retrofit retrofit) {
    return Preconditions.checkNotNullFromProvides(NetworkModule.INSTANCE.provideGoogleBooksApi(retrofit));
  }
}
