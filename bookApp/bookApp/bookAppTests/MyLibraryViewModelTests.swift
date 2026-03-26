// bookAppTests/MyLibraryViewModelTests.swift
// Unit tests for MyLibraryViewModel — initial state, computed properties, and error state.

import Foundation
import Testing
@testable import bookApp


struct MyLibraryViewModelTests {

    // MARK: - Initial State

    @Test("Initial state is clean — no error, no loading, empty collections")
    @MainActor func initialState_isClean() {
        let vm = MyLibraryViewModel()
        #expect(vm.isLoading == false)
        #expect(vm.showError == false)
        #expect(vm.errorMessage == nil)
        #expect(vm.myListedBooks.isEmpty)
        #expect(vm.borrowedBooks.isEmpty)
        #expect(vm.lentBooks.isEmpty)
    }

    // MARK: - Computed Properties

    @Test("totalBooksShared reflects myListedBooks count")
    @MainActor func totalBooksShared_reflectsMyBooksCount() {
        let vm = MyLibraryViewModel()
        vm.myListedBooks = [
            Book(
                title: "Book A", author: "Author A", genre: "Fiction",
                description: "", ownerId: "user-1", ownerName: "User 1",
                visibleInGroups: ["group-1"]
            ),
            Book(
                title: "Book B", author: "Author B", genre: "History",
                description: "", isAvailable: false, ownerId: "user-1",
                ownerName: "User 1", visibleInGroups: ["group-1"]
            )
        ]
        #expect(vm.totalBooksShared == 2)
    }

    @Test("activeLoans only includes transactions with .active status")
    @MainActor func activeLoans_onlyActiveStatus() {
        let vm = MyLibraryViewModel()
        vm.borrowedBooks = [
            Transaction.makeStub(status: .active),
            Transaction.makeStub(status: .pending, id: "t-2"),
            Transaction.makeStub(status: .returned, id: "t-3")
        ]
        #expect(vm.activeLoans.count == 1)
        #expect(vm.activeLoans.first?.status == .active)
    }

    @Test("totalActiveLends equals activeLoans count")
    @MainActor func totalActiveLends_equalsActiveLoanCount() {
        let vm = MyLibraryViewModel()
        vm.borrowedBooks = [
            Transaction.makeStub(status: .active),
            Transaction.makeStub(status: .active, id: "t-2")
        ]
        #expect(vm.totalActiveLends == 2)
    }

    @Test("myListedBooks is identical to myListedBooks")
    @MainActor func myListedBooks_equalsMyBooks() {
        let vm = MyLibraryViewModel()
        let book = Book(
            title: "Test", author: "Author", genre: "Genre",
            description: "", ownerId: "u", ownerName: "User",
            visibleInGroups: []
        )
        vm.myListedBooks = [book]
        #expect(vm.myListedBooks.count == vm.myListedBooks.count)
        #expect(vm.myListedBooks.first?.id == vm.myListedBooks.first?.id)
    }

    // MARK: - Actions

    @Test("fetchAllData successfully fetches all categories")
    @MainActor func fetchAllData_success() async {
        let mockRefresher = MockAppDataRefresher()
        mockRefresher.myListedBooksToReturn = [Book(title: "My Book", author: "Me", genre: "Sci-Fi", description: "", ownerId: "u1", ownerName: "Me", visibleInGroups: [])]
        mockRefresher.borrowerTransactionsToReturn = [Transaction.makeStub(status: .active)]
        mockRefresher.ownerTransactionsToReturn = [Transaction.makeStub(status: .pending)]
        mockRefresher.historyTransactionsToReturn = [Transaction.makeStub(status: .returned)]
        
        let vm = MyLibraryViewModel(refresher: mockRefresher)
        await vm.fetchAllData(userId: "u1")
        
        #expect(vm.myListedBooks.count == 1)
        #expect(vm.borrowedBooks.count == 1)
        #expect(vm.lentBooks.count == 1)
        #expect(vm.showError == false)
    }

    @Test("updateRequestStatus successfully approves a request")
    @MainActor func updateRequestStatus_approve_success() async {
        let mockTxnService = MockTransactionService()
        let mockRefresher = MockAppDataRefresher()
        let transaction = Transaction.makeStub(status: .pending, id: "txn-123")
        
        let vm = MyLibraryViewModel(transactionService: mockTxnService, refresher: mockRefresher)
        vm.updateRequestStatus(transaction, newStatus: .approved)
        
        // Since it's a Task internally, we might need a small delay or use a more robust way to wait for completion
        // For unit tests, sometimes it's better to wait a bit
        try? await Task.sleep(nanoseconds: 100_000_000) 
        
        #expect(mockTxnService.lastApprovedId == "txn-123")
        #expect(vm.showError == false)
    }

    @Test("toggleBookAvailability successfully toggles isAvailable")
    @MainActor func toggleBookAvailability_success() async {
        let mockBookService = MockBookService()
        var book = Book(title: "Test", author: "Author", genre: "Genre", description: "", ownerId: "u", ownerName: "Me", visibleInGroups: [])
        book.isAvailable = true
        
        let vm = MyLibraryViewModel(bookService: mockBookService)
        vm.toggleBookAvailability(book)
        
        try? await Task.sleep(nanoseconds: 100_000_000)
        
        #expect(mockBookService.lastUpdatedBook?.isAvailable == false)
        #expect(vm.showError == false)
    }

    @Test("deleteBook successfully removes book")
    @MainActor func deleteBook_success() async {
        let mockBookService = MockBookService()
        let book = Book(id: "b1", title: "Test", author: "Author", genre: "Genre", description: "", ownerId: "u", ownerName: "Me", visibleInGroups: [])
        
        let vm = MyLibraryViewModel(bookService: mockBookService)
        vm.myListedBooks = [book]
        
        await vm.deleteBook(book)
        
        #expect(mockBookService.lastDeletedBookId == "b1")
        #expect(vm.myListedBooks.isEmpty)
        #expect(vm.showError == false)
    }

    // MARK: - Error state validation

    @Test("showError false by default, can be set to true")
    @MainActor func showError_defaultFalse_canBeSetTrue() {
        let vm = MyLibraryViewModel()
        #expect(vm.showError == false)
        vm.showError = true
        vm.errorMessage = "Something went wrong"
        #expect(vm.showError == true)
        #expect(vm.errorMessage == "Something went wrong")
    }

    @Test("overdueLoans is empty when there are no active loans with passed due dates")
    @MainActor func overdueLoans_emptyWhenNoOverdue() {
        let vm = MyLibraryViewModel()
        // Active loan with future due date → not overdue
        vm.borrowedBooks = [Transaction.makeStub(status: .active, dueDate: Date().addingTimeInterval(86400 * 5))]
        #expect(vm.overdueLoans.isEmpty)
    }
}


// MARK: - Transaction Test Stub

extension Transaction {
    /// Creates a minimal `Transaction` for testing purposes.
    static func makeStub(
        status: TransactionStatus,
        id: String = "t-1",
        dueDate: Date? = nil
    ) -> Transaction {
        Transaction(
            id: id,
            bookId: "book-1",
            bookTitle: "Test Book",
            borrowerId: "user-2",
            borrowerName: "Borrower",
            ownerId: "user-1",
            ownerName: "Owner",
            groupId: "group-1",
            status: status,
            duration: .twoWeeks,
            lendingFee: 0,
            dueDate: dueDate
        )
    }
}
