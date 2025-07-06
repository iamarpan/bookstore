#!/bin/bash

# Firebase Emulator Setup Script
# Comprehensive setup including Java, Node.js, Firebase CLI, and emulator startup

set -e  # Exit on any error

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
BLUE='\033[0;34m'
PURPLE='\033[0;35m'
CYAN='\033[0;36m'
NC='\033[0m' # No Color

# Script directory
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
PROJECT_DIR="$SCRIPT_DIR"

# Configuration
JAVA_VERSION="11"
NODE_MIN_VERSION="16"
FIREBASE_PROJECT_ID="demo-bookstore"

echo -e "${BLUE}🔥 Firebase Emulator Setup Script${NC}"
echo -e "${BLUE}=================================${NC}"
echo -e "${CYAN}This script will set up your complete Firebase development environment${NC}"
echo ""

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

print_header() {
    echo -e "${PURPLE}🚀 $1${NC}"
}

# Function to check if command exists
command_exists() {
    command -v "$1" >/dev/null 2>&1
}

# Function to get macOS version for compatibility
get_macos_version() {
    sw_vers -productVersion | cut -d '.' -f 1-2
}

# Function to install Java
install_java() {
    print_header "STEP 1: Java Installation"
    
    if command_exists java; then
        JAVA_VER=$(java -version 2>&1 | head -n 1 | cut -d'"' -f2 | cut -d'.' -f1-2)
        print_info "Java version found: $JAVA_VER"
        
        # Check if Java version is 11 or higher
        if [[ "$JAVA_VER" =~ ^1\.8 ]] || [[ "$JAVA_VER" =~ ^[1-9][0-9]*\. ]] && [[ "${JAVA_VER%%.*}" -ge 11 ]]; then
            print_status "Java $JAVA_VER is compatible with Firebase"
            export JAVA_HOME=$(/usr/libexec/java_home)
            print_info "JAVA_HOME set to: $JAVA_HOME"
            return 0
        else
            print_warning "Java version $JAVA_VER is too old. Firebase requires Java 11+"
        fi
    else
        print_warning "Java not found on system"
    fi
    
    print_info "Installing Java $JAVA_VERSION using Homebrew..."
    
    # Check if Homebrew is installed
    if ! command_exists brew; then
        print_warning "Homebrew not found. Installing Homebrew first..."
        /bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"
        
        # Add Homebrew to PATH for Apple Silicon Macs
        if [[ $(uname -m) == "arm64" ]]; then
            echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
            eval "$(/opt/homebrew/bin/brew shellenv)"
        fi
    fi
    
    print_info "Installing OpenJDK $JAVA_VERSION..."
    brew install openjdk@$JAVA_VERSION
    
    # Create symlink for system Java wrappers
    if [[ $(uname -m) == "arm64" ]]; then
        JAVA_PATH="/opt/homebrew/opt/openjdk@$JAVA_VERSION"
    else
        JAVA_PATH="/usr/local/opt/openjdk@$JAVA_VERSION"
    fi
    
    sudo ln -sfn $JAVA_PATH/libexec/openjdk.jdk /Library/Java/JavaVirtualMachines/openjdk-$JAVA_VERSION.jdk
    
    # Set JAVA_HOME
    export JAVA_HOME=$(/usr/libexec/java_home -v $JAVA_VERSION)
    
    # Add to shell profile
    SHELL_PROFILE=""
    if [[ "$SHELL" == *"zsh"* ]]; then
        SHELL_PROFILE="$HOME/.zshrc"
    elif [[ "$SHELL" == *"bash"* ]]; then
        SHELL_PROFILE="$HOME/.bash_profile"
    fi
    
    if [[ -n "$SHELL_PROFILE" ]]; then
        echo "export JAVA_HOME=\$(/usr/libexec/java_home -v $JAVA_VERSION)" >> "$SHELL_PROFILE"
        print_info "Added JAVA_HOME to $SHELL_PROFILE"
    fi
    
    print_status "Java $JAVA_VERSION installed successfully"
    print_info "JAVA_HOME: $JAVA_HOME"
}

