// ViewModels/HomeViewModel.swift
import Foundation
import Combine
import FirebaseFirestore

@MainActor
class HomeViewModel: ObservableObject {
    @Published var books: [Book] = []
    @Published var searchText: String = ""
    @Published var selectedGenre: String? = nil
    @Published var selectedAvailability: String? = nil
    @Published var isLoading: Bool = false
    @Published var showError: Bool = false
    @Published var errorMessage: String? = nil
    
    private var booksListener: ListenerRegistration?
    private let firestoreService = FirestoreService()
    
    @Published var activeBookClub: BookClub?
    
    // MARK: - Computed Properties
    
    var filteredBooks: [Book] {
        var filtered = books
        
        // Apply search filter
        if !searchText.isEmpty {
            filtered = filtered.filter { book in
                book.title.localizedCaseInsensitiveContains(searchText) ||
                book.author.localizedCaseInsensitiveContains(searchText) ||
                book.genre.localizedCaseInsensitiveContains(searchText)
            }
        }
        
        // Apply genre filter
        if let selectedGenre = selectedGenre, !selectedGenre.isEmpty {
            filtered = filtered.filter { $0.genre == selectedGenre }
        }
        
        // Apply availability filter
        if let selectedAvailability = selectedAvailability, !selectedAvailability.isEmpty {
            if selectedAvailability == "Available" {
                filtered = filtered.filter { $0.isAvailable }
            } else if selectedAvailability == "Not Available" {
                filtered = filtered.filter { !$0.isAvailable }
            }
        }
        
        return filtered
    }
    
    var hasActiveFilters: Bool {
        return selectedGenre != nil || selectedAvailability != nil
    }
    
    var genres: [String] {
        let allGenres = Set(books.map { $0.genre })
        return Array(allGenres).sorted()
    }
    
    let availabilityOptions = ["Available", "Not Available"]
    
    // MARK: - Methods
    
    func startListening(for bookClubId: String) {
        isLoading = true
        
        // Fetch Book Club Details
        Task {
            do {
                if let club = try await firestoreService.getBookClub(byId: bookClubId) {
                    self.activeBookClub = club
                }
            } catch {
                print("Error fetching book club: \(error)")
            }
        }
        
        // Listen for Books
        booksListener = firestoreService.listenToBooks(for: bookClubId) { [weak self] books in
            Task { @MainActor in
                self?.books = books
                self?.isLoading = false
            }
        }
    }
    
    func stopListening() {
        booksListener?.remove()
    }
    
    func refreshBooks() {
        // Since we are using a real-time listener, we don't strictly need to "fetch" again.
        // However, if we want to force a re-sync or if the listener failed, we could restart it.
        // For this implementation, we will restart the listener to ensure fresh data.
        
        guard let bookClubId = books.first?.bookClubId else {
            // If we don't have books yet, we can't easily know which club to refresh for 
            // without storing bookClubId separately. 
            // Let's assume the View will call startListening again if needed.
            isLoading = false
            return
        }
        
        stopListening()
        startListening(for: bookClubId)
    }
    
    func clearFilters() {
        selectedGenre = nil
        selectedAvailability = nil
    }
}