package com.bookstore.bookapp.presentation.viewmodel;

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
public final class DiscoverGroupsViewModel_Factory implements Factory<DiscoverGroupsViewModel> {
  private final Provider<GroupRepository> groupRepositoryProvider;

  public DiscoverGroupsViewModel_Factory(Provider<GroupRepository> groupRepositoryProvider) {
    this.groupRepositoryProvider = groupRepositoryProvider;
  }

  @Override
  public DiscoverGroupsViewModel get() {
    return newInstance(groupRepositoryProvider.get());
  }

  public static DiscoverGroupsViewModel_Factory create(
      Provider<GroupRepository> groupRepositoryProvider) {
    return new DiscoverGroupsViewModel_Factory(groupRepositoryProvider);
  }

  public static DiscoverGroupsViewModel newInstance(GroupRepository groupRepository) {
    return new DiscoverGroupsViewModel(groupRepository);
  }
}
