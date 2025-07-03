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
    
    func startListening(for societyId: String) {
        isLoading = true
        booksListener = firestoreService.listenToBooks(for: societyId) { [weak self] books in
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
        isLoading = true
        // In a real implementation, you might refresh the listener or trigger a new fetch
        // For now, we'll just toggle loading state
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.isLoading = false
        }
    }
    
    func clearFilters() {
        selectedGenre = nil
        selectedAvailability = nil
    }
}