# Function to install Node.js
install_nodejs() {
    print_header "STEP 2: Node.js Installation"
    
    if command_exists node; then
        NODE_VER=$(node --version | sed 's/v//')
        NODE_MAJOR=$(echo $NODE_VER | cut -d'.' -f1)
        
        if [[ $NODE_MAJOR -ge $NODE_MIN_VERSION ]]; then
            print_status "Node.js $NODE_VER is compatible"
            return 0
        else
            print_warning "Node.js $NODE_VER is too old. Need version $NODE_MIN_VERSION+"
        fi
    else
        print_warning "Node.js not found"
    fi
    
    print_info "Installing Node.js using Homebrew..."
    
    if ! command_exists brew; then
        print_error "Homebrew is required but not found. Please install Homebrew first."
        exit 1
    fi
    
    brew install node
    
    # Verify installation
    if command_exists node && command_exists npm; then
        print_status "Node.js $(node --version) and npm $(npm --version) installed successfully"
    else
        print_error "Node.js installation failed"
        exit 1
    fi
}

# Function to install Firebase CLI
install_firebase_cli() {
    print_header "STEP 3: Firebase CLI Installation"
    
    if command_exists firebase; then
        FB_VER=$(firebase --version | head -n 1)
        print_status "Firebase CLI already installed: $FB_VER"
        return 0
    fi
    
    print_info "Installing Firebase CLI globally..."
    npm install -g firebase-tools
    
    # Verify installation
    if command_exists firebase; then
        print_status "Firebase CLI installed successfully: $(firebase --version | head -n 1)"
    else
        print_error "Firebase CLI installation failed"
        exit 1
    fi
}

# Function to setup Firebase functions dependencies
setup_functions() {
    print_header "STEP 4: Firebase Functions Setup"
    
    if [[ -f "$PROJECT_DIR/functions/package.json" ]]; then
        print_info "Installing Firebase Functions dependencies..."
        cd "$PROJECT_DIR/functions"
        
        if [[ -f "package-lock.json" ]]; then
            npm ci
        else
            npm install
        fi
        
        print_status "Functions dependencies installed"
        cd "$PROJECT_DIR"
    else
        print_warning "No functions/package.json found. Skipping functions setup."
    fi
}

# Function to setup DataConnect directory
setup_dataconnect() {
    print_header "STEP 5: DataConnect Setup"
    
    DATACONNECT_DIR="$PROJECT_DIR/dataconnect/.dataconnect/pgliteData"
    
    if [[ ! -d "$DATACONNECT_DIR" ]]; then
        print_info "Creating DataConnect data directory..."
        mkdir -p "$DATACONNECT_DIR"
        print_status "DataConnect directory created"
    else
        print_status "DataConnect directory already exists"
    fi
}

# Function to login to Firebase (optional)
firebase_login() {
    print_header "STEP 6: Firebase Authentication"
    
    if firebase projects:list >/dev/null 2>&1; then
        print_status "Already logged in to Firebase"
        return 0
    fi
    
    print_info "You can optionally log in to Firebase to access your projects"
    read -p "Do you want to log in to Firebase? (y/N): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Yy]$ ]]; then
        print_info "Opening browser for Firebase login..."
        firebase login
        print_status "Firebase login completed"
    else
        print_info "Skipping Firebase login. You can use demo project for development."
    fi
}

# Function to start Firebase emulators
start_emulators() {
    print_header "STEP 7: Starting Firebase Emulators"
    
    # Verify firebase.json exists
    if [[ ! -f "$PROJECT_DIR/firebase.json" ]]; then
        print_error "firebase.json not found in $PROJECT_DIR"
        print_info "Make sure you're running this script from your Firebase project root"
        exit 1
    fi
    
    print_info "Validating Firebase configuration..."
    
    # Set Firebase project for demo mode
    export FIREBASE_PROJECT_ID="$FIREBASE_PROJECT_ID"
    
    print_info "Starting Firebase emulators..."
    print_info "Project ID: $FIREBASE_PROJECT_ID"
    
    # Start emulators with all services
    firebase emulators:start --project="$FIREBASE_PROJECT_ID" || {
        print_error "Failed to start Firebase emulators"
        print_info "Trying with individual services..."
        firebase emulators:start --only firestore,storage,functions --project="$FIREBASE_PROJECT_ID"
    }
}

