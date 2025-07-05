#!/bin/bash

# BookstoreApp Launch Script
# This script launches the iOS app and optionally starts Firebase services

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

echo -e "${BLUE}🚀 BookstoreApp Launch Script${NC}"
echo -e "${BLUE}=================================${NC}"

# Function to print colored messages
print_status() {
    echo -e "${GREEN}✅ $1${NC}"
}

print_warning() {
    echo -e "${YELLOW}⚠️  $1${NC}"
}

print_error() {
    echo -e "${RED}❌ $1${NC}"
}

print_info() {
    echo -e "${BLUE}ℹ️  $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to check prerequisites
check_prerequisites() {
    print_info "Checking prerequisites..."
    
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script requires macOS to run iOS apps"
        exit 1
    fi
    
    # Check if Xcode is installed
    if ! command_exists xcodebuild; then
        print_error "Xcode is not installed. Please install Xcode from the App Store."
        exit 1
    fi
    
    # Check if project exists
    if [[ ! -f "$PROJECT_DIR/bookApp/bookApp/bookApp.xcodeproj/project.pbxproj" ]]; then
        print_error "Xcode project not found at $PROJECT_DIR/bookApp/bookApp/bookApp.xcodeproj"
        exit 1
    fi
    
    print_status "Prerequisites check passed"
}

# Function to install Firebase packages
install_firebase_packages() {
    print_info "Checking Firebase package dependencies..."
    
    cd "$PROJECT_DIR/bookApp/bookApp"
    
    # Check if Firebase packages are already installed by looking for Package.resolved
    if [[ -f "bookApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" ]]; then
        if grep -q "firebase-ios-sdk" "bookApp.xcodeproj/project.xcworkspace/xcshareddata/swiftpm/Package.resolved" 2>/dev/null; then
            print_status "Firebase packages already installed"
            
            # Verify the packages are properly resolved
            print_info "Verifying Firebase package resolution..."
            if xcodebuild -resolvePackageDependencies -project bookApp.xcodeproj 2>/dev/null; then
                print_status "Firebase packages properly resolved"
            else
                print_warning "Firebase packages need to be re-resolved"
                print_info "Attempting to resolve Firebase packages..."
                xcodebuild -resolvePackageDependencies -project bookApp.xcodeproj
            fi
            
            cd "$PROJECT_DIR"
            return 0
        fi
    fi
    
    print_warning "Firebase packages not found!"
    print_info "Installing Firebase packages via Swift Package Manager..."
    
    # Add Firebase iOS SDK package
    print_info "Adding Firebase iOS SDK package..."
    
    print_error "⚠️  IMPORTANT: Firebase packages must be added manually in Xcode."
    print_info "When Xcode opens, follow these steps:"
    echo ""
    echo -e "${YELLOW}📦 Firebase Package Installation (REQUIRED):${NC}"
    echo "1. In Xcode, go to File → Add Package Dependencies"
    echo "2. Enter this URL: https://github.com/firebase/firebase-ios-sdk"
    echo "3. Click 'Add Package' and wait for it to resolve"
    echo "4. Select these products (REQUIRED for the app to work):"
    echo "   • FirebaseAuth"
    echo "   • FirebaseCore (automatically included)"
    echo "   • FirebaseCoreExtension (automatically included)"
    echo "   • FirebaseFirestore"
    echo "   • FirebaseFirestoreInternalWrapper (automatically included)"
    echo "   • FirebaseStorage"
    echo "   • FirebaseMessaging"
    echo "   • FirebaseAnalytics"
    echo "   • FirebaseFunctions"
    echo "5. Click 'Add Package' and wait for installation"
    echo "6. Build the project (⌘+B) to verify installation"
    echo ""
    echo -e "${RED}❌ WITHOUT FIREBASE PACKAGES, YOU'LL GET BUILD ERRORS!${NC}"
    echo -e "${GREEN}✅ Use --skip-packages flag to run in mock mode without Firebase${NC}"
    echo ""
    
    # Try automated resolution after manual installation
    print_info "After adding packages in Xcode, run this command to resolve dependencies:"
    echo "  xcodebuild -resolvePackageDependencies -project bookApp.xcodeproj"
    echo ""
    
    cd "$PROJECT_DIR"
}

# Function to handle Firebase module errors
handle_firebase_errors() {
    print_error "🚨 Firebase Module Errors Detected!"
    echo ""
    echo -e "${RED}Common Firebase Errors:${NC}"
    echo "• Missing required modules: 'FirebaseCore', 'FirebaseCoreExtension', 'FirebaseFirestoreInternalWrapper'"
    echo "• Module 'FirebaseAuth' not found"
    echo "• No such module 'FirebaseFirestore'"
    echo ""
    echo -e "${YELLOW}💡 Solutions:${NC}"
    echo ""
    echo -e "${GREEN}OPTION 1: Install Firebase Packages (Recommended)${NC}"
    echo "1. In Xcode: File → Add Package Dependencies"
    echo "2. URL: https://github.com/firebase/firebase-ios-sdk"
    echo "3. Add ALL required packages (see list above)"
    echo "4. Clean build: Product → Clean Build Folder"
    echo "5. Build again: ⌘+B"
    echo ""
    echo -e "${GREEN}OPTION 2: Run in Mock Mode (Quick Fix)${NC}"
    echo "1. Close Xcode"
    echo "2. Run: ./launch_app.sh --mock-mode"
    echo "3. This disables Firebase and uses mock data"
    echo "4. App will work immediately with sample data"
    echo ""
    echo -e "${GREEN}OPTION 3: Fix Package Resolution${NC}"
    echo "1. In Xcode: File → Packages → Reset Package Caches"
    echo "2. File → Packages → Resolve Package Versions"
    echo "3. Clean build: Product → Clean Build Folder"
    echo "4. Build again: ⌘+B"
    echo ""
    print_info "Choose the option that works best for your needs!"
}

# Function to start Firebase emulators
start_firebase() {
    print_info "Starting Firebase emulators..."
    
    if ! command_exists firebase; then
        print_warning "Firebase CLI not found. Installing..."
        if command_exists npm; then
            npm install -g firebase-tools
        else
            print_error "npm not found. Please install Node.js first."
            return 1
        fi
    fi
    
    if [[ -f "$PROJECT_DIR/functions/package.json" ]]; then
        print_info "Installing Firebase Functions dependencies..."
        cd "$PROJECT_DIR/functions"
        npm install
        cd "$PROJECT_DIR"
    fi
    
    print_info "Starting Firebase emulators in background..."
    firebase emulators:start --only firestore,storage,functions &
    FIREBASE_PID=$!
    
    print_status "Firebase emulators started (PID: $FIREBASE_PID)"
    echo "🔥 Firebase Console: http://localhost:4000"
    echo "🗄️  Firestore: http://localhost:8080"
    echo "📁 Storage: http://localhost:9199"
    
    # Wait for emulators to start
    sleep 5
}

# Function to open and run iOS app
launch_ios_app() {
    print_info "Opening Xcode project..."
    
    cd "$PROJECT_DIR/bookApp/bookApp"
    
    # Open Xcode project
    open bookApp.xcodeproj
    
    print_status "Xcode project opened successfully"
    print_info "The app will open in Xcode. Press ⌘+R to build and run."
    
    # Optional: Auto-build and run (commented out as it might interfere with user workflow)
    # print_info "Building and running app..."
    # xcodebuild -project bookApp.xcodeproj -scheme bookApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' build
    # xcrun simctl boot "iPhone 15 Pro" 2>/dev/null || true
    # xcodebuild -project bookApp.xcodeproj -scheme bookApp -destination 'platform=iOS Simulator,name=iPhone 15 Pro' run
}

# Function to show app information
show_app_info() {
    echo ""
    echo -e "${BLUE}📱 App Information${NC}"
    echo -e "${BLUE}==================${NC}"
    echo "🏠 Project: BookstoreApp"
    echo "📍 Location: $PROJECT_DIR"
    echo "🔧 Platform: iOS 15.0+"
    if [[ "$FORCE_MOCK_MODE" == true ]]; then
        echo "🎯 Mode: Mock Data (Firebase Disabled)"
    else
        echo "🎯 Mode: Development (Mock Data)"
    fi
    echo ""
    echo -e "${GREEN}🎮 How to use:${NC}"
    echo "1. Enter any phone number (e.g., +1234567890)"
    echo "2. Enter any 6-digit OTP (e.g., 123456)"
    echo "3. Complete registration with your details"
    echo "4. Explore the app features!"
    echo ""
    echo -e "${YELLOW}💡 Features available:${NC}"
    echo "• 📚 Browse books catalog"
    echo "• ➕ Add new books (ISBN scanning)"
    echo "• 📖 My Library management"
    echo "• 👤 User profile & settings"
    echo "• 🏠 Society/building management"
    echo ""
    echo -e "${BLUE}🔥 Firebase Integration:${NC}"
    echo "• Install Firebase packages in Xcode (instructions shown above)"
    echo "• Add GoogleService-Info.plist to your project"
    echo "• Use --firebase flag to start emulators"
    echo "• App works with mock data without Firebase setup"
    echo ""
    echo -e "${RED}🚨 Got Firebase Errors?${NC}"
    echo "• Firebase modules missing: ./fix_firebase_errors.sh"
    echo "• GoogleService-Info.plist missing: ./fix_googleservice_plist.sh"
    echo "• Quick fix (no Firebase): ./launch_app.sh --mock-mode"
    echo "• App crashes on launch: Use mock mode immediately"
    echo ""
}

# Function to cleanup on exit
cleanup() {
    if [[ -n "$FIREBASE_PID" ]]; then
        print_info "Stopping Firebase emulators..."
        kill $FIREBASE_PID 2>/dev/null || true
    fi
}

# Trap cleanup on script exit
trap cleanup EXIT

# Main execution
main() {
    # Parse command line arguments
    LAUNCH_FIREBASE=false
    SKIP_PACKAGES=false
    FORCE_MOCK_MODE=false
    
    while [[ $# -gt 0 ]]; do
        case $1 in
            -f|--firebase)
                LAUNCH_FIREBASE=true
                shift
                ;;
            -s|--skip-packages)
                SKIP_PACKAGES=true
                shift
                ;;
            -m|--mock-mode)
                FORCE_MOCK_MODE=true
                SKIP_PACKAGES=true
                shift
                ;;
            -h|--help)
                echo "Usage: $0 [OPTIONS]"
                echo "Options:"
                echo "  -f, --firebase       Start Firebase emulators"
                echo "  -s, --skip-packages  Skip Firebase package installation check"
                echo "  -m, --mock-mode      Force mock mode (no Firebase, no packages)"
                echo "  -h, --help           Show this help message"
                echo ""
                echo "Examples:"
                echo "  $0                   # Standard launch with Firebase check"
                echo "  $0 --firebase        # Launch with Firebase emulators"
                echo "  $0 --skip-packages   # Skip package check"
                echo "  $0 --mock-mode       # Run in mock mode (no Firebase)"
                exit 0
                ;;
            *)
                print_error "Unknown option: $1"
                exit 1
                ;;
        esac
    done
    
    # Check prerequisites
    check_prerequisites
    
    # Install Firebase packages
    if [[ "$FORCE_MOCK_MODE" == true ]]; then
        print_warning "Running in MOCK MODE - Firebase packages disabled"
        print_info "App will work with mock data and authentication"
    elif [[ "$SKIP_PACKAGES" == false ]]; then
        install_firebase_packages
    else
        print_info "Skipping Firebase package installation check"
    fi
    
    # Start Firebase if requested
    if [[ "$LAUNCH_FIREBASE" == true ]]; then
        start_firebase
    else
        print_info "Running in mock data mode (use -f to start Firebase)"
    fi
    
    # Launch iOS app
    launch_ios_app
    
    # Show app information
    show_app_info
    
    if [[ "$LAUNCH_FIREBASE" == true ]]; then
        print_info "Firebase emulators are running in background"
        print_info "Press Ctrl+C to stop emulators and exit"
        
        # Keep script running to maintain Firebase emulators
        while true; do
            sleep 1
        done
    else
        print_status "App launched successfully in development mode!"
    fi
}

# Run main function
main "$@" 