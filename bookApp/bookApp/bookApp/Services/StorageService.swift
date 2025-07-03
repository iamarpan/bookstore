import Foundation
import FirebaseStorage
import UIKit

@MainActor
class StorageService: ObservableObject {
    @Published var uploadProgress: Double = 0.0
    @Published var isUploading: Bool = false
    @Published var uploadError: String?
    
    private let storage = Storage.storage()
    
    // MARK: - Book Cover Upload
    
    /// Uploads a book cover image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - bookId: The unique book identifier
    ///   - compressionQuality: JPEG compression quality (0.0 to 1.0)
    /// - Returns: The download URL string
    func uploadBookCover(_ image: UIImage, bookId: String, compressionQuality: CGFloat = 0.7) async throws -> String {
        guard let imageData = compressImage(image, quality: compressionQuality) else {
            throw StorageError.imageCompressionFailed
        }
        
        let storageRef = storage.reference().child("book_covers/\(bookId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "bookId": bookId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        return try await uploadImage(data: imageData, to: storageRef, metadata: metadata)
    }
    
    /// Uploads multiple book cover images (for books with multiple photos)
    /// - Parameters:
    ///   - images: Array of UIImages to upload
    ///   - bookId: The unique book identifier
    ///   - compressionQuality: JPEG compression quality
    /// - Returns: Array of download URL strings
    func uploadBookCoverImages(_ images: [UIImage], bookId: String, compressionQuality: CGFloat = 0.7) async throws -> [String] {
        var downloadURLs: [String] = []
        
        for (index, image) in images.enumerated() {
            let imageId = "\(bookId)_\(index)"
            let url = try await uploadBookCover(image, bookId: imageId, compressionQuality: compressionQuality)
            downloadURLs.append(url)
        }
        
        return downloadURLs
    }
    
    // MARK: - Profile Image Upload
    
    /// Uploads a user profile image to Firebase Storage
    /// - Parameters:
    ///   - image: The UIImage to upload
    ///   - userId: The unique user identifier
    ///   - compressionQuality: JPEG compression quality
    /// - Returns: The download URL string
    func uploadProfileImage(_ image: UIImage, userId: String, compressionQuality: CGFloat = 0.8) async throws -> String {
        guard let imageData = compressImage(image, quality: compressionQuality) else {
            throw StorageError.imageCompressionFailed
        }
        
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        
        let metadata = StorageMetadata()
        metadata.contentType = "image/jpeg"
        metadata.customMetadata = [
            "userId": userId,
            "uploadedAt": ISO8601DateFormatter().string(from: Date())
        ]
        
        return try await uploadImage(data: imageData, to: storageRef, metadata: metadata)
    }
    
    // MARK: - Generic Image Upload
    
    /// Generic method to upload image data to Firebase Storage with progress tracking
    /// - Parameters:
    ///   - data: The image data to upload
    ///   - storageRef: The Firebase Storage reference
    ///   - metadata: Storage metadata
    /// - Returns: The download URL string
    private func uploadImage(data: Data, to storageRef: StorageReference, metadata: StorageMetadata) async throws -> String {
        isUploading = true
        uploadProgress = 0.0
        uploadError = nil
        
        defer {
            isUploading = false
            uploadProgress = 0.0
        }
        
        do {
            // Create upload task with progress tracking
            let uploadTask = storageRef.putData(data, metadata: metadata)
            
            // Observe upload progress
            uploadTask.observe(.progress) { [weak self] snapshot in
                guard let self = self,
                      let progress = snapshot.progress else { return }
                
                Task { @MainActor in
                    self.uploadProgress = Double(progress.completedUnitCount) / Double(progress.totalUnitCount)
                }
            }
            
            // Wait for upload completion
            let _ = try await uploadTask
            
            // Get download URL
            let downloadURL = try await storageRef.downloadURL()
            return downloadURL.absoluteString
            
        } catch {
            uploadError = error.localizedDescription
            throw StorageError.uploadFailed(error.localizedDescription)
        }
    }
    
    // MARK: - Image Deletion
    
    /// Deletes a book cover image from Firebase Storage
    /// - Parameter bookId: The unique book identifier
    func deleteBookCover(bookId: String) async throws {
        let storageRef = storage.reference().child("book_covers/\(bookId).jpg")
        try await storageRef.delete()
    }
    
    /// Deletes a profile image from Firebase Storage
    /// - Parameter userId: The unique user identifier
    func deleteProfileImage(userId: String) async throws {
        let storageRef = storage.reference().child("profile_images/\(userId).jpg")
        try await storageRef.delete()
    }
    
    /// Deletes multiple book cover images
    /// - Parameter bookId: The book ID (will delete all variants)
    func deleteBookCoverImages(bookId: String) async throws {
        let bookCoversRef = storage.reference().child("book_covers")
        
        // List all files with the bookId prefix
        let result = try await bookCoversRef.listAll()
        
        for item in result.items {
            if item.name.hasPrefix(bookId) {
                try await item.delete()
            }
        }
    }
    
    // MARK: - Image Utilities
    
    /// Compresses an image to reduce file size while maintaining quality
    /// - Parameters:
    ///   - image: The UIImage to compress
    ///   - quality: JPEG compression quality (0.0 to 1.0)
    ///   - maxSize: Maximum dimension in pixels (optional)
    /// - Returns: Compressed image data
    private func compressImage(_ image: UIImage, quality: CGFloat, maxSize: CGFloat = 1024) -> Data? {
        // Resize image if needed
        let resizedImage = resizeImage(image, maxSize: maxSize)
        
        // Convert to JPEG data with compression
        return resizedImage.jpegData(compressionQuality: quality)
    }
    
    /// Resizes an image to fit within the specified maximum dimension
    /// - Parameters:
    ///   - image: The UIImage to resize
    ///   - maxSize: Maximum dimension in pixels
    /// - Returns: Resized UIImage
    private func resizeImage(_ image: UIImage, maxSize: CGFloat) -> UIImage {
        let size = image.size
        
        // Check if resizing is needed
        if size.width <= maxSize && size.height <= maxSize {
            return image
        }
        
        // Calculate new size maintaining aspect ratio
        let aspectRatio = size.width / size.height
        let newSize: CGSize
        
        if size.width > size.height {
            newSize = CGSize(width: maxSize, height: maxSize / aspectRatio)
        } else {
            newSize = CGSize(width: maxSize * aspectRatio, height: maxSize)
        }
        
        // Resize the image
        UIGraphicsBeginImageContextWithOptions(newSize, false, 0.0)
        image.draw(in: CGRect(origin: .zero, size: newSize))
        let resizedImage = UIGraphicsGetImageFromCurrentImageContext()
        UIGraphicsEndImageContext()
        
        return resizedImage ?? image
    }
    
    // MARK: - Download Methods
    
    /// Downloads an image from Firebase Storage
    /// - Parameter url: The download URL string
    /// - Returns: The downloaded UIImage
    func downloadImage(from url: String) async throws -> UIImage {
        guard let downloadURL = URL(string: url) else {
            throw StorageError.invalidURL
        }
        
        let (data, _) = try await URLSession.shared.data(from: downloadURL)
        
        guard let image = UIImage(data: data) else {
            throw StorageError.imageDecodingFailed
        }
        
        return image
    }
    
    /// Gets the storage reference for a book cover
    /// - Parameter bookId: The unique book identifier
    /// - Returns: Firebase Storage reference
    func getBookCoverReference(bookId: String) -> StorageReference {
        return storage.reference().child("book_covers/\(bookId).jpg")
    }
    
    /// Gets the storage reference for a profile image
    /// - Parameter userId: The unique user identifier
    /// - Returns: Firebase Storage reference
    func getProfileImageReference(userId: String) -> StorageReference {
        return storage.reference().child("profile_images/\(userId).jpg")
    }
    
    // MARK: - Validation
    
    /// Validates if an image meets the upload requirements
    /// - Parameters:
    ///   - image: The UIImage to validate
    ///   - maxFileSize: Maximum file size in bytes (default 5MB)
    ///   - minDimension: Minimum dimension in pixels
    ///   - maxDimension: Maximum dimension in pixels
    /// - Returns: Boolean indicating if the image is valid
    func validateImage(_ image: UIImage, maxFileSize: Int = 5_000_000, minDimension: CGFloat = 100, maxDimension: CGFloat = 4000) -> Bool {
        let size = image.size
        
        // Check dimensions
        if size.width < minDimension || size.height < minDimension {
            return false
        }
        
        if size.width > maxDimension || size.height > maxDimension {
            return false
        }
        
        // Check file size (estimate)
        if let imageData = image.jpegData(compressionQuality: 1.0),
           imageData.count > maxFileSize {
            return false
        }
        
        return true
    }
    
    // MARK: - Error Handling
    
    /// Resets error state
    func clearError() {
        uploadError = nil
    }
    
    /// Cancels current upload (if any)
    func cancelUpload() {
        // Implementation for canceling upload if needed
        isUploading = false
        uploadProgress = 0.0
    }
}

// MARK: - Storage Errors

enum StorageError: LocalizedError {
    case imageCompressionFailed
    case uploadFailed(String)
    case downloadFailed(String)
    case invalidURL
    case imageDecodingFailed
    case fileTooLarge
    case unsupportedFormat
    
