// Services/FirestoreService.swift
import FirebaseFirestore
import FirebaseAuth
import Foundation

class FirestoreService: ObservableObject {
    private var db: Firestore { Firestore.firestore() }
    
    // MARK: - Books
    func addBook(_ book: Book) async throws -> String {
        let docRef = try await db.collection("books").addDocument(data: book.toDictionary())
        return docRef.documentID
    }
    
    func updateBook(_ book: Book) async throws {
        guard let id = book.id else {
            throw NSError(domain: "FirestoreService", code: 1001, userInfo: [NSLocalizedDescriptionKey: "Book ID is missing"])
        }
        
        try await db.collection("books").document(id).updateData(book.toDictionary())
    }
    
    func deleteBook(with id: String) async throws {
        try await db.collection("books").document(id).delete()
    }
    
    func getBooks(for bookClubId: String) async throws -> [Book] {
        let snapshot = try await db.collection("books")
            .whereField("bookClubId", isEqualTo: bookClubId)
            .whereField("isAvailable", isEqualTo: true)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Book.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func getUserBooks(userId: String) async throws -> [Book] {
        let snapshot = try await db.collection("books")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "createdAt", descending: true)
            .getDocuments()
        
        return snapshot.documents.compactMap { document in
            Book.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    func updateBookAvailability(bookId: String, isAvailable: Bool) async throws {
        try await db.collection("books").document(bookId).updateData([
            "isAvailable": isAvailable,
            "updatedAt": FieldValue.serverTimestamp()
        ])
    }
    
    // MARK: - Book Requests
    func listenToRequests(for userId: String, completion: @escaping ([BookRequest]) -> Void) -> ListenerRegistration {
        return db.collection("bookRequests")
            .whereField("borrowerId", isEqualTo: userId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let requests = documents.compactMap { document in
                    BookRequest.fromDictionary(document.data(), id: document.documentID)
                }
                
                completion(requests)
            }
    }
    
    func addBookRequest(_ request: BookRequest) async throws -> String {
        let docRef = try await db.collection("bookRequests").addDocument(data: request.toDictionary())
        return docRef.documentID
    }
    
    func updateBookRequest(_ request: BookRequest) async throws {
        guard let id = request.id else {
            throw NSError(domain: "FirestoreService", code: 1002, userInfo: [NSLocalizedDescriptionKey: "Request ID is missing"])
        }
        
        try await db.collection("bookRequests").document(id).updateData(request.toDictionary())
    }
    
    func getIncomingRequests(for userId: String) async throws -> [BookRequest] {
        let snapshot = try await db.collection("bookRequests")
            .whereField("ownerId", isEqualTo: userId)
            .order(by: "requestDate", descending: true)
            .getDocuments()
            
        return snapshot.documents.compactMap { document in
            BookRequest.fromDictionary(document.data(), id: document.documentID)
        }
    }
    
    // MARK: - Notifications
    func addNotification(_ notification: BookNotification) async throws -> String {
        let docRef = try await db.collection("notifications").addDocument(data: notification.toDictionary())
        return docRef.documentID
    }
    
    func markNotificationAsRead(notificationId: String) async throws {
        try await db.collection("notifications").document(notificationId).updateData([
            "isRead": true
        ])
    }
    
    // MARK: - Users
    func getUser(by id: String) async throws -> User? {
        let document = try await db.collection("users").document(id).getDocument()
        
        guard let data = document.data() else {
            return nil
        }
        
        return User.fromDictionary(data, id: document.documentID)
    }
    
    func updateUser(_ user: User) async throws {
        guard let id = user.id else {
            throw NSError(domain: "FirestoreService", code: 1003, userInfo: [NSLocalizedDescriptionKey: "User ID is missing"])
        }
        
        try await db.collection("users").document(id).updateData(user.toDictionary())
    }
    
    // MARK: - Book Clubs
    func createBookClub(_ club: BookClub) async throws -> String {
        let docRef = try await db.collection("bookClubs").addDocument(data: club.toDictionary())
        return docRef.documentID
    }
    
    func getBookClub(by code: String) async throws -> BookClub? {
        let snapshot = try await db.collection("bookClubs")
            .whereField("inviteCode", isEqualTo: code)
            .limit(to: 1)
            .getDocuments()
        
        guard let document = snapshot.documents.first else {
            return nil
        }
        
        return BookClub.fromDictionary(document.data(), id: document.documentID)
    }
    
    func getBookClub(byId id: String) async throws -> BookClub? {
        let document = try await db.collection("bookClubs").document(id).getDocument()
        
        guard let data = document.data() else {
            return nil
        }
        
        return BookClub.fromDictionary(data, id: document.documentID)
    }
    
    func joinBookClub(clubId: String, userId: String) async throws {
        let clubRef = db.collection("bookClubs").document(clubId)
        
        // Add user to memberIds array
        try await clubRef.updateData([
            "memberIds": FieldValue.arrayUnion([userId])
        ])
    }
    
    // MARK: - Real-time Listeners
    func listenToBooks(for bookClubId: String, completion: @escaping ([Book]) -> Void) -> ListenerRegistration {
        return db.collection("books")
            .whereField("bookClubId", isEqualTo: bookClubId)
            .addSnapshotListener { snapshot, error in
                guard let documents = snapshot?.documents else {
                    completion([])
                    return
                }
                
                let books = documents.compactMap { document in
                    Book.fromDictionary(document.data(), id: document.documentID)
                }
                
                completion(books)
            }
    }
}