# TaskWask - Quick Setup Guide

## 🚀 Quick Start

### Step 1: Firebase Configuration

**IMPORTANT**: Before running the app, you must configure Firebase.

1. Install Firebase CLI and FlutterFire CLI:
   ```bash
   npm install -g firebase-tools
   dart pub global activate flutterfire_cli
   ```

2. Login to Firebase:
   ```bash
   firebase login
   ```

3. Run FlutterFire configuration:
   ```bash
   flutterfire configure
   ```
   - Select/create your Firebase project
   - Choose platforms (Android, iOS, Web, etc.)
   - This will update `lib/firebase_options.dart`

### Step 2: Enable Firebase Services

Go to [Firebase Console](https://console.firebase.google.com/):

1. **Authentication**:
   - Enable Email/Password
   - Enable Google Sign-In
   - For Google: Add SHA-1 fingerprint for Android

2. **Firestore Database**:
   - Create database (production or test mode)
   - Add security rules (see below)

3. **Get SHA-1 (for Android Google Sign-In)**:
   ```bash
   cd android
   ./gradlew signingReport
   ```
   Copy SHA-1 and add to Firebase Console → Project Settings → Android app

### Step 3: Firestore Security Rules

In Firebase Console → Firestore Database → Rules:

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

### Step 4: Run the App

```bash
flutter pub get
flutter run
```

## 📱 Testing the App

### Test User Flow:
1. **Sign Up**: Create account with email/password or Google
2. **Add Task**: Tap + button, fill details, set due date
3. **View Tasks**: Check To-Do tab (today's tasks only)
4. **Edit Task**: Tap any task card to edit
5. **Change Status**: Tap status icon to move between To-Do/In Progress/Done
6. **Set Reminder**: Edit task, set custom reminder
7. **Profile**: View profile, sign out

## 🎨 Customization

### Change Theme Colors
Edit `lib/theme/app_theme.dart`:
```dart
static const Color primaryBlack = Color(0xFF000000);
static const Color primaryWhite = Color(0xFFFFFFFF);
```

### Change Login Session Duration
Edit `lib/repositories/auth_repository.dart`:
```dart
static const int _loginValidDays = 10; // Change this
```

## ⚠️ Common Issues

### Firebase Not Initialized
**Error**: `[core/no-app] No Firebase App '[DEFAULT]' has been created`
**Fix**: Run `flutterfire configure` and restart app

### Google Sign-In Failed
**Error**: Sign-in cancelled or failed
**Fix**: 
- Add SHA-1 to Firebase Console
- Download updated `google-services.json`
- Clean and rebuild: `flutter clean && flutter run`

### Notifications Not Working
**Fix**:
- Grant notification permissions in device settings
- For Android 12+: Grant "Exact Alarm" permission

## 📦 Project Structure

```
lib/
├── main.dart                   # App entry & Firebase init
├── firebase_options.dart       # Firebase config (auto-generated)
├── models/                     # Data models
├── repositories/               # Business logic & Firebase operations
├── services/                   # Notification service
├── screens/                    # UI screens
├── widgets/                    # Reusable widgets
└── theme/                      # App theme & constants
```

## 🔑 Key Features Implementation

### Today's Tasks Filter
Located in `lib/repositories/task_repository.dart`:
```dart
Stream<List<TaskModel>> getTodayTasks(String userId)
```
Automatically filters tasks to show only today's scheduled items.

### Persistent Login (10 Days)
Located in `lib/repositories/auth_repository.dart`:
```dart
Future<bool> isSessionValid()
```
Checks if last login was within 10 days.

### Custom Notifications
Located in `lib/services/notification_service.dart`:
- Due date notifications
- Custom reminder alerts (1hr, 1day, 1week, custom)

## 🎯 Next Steps

1. **Configure Firebase** (required)
2. **Test authentication** flows
3. **Create sample tasks**
4. **Test notifications**
5. **Customize theme** (optional)

## 📞 Support

For issues, check:
1. README.md (detailed documentation)
2. Firebase Console logs
3. Flutter DevTools

---

**Ready to build? Run `flutter run` and start managing tasks! 🚀**
