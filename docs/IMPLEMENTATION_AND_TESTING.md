# Writtle — Implementation and Testing Plan

**Document Version:** 1.0.0  
**Status:** Draft / Pending Review  
**Product:** Writtle (Anonymous Storytelling Application)  
**Target:** Flutter (Android) + Supabase  

---

# PART 1: 12-MILESTONE DEVELOPMENT ROADMAP

---

### Milestone 1: Environment & Project Setup
- **Objective:** Establish a clean, reproducible development environment with essential toolchains and version control.
- **Tasks:**
  1. Initialize Git repository and commit initial baseline.
  2. Verify Android SDK, emulator, and physical test device readiness (`2404APC5FG`).
  3. Configure linting rules in `analysis_options.yaml` for clean code enforcement.
- **Dependencies:** None.
- **Affected Files:** `.gitignore`, `analysis_options.yaml`, `pubspec.yaml`.
- **Testing:** Execute `flutter doctor` and `flutter test`.
- **Completion Criteria:** Git tracking active, zero analyzer warnings on fresh boilerplate.

### Milestone 2: Documentation Review & Approval
- **Objective:** Formalize product specifications, business rules, database schema, and UI tokens before coding.
- **Tasks:**
  1. Complete and review all five documentation files in `docs/`.
  2. Align requirements with user approval.
- **Dependencies:** Milestone 1.
- **Affected Files:** `docs/PRD.md`, `docs/BUSINESS_AND_SYSTEM_DESIGN.md`, `docs/DATABASE_AND_API.md`, `docs/UI_UX_DESIGN.md`, `docs/IMPLEMENTATION_AND_TESTING.md`.
- **Testing:** Cross-reference validation across all documents.
- **Completion Criteria:** Explicit user approval of all specifications.

### Milestone 3: UI Foundation & Design System Tokens
- **Objective:** Implement the Editorial Minimalism design tokens and reusable visual primitives in Flutter.
- **Tasks:**
  1. Configure fonts (Serif headings, Sans UI).
  2. Implement `WrittleTheme` and `AppColors` palette (`#FBF9F5`, `#1A1816`, `#8B4513`, etc.).
  3. Create reusable atom widgets: `EditorialButton`, `CategoryChip`, `AnonymityToggle`, `WrittleAppBar`.
- **Dependencies:** Milestone 2.
- **Affected Files:** `lib/core/theme/`, `lib/core/widgets/`.
- **Testing:** Widget tests for theme tokens and custom buttons.
- **Completion Criteria:** Design tokens render accurately in isolation.

### Milestone 4: Navigation Shell & UI Prototype (Mock Data)
- **Objective:** Construct the complete screen navigation hierarchy with mock data before connecting to backend.
- **Tasks:**
  1. Implement Bottom Navigation Bar (Feed, Bookmarks, Profile).
  2. Build mock UI screens: `HomeFeedScreen`, `StoryReaderScreen`, `StoryEditorScreen`, `BookmarksScreen`, `ProfileScreen`.
  3. Connect routing between feed, reader, and editor.
- **Dependencies:** Milestone 3.
- **Affected Files:** `lib/screens/`, `lib/routes/`.
- **Testing:** Widget tests for navigation transitions and screen rendering.
- **Completion Criteria:** Fluid navigation across all core screens with zero layout overflows on Android.

### Milestone 5: Supabase Project & Client Configuration
- **Objective:** Configure the Supabase client SDK in Flutter safely.
- **Tasks:**
  1. Add `supabase_flutter` and `flutter_riverpod` to `pubspec.yaml`.
  2. Initialize Supabase in `main.dart` using environment variables or configuration constants.
  3. Guarantee zero storage of `service_role` keys in client code.
- **Dependencies:** Milestone 4.
- **Affected Files:** `pubspec.yaml`, `lib/main.dart`, `lib/core/constants/`.
- **Testing:** Smoke test connecting to Supabase URL.
- **Completion Criteria:** App boots and confirms active Supabase connection.

### Milestone 6: Database Schema, Views, & RLS Policies
- **Objective:** Deploy the PostgreSQL schema, indexes, `public_stories_view`, and Row Level Security policies.
- **Tasks:**
  1. Execute SQL migration scripts for tables: `profiles`, `categories`, `stories`, `comments`, `likes`, `bookmarks`, `reports`.
  2. Deploy `public_stories_view` ensuring author anonymity masking.
  3. Enable RLS and apply security policies defined in `docs/DATABASE_AND_API.md`.
  4. Seed default categories (`Reflections`, `Romance`, etc.).
