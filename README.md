# TaskWask - Premium Task Management App

A beautiful, high-end task management application built with Flutter and Firebase, featuring a premium black and white monochrome design.

## Features

### ✨ Core Features
- **Premium Black & White UI**: Clean, minimalist monochrome design with high contrast
- **Firebase Authentication**: 
  - Google Sign-In
  - Email/Password authentication
  - Persistent login (10-day session validity)
- **Smart Task Management**:
  - Create, read, update, and delete tasks
  - Task status tracking (To-Do, In Progress, Done)
  - Today's tasks view (only shows tasks scheduled for today)
  - Future task scheduling
  - Custom categories (Work, Personal, etc.)
  - Wishlist section for non-urgent items
- **Notifications & Reminders**:
  - Due date notifications
  - Custom reminder alerts (1 hour, 1 day, 1 week before, or custom time)
- **Profile Management**: User profile with logout functionality
- **Smooth Animations**: 
  - Animated splash screen with custom triangle icon (|>)
  - Micro-interactions for task status changes
  - Hero animations for screen transitions

## ⚠️ Important Security Notice

**This repository does NOT include Firebase configuration files for security reasons.**

Sensitive files like `firebase_options.dart`, `google-services.json`, and Firebase API keys are excluded from version control.

## Setup Instructions

**📋 See [SETUP_INSTRUCTIONS.md](SETUP_INSTRUCTIONS.md) for complete Firebase setup guide.**

### Quick Start

1. **Prerequisites**
   - Flutter SDK (^3.10.4)
   - Firebase account
   - Android Studio / VS Code

2. **Clone & Install**
   ```bash
   git clone <your-repo-url>
   cd taskwask
   flutter pub get
   ```

3. **Configure Firebase**
   ```bash
   # Install Firebase CLI
   npm install -g firebase-tools
   
   # Install FlutterFire CLI
   dart pub global activate flutterfire_cli
   
   # Configure your Firebase project
   flutterfire configure
   ```
   This will update `lib/firebase_options.dart` with your project details.

#### Enable Authentication
1. In Firebase Console, go to **Authentication** → **Sign-in method**
2. Enable **Email/Password** authentication
3. Enable **Google** sign-in

#### Create Firestore Database
1. Go to **Firestore Database** and create database
2. Set up security rules:
   ```javascript
   rules_version = '2';
   service cloud.firestore {
     match /databases/{database}/documents {
       match /tasks/{taskId} {
         allow read, write: if request.auth != null && 
                             request.auth.uid == resource.data.userId;
         allow create: if request.auth != null && 
                         request.auth.uid == request.resource.data.userId;
       }
     }
   }
   ```

### 3. Install Dependencies

```bash
flutter pub get
```

### 4. Run the App

```bash
flutter run
```

## Usage

### Creating Tasks
1. Tap the **+** button on the home screen
2. Fill in task details (name, description, due date, etc.)
3. Optionally set a reminder and category
4. Tap **Create Task**

### Managing Tasks
- **View Tasks**: Swipe between To-Do, In Progress, and Done tabs
- **Edit Task**: Tap on any task card
- **Change Status**: Tap the status icon
- **Delete Task**: Use the three-dot menu

## Customization

Modify theme colors in [lib/theme/app_theme.dart](lib/theme/app_theme.dart):

```dart
static const Color primaryBlack = Color(0xFF000000);
static const Color primaryWhite = Color(0xFFFFFFFF);
```

## License

© 2025 TaskWask. All rights reserved.

