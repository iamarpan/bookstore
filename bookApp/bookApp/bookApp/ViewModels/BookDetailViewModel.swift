import Foundation
import Combine

@MainActor
class BookDetailViewModel: ObservableObject {
    @Published var book: Book
    @Published var isLoading = false
    @Published var showSuccessAlert = false
    @Published var showError = false
    @Published var errorMessage: String?
    @Published var hasRequestedBook = false
    @Published var existingTransaction: Transaction?
    @Published var navigateToTransaction: Transaction?
    
    private let store = AppDataStore.shared
    private let refresher: any AppDataRefresherProtocol
    private var cancellables = Set<AnyCancellable>()
    
    init(book: Book, refresher: (any AppDataRefresherProtocol)? = nil) {
        self.book = book
        self.refresher = refresher ?? AppDataRefresher.shared
        setupTransactionObservation()
        checkExistingRequest()
    }
    
    private func setupTransactionObservation() {
        store.$borrowedTransactions
            .receive(on: DispatchQueue.main)
            .sink { [weak self] transactions in
                self?.updateStateWithTransactions(transactions)
            }
            .store(in: &cancellables)
    }
    
    func requestBook() async {
        guard !hasRequestedBook else { return }
        
        isLoading = true
        
        do {
            let transaction = try await TransactionService().createBorrowRequest(
                bookId: book.id,
                duration: .twoWeeks,
                message: "I'd like to borrow this book!"
            )
            
            // Trigger a refresh (it will update the store, and we'll react)
            _ = try await refresher.refreshBorrowerTransactionsIfNeeded(forceRefresh: true)
            showSuccessAlert = true
            
        } catch {
            errorMessage = "Failed to send request: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    func cancelRequest() async {
        guard hasRequestedBook, let transaction = existingTransaction else { return }
        
        isLoading = true
        
        do {
            _ = try await TransactionService().cancelTransaction(id: transaction.id)
            
            // Trigger refresh
            _ = try await refresher.refreshBorrowerTransactionsIfNeeded(forceRefresh: true)
            
        } catch {
            errorMessage = "Failed to cancel request: \(error.localizedDescription)"
            showError = true
        }
        
        isLoading = false
    }
    
    private func checkExistingRequest() {
        Task {
            await fetchExistingRequest()
        }
    }
    
    func fetchExistingRequest() async {
        do {
            _ = try await refresher.refreshBorrowerTransactionsIfNeeded(forceRefresh: false)
        } catch {
            print("⚠️ BookDetailViewModel: could not check existing request — \(error.localizedDescription)")
        }
    }

    private func updateStateWithTransactions(_ transactions: [Transaction]) {
        if let match = transactions.first(where: {
            $0.bookId == book.id &&
            ($0.status == .pending || $0.status == .approved || $0.status == .active)
        }) {
            existingTransaction = match
            hasRequestedBook = true
        } else if hasRequestedBook {
            existingTransaction = nil
            hasRequestedBook = false
        }
    }
    
    var canRequestBook: Bool {
        let currentUserId = User.loadFromUserDefaults()?.id ?? ""
        return book.isAvailable &&
               !hasRequestedBook &&
               book.ownerId != currentUserId
    }
    
    var requestButtonTitle: String {
        let currentUserId = User.loadFromUserDefaults()?.id ?? ""
        
        if let transaction = existingTransaction {
            switch transaction.status {
            case .pending, .approved:
                return "Request Sent"
            case .active:
                return "Manage Borrow"
            case .returned, .rejected, .cancelled:
                break // Fall through to standard availability check
            }
        }
        
        if book.ownerId == currentUserId {
            return "Your Book"
        } else if !book.isAvailable {
            return "Not Available"
        } else {
            return "Request This Book"
        }
    }
    
    var requestStatus: RequestStatus? {
        let currentUserId = User.loadFromUserDefaults()?.id ?? ""
        
        if book.ownerId == currentUserId {
            return .ownBook
        }
        
        if let transaction = existingTransaction {
            switch transaction.status {
            case .pending, .approved:
                return .requested
            case .active:
                return .borrowed
            case .returned, .rejected, .cancelled:
                break // Fall through to standard availability check
            }
        }
        
        if !book.isAvailable {
            return .unavailable
        }
        
        return .canRequest
    }

    var availabilityText: String {
        if let transaction = existingTransaction {
            switch transaction.status {
            case .pending, .approved:
                return "Requested by you"
            case .active:
                return "Borrowed by you"
            default:
                break
            }
        }
        return book.isAvailable ? "Available" : "Borrowed"
    }
    
    func showTransactionDetail() {
        if let transaction = existingTransaction {
            navigateToTransaction = transaction
        }
    }
}

enum RequestStatus {
    case canRequest
    case requested
    case borrowed
    case unavailable
    case ownBook
}