- **Dependencies:** Milestone 5.
- **Affected Files:** `supabase/migrations/` or Supabase SQL Editor.
- **Testing:** Execute SQL RLS permission tests for public vs author contexts.
- **Completion Criteria:** All tables exist, RLS active, and anonymous queries conceal user ID.

### Milestone 7: Authentication Feature
- **Objective:** Implement user registration, login, logout, and profile initialization.
- **Tasks:**
  1. Build `AuthRepository` and `AuthNotifier` (Riverpod).
  2. Implement `LoginScreen` and `RegisterScreen` with form validation.
  3. Verify automatic profile creation trigger upon registration (`BR-001`).
- **Dependencies:** Milestone 6.
- **Affected Files:** `lib/features/auth/`, `lib/models/user_model.dart`.
- **Testing:** Automated tests for email/password validation, login success/failure (`TC-001`, `TC-002`).
- **Completion Criteria:** Full authentication cycle working with persistent session.

### Milestone 8: Story Feed & Reader Detail
- **Objective:** Connect public story reading with real backend data.
- **Tasks:**
  1. Implement `StoryRepository` and `StoryListNotifier`.
  2. Query `public_stories_view` with category filtering and pagination.
  3. Render `StoryReaderScreen` with estimated reading time and typography styling.
- **Dependencies:** Milestone 7.
- **Affected Files:** `lib/features/stories/`, `lib/models/story_model.dart`.
- **Testing:** Feed fetching, category filtering, and anonymity verification tests (`TC-003`, `TC-004`).
- **Completion Criteria:** Published stories display in feed; anonymous stories show `"Anonymous"` author.

### Milestone 9: Story Editor & Draft Management
- **Objective:** Enable creating, drafting, publishing, editing, and soft-deleting stories.
- **Tasks:**
  1. Implement story form with Title, Content, Category, and Anonymity toggle.
  2. Save draft functionality (`status = 'draft'`).
  3. Publish story functionality (`status = 'published'`).
  4. Author management screen ("My Stories & Drafts").
- **Dependencies:** Milestone 8.
- **Affected Files:** `lib/features/editor/`, `lib/features/profile/`.
- **Testing:** Draft isolation tests, publishing validation tests (`TC-005`, `TC-006`).
- **Completion Criteria:** Authors can create drafts, publish anonymously or with pen name, and delete their stories.

### Milestone 10: Social Interactions (Likes, Bookmarks, Comments)
- **Objective:** Implement mindful community interactions.
- **Tasks:**
  1. Toggle Like/Unlike with optimistic UI update.
  2. Toggle Bookmark with dedicated "Saved Stories" library.
  3. Comments bottom sheet with submission and author deletion.
- **Dependencies:** Milestone 9.
- **Affected Files:** `lib/features/interactions/`.
- **Testing:** Like idempotency, bookmark isolation, comment deletion tests (`TC-007`, `TC-008`).
- **Completion Criteria:** Interactions persist correctly in database and update UI counters.

### Milestone 11: Content Reporting & Moderation
- **Objective:** Equip users to report inappropriate narratives and administrators to moderate content.
- **Tasks:**
  1. Implement `ReportStoryDialog` and report submission service.
  2. Prevent duplicate reports (`BR-011`).
  3. Verify admin ability to flag story as `moderated` and confirm immediate feed removal.
- **Dependencies:** Milestone 10.
- **Affected Files:** `lib/features/moderation/`.
- **Testing:** Duplicate report prevention test, moderated story hiding test (`TC-009`, `TC-010`).
- **Completion Criteria:** Reports recorded in database; moderated stories vanish from public views.

### Milestone 12: End-to-End Verification & Release Readiness
- **Objective:** Comprehensive testing, code cleanup, and APK build verification.
- **Tasks:**
  1. Run full test suite (`flutter test`).
  2. Static analysis audit (`flutter analyze`).
  3. Test APK build for Android (`flutter build apk --release`).
  4. Perform real-device smoke test on Android device.
- **Dependencies:** Milestone 11.
- **Affected Files:** Entire project.
- **Testing:** Full regression test suite (`TC-001` through `TC-012`).
- **Completion Criteria:** Zero analyzer warnings, all tests pass, release APK installs and runs cleanly.

---

# PART 2: CODING STANDARDS & ARCHITECTURE

