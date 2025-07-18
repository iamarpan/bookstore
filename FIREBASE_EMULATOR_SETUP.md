# Firebase Emulator Setup Guide

This guide explains how to use the `setup_firebase_emulators.sh` script to set up your complete Firebase development environment.

## Overview

The setup script automatically installs and configures everything you need for Firebase development:

- ☕ **Java 11+** (required for Firebase emulators)
- 📦 **Node.js 16+** (required for Firebase CLI)
- 🔥 **Firebase CLI** (for running emulators)
- ⚙️ **Firebase Functions dependencies**
- 🗂️ **DataConnect directories**
- 🚀 **All Firebase emulators**

## Quick Start

### 1. Run the Setup Script

```bash
# Make script executable (if not already)
chmod +x setup_firebase_emulators.sh

# Run full setup
./setup_firebase_emulators.sh
```

### 2. What the Script Does

The script will:

1. **Check/Install Java 11** using Homebrew
2. **Check/Install Node.js** using Homebrew  
3. **Install Firebase CLI** globally via npm
4. **Set up Functions dependencies** (if functions/ exists)
5. **Create DataConnect directories**
6. **Optional Firebase login** (for accessing your projects)
7. **Start all Firebase emulators**

### 3. Firebase Emulator URLs

Once running, access these URLs:

- 🔥 **Emulator Suite UI**: http://localhost:4000
- 🗄️ **Firestore Emulator**: http://localhost:8080  
- 📁 **Storage Emulator**: http://localhost:9199
- ⚡ **Functions Emulator**: http://localhost:5001
- 🔗 **DataConnect**: http://localhost:9399

## Command Line Options

### Basic Usage

```bash
# Full setup and start emulators
./setup_firebase_emulators.sh

# Setup without Firebase login
./setup_firebase_emulators.sh --no-login

# Show help
./setup_firebase_emulators.sh --help
```

### Install Individual Components

```bash
# Install only Java
./setup_firebase_emulators.sh --java-only

# Install only Node.js
./setup_firebase_emulators.sh --node-only

# Install only Firebase CLI
./setup_firebase_emulators.sh --cli-only
```

## Prerequisites

### System Requirements

- **macOS** (tested on macOS 10.15+)
- **Internet connection** (for downloading packages)
- **Terminal access**

### What Gets Installed

The script uses **Homebrew** to install packages. If Homebrew isn't installed, the script will install it first.

#### Java Installation
- Installs **OpenJDK 11** via Homebrew
- Sets up `JAVA_HOME` environment variable
- Creates system symlinks for compatibility
- Adds `JAVA_HOME` to your shell profile (`.zshrc` or `.bash_profile`)

#### Node.js Installation
- Installs **latest stable Node.js** via Homebrew
- Includes **npm** package manager
- Verifies Node.js version compatibility (16+)

#### Firebase CLI Installation
- Installs **firebase-tools** globally via npm
- Provides `firebase` command for emulator management
- Supports all Firebase services and commands

## Firebase Project Configuration

### Demo Project Mode

By default, the script uses `demo-bookstore` as the project ID for local development. This allows you to:

- Run emulators without a real Firebase project
- Test all Firebase features locally
- Develop offline without internet connection

### Using Your Own Project

To connect to your real Firebase project:

1. **Login to Firebase** (when prompted by script)
2. **Modify project ID** in the script or use:
   ```bash
   export FIREBASE_PROJECT_ID="your-project-id"
   ./setup_firebase_emulators.sh
   ```

## iOS App Integration

### Automatic Connection

Your iOS app will automatically connect to local emulators when:

- Running in **development mode**
- Using **debug builds**
- Emulators are running on standard ports

### Manual Configuration

If needed, configure your iOS app to use emulators:

```swift
// In your app startup code
#if DEBUG
// Connect to Firestore emulator
let settings = Firestore.firestore().settings
settings.host = "localhost:8080"
settings.isPersistenceEnabled = false
settings.isSSLEnabled = false
Firestore.firestore().settings = settings

// Connect to Auth emulator
Auth.auth().useEmulator(withHost: "localhost", port: 9099)

// Connect to Storage emulator
Storage.storage().useEmulator(withHost: "localhost", port: 9199)
#endif
```

