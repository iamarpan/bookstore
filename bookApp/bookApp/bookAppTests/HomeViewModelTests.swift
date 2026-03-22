// bookAppTests/HomeViewModelTests.swift
// Unit tests for HomeViewModel — filter state and computed properties.

import Testing
@testable import bookApp

// MARK: - HomeViewModelTests

struct HomeViewModelTests {

    // MARK: - Initial State

    @Test("Initial state: no books, no error, not loading")
    @MainActor func initialState() {
        let vm = HomeViewModel()
        #expect(vm.books.isEmpty)
        #expect(vm.showError == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.isLoading == false)
    }

    // MARK: - hasActiveFilters

    @Test("hasActiveFilters is false when no genre or availability selected")
    @MainActor func hasActiveFilters_noSelection_isFalse() {
        let vm = HomeViewModel()
        vm.selectedGenre = nil
        vm.selectedAvailability = nil
        #expect(vm.hasActiveFilters == false)
    }

    @Test("hasActiveFilters is true when genre is selected")
    @MainActor func hasActiveFilters_genreSelected_isTrue() {
        let vm = HomeViewModel()
        vm.selectedGenre = "Mystery"
        #expect(vm.hasActiveFilters == true)
    }

    @Test("hasActiveFilters is true when availability is selected")
    @MainActor func hasActiveFilters_availabilitySelected_isTrue() {
        let vm = HomeViewModel()
        vm.selectedAvailability = "Available"
        #expect(vm.hasActiveFilters == true)
    }

    @Test("Both genre and availability selected: hasActiveFilters is true")
    @MainActor func hasActiveFilters_bothSelected_isTrue() {
        let vm = HomeViewModel()
        vm.selectedGenre = "Fantasy"
        vm.selectedAvailability = "Available"
        #expect(vm.hasActiveFilters == true)
    }

    @Test("Resetting selections to nil makes hasActiveFilters false again")
    @MainActor func hasActiveFilters_afterReset_isFalse() {
        let vm = HomeViewModel()
        vm.selectedGenre = "Fantasy"
        vm.selectedAvailability = "Available"
        vm.selectedGenre = nil
        vm.selectedAvailability = nil
        #expect(vm.hasActiveFilters == false)
    }

    // MARK: - searchText

    @Test("searchText is empty by default")
    @MainActor func searchText_defaultEmpty() {
        let vm = HomeViewModel()
        #expect(vm.searchText.isEmpty)
    }

    @Test("searchText update is reflected immediately")
    @MainActor func searchText_canBeUpdated() {
        let vm = HomeViewModel()
        vm.searchText = "Tolkien"
        #expect(vm.searchText == "Tolkien")
    }

    // MARK: - availabilityOptions

    @Test("availabilityOptions contains 'Available' and 'Not Available'")
    @MainActor func availabilityOptions_containsExpectedValues() {
        let vm = HomeViewModel()
        #expect(vm.availabilityOptions.contains("Available"))
        #expect(vm.availabilityOptions.contains("Not Available"))
        #expect(vm.availabilityOptions.count == 2)
    }
}
