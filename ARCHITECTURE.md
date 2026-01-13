# TaskWask - Features & Architecture Documentation

## 🎯 Feature Overview

### Authentication System
- **Email/Password Authentication**: Traditional sign-up and login
- **Google Sign-In**: One-tap authentication with Google account
- **Persistent Sessions**: Auto-login for 10 days after last sign-in
- **Session Validation**: Automatic session expiry and re-authentication
- **Secure Sign-Out**: Proper cleanup of authentication tokens and local storage

### Task Management

#### Task Properties
Each task contains:
- `id`: Unique identifier (UUID)
- `userId`: Owner's Firebase UID
- `taskName`: Title of the task
- `description`: Detailed description
- `creationDate`: When the task was created
- `dueDate`: When the task is due (includes time)
- `status`: To-Do, In Progress, or Done
- `category`: Optional custom category (e.g., "Work", "Personal")
- `isWishlist`: Flag for wishlist items
- `reminderTime`: Optional custom reminder timestamp

#### Smart Filtering
1. **To-Do Tab**: Shows ONLY tasks scheduled for TODAY
   - Future tasks appear automatically on their scheduled date
   - Past incomplete tasks marked as overdue
   
2. **In Progress Tab**: Shows all in-progress tasks regardless of date

3. **Done Tab**: Shows all completed tasks

#### CRUD Operations
- **Create**: Add new tasks with all properties
- **Read**: Stream-based real-time updates from Firestore
- **Update**: Edit any task property including status
- **Delete**: Remove tasks with confirmation dialog

### Notification System

#### Due Date Notifications
- Automatically scheduled when task is created
- Triggers at exact due date/time
- Uses Android ExactAlarm for precision

#### Custom Reminders
Users can set reminders:
- **1 hour before** due date
- **1 day before** due date
- **1 week before** due date
- **Custom time** (user selects date/time)
- **No reminder** option

#### Notification Features
- Background notifications
- Clickable notifications (navigate to task)
- Auto-cancellation when task is completed/deleted
- Rescheduling support when task is edited

### User Interface

#### Theme System
**Premium Black & White Design**:
- Primary Black: `#000000`
- Primary White: `#FFFFFF`
- Dark Grey: `#1A1A1A`
- Medium Grey: `#2D2D2D`
- Light Grey: `#E0E0E0`

**Typography**:
- Clean, readable fonts
- Proper hierarchy (Display, Headline, Title, Body)
- Letter spacing for premium feel

**Components**:
- Custom-styled cards with borders
- Rounded corners (12px standard)
- Minimalist icons
- Black and white status indicators

#### Animations

1. **Splash Screen**:
   - Fade-in animation
   - Scale animation with elastic effect
   - Rotation animation for logo
   - Custom triangle (|>) icon painter

2. **Task Cards**:
   - Scale animation on tap
   - Smooth expand/collapse for descriptions
   - Status change animations

3. **Screen Transitions**:
   - Hero animations for task details
   - Slide transitions between screens

