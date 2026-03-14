# BookShare App Redesign Implementation Plan

This plan breaks down the redesign document into actionable, atomic tasks grouped by feature and section.

## 1. Phase 1: Critical Fixes & General Corrections

**Affected Files & Components:**
- `strings.xml`, `AuthScreen.kt`
- `MainScreen.kt` (or BottomNav configuration)
- `ProfileScreen.kt`
- `MyLibraryScreen.kt`
- `NavGraph.kt`, `ui/GroupDetailScreen.kt`

**Atomic Tasks:**
1. Fix branding inconsistency by renaming "Book Club" to "BookShare" globally (`strings.xml`, `AuthScreen.kt`).
2. Fix the Groups tab icon from `Search` to `Groups`/`People` in the bottom navigation.
3. Fix the Library tab icon from `List` to `LocalLibrary` in the bottom navigation.
4. Replace generic `Icons.Default.Person` icons in `ProfileScreen.kt` with context-specific icons (`MenuBook`, `BookmarkAdded`, `Share`, `Star`, etc.).
5. Implement navigation on `MyLibraryScreen` book tap to route correctly.
6. Populate `TransactionList` on `MyLibraryScreen` with actual list items instead of just a raw count.
7. Build the `GroupDetailScreen` UI to replace the current placeholder and hook it into `NavGraph.kt`.

**Dependencies:**
- None. These are standalone critical fixes that can be tackled immediately to restore broken functionality.

**Risks & Considerations:**
- Hooking up the `GroupDetailScreen` may expose missing API or Repository layer dependencies if the backend integration wasn't ready.

## 2. Phase 2 & Foundation: Design System & Core Components

**Affected Files & Components:**
- `ui/theme/Color.kt`, `ui/theme/Type.kt`, `ui/theme/Theme.kt`
- New: `components/AvailabilityBadge.kt`, `components/ConditionIndicator.kt`, `components/PriceTag.kt`, `components/DistanceChip.kt`, `components/SearchBar.kt`, `components/SectionHeader.kt`, `components/HorizontalBookList.kt`, `components/EmptyState.kt`, `components/SkeletonLoader.kt`, `components/OwnerInfoCard.kt`, `components/LendingTermsCard.kt`, `components/StatusBanner.kt`, `components/UserAvatar.kt`

**Atomic Tasks:**
1. Update `Color.kt` with the new semantically rich color palette (`Primary`, `PrimaryVariant`, `Accent`, `SurfaceElevated`, `Available`, `Borrowed`, `Unavailable`, `Overdue`).
2. Update `Type.kt` with serif display fonts and enhanced typography styles (`displayLarge`).
3. Build atomic UI components: `AvailabilityBadge`, `ConditionIndicator`, `PriceTag`, `DistanceChip`, `UserAvatar`.
4. Build structural UI components: `SearchBar`, `SectionHeader`, `HorizontalBookList`, `EmptyState`, `SkeletonLoader`.
5. Build complex UI cards: `OwnerInfoCard`, `LendingTermsCard`, `StatusBanner`.

**Dependencies:**
- Minimal. This sets the foundation for Phase 3 and Phase 4.

**Risks & Considerations:**
- Modifying global `Color.kt` and `Type.kt` may have unintended visual side effects on existing screens not yet redesigned. We need to ensure backward compatibility or update old un-redesigned screens to use the new tokens gracefully.

## 3. Phase 3: Auth Screen Redesign

**Affected Files & Components:**
- `AuthScreen.kt`

**Atomic Tasks:**
1. Replace the generic launcher icon with the custom BookShare logo SVG.
2. Add a responsive illustration emphasizing "people sharing books in a circle".
3. Integrate a country code picker (`+91`) next to the phone number input field.
4. Add Terms of Service and Privacy Policy consent text/links at the bottom.
5. Apply a subtle gradient background.
6. Implement an animated logo effect on screen load.

**Dependencies:**
- Built after Design System updates (fonts/colors) are in place.

**Risks & Considerations:**
- Country code pickers can introduce complexity with keyboard interactions and phone number validation.

## 4. Phase 3: Enhanced Book Card

**Affected Files & Components:**
- `BookCard.kt`

**Atomic Tasks:**
1. Wrap the existing `AsyncImage` in a Box to allow absolute positioning of badge overlays.
2. Integrate `AvailabilityBadge` at the top right of the cover image.
3. Integrate `ConditionDots` at the bottom left of the cover image.
4. Implement `SkeletonLoader` shimmer effect while the image and data load.
5. Update text layout for the Title, Author, `PriceTag`, and `DistanceChip`.
6. Add physical press feedback (scale-down animation from `1f` to `0.95f` using `pointerInput`).

**Dependencies:**
- Strictly depends on Phase 2 (Foundation) completion for the badges, chips, and shimmer loader.

**Risks & Considerations:**
- `pointerInput` and custom animations may conflict with standard `clickable` accessibility semantics. Ensure standard actions still function.

## 5. Phase 3: Home Screen Redesign & Navigation

**Affected Files & Components:**
- `HomeScreen.kt`, `MainScreen.kt`

**Atomic Tasks:**
1. Update the bottom navigation layout to include a Floating Action Button (FAB) for the Add Book action.
2. Implement the persistent `SearchBar` component at the top of the Home Screen.
3. Refactor the main layout from a hardcoded grid to a `LazyColumn` for multiple curated sections.
4. Implement the "Continue Reading" horizontal carousel (`LazyRow` inside the column) using book covers.
5. Implement "Available Near You", "Popular in Your Groups", and "Recently Added" horizontal carousels using `EnhancedBookCard`.
6. Add custom pull-to-refresh mechanism with the book-flipping animation.

**Dependencies:**
- Depends on Phase 3 (`EnhancedBookCard`) and Phase 2 components (`SearchBar`, `SectionHeader`, `HorizontalBookList`).

**Risks & Considerations:**
- Multiple nested horizontal lists inside a vertical list can cause scrolling jank. Ensure proper use of the `key` parameter to allow items to recycle efficiently. 

## 6. Phase 3: Book Detail Screen Redesign

**Affected Files & Components:**
- `BookDetailScreen.kt`

**Atomic Tasks:**
1. Implement the Hero image section with the 3D tilt and shadow effect.
2. Add quick glance chips (condition, availability) below the hero image.
3. Integrate the `OwnerInfoCard` to display owner details and response time.
4. Integrate the `LendingTermsCard` to display pricing and duration rules.
5. Add the "Also in these groups" chip list.
6. Implement a sticky bottom action bar for `Request to Borrow` and `Message Owner`.
7. Configure shared element transition for the book cover spanning from the Home Screen to the Detail view.

**Dependencies:**
- Depends on Phase 2 components (`OwnerInfoCard`, `LendingTermsCard`).
- Shared transitions rely on `NavGraph.kt` configurations built on top of the Home Screen.

**Risks & Considerations:**
- Shared element transitions in Compose Navigation are experimental and can exhibit jitter or complex animation bugs if sizes don't match.

## 7. Phase 4: Remaining Profile Screen & Empty States Enhancements

**Affected Files & Components:**
- `ProfileScreen.kt`, multiple other screens supporting empty states.

**Atomic Tasks:**
1. Add a `UserAvatar` header showing the profile photo (with edit overlay) and location to the Profile Screen.
2. Implement the "Your Impact" statistics row.
3. Add toggles for Notifications and Dark Mode, wrapping them in reusable structural list items.
4. Integrate `EmptyState` components into `MyLibraryScreen` (e.g., "No active borrows") and `DiscoverGroupsScreen`.
5. Implement missing onboarding flow logic.

**Dependencies:**
- Partially depends on Phase 2 (`EmptyState`, `UserAvatar`).

**Risks & Considerations:**
- Implementing persistence for an app-level Dark Mode toggle requires a globally available state manager, hooking into DataStore setup.
