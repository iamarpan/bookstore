# Society Book Exchange iOS App

A SwiftUI-based mobile application for apartment society residents to share and borrow books among neighbors. Built with Firebase backend and following MVVM architecture patterns.

## 🚀 Features

### Core Functionality
- **Book Catalog**: Browse available books with search and filtering
- **Book Management**: Add new books with cover images
- **Request System**: Send and manage book lending requests (simulated)
- **Library Tracking**: Track borrowed and lent books
- **User Profiles**: View user information and app settings

### Technical Features
- **SwiftUI Interface**: Modern iOS 15+ native UI
- **MVVM Architecture**: Clean separation of concerns
- **Mock Data Integration**: Sample data for immediate testing
- **Image Caching**: Efficient loading and caching of book covers
- **Offline First**: Works completely offline with sample data
- **Input Validation**: Comprehensive form validation and error handling

## 📱 Screenshots

[Add screenshots of your app here]

## 🛠 Technical Stack

- **Frontend**: SwiftUI (iOS 15+)
- **Architecture**: MVVM pattern
- **Backend**: Mock data (ready for future Firebase integration)
- **Image Handling**: URLSession with NSCache for caching
- **State Management**: ObservableObject and @Published properties
- **Async Operations**: Swift Concurrency (async/await)

## 📋 Requirements

- iOS 15.0+
- Xcode 13.0+
- Swift 5.5+
- Firebase project configured

## 🔧 Setup Instructions

**⚠️ IMPORTANT:** This project contains Swift files that need to be added to a proper iOS project in Xcode. See the **[SETUP_GUIDE.md](SETUP_GUIDE.md)** for complete step-by-step instructions.

### Quick Start

1. **Create a new iOS project in Xcode** (not a Swift Package)
2. **Add Firebase dependencies** via Xcode's Package Manager
3. **Copy all the Swift files** into your Xcode project with proper folder structure
4. **Configure Firebase** with your `GoogleService-Info.plist`
5. **Build and run!**

For detailed instructions, **follow the [SETUP_GUIDE.md](SETUP_GUIDE.md)**

### Ready to Run
The app now works immediately with:
- ✅ **Sample books** pre-loaded (The Great Gatsby, Becoming)
- ✅ **All features functional** with mock data
- ✅ **No setup required** - just build and run!
- ✅ **Clean directory structure** - no redundant files

## 📂 Project Structure

```
bookstore/
├── bookApp/                        # Main Xcode project
│   ├── bookApp.xcodeproj/         # Xcode project file
│   ├── Info.plist                 # App configuration
│   └── bookApp/                   # Source code
│       ├── BookstoreApp.swift     # Main app entry point
│       ├── ContentView.swift      # Root view
│       ├── Models/                # Data models
│       │   ├── Book.swift
│       │   ├── User.swift
│       │   └── BookRequest.swift
│       ├── ViewModels/            # MVVM ViewModels
│       │   ├── AuthViewModel.swift
│       │   ├── HomeViewModel.swift
│       │   ├── BookDetailViewModel.swift
│       │   ├── AddBookViewModel.swift
│       │   └── MyLibraryViewModel.swift
│       ├── Views/                 # SwiftUI Views
│       │   ├── MainTabView.swift
│       │   ├── HomeView.swift
│       │   ├── BookDetailView.swift
│       │   ├── AddBookView.swift
│       │   ├── MyLibraryView.swift
│       │   └── ProfileView.swift
│       └── Utilities/             # Helper utilities
│           └── ImageCache.swift
├── README.md                      # This documentation
└── SIMPLIFIED_STRUCTURE.md        # Structure documentation
```

## 🏗 Architecture Overview

### MVVM Pattern
- **Models**: Data structures (`Book`, `User`, `BookRequest`)
- **Views**: SwiftUI views for UI presentation
- **ViewModels**: Business logic and state management
- **Services**: External API communication (Firebase)

### Data Flow
1. Views observe ViewModels using `@ObservableObject`
2. ViewModels handle user actions and update `@Published` properties
3. Services manage Firebase operations and data persistence
4. Views automatically update when ViewModel state changes

## 🔐 Authentication Flow

1. User enters phone number
2. Firebase sends OTP via SMS
3. User enters OTP and registration details
4. Firebase verifies OTP and creates user account
5. User profile stored in Firestore
6. User authenticated and can access app features

## 📊 Database Schema

### Books Collection
```
books/{bookId}
├── title: String
├── author: String
├── genre: String
├── imageUrl: String?
├── notes: String?
├── ownerId: String
├── ownerFlatNumber: String
├── isAvailable: Boolean
└── dateAdded: Date
```

### Users Collection
```
users/{userId}
├── name: String
├── flatNumber: String
├── phone: String
└── joinedDate: Date
```

### Requests Collection
```
requests/{requestId}
├── bookId: String
├── borrowerId: String
├── borrowerName: String
├── borrowerFlatNumber: String
├── status: String
├── requestDate: Date
├── responseDate: Date?
├── returnDate: Date?
└── notes: String?
```

## 🚨 Error Handling

The app includes comprehensive error handling:
- Network connectivity issues
- Firebase authentication errors
- Firestore operation failures
- Input validation errors
- Image loading failures

All errors are presented to users with helpful messages and fallback options.

## 🔄 State Management

Using Combine framework for reactive programming:
- `@Published` properties for automatic UI updates
- `@StateObject` for ViewModel lifecycle management
- `@EnvironmentObject` for shared state across views
- Cancellable subscriptions for memory management

## 🎨 UI/UX Features

- **Modern Design**: Clean, intuitive interface following iOS design guidelines
- **Dark Mode Support**: Automatic adaptation to system appearance
- **Accessibility**: VoiceOver support and dynamic type scaling
- **Pull-to-Refresh**: Easy data refreshing in lists
- **Loading States**: Visual feedback during async operations
- **Error States**: Clear error messages and recovery options

## 🧪 Testing

The app includes mock data for testing purposes:
- `Book.mockBooks` - Sample book data
- `BookRequest.mockRequests` - Sample request data
- `User.mockUser` - Sample user data

To test without Firebase:
```swift
// Set this environment variable
USE_MOCK_DATA=true
```

## 🔮 Future Enhancements

### Planned Features
- **Push Notifications**: Real-time request notifications
- **Chat System**: In-app messaging between users
- **Book Reviews**: Rating and review system
- **Advanced Search**: Filters by availability, distance, etc.
- **Book Recommendations**: AI-powered suggestions
- **Reading Lists**: Personal wish lists and collections
- **Social Features**: Friend connections and book sharing

### Technical Improvements
- **Unit Tests**: Comprehensive test coverage
- **UI Tests**: Automated UI testing
- **Performance Optimization**: Advanced caching strategies
- **Offline Sync**: Complete offline functionality
- **Analytics**: User behavior tracking
- **Crashlytics**: Error monitoring and reporting

## 🤝 Contributing

1. Fork the repository
2. Create a feature branch
3. Commit your changes
4. Push to the branch
5. Create a Pull Request

## 📄 License

This project is licensed under the MIT License - see the [LICENSE](LICENSE) file for details.

## 📞 Support

For support or questions:
- Create an issue in this repository
- Email: [your-email@example.com]
- Documentation: [Link to detailed docs]

## 🙏 Acknowledgments

- Firebase team for excellent mobile backend services
- Apple for SwiftUI and modern iOS development tools
- Open source community for inspiration and best practices

---

**Note**: This is a community-focused app designed for use within apartment societies. Please ensure proper user consent and data privacy compliance when deploying to production. 