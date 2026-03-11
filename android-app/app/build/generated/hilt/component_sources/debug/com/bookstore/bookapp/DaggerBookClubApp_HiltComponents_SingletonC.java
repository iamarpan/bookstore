package com.bookstore.bookapp;

import android.app.Activity;
import android.app.Service;
import android.view.View;
import androidx.fragment.app.Fragment;
import androidx.lifecycle.SavedStateHandle;
import androidx.lifecycle.ViewModel;
import com.bookstore.bookapp.data.local.BookShareDatabase;
import com.bookstore.bookapp.data.local.UserPreferences;
import com.bookstore.bookapp.data.local.dao.BookClubDao;
import com.bookstore.bookapp.data.local.dao.BookDao;
import com.bookstore.bookapp.data.local.dao.TransactionDao;
import com.bookstore.bookapp.data.remote.api.AuthApi;
import com.bookstore.bookapp.data.remote.api.BookApi;
import com.bookstore.bookapp.data.remote.api.GoogleBooksApi;
import com.bookstore.bookapp.data.remote.api.GroupApi;
import com.bookstore.bookapp.data.remote.api.TransactionApi;
import com.bookstore.bookapp.data.repository.AuthRepositoryImpl;
import com.bookstore.bookapp.data.repository.BookRepositoryImpl;
import com.bookstore.bookapp.data.repository.GroupRepositoryImpl;
import com.bookstore.bookapp.data.repository.TransactionRepositoryImpl;
import com.bookstore.bookapp.di.AppModule_ProvideUserPreferencesFactory;
import com.bookstore.bookapp.di.DatabaseModule_ProvideBookClubDaoFactory;
import com.bookstore.bookapp.di.DatabaseModule_ProvideBookDaoFactory;
import com.bookstore.bookapp.di.DatabaseModule_ProvideBookShareDatabaseFactory;
import com.bookstore.bookapp.di.DatabaseModule_ProvideTransactionDaoFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideAuthApiFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideAuthInterceptorFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideBookApiFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideGoogleBooksApiFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideGoogleBooksRetrofitFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideGroupApiFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideOkHttpClientFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideRetrofitFactory;
import com.bookstore.bookapp.di.NetworkModule_ProvideTransactionApiFactory;
import com.bookstore.bookapp.di.RepositoryProviderModule_ProvideAuthRepositoryImplFactory;
import com.bookstore.bookapp.di.RepositoryProviderModule_ProvideBookRepositoryImplFactory;
import com.bookstore.bookapp.di.RepositoryProviderModule_ProvideGroupRepositoryImplFactory;
import com.bookstore.bookapp.di.RepositoryProviderModule_ProvideTransactionRepositoryImplFactory;
import com.bookstore.bookapp.presentation.viewmodel.AddBookViewModel;
import com.bookstore.bookapp.presentation.viewmodel.AddBookViewModel_HiltModules;
import com.bookstore.bookapp.presentation.viewmodel.AuthViewModel;
import com.bookstore.bookapp.presentation.viewmodel.AuthViewModel_HiltModules;
import com.bookstore.bookapp.presentation.viewmodel.BookDetailViewModel;
import com.bookstore.bookapp.presentation.viewmodel.BookDetailViewModel_HiltModules;
import com.bookstore.bookapp.presentation.viewmodel.DiscoverGroupsViewModel;
import com.bookstore.bookapp.presentation.viewmodel.DiscoverGroupsViewModel_HiltModules;
import com.bookstore.bookapp.presentation.viewmodel.HomeViewModel;
import com.bookstore.bookapp.presentation.viewmodel.HomeViewModel_HiltModules;
import com.bookstore.bookapp.presentation.viewmodel.MyLibraryViewModel;
import com.bookstore.bookapp.presentation.viewmodel.MyLibraryViewModel_HiltModules;
import com.bookstore.bookapp.presentation.viewmodel.ProfileViewModel;
import com.bookstore.bookapp.presentation.viewmodel.ProfileViewModel_HiltModules;
import dagger.hilt.android.ActivityRetainedLifecycle;
import dagger.hilt.android.ViewModelLifecycle;
import dagger.hilt.android.internal.builders.ActivityComponentBuilder;
import dagger.hilt.android.internal.builders.ActivityRetainedComponentBuilder;
import dagger.hilt.android.internal.builders.FragmentComponentBuilder;
import dagger.hilt.android.internal.builders.ServiceComponentBuilder;
import dagger.hilt.android.internal.builders.ViewComponentBuilder;
import dagger.hilt.android.internal.builders.ViewModelComponentBuilder;
import dagger.hilt.android.internal.builders.ViewWithFragmentComponentBuilder;
import dagger.hilt.android.internal.lifecycle.DefaultViewModelFactories;
import dagger.hilt.android.internal.lifecycle.DefaultViewModelFactories_InternalFactoryFactory_Factory;
import dagger.hilt.android.internal.managers.ActivityRetainedComponentManager_LifecycleModule_ProvideActivityRetainedLifecycleFactory;
import dagger.hilt.android.internal.managers.SavedStateHandleHolder;
import dagger.hilt.android.internal.modules.ApplicationContextModule;
import dagger.hilt.android.internal.modules.ApplicationContextModule_ProvideContextFactory;
import dagger.internal.DaggerGenerated;
import dagger.internal.DoubleCheck;
import dagger.internal.IdentifierNameString;
import dagger.internal.KeepFieldType;
import dagger.internal.LazyClassKeyMap;
import dagger.internal.MapBuilder;
import dagger.internal.Preconditions;
import dagger.internal.Provider;
import java.util.Collections;
import java.util.Map;
import java.util.Set;
import javax.annotation.processing.Generated;
import okhttp3.Interceptor;
import okhttp3.OkHttpClient;
import retrofit2.Retrofit;

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
public final class DaggerBookClubApp_HiltComponents_SingletonC {
  private DaggerBookClubApp_HiltComponents_SingletonC() {
  }