# Function to show emulator URLs
show_emulator_info() {
    echo ""
    print_header "🎉 Firebase Emulators Running!"
    echo ""
    echo -e "${GREEN}Firebase Emulator URLs:${NC}"
    echo -e "🔥 Emulator Suite UI:    ${CYAN}http://localhost:4000${NC}"
    echo -e "🗄️  Firestore Emulator:   ${CYAN}http://localhost:8080${NC}"
    echo -e "📁 Storage Emulator:     ${CYAN}http://localhost:9199${NC}"
    echo -e "⚡ Functions Emulator:   ${CYAN}http://localhost:5001${NC}"
    echo -e "🔗 DataConnect:          ${CYAN}http://localhost:9399${NC}"
    echo ""
    echo -e "${YELLOW}📱 iOS App Configuration:${NC}"
    echo "Your iOS app should connect to these emulators automatically"
    echo "when running in development mode."
    echo ""
    echo -e "${BLUE}💡 Useful Commands:${NC}"
    echo "• Stop emulators: Ctrl+C"
    echo "• View logs: Check terminal output"
    echo "• Reset data: firebase emulators:start --import=./backup --export-on-exit"
    echo ""
    echo -e "${GREEN}🚀 Development environment is ready!${NC}"
}

# Function to handle cleanup on exit
cleanup() {
    echo ""
    print_info "Cleaning up..."
    # Kill any background processes if needed
    exit 0
}

# Set up signal handlers
trap cleanup EXIT INT TERM

# Main execution
main() {
    # Check if we're on macOS
    if [[ "$OSTYPE" != "darwin"* ]]; then
        print_error "This script is designed for macOS. For other platforms, please install Java, Node.js, and Firebase CLI manually."
        exit 1
    fi
    
    print_info "Starting Firebase emulator setup for macOS..."
    print_info "This will install/verify: Java $JAVA_VERSION+, Node.js $NODE_MIN_VERSION+, Firebase CLI"
    echo ""
    
    # Show what will be installed
    echo -e "${CYAN}This script will:${NC}"
    echo "1. ☕ Install/verify Java $JAVA_VERSION (required for Firebase)"
    echo "2. 📦 Install/verify Node.js $NODE_MIN_VERSION+ (required for Firebase CLI)"
    echo "3. 🔥 Install/verify Firebase CLI"
    echo "4. ⚙️  Set up Firebase Functions dependencies"
    echo "5. 🗂️  Create DataConnect directories"
    echo "6. 🔐 Optional: Log in to Firebase"
    echo "7. 🚀 Start Firebase emulators"
    echo ""
    
    read -p "Continue with setup? (Y/n): " -n 1 -r
    echo
    
    if [[ $REPLY =~ ^[Nn]$ ]]; then
        print_info "Setup cancelled by user"
        exit 0
    fi
    
    # Execute setup steps
    install_java
    install_nodejs
    install_firebase_cli
    setup_functions
    setup_dataconnect
    firebase_login
    
    echo ""
    print_header "🎯 Starting Firebase Emulators"
    echo ""
    
    show_emulator_info
    
    # Start emulators (this will block)
    start_emulators
}

# Help function
show_help() {
    echo "Firebase Emulator Setup Script"
    echo ""
    echo "Usage: $0 [OPTIONS]"
    echo ""
    echo "Options:"
    echo "  -h, --help     Show this help message"
    echo "  --no-login     Skip Firebase login step"
    echo "  --java-only    Only install Java and exit"
    echo "  --node-only    Only install Node.js and exit"
    echo "  --cli-only     Only install Firebase CLI and exit"
    echo ""
    echo "Examples:"
    echo "  $0                # Full setup and start emulators"
    echo "  $0 --no-login     # Setup without Firebase login"
    echo "  $0 --java-only    # Just install Java"
}

# Parse command line arguments
case "${1:-}" in
    -h|--help)
        show_help
        exit 0
        ;;
    --no-login)
        firebase_login() { print_info "Skipping Firebase login"; }
        ;;
    --java-only)
        install_java
        exit 0
        ;;
    --node-only)
        install_nodejs
        exit 0
        ;;
    --cli-only)
        install_firebase_cli
        exit 0
        ;;
esac

# Run main function
main 