## 2.1. Clean Folder Structure
```
lib/
├── main.dart
├── core/
│   ├── constants/       # App constants, route paths, string assets
│   ├── theme/           # WrittleTheme, AppColors, typography tokens
│   ├── network/         # Supabase client wrapper & error mapping
│   ├── utils/           # Date formatters, reading time calculators
│   └── widgets/         # Shared UI atoms (Buttons, AppBar, Dialogs)
├── models/              # Immutable data models with fromMap/toMap
│   ├── user_profile.dart
│   ├── story.dart
│   ├── category.dart
│   ├── comment.dart
│   └── report.dart
├── repositories/        # Data access layer interfacing with Supabase
│   ├── auth_repository.dart
│   ├── story_repository.dart
│   ├── interaction_repository.dart
│   └── profile_repository.dart
├── providers/           # Riverpod state notifiers and providers
│   ├── auth_provider.dart
│   ├── feed_provider.dart
│   ├── story_detail_provider.dart
│   └── bookmarks_provider.dart
└── screens/             # UI presentation layer organized by feature
    ├── auth/
    ├── feed/
    ├── reader/
    ├── editor/
    ├── bookmarks/
    └── profile/
```

## 2.2. Dart Conventions
- Class names: `UpperCamelCase` (e.g. `StoryRepository`).
- Files and directories: `snake_case` (e.g. `story_card.dart`).
- Variables and functions: `lowerCamelCase` (e.g. `publishStory()`).
- Always use `const` constructors where possible to optimize widget rebuilding.
- No business logic inside `build()` methods; delegate to Riverpod notifiers.

---

# PART 3: SECURITY & PRIVACY CHECKLIST

- [ ] **SEC-01 (Public Anonymity):** Public feed queries select exclusively from `public_stories_view`. No `user_id` or email is ever returned for anonymous stories.
- [ ] **SEC-02 (RLS Enforcement):** Every PostgreSQL table has Row Level Security enabled.
- [ ] **SEC-03 (Draft Isolation):** Draft stories cannot be accessed or listed by any user other than the author (`auth.uid() = user_id`).
- [ ] **SEC-04 (Secret Isolation):** Only the public `anon` key is configured in the Flutter client. The `service_role` secret is strictly prohibited from client code.
- [ ] **SEC-05 (Input Sanitization):** Character length limits and trim validation are enforced on both client and database levels.
- [ ] **SEC-06 (Cascade Safety):** Account deletion cleans up associated profiles, stories, comments, and interactions cleanly via `ON DELETE CASCADE`.

---

# PART 4: TEST PLAN & TEST MATRIX

All test cases are mapped to requirements (`FR-xxx`) and business rules (`BR-xxx`).

| Test Case ID | Test Category | Target Feature | Mapped IDs | Test Procedure & Expected Outcome |
| :--- | :--- | :--- | :--- | :--- |
| **`TC-001`** | Unit | Auth Validation | `FR-001`, `BR-001` | Validate email regex and minimum 8-char password. Rejects malformed emails and short passwords. |
| **`TC-002`** | Integration | User Registration | `FR-001`, `FR-004` | Register new user. Verify `auth.users` row and matching `public.profiles` with generated Pen Name exist. |
| **`TC-003`** | Integration | Privacy Anonymity | `FR-014`, `BR-003`, `NFR-001` | Publish story with `is_anonymous=true`. Query public feed. Verify `author_name == 'Anonymous'` and `user_id` is absent. |
| **`TC-004`** | Integration | Pseudonym Mode | `FR-015`, `BR-002` | Publish story with `is_anonymous=false`. Query public feed. Verify `author_name == author's pen_name`. |
| **`TC-005`** | Integration | Draft Isolation | `FR-007`, `FR-011`, `BR-007` | User A saves draft. User B attempts query. User B receives empty result. |
| **`TC-006`** | Unit | Read Time Calculator | `FR-013` | Supply 400-word text string. Verify function outputs `2 min read`. |
| **`TC-007`** | Integration | Like Idempotency | `FR-018`, `BR-008` | User likes story $\rightarrow$ count increments. User likes again $\rightarrow$ count decrements (unlike). |
| **`TC-008`** | Integration | Bookmark Flow | `FR-019`, `FR-020`, `BR-009` | User bookmarks story $\rightarrow$ story appears in user's saved library. Unbookmark $\rightarrow$ removed. |
| **`TC-009`** | Integration | Duplicate Report | `FR-023`, `FR-024`, `BR-011` | User reports story once $\rightarrow$ success. User reports same story again $\rightarrow$ rejected with duplicate error. |
| **`TC-010`** | Integration | Moderation Removal | `FR-025`, `BR-012` | Admin sets `status='moderated'`. Verify story immediately disappears from public feed query. |
| **`TC-011`** | Widget | Empty State Rendering | `NFR-008`, `UI-Design` | Render feed with empty list. Verify poetic empty state widget displays with "Write" CTA. |
| **`TC-012`** | Widget | Error & Retry Flow | `NFR-007`, `UI-Design` | Simulate network failure. Verify user-friendly error banner and functional "Retry" button render. |