    var errorDescription: String? {
        switch self {
        case .imageCompressionFailed:
            return "Failed to compress image for upload"
        case .uploadFailed(let message):
            return "Upload failed: \(message)"
        case .downloadFailed(let message):
            return "Download failed: \(message)"
        case .invalidURL:
            return "Invalid image URL"
        case .imageDecodingFailed:
            return "Failed to decode downloaded image"
        case .fileTooLarge:
            return "Image file is too large"
        case .unsupportedFormat:
            return "Unsupported image format"
        }
    }
    
    var recoverySuggestion: String? {
        switch self {
        case .imageCompressionFailed:
            return "Try using a different image or check image format"
        case .uploadFailed:
            return "Check your internet connection and try again"
        case .downloadFailed:
            return "Check your internet connection and try again"
        case .invalidURL:
            return "Please provide a valid image URL"
        case .imageDecodingFailed:
            return "The image file may be corrupted"
        case .fileTooLarge:
            return "Please choose a smaller image or reduce quality"
        case .unsupportedFormat:
            return "Please use JPEG or PNG format"
        }
    }
}

// MARK: - Upload Configuration

struct UploadConfiguration {
    let compressionQuality: CGFloat
    let maxDimension: CGFloat
    let maxFileSize: Int
    
    static let bookCover = UploadConfiguration(
        compressionQuality: 0.7,
        maxDimension: 1024,
        maxFileSize: 2_000_000 // 2MB
    )
    
    static let profileImage = UploadConfiguration(
        compressionQuality: 0.8,
        maxDimension: 512,
        maxFileSize: 1_000_000 // 1MB
    )
} 