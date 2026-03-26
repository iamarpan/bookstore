// bookAppTests/BookDetailViewModelTests.swift
// Unit tests for BookDetailViewModel — state computation, button labels, and request status logic.

import Foundation
import Testing
@testable import bookApp


// MARK: - Helpers

private func makeBook(
    id: String = "book-1",
    ownerId: String = "owner-X",
    isAvailable: Bool = true
) -> Book {
    Book(
        id: id,
        title: "Test Book",
        author: "Test Author",
        genre: "Fiction",
        description: "A test book",
        imageUrl: "",
        isAvailable: isAvailable,
        ownerId: ownerId,
        ownerName: "Owner Name",
        visibleInGroups: ["group-1"]
    )
}

// MARK: - BookDetailViewModelTests

struct BookDetailViewModelTests {

    // Clear any persisted login session before each test so that
    // `User.loadFromUserDefaults()` returns nil and the ownerId check is deterministic.
    // "currentUser" is the exact key used in User.saveToUserDefaults() / clearFromUserDefaults()
    // (confirmed in User.swift).
    init() {
        UserDefaults.standard.removeObject(forKey: "currentUser")
    }

    // MARK: - canRequestBook

    @Test("canRequestBook is true for available book by a different user")
    @MainActor func canRequestBook_availableAndNotOwner_isTrue() {
        // No logged-in user → currentUserId == "" which must differ from "owner-X"
        let book = makeBook(ownerId: "owner-X", isAvailable: true)
        let vm = BookDetailViewModel(book: book)
        vm.hasRequestedBook = false
        #expect(vm.canRequestBook == true)
    }

    @Test("canRequestBook is false when book is unavailable")
    @MainActor func canRequestBook_unavailableBook_isFalse() {
        let book = makeBook(isAvailable: false)
        let vm = BookDetailViewModel(book: book)
        vm.hasRequestedBook = false
        #expect(vm.canRequestBook == false)
    }

    @Test("canRequestBook is false when user already requested the book")
    @MainActor func canRequestBook_alreadyRequested_isFalse() {
        let book = makeBook(isAvailable: true)
        let vm = BookDetailViewModel(book: book)
        vm.hasRequestedBook = true
        #expect(vm.canRequestBook == false)
    }

    // MARK: - requestButtonTitle

    @Test("requestButtonTitle shows 'Not Available' for unavailable book")
    @MainActor func requestButtonTitle_unavailable() {
        let book = makeBook(isAvailable: false)
        let vm = BookDetailViewModel(book: book)
        #expect(vm.requestButtonTitle == "Not Available")
    }

    @Test("requestButtonTitle shows 'Manage Borrow' when book is borrowed by user")
    @MainActor func requestButtonTitle_borrowedByUser() {
        let book = makeBook(isAvailable: false)
        let vm = BookDetailViewModel(book: book)
        vm.existingTransaction = Transaction(
            bookId: book.id,
            bookTitle: book.title,
            borrowerId: "me",
            borrowerName: "Me",
            ownerId: "owner",
            ownerName: "Owner",
            groupId: "g1",
            status: .active,
            duration: .oneWeek,
            lendingFee: 0
        )
        #expect(vm.requestButtonTitle == "Manage Borrow")
    }

    @Test("requestButtonTitle shows 'Request Sent' when already requested")
    @MainActor func requestButtonTitle_alreadyRequested() {
        let book = makeBook(isAvailable: true)
        let vm = BookDetailViewModel(book: book)
        vm.existingTransaction = Transaction(
            bookId: book.id,
            bookTitle: book.title,
            borrowerId: "me",
            borrowerName: "Me",
            ownerId: "owner",
            ownerName: "Owner",
            groupId: "g1",
            status: .pending,
            duration: .oneWeek,
            lendingFee: 0
        )
        #expect(vm.requestButtonTitle == "Request Sent")
    }

    @Test("requestButtonTitle shows 'Request This Book' when book is available and not requested")
    @MainActor func requestButtonTitle_canRequest() {
        let book = makeBook(ownerId: "other-owner", isAvailable: true)
        let vm = BookDetailViewModel(book: book)
        vm.hasRequestedBook = false
        #expect(vm.requestButtonTitle == "Request This Book")
    }

    // MARK: - requestStatus

    @Test("requestStatus is .unavailable when book is not available and no transaction")
    @MainActor func requestStatus_bookUnavailable_isUnavailable() {
        let book = makeBook(isAvailable: false)
        let vm = BookDetailViewModel(book: book)
        vm.existingTransaction = nil
        vm.hasRequestedBook = false
        #expect(vm.requestStatus == .unavailable)
    }

    @Test("requestStatus is .canRequest when book is available by a different user with no transaction")
    @MainActor func requestStatus_canRequest() {
        let book = makeBook(ownerId: "other-owner", isAvailable: true)
        let vm = BookDetailViewModel(book: book)
        vm.existingTransaction = nil
        vm.hasRequestedBook = false
        #expect(vm.requestStatus == .canRequest)
    }

    // MARK: - Initial state

    @Test("Initial state has no error and is not loading")
    @MainActor func initialState_noErrorNotLoading() {
        let book = makeBook()
        let vm = BookDetailViewModel(book: book)
        #expect(vm.showError == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.showSuccessAlert == false)
    }

    // MARK: - requestBook guard

    @Test("requestBook does nothing if book already requested")
    @MainActor func requestBook_alreadyRequested_doesNothing() async {
        let book = makeBook()
        let vm = BookDetailViewModel(book: book)
        vm.hasRequestedBook = true
        // Should return early without setting isLoading
        await vm.requestBook()
        // isLoading must remain false (guard exits before setting it)
        #expect(vm.isLoading == false)
    }

    // MARK: - cancelRequest guard

    @Test("cancelRequest does nothing when there is no existing transaction")
    @MainActor func cancelRequest_noTransaction_doesNothing() async {
        let book = makeBook()
        let vm = BookDetailViewModel(book: book)
        vm.hasRequestedBook = false
        vm.existingTransaction = nil
        await vm.cancelRequest()
        #expect(vm.isLoading == false)
    }
}