#### Custom Icon
Triangle play icon (|>) painted with CustomPainter:
- Vertical line on left
- Triangle pointing right
- Pure black (#000000)
- Used in splash screen and login

## 🏗️ Architecture

### Project Structure

```
lib/
├── main.dart                           # App initialization & routing
├── firebase_options.dart               # Firebase configuration
│
├── models/                             # Data Models
│   ├── task_model.dart                # Task entity with methods
│   └── user_model.dart                # User entity
│
├── repositories/                       # Data Layer
│   ├── auth_repository.dart           # Authentication logic
│   └── task_repository.dart           # Task CRUD & queries
│
├── services/                           # Services
│   └── notification_service.dart      # Notification management
│
├── screens/                            # UI Screens
│   ├── splash_screen.dart             # Animated splash
│   ├── login_screen.dart              # Login UI
│   ├── signup_screen.dart             # Sign-up UI
│   ├── home_screen.dart               # Main dashboard with tabs
│   ├── add_task_screen.dart           # Task creation form
│   ├── edit_task_screen.dart          # Task editing form
│   └── profile_screen.dart            # User profile
│
├── widgets/                            # Reusable Widgets
│   └── task_card.dart                 # Task display component
│
└── theme/                              # Styling
    └── app_theme.dart                 # Theme configuration & constants
```

### State Management

**Provider Pattern**:
- `AuthRepository`: Singleton provider for authentication state
- `TaskRepository`: Singleton provider for task operations
- `StreamBuilder`: Real-time data updates from Firestore

**Why Provider?**:
- Simple and efficient for this app's complexity
- Good separation of concerns
- Easy to test
- Low boilerplate

### Data Flow

```
UI (Screens/Widgets)
    ↓
Providers (context.read<Repository>())
    ↓
Repositories (Business Logic)
    ↓
Firebase Services (Auth, Firestore)
    ↓
Cloud (Firebase Backend)
```

**Real-time Updates**:
```
Firestore changes
    ↓
Stream updates
    ↓
StreamBuilder rebuilds
    ↓
UI reflects changes
```

## 🔐 Security

### Authentication
- Firebase Auth handles all authentication
- Passwords never stored locally
- OAuth tokens managed by Firebase
- Automatic token refresh

### Data Access Rules
```javascript
// Firestore Security Rules
match /tasks/{taskId} {
  // Users can only read/write their own tasks
  allow read, write: if request.auth.uid == resource.data.userId;
  allow create: if request.auth.uid == request.resource.data.userId;
}
```

### Local Storage
- Only stores last login timestamp (for session validation)
- No sensitive data cached locally
- Automatic cleanup on sign-out

## 📊 Database Schema

### Firestore Collection: `tasks`

```json
{
  "id": "uuid-string",
  "userId": "firebase-user-uid",
  "taskName": "Complete project",
  "description": "Finish TaskWask implementation",
  "creationDate": Timestamp,
  "dueDate": Timestamp,
  "status": "toDo" | "inProgress" | "done",
  "category": "Work" | null,
  "isWishlist": false,
  "reminderTime": Timestamp | null
}
```

### Indexes Required
Firestore will auto-suggest these when querying:
1. `userId` + `isWishlist` + `dueDate`
2. `userId` + `status` + `dueDate`

## 🎨 Design Principles

### Premium Aesthetic
1. **Minimalism**: Clean, uncluttered interfaces
2. **High Contrast**: Black on white for clarity
3. **Consistency**: Same spacing, borders, and styles throughout
4. **Typography**: Clear hierarchy, good readability
5. **Whitespace**: Generous padding and margins

### User Experience
1. **Intuitive Navigation**: Clear tabs and icons
2. **Immediate Feedback**: Loading states, success messages
3. **Error Handling**: Friendly error messages
4. **Confirmations**: Dialogs for destructive actions
5. **Smooth Animations**: Subtle, purposeful motion

## 🚀 Performance Optimizations

### Firestore Queries
- Indexed queries for fast lookups
- Stream-based updates (no polling)
- Efficient filtering on server-side

### UI Rendering
- `const` constructors where possible
- ListView.builder for large lists
- Proper disposal of controllers and streams

### Notifications
- Batch scheduling
- Efficient cancellation
- Background processing

## 🧪 Testing Strategy

### Unit Tests (Recommended)
- Model serialization/deserialization
- Repository methods
- Date filtering logic

### Widget Tests (Recommended)
- Screen rendering
- Form validation
- User interactions

### Integration Tests (Recommended)
- Complete user flows
- Firebase integration
- Notification scheduling

## 📈 Future Enhancements

### Phase 2 Features
- [ ] Task search and advanced filtering
- [ ] Recurring tasks
- [ ] Subtasks and checklists
- [ ] Task priority levels
- [ ] Statistics and productivity insights

### Phase 3 Features
- [ ] Collaboration (share tasks)
- [ ] Dark mode toggle
- [ ] Multiple theme options
- [ ] File attachments
- [ ] Voice input

### Technical Improvements
- [ ] Offline support with local caching
- [ ] Biometric authentication
- [ ] Widget for home screen
- [ ] Wear OS support
- [ ] Cloud backup/restore

## 🛠️ Development Guidelines

### Code Style
- Follow Dart/Flutter style guide
- Use meaningful variable names
- Add comments for complex logic
- Keep functions small and focused

### Git Workflow
- Feature branches for new features
- Descriptive commit messages
- Pull requests for code review

### Documentation
- Update README for new features
- Document API changes
- Keep architecture docs current

---

**Built with best practices and modern Flutter development standards** 🎯
