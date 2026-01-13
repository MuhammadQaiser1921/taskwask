# Firebase Setup Instructions

This project uses Firebase for authentication, database, and storage. Follow these steps to configure Firebase for your own instance:

## Prerequisites
- Flutter SDK installed
- Firebase CLI installed (`npm install -g firebase-tools`)
- FlutterFire CLI installed (`dart pub global activate flutterfire_cli`)

## Setup Steps

### 1. Create a Firebase Project
1. Go to [Firebase Console](https://console.firebase.google.com/)
2. Click "Add Project"
3. Enter your project name
4. Enable Google Analytics (optional)

### 2. Configure Firebase for Flutter

Run the FlutterFire configuration command:
```bash
flutterfire configure
```

This will:
- Create `lib/firebase_options.dart` with your Firebase configuration
- Download platform-specific config files

### 3. Download Platform-Specific Config Files

#### For Android:
1. In Firebase Console, go to Project Settings
2. Under "Your apps", select the Android app
3. Download `google-services.json`
4. Place it in `android/app/google-services.json`

#### For iOS (if needed):
1. In Firebase Console, go to Project Settings
2. Under "Your apps", select the iOS app
3. Download `GoogleService-Info.plist`
4. Place it in `ios/Runner/GoogleService-Info.plist`

### 4. Update Web Configuration

Edit `web/index.html` and replace the Firebase config (around line 32-40) with your web app config from Firebase Console:

```javascript
const firebaseConfig = {
  apiKey: "YOUR_WEB_API_KEY",
  authDomain: "YOUR_PROJECT_ID.firebaseapp.com",
  projectId: "YOUR_PROJECT_ID",
  storageBucket: "YOUR_PROJECT_ID.firebasestorage.app",
  messagingSenderId: "YOUR_SENDER_ID",
  appId: "YOUR_WEB_APP_ID",
  measurementId: "YOUR_MEASUREMENT_ID"
};
```

### 5. Enable Firebase Services

In Firebase Console, enable:
1. **Authentication** → Enable Email/Password and Google Sign-In
2. **Firestore Database** → Create database in production mode
3. **Storage** → Create storage bucket

### 6. Configure Firebase Rules

#### Firestore Rules:
Go to Firestore Database → Rules and paste:
```
rules_version = '2';
service cloud.firestore {
  match /databases/{database}/documents {
    match /users/{userId} {
      allow read, write: if request.auth != null && request.auth.uid == userId;
    }
    match /tasks/{taskId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
    match /categories/{categoryId} {
      allow read, write: if request.auth != null && request.auth.uid == resource.data.userId;
    }
  }
}
```

#### Storage Rules:
Go to Storage → Rules and paste:
```
rules_version = '2';
service firebase.storage {
  match /b/{bucket}/o {
    match /profile_pictures/{userId} {
      allow read: if request.auth != null;
      allow write: if request.auth != null && request.auth.uid == userId;
    }
  }
}
```

### 7. Google Sign-In Configuration (Web)

1. In Firebase Console, go to Authentication → Sign-in method
2. Enable Google provider
3. Copy the Web Client ID
4. Update `web/index.html` meta tag (around line 9):
```html
<meta name="google-signin-client_id" content="YOUR_WEB_CLIENT_ID.apps.googleusercontent.com">
```

## Running the App

After completing the setup:
```bash
flutter pub get
flutter run
```

## Important Notes

- **NEVER commit** `firebase_options.dart`, `google-services.json`, or actual Firebase configs to public repositories
- Template files are provided: `*.example` files show the structure
- Each developer/environment should have their own Firebase project configuration
- API keys in Firebase config are meant to identify your Firebase project, but should still be protected with proper Firebase Security Rules