  public static Builder builder() {
    return new Builder();
  }

  public static final class Builder {
    private ApplicationContextModule applicationContextModule;

    private Builder() {
    }

    public Builder applicationContextModule(ApplicationContextModule applicationContextModule) {
      this.applicationContextModule = Preconditions.checkNotNull(applicationContextModule);
      return this;
    }

    public BookClubApp_HiltComponents.SingletonC build() {
      Preconditions.checkBuilderRequirement(applicationContextModule, ApplicationContextModule.class);
      return new SingletonCImpl(applicationContextModule);
    }
  }

  private static final class ActivityRetainedCBuilder implements BookClubApp_HiltComponents.ActivityRetainedC.Builder {
    private final SingletonCImpl singletonCImpl;

    private SavedStateHandleHolder savedStateHandleHolder;

    private ActivityRetainedCBuilder(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;
    }

    @Override
    public ActivityRetainedCBuilder savedStateHandleHolder(
        SavedStateHandleHolder savedStateHandleHolder) {
      this.savedStateHandleHolder = Preconditions.checkNotNull(savedStateHandleHolder);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.ActivityRetainedC build() {
      Preconditions.checkBuilderRequirement(savedStateHandleHolder, SavedStateHandleHolder.class);
      return new ActivityRetainedCImpl(singletonCImpl, savedStateHandleHolder);
    }
  }

  private static final class ActivityCBuilder implements BookClubApp_HiltComponents.ActivityC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private Activity activity;

    private ActivityCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
    }

    @Override
    public ActivityCBuilder activity(Activity activity) {
      this.activity = Preconditions.checkNotNull(activity);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.ActivityC build() {
      Preconditions.checkBuilderRequirement(activity, Activity.class);
      return new ActivityCImpl(singletonCImpl, activityRetainedCImpl, activity);
    }
  }

  private static final class FragmentCBuilder implements BookClubApp_HiltComponents.FragmentC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private Fragment fragment;

    private FragmentCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
    }

    @Override
    public FragmentCBuilder fragment(Fragment fragment) {
      this.fragment = Preconditions.checkNotNull(fragment);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.FragmentC build() {
      Preconditions.checkBuilderRequirement(fragment, Fragment.class);
      return new FragmentCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, fragment);
    }
  }

  private static final class ViewWithFragmentCBuilder implements BookClubApp_HiltComponents.ViewWithFragmentC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl;

    private View view;

    private ViewWithFragmentCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        FragmentCImpl fragmentCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
      this.fragmentCImpl = fragmentCImpl;
    }

    @Override
    public ViewWithFragmentCBuilder view(View view) {
      this.view = Preconditions.checkNotNull(view);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.ViewWithFragmentC build() {
      Preconditions.checkBuilderRequirement(view, View.class);
      return new ViewWithFragmentCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, fragmentCImpl, view);
    }
  }

  private static final class ViewCBuilder implements BookClubApp_HiltComponents.ViewC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private View view;

    private ViewCBuilder(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
        ActivityCImpl activityCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
    }

    @Override
    public ViewCBuilder view(View view) {
      this.view = Preconditions.checkNotNull(view);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.ViewC build() {
      Preconditions.checkBuilderRequirement(view, View.class);
      return new ViewCImpl(singletonCImpl, activityRetainedCImpl, activityCImpl, view);
    }
  }

  private static final class ViewModelCBuilder implements BookClubApp_HiltComponents.ViewModelC.Builder {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private SavedStateHandle savedStateHandle;

    private ViewModelLifecycle viewModelLifecycle;

    private ViewModelCBuilder(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
    }

    @Override
    public ViewModelCBuilder savedStateHandle(SavedStateHandle handle) {
      this.savedStateHandle = Preconditions.checkNotNull(handle);
      return this;
    }

    @Override
    public ViewModelCBuilder viewModelLifecycle(ViewModelLifecycle viewModelLifecycle) {
      this.viewModelLifecycle = Preconditions.checkNotNull(viewModelLifecycle);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.ViewModelC build() {
      Preconditions.checkBuilderRequirement(savedStateHandle, SavedStateHandle.class);
      Preconditions.checkBuilderRequirement(viewModelLifecycle, ViewModelLifecycle.class);
      return new ViewModelCImpl(singletonCImpl, activityRetainedCImpl, savedStateHandle, viewModelLifecycle);
    }
  }

  private static final class ServiceCBuilder implements BookClubApp_HiltComponents.ServiceC.Builder {
    private final SingletonCImpl singletonCImpl;

    private Service service;

    private ServiceCBuilder(SingletonCImpl singletonCImpl) {
      this.singletonCImpl = singletonCImpl;
    }

    @Override
    public ServiceCBuilder service(Service service) {
      this.service = Preconditions.checkNotNull(service);
      return this;
    }

    @Override
    public BookClubApp_HiltComponents.ServiceC build() {
      Preconditions.checkBuilderRequirement(service, Service.class);
      return new ServiceCImpl(singletonCImpl, service);
    }
  }

  private static final class ViewWithFragmentCImpl extends BookClubApp_HiltComponents.ViewWithFragmentC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl;

    private final ViewWithFragmentCImpl viewWithFragmentCImpl = this;

    private ViewWithFragmentCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        FragmentCImpl fragmentCImpl, View viewParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;
      this.fragmentCImpl = fragmentCImpl;


    }
  }

  private static final class FragmentCImpl extends BookClubApp_HiltComponents.FragmentC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final FragmentCImpl fragmentCImpl = this;

    private FragmentCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, ActivityCImpl activityCImpl,
        Fragment fragmentParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;


    }

    @Override
    public DefaultViewModelFactories.InternalFactoryFactory getHiltInternalFactoryFactory() {
      return activityCImpl.getHiltInternalFactoryFactory();
    }

    @Override
    public ViewWithFragmentComponentBuilder viewWithFragmentComponentBuilder() {
      return new ViewWithFragmentCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl, fragmentCImpl);
    }
  }

  private static final class ViewCImpl extends BookClubApp_HiltComponents.ViewC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl;

    private final ViewCImpl viewCImpl = this;

    private ViewCImpl(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
        ActivityCImpl activityCImpl, View viewParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.activityCImpl = activityCImpl;


    }
  }

  private static final class ActivityCImpl extends BookClubApp_HiltComponents.ActivityC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ActivityCImpl activityCImpl = this;

    private ActivityCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, Activity activityParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;


    }

    @Override
    public void injectMainActivity(MainActivity mainActivity) {
    }

    @Override
    public DefaultViewModelFactories.InternalFactoryFactory getHiltInternalFactoryFactory() {
      return DefaultViewModelFactories_InternalFactoryFactory_Factory.newInstance(getViewModelKeys(), new ViewModelCBuilder(singletonCImpl, activityRetainedCImpl));
    }

    @Override
    public Map<Class<?>, Boolean> getViewModelKeys() {
      return LazyClassKeyMap.<Boolean>of(MapBuilder.<String, Boolean>newMapBuilder(7).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_AddBookViewModel, AddBookViewModel_HiltModules.KeyModule.provide()).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_AuthViewModel, AuthViewModel_HiltModules.KeyModule.provide()).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_BookDetailViewModel, BookDetailViewModel_HiltModules.KeyModule.provide()).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_DiscoverGroupsViewModel, DiscoverGroupsViewModel_HiltModules.KeyModule.provide()).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_HomeViewModel, HomeViewModel_HiltModules.KeyModule.provide()).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_MyLibraryViewModel, MyLibraryViewModel_HiltModules.KeyModule.provide()).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_ProfileViewModel, ProfileViewModel_HiltModules.KeyModule.provide()).build());
    }

    @Override
    public ViewModelComponentBuilder getViewModelComponentBuilder() {
      return new ViewModelCBuilder(singletonCImpl, activityRetainedCImpl);
    }

    @Override
    public FragmentComponentBuilder fragmentComponentBuilder() {
      return new FragmentCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl);
    }

    @Override
    public ViewComponentBuilder viewComponentBuilder() {
      return new ViewCBuilder(singletonCImpl, activityRetainedCImpl, activityCImpl);
    }

    @IdentifierNameString
    private static final class LazyClassKeyProvider {
      static String com_bookstore_bookapp_presentation_viewmodel_AddBookViewModel = "com.bookstore.bookapp.presentation.viewmodel.AddBookViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_MyLibraryViewModel = "com.bookstore.bookapp.presentation.viewmodel.MyLibraryViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_BookDetailViewModel = "com.bookstore.bookapp.presentation.viewmodel.BookDetailViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_AuthViewModel = "com.bookstore.bookapp.presentation.viewmodel.AuthViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_HomeViewModel = "com.bookstore.bookapp.presentation.viewmodel.HomeViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_DiscoverGroupsViewModel = "com.bookstore.bookapp.presentation.viewmodel.DiscoverGroupsViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_ProfileViewModel = "com.bookstore.bookapp.presentation.viewmodel.ProfileViewModel";

      @KeepFieldType
      AddBookViewModel com_bookstore_bookapp_presentation_viewmodel_AddBookViewModel2;

      @KeepFieldType
      MyLibraryViewModel com_bookstore_bookapp_presentation_viewmodel_MyLibraryViewModel2;

      @KeepFieldType
      BookDetailViewModel com_bookstore_bookapp_presentation_viewmodel_BookDetailViewModel2;

      @KeepFieldType
      AuthViewModel com_bookstore_bookapp_presentation_viewmodel_AuthViewModel2;

      @KeepFieldType
      HomeViewModel com_bookstore_bookapp_presentation_viewmodel_HomeViewModel2;

      @KeepFieldType
      DiscoverGroupsViewModel com_bookstore_bookapp_presentation_viewmodel_DiscoverGroupsViewModel2;

      @KeepFieldType
      ProfileViewModel com_bookstore_bookapp_presentation_viewmodel_ProfileViewModel2;
    }
  }

  private static final class ViewModelCImpl extends BookClubApp_HiltComponents.ViewModelC {
    private final SavedStateHandle savedStateHandle;

    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl;

    private final ViewModelCImpl viewModelCImpl = this;

    private Provider<AddBookViewModel> addBookViewModelProvider;

    private Provider<AuthViewModel> authViewModelProvider;

    private Provider<BookDetailViewModel> bookDetailViewModelProvider;

    private Provider<DiscoverGroupsViewModel> discoverGroupsViewModelProvider;

    private Provider<HomeViewModel> homeViewModelProvider;

    private Provider<MyLibraryViewModel> myLibraryViewModelProvider;

    private Provider<ProfileViewModel> profileViewModelProvider;

    private ViewModelCImpl(SingletonCImpl singletonCImpl,
        ActivityRetainedCImpl activityRetainedCImpl, SavedStateHandle savedStateHandleParam,
        ViewModelLifecycle viewModelLifecycleParam) {
      this.singletonCImpl = singletonCImpl;
      this.activityRetainedCImpl = activityRetainedCImpl;
      this.savedStateHandle = savedStateHandleParam;
      initialize(savedStateHandleParam, viewModelLifecycleParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final SavedStateHandle savedStateHandleParam,
        final ViewModelLifecycle viewModelLifecycleParam) {
      this.addBookViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 0);
      this.authViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 1);
      this.bookDetailViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 2);
      this.discoverGroupsViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 3);
      this.homeViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 4);
      this.myLibraryViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 5);
      this.profileViewModelProvider = new SwitchingProvider<>(singletonCImpl, activityRetainedCImpl, viewModelCImpl, 6);
    }

    @Override
    public Map<Class<?>, javax.inject.Provider<ViewModel>> getHiltViewModelMap() {
      return LazyClassKeyMap.<javax.inject.Provider<ViewModel>>of(MapBuilder.<String, javax.inject.Provider<ViewModel>>newMapBuilder(7).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_AddBookViewModel, ((Provider) addBookViewModelProvider)).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_AuthViewModel, ((Provider) authViewModelProvider)).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_BookDetailViewModel, ((Provider) bookDetailViewModelProvider)).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_DiscoverGroupsViewModel, ((Provider) discoverGroupsViewModelProvider)).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_HomeViewModel, ((Provider) homeViewModelProvider)).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_MyLibraryViewModel, ((Provider) myLibraryViewModelProvider)).put(LazyClassKeyProvider.com_bookstore_bookapp_presentation_viewmodel_ProfileViewModel, ((Provider) profileViewModelProvider)).build());
    }

    @Override
    public Map<Class<?>, Object> getHiltViewModelAssistedMap() {
      return Collections.<Class<?>, Object>emptyMap();
    }

    @IdentifierNameString
    private static final class LazyClassKeyProvider {
      static String com_bookstore_bookapp_presentation_viewmodel_DiscoverGroupsViewModel = "com.bookstore.bookapp.presentation.viewmodel.DiscoverGroupsViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_ProfileViewModel = "com.bookstore.bookapp.presentation.viewmodel.ProfileViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_HomeViewModel = "com.bookstore.bookapp.presentation.viewmodel.HomeViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_AddBookViewModel = "com.bookstore.bookapp.presentation.viewmodel.AddBookViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_MyLibraryViewModel = "com.bookstore.bookapp.presentation.viewmodel.MyLibraryViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_AuthViewModel = "com.bookstore.bookapp.presentation.viewmodel.AuthViewModel";

      static String com_bookstore_bookapp_presentation_viewmodel_BookDetailViewModel = "com.bookstore.bookapp.presentation.viewmodel.BookDetailViewModel";

      @KeepFieldType
      DiscoverGroupsViewModel com_bookstore_bookapp_presentation_viewmodel_DiscoverGroupsViewModel2;

      @KeepFieldType
      ProfileViewModel com_bookstore_bookapp_presentation_viewmodel_ProfileViewModel2;

      @KeepFieldType
      HomeViewModel com_bookstore_bookapp_presentation_viewmodel_HomeViewModel2;

      @KeepFieldType
      AddBookViewModel com_bookstore_bookapp_presentation_viewmodel_AddBookViewModel2;

      @KeepFieldType
      MyLibraryViewModel com_bookstore_bookapp_presentation_viewmodel_MyLibraryViewModel2;

      @KeepFieldType
      AuthViewModel com_bookstore_bookapp_presentation_viewmodel_AuthViewModel2;

      @KeepFieldType
      BookDetailViewModel com_bookstore_bookapp_presentation_viewmodel_BookDetailViewModel2;
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final ActivityRetainedCImpl activityRetainedCImpl;

      private final ViewModelCImpl viewModelCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
          ViewModelCImpl viewModelCImpl, int id) {
        this.singletonCImpl = singletonCImpl;
        this.activityRetainedCImpl = activityRetainedCImpl;
        this.viewModelCImpl = viewModelCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // com.bookstore.bookapp.presentation.viewmodel.AddBookViewModel 
          return (T) new AddBookViewModel(singletonCImpl.provideBookRepositoryImplProvider.get());

          case 1: // com.bookstore.bookapp.presentation.viewmodel.AuthViewModel 
          return (T) new AuthViewModel(singletonCImpl.provideAuthRepositoryImplProvider.get());

          case 2: // com.bookstore.bookapp.presentation.viewmodel.BookDetailViewModel 
          return (T) new BookDetailViewModel(singletonCImpl.provideBookRepositoryImplProvider.get(), singletonCImpl.provideTransactionRepositoryImplProvider.get(), viewModelCImpl.savedStateHandle);

          case 3: // com.bookstore.bookapp.presentation.viewmodel.DiscoverGroupsViewModel 
          return (T) new DiscoverGroupsViewModel(singletonCImpl.provideGroupRepositoryImplProvider.get());

          case 4: // com.bookstore.bookapp.presentation.viewmodel.HomeViewModel 
          return (T) new HomeViewModel(singletonCImpl.provideBookRepositoryImplProvider.get(), singletonCImpl.provideGroupRepositoryImplProvider.get());

          case 5: // com.bookstore.bookapp.presentation.viewmodel.MyLibraryViewModel 
          return (T) new MyLibraryViewModel(singletonCImpl.provideBookRepositoryImplProvider.get(), singletonCImpl.provideTransactionRepositoryImplProvider.get());

          case 6: // com.bookstore.bookapp.presentation.viewmodel.ProfileViewModel 
          return (T) new ProfileViewModel(singletonCImpl.provideAuthRepositoryImplProvider.get());

          default: throw new AssertionError(id);
        }
      }
    }
  }

  private static final class ActivityRetainedCImpl extends BookClubApp_HiltComponents.ActivityRetainedC {
    private final SingletonCImpl singletonCImpl;

    private final ActivityRetainedCImpl activityRetainedCImpl = this;

    private Provider<ActivityRetainedLifecycle> provideActivityRetainedLifecycleProvider;

    private ActivityRetainedCImpl(SingletonCImpl singletonCImpl,
        SavedStateHandleHolder savedStateHandleHolderParam) {
      this.singletonCImpl = singletonCImpl;

      initialize(savedStateHandleHolderParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final SavedStateHandleHolder savedStateHandleHolderParam) {
      this.provideActivityRetainedLifecycleProvider = DoubleCheck.provider(new SwitchingProvider<ActivityRetainedLifecycle>(singletonCImpl, activityRetainedCImpl, 0));
    }

    @Override
    public ActivityComponentBuilder activityComponentBuilder() {
      return new ActivityCBuilder(singletonCImpl, activityRetainedCImpl);
    }

    @Override
    public ActivityRetainedLifecycle getActivityRetainedLifecycle() {
      return provideActivityRetainedLifecycleProvider.get();
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final ActivityRetainedCImpl activityRetainedCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, ActivityRetainedCImpl activityRetainedCImpl,
          int id) {
        this.singletonCImpl = singletonCImpl;
        this.activityRetainedCImpl = activityRetainedCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // dagger.hilt.android.ActivityRetainedLifecycle 
          return (T) ActivityRetainedComponentManager_LifecycleModule_ProvideActivityRetainedLifecycleFactory.provideActivityRetainedLifecycle();

          default: throw new AssertionError(id);
        }
      }
    }
  }

  private static final class ServiceCImpl extends BookClubApp_HiltComponents.ServiceC {
    private final SingletonCImpl singletonCImpl;

    private final ServiceCImpl serviceCImpl = this;

    private ServiceCImpl(SingletonCImpl singletonCImpl, Service serviceParam) {
      this.singletonCImpl = singletonCImpl;


    }
  }

  private static final class SingletonCImpl extends BookClubApp_HiltComponents.SingletonC {
    private final ApplicationContextModule applicationContextModule;

    private final SingletonCImpl singletonCImpl = this;

    private Provider<UserPreferences> provideUserPreferencesProvider;

    private Provider<Interceptor> provideAuthInterceptorProvider;

    private Provider<OkHttpClient> provideOkHttpClientProvider;

    private Provider<Retrofit> provideRetrofitProvider;

    private Provider<BookApi> provideBookApiProvider;

    private Provider<BookShareDatabase> provideBookShareDatabaseProvider;

    private Provider<BookDao> provideBookDaoProvider;

    private Provider<Retrofit> provideGoogleBooksRetrofitProvider;

    private Provider<GoogleBooksApi> provideGoogleBooksApiProvider;

    private Provider<BookRepositoryImpl> provideBookRepositoryImplProvider;

    private Provider<AuthApi> provideAuthApiProvider;

    private Provider<AuthRepositoryImpl> provideAuthRepositoryImplProvider;

    private Provider<TransactionApi> provideTransactionApiProvider;

    private Provider<TransactionDao> provideTransactionDaoProvider;

    private Provider<TransactionRepositoryImpl> provideTransactionRepositoryImplProvider;

    private Provider<GroupApi> provideGroupApiProvider;

    private Provider<BookClubDao> provideBookClubDaoProvider;

    private Provider<GroupRepositoryImpl> provideGroupRepositoryImplProvider;

    private SingletonCImpl(ApplicationContextModule applicationContextModuleParam) {
      this.applicationContextModule = applicationContextModuleParam;
      initialize(applicationContextModuleParam);

    }

    @SuppressWarnings("unchecked")
    private void initialize(final ApplicationContextModule applicationContextModuleParam) {
      this.provideUserPreferencesProvider = DoubleCheck.provider(new SwitchingProvider<UserPreferences>(singletonCImpl, 5));
      this.provideAuthInterceptorProvider = DoubleCheck.provider(new SwitchingProvider<Interceptor>(singletonCImpl, 4));
      this.provideOkHttpClientProvider = DoubleCheck.provider(new SwitchingProvider<OkHttpClient>(singletonCImpl, 3));
      this.provideRetrofitProvider = DoubleCheck.provider(new SwitchingProvider<Retrofit>(singletonCImpl, 2));
      this.provideBookApiProvider = DoubleCheck.provider(new SwitchingProvider<BookApi>(singletonCImpl, 1));
      this.provideBookShareDatabaseProvider = DoubleCheck.provider(new SwitchingProvider<BookShareDatabase>(singletonCImpl, 7));
      this.provideBookDaoProvider = DoubleCheck.provider(new SwitchingProvider<BookDao>(singletonCImpl, 6));
      this.provideGoogleBooksRetrofitProvider = DoubleCheck.provider(new SwitchingProvider<Retrofit>(singletonCImpl, 9));
      this.provideGoogleBooksApiProvider = DoubleCheck.provider(new SwitchingProvider<GoogleBooksApi>(singletonCImpl, 8));
      this.provideBookRepositoryImplProvider = DoubleCheck.provider(new SwitchingProvider<BookRepositoryImpl>(singletonCImpl, 0));
      this.provideAuthApiProvider = DoubleCheck.provider(new SwitchingProvider<AuthApi>(singletonCImpl, 11));
      this.provideAuthRepositoryImplProvider = DoubleCheck.provider(new SwitchingProvider<AuthRepositoryImpl>(singletonCImpl, 10));
      this.provideTransactionApiProvider = DoubleCheck.provider(new SwitchingProvider<TransactionApi>(singletonCImpl, 13));
      this.provideTransactionDaoProvider = DoubleCheck.provider(new SwitchingProvider<TransactionDao>(singletonCImpl, 14));
      this.provideTransactionRepositoryImplProvider = DoubleCheck.provider(new SwitchingProvider<TransactionRepositoryImpl>(singletonCImpl, 12));
      this.provideGroupApiProvider = DoubleCheck.provider(new SwitchingProvider<GroupApi>(singletonCImpl, 16));
      this.provideBookClubDaoProvider = DoubleCheck.provider(new SwitchingProvider<BookClubDao>(singletonCImpl, 17));
      this.provideGroupRepositoryImplProvider = DoubleCheck.provider(new SwitchingProvider<GroupRepositoryImpl>(singletonCImpl, 15));
    }

    @Override
    public void injectBookClubApp(BookClubApp bookClubApp) {
    }

    @Override
    public Set<Boolean> getDisableFragmentGetContextFix() {
      return Collections.<Boolean>emptySet();
    }

    @Override
    public ActivityRetainedComponentBuilder retainedComponentBuilder() {
      return new ActivityRetainedCBuilder(singletonCImpl);
    }

    @Override
    public ServiceComponentBuilder serviceComponentBuilder() {
      return new ServiceCBuilder(singletonCImpl);
    }

    private static final class SwitchingProvider<T> implements Provider<T> {
      private final SingletonCImpl singletonCImpl;

      private final int id;

      SwitchingProvider(SingletonCImpl singletonCImpl, int id) {
        this.singletonCImpl = singletonCImpl;
        this.id = id;
      }

      @SuppressWarnings("unchecked")
      @Override
      public T get() {
        switch (id) {
          case 0: // com.bookstore.bookapp.data.repository.BookRepositoryImpl 
          return (T) RepositoryProviderModule_ProvideBookRepositoryImplFactory.provideBookRepositoryImpl(singletonCImpl.provideBookApiProvider.get(), singletonCImpl.provideBookDaoProvider.get(), singletonCImpl.provideGoogleBooksApiProvider.get());

          case 1: // com.bookstore.bookapp.data.remote.api.BookApi 
          return (T) NetworkModule_ProvideBookApiFactory.provideBookApi(singletonCImpl.provideRetrofitProvider.get());

          case 2: // @javax.inject.Named("MainRetrofit") retrofit2.Retrofit 
          return (T) NetworkModule_ProvideRetrofitFactory.provideRetrofit(singletonCImpl.provideOkHttpClientProvider.get());

          case 3: // okhttp3.OkHttpClient 
          return (T) NetworkModule_ProvideOkHttpClientFactory.provideOkHttpClient(singletonCImpl.provideAuthInterceptorProvider.get());

          case 4: // okhttp3.Interceptor 
          return (T) NetworkModule_ProvideAuthInterceptorFactory.provideAuthInterceptor(singletonCImpl.provideUserPreferencesProvider.get());

          case 5: // com.bookstore.bookapp.data.local.UserPreferences 
          return (T) AppModule_ProvideUserPreferencesFactory.provideUserPreferences(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 6: // com.bookstore.bookapp.data.local.dao.BookDao 
          return (T) DatabaseModule_ProvideBookDaoFactory.provideBookDao(singletonCImpl.provideBookShareDatabaseProvider.get());

          case 7: // com.bookstore.bookapp.data.local.BookShareDatabase 
          return (T) DatabaseModule_ProvideBookShareDatabaseFactory.provideBookShareDatabase(ApplicationContextModule_ProvideContextFactory.provideContext(singletonCImpl.applicationContextModule));

          case 8: // com.bookstore.bookapp.data.remote.api.GoogleBooksApi 
          return (T) NetworkModule_ProvideGoogleBooksApiFactory.provideGoogleBooksApi(singletonCImpl.provideGoogleBooksRetrofitProvider.get());

          case 9: // @javax.inject.Named("GoogleBooksRetrofit") retrofit2.Retrofit 
          return (T) NetworkModule_ProvideGoogleBooksRetrofitFactory.provideGoogleBooksRetrofit(singletonCImpl.provideOkHttpClientProvider.get());

          case 10: // com.bookstore.bookapp.data.repository.AuthRepositoryImpl 
          return (T) RepositoryProviderModule_ProvideAuthRepositoryImplFactory.provideAuthRepositoryImpl(singletonCImpl.provideAuthApiProvider.get(), singletonCImpl.provideUserPreferencesProvider.get());

          case 11: // com.bookstore.bookapp.data.remote.api.AuthApi 
          return (T) NetworkModule_ProvideAuthApiFactory.provideAuthApi(singletonCImpl.provideRetrofitProvider.get());

          case 12: // com.bookstore.bookapp.data.repository.TransactionRepositoryImpl 
          return (T) RepositoryProviderModule_ProvideTransactionRepositoryImplFactory.provideTransactionRepositoryImpl(singletonCImpl.provideTransactionApiProvider.get(), singletonCImpl.provideTransactionDaoProvider.get());

          case 13: // com.bookstore.bookapp.data.remote.api.TransactionApi 
          return (T) NetworkModule_ProvideTransactionApiFactory.provideTransactionApi(singletonCImpl.provideRetrofitProvider.get());

          case 14: // com.bookstore.bookapp.data.local.dao.TransactionDao 
          return (T) DatabaseModule_ProvideTransactionDaoFactory.provideTransactionDao(singletonCImpl.provideBookShareDatabaseProvider.get());

          case 15: // com.bookstore.bookapp.data.repository.GroupRepositoryImpl 
          return (T) RepositoryProviderModule_ProvideGroupRepositoryImplFactory.provideGroupRepositoryImpl(singletonCImpl.provideGroupApiProvider.get(), singletonCImpl.provideBookClubDaoProvider.get());

          case 16: // com.bookstore.bookapp.data.remote.api.GroupApi 
          return (T) NetworkModule_ProvideGroupApiFactory.provideGroupApi(singletonCImpl.provideRetrofitProvider.get());

          case 17: // com.bookstore.bookapp.data.local.dao.BookClubDao 
          return (T) DatabaseModule_ProvideBookClubDaoFactory.provideBookClubDao(singletonCImpl.provideBookShareDatabaseProvider.get());

          default: throw new AssertionError(id);
        }
      }
    }
  }
}