## Troubleshooting

### Common Issues

#### 1. Java Version Problems

**Error**: `Java version too old` or `JAVA_HOME not set`

**Solution**:
```bash
# Install Java 11
./setup_firebase_emulators.sh --java-only

# Verify installation
java -version
echo $JAVA_HOME
```

#### 2. Node.js Version Problems

**Error**: `Node.js version too old`

**Solution**:
```bash
# Install latest Node.js
./setup_firebase_emulators.sh --node-only

# Verify installation
node --version
npm --version
```

#### 3. Firebase CLI Issues

**Error**: `firebase command not found`

**Solution**:
```bash
# Install Firebase CLI
./setup_firebase_emulators.sh --cli-only

# Verify installation
firebase --version
```

#### 4. Permission Errors

**Error**: `Permission denied` when installing packages

**Solution**:
```bash
# The script will prompt for sudo password when needed
# Make sure you have admin privileges

# If npm permissions are wrong:
sudo chown -R $(whoami) $(npm config get prefix)/{lib/node_modules,bin,share}
```

#### 5. Port Conflicts

**Error**: `Port already in use`

**Solution**:
```bash
# Find and kill processes using Firebase ports
lsof -ti:4000,8080,9199,5001,9399 | xargs kill

# Or restart with different ports in firebase.json
```

#### 6. Homebrew Issues

**Error**: `brew command not found`

**Solution**:
```bash
# Install Homebrew manually
/bin/bash -c "$(curl -fsSL https://raw.githubusercontent.com/Homebrew/install/HEAD/install.sh)"

# For Apple Silicon Macs, add to PATH:
echo 'eval "$(/opt/homebrew/bin/brew shellenv)"' >> ~/.zprofile
eval "$(/opt/homebrew/bin/brew shellenv)"
```

### Verification Commands

```bash
# Check Java installation
java -version
echo $JAVA_HOME

# Check Node.js installation  
node --version
npm --version

# Check Firebase CLI
firebase --version

# Check if emulators are running
curl http://localhost:4000
curl http://localhost:8080
```

## Manual Setup (Alternative)

If the script doesn't work for your system, you can install manually:

### 1. Install Java 11+

```bash
# Via Homebrew
brew install openjdk@11

# Set JAVA_HOME
export JAVA_HOME=$(/usr/libexec/java_home -v 11)
echo 'export JAVA_HOME=$(/usr/libexec/java_home -v 11)' >> ~/.zshrc
```

### 2. Install Node.js 16+

```bash
# Via Homebrew
brew install node

# Verify
node --version  # Should be 16+
```

### 3. Install Firebase CLI

```bash
# Via npm
npm install -g firebase-tools

# Verify
firebase --version
```

### 4. Start Emulators

```bash
# Navigate to project directory
cd /path/to/your/firebase/project

# Start emulators
firebase emulators:start --project=demo-project
```

## Development Workflow

### Daily Development

1. **Start emulators**:
   ```bash
   ./setup_firebase_emulators.sh
   ```

2. **Develop your app** with emulators running

3. **Stop emulators**: Press `Ctrl+C` in terminal

### Data Persistence

```bash
# Export emulator data
firebase emulators:start --export-on-exit=./backup

# Import existing data
firebase emulators:start --import=./backup
```

### Production Deployment

```bash
# Deploy to production
firebase deploy

# Deploy specific services
firebase deploy --only firestore,storage,functions
```

## Support

### Getting Help

- **Script issues**: Check the troubleshooting section above
- **Firebase issues**: Visit [Firebase Documentation](https://firebase.google.com/docs)
- **Emulator issues**: Check [Firebase Emulator Suite docs](https://firebase.google.com/docs/emulator-suite)

### Useful Commands

```bash
# View Firebase projects
firebase projects:list

# View emulator status
firebase emulators:exec --only firestore "echo 'Emulators ready'"

# Clear emulator data
firebase emulators:start --only firestore --import=./empty-data

# View function logs
firebase functions:log

# Validate Firebase configuration
firebase use --add
```

---

**🚀 Happy coding with Firebase emulators!** 