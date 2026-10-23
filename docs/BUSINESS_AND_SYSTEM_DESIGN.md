# Writtle — Business and System Design

**Document Version:** 1.0.0  
**Status:** Draft / Pending Review  
**Product:** Writtle (Anonymous Storytelling Application)  
**Target:** Flutter (Android) + Supabase  

---

# PART 1: BUSINESS LOGIC & RULES

This section outlines the core operational and domain rules governing the Writtle platform. All business rules are assigned a permanent identifier (`BR-xxx`).

---

## 1. Authentication & Identity Rules

### `BR-001`: Account Creation & Registration
- Users must provide an email and password to create an account.
- Passwords must be at least 8 characters in length.
- Upon registration, an internal user record is automatically created in `auth.users` (Supabase Auth) and an associated record is initialized in the `public.profiles` table.
- A random, unique default Pen Name (e.g. `Author_8192` or `Wanderer_401`) is generated for new accounts.

### `BR-002`: Separation of Identities
Writtle defines three distinct identity layers:
1. **Private Account Identity:** Email address and `auth.users.id`. Strictly internal, never displayed publicly under any circumstance.
2. **Pseudonymous Identity (Pen Name):** The public alias chosen by the user in their profile (e.g. `UrbanMonk`). Used when the author chooses to publish non-anonymously.
3. **Pure Anonymous Mode:** Stories published under this mode completely sever public linkage to both the real account and the Pen Name. The author string is rendered simply as `"Anonymous"`.

### `BR-003`: Public Anonymity Protection
- When a story is marked as `is_anonymous = true`, client-facing queries must not return the author's `user_id`, Pen Name, or avatar.
- Even if a user inspects the raw HTTP/JSON network response, no identifying metadata may be exposed.
- Internal database storage retains `user_id` strictly for author ownership validation (e.g., enabling the author to edit/delete their own story).

---

## 2. Story Lifecycle & Publishing Rules

### `BR-004`: Story States & Visibility
A story exists in one of the following states:
- `draft`: Only visible to the author. Not listed in public feeds or search results.
- `published`: Publicly visible to all readers in feeds and detail views, provided it is not archived or moderated.
- `archived`: Soft-deleted by the author. Hidden from public feeds and user profile, but preserved in the database for reference integrity and moderation audit.
- `moderated`: Hidden from all public feeds due to administrative action or policy violation.

```mermaid
stateDiagram-v2
    [*] --> Draft: User writes new story
    Draft --> Published: User publishes story
    Draft --> Discarded: User discards draft (Hard delete if never published)
    Published --> Published: User edits story content
    Published --> Archived: User deletes story (Soft delete)
    Published --> Moderated: Admin hides violating story
    Moderated --> Published: Admin restores story
    Archived --> [*]
    Discarded --> [*]
```

### `BR-005`: Story Creation & Publishing Validation
- **Title:** Minimum 3 characters, maximum 120 characters. Cannot be blank.
- **Content:** Minimum 30 characters, maximum 15,000 characters.
- **Category:** Must belong to the approved list of categories (`Reflections`, `Romance`, `Life Lessons`, `Fiction`, `Confessions`).
- **Anonymity Selection:** Author must explicitly designate whether the story is published anonymously (`is_anonymous = true`) or with their Pen Name (`is_anonymous = false`).
- Precondition: User must be authenticated.
- Expected Outcome: Record inserted into `stories` with appropriate status and timestamps.

### `BR-006`: Story Ownership & Editing
- Only the user whose `auth.uid()` matches `stories.user_id` may modify or soft-delete a story.
- An author may switch a published story from Pen Name to Anonymous at any time, but switching from Anonymous to Pen Name is allowed only by the original author.
- Edits made to published stories update the `updated_at` timestamp.

### `BR-007`: Draft Management
- A user may have multiple drafts stored privately.
- Drafts can be saved with incomplete data (e.g. title without content, or content without title).
- Drafts are strictly confidential: no other user or reader can read, list, or search another user's drafts.

---

## 3. Social Interactions & Community Rules

### `BR-008`: Story Reactions (Likes)
- Any authenticated user can like a published story.
- Liking is idempotent: a user can like a story at most once. Liking again acts as an "unlike" (toggling state).
- The total like count is cached or computed and displayed on the story.
- Liking an anonymous story does not reveal the author's identity to the liker, nor does it reveal the liker's identity to the public.

### `BR-009`: Bookmarking
- Authenticated users can bookmark published stories for personal reference.
- Bookmarks are strictly private to the user who created them.
- Users can view all their bookmarked stories in a dedicated "Bookmarks" library screen.

### `BR-010`: Comments & Discussion
- Authenticated users may post comments on any published story.
- Comments require content between 2 and 1,000 characters.
- Comment authors can delete their own comments.
- Story authors can delete any comment on their own story to preserve a constructive and respectful atmosphere.

---

## 4. Moderation & Abuse Prevention

### `BR-011`: User Reports
- Authenticated users can report a story for: `spam`, `harassment`, `hate_speech`, `explicit_content`, or `other`.
- A user may only submit one active report per story to prevent duplicate spam reporting.
- Reports are stored in a dedicated `reports` table accessible only to authenticated reporters (to insert) and administrators (to read and resolve).

### `BR-012`: Administrative Moderation
- Content flagged with multiple reports or deemed harmful can be marked with `status = 'moderated'` by an administrator.
- Once moderated, the story is instantly removed from public feeds and detail screens.
- For MVP, moderation actions are performed directly by the administrator via the Supabase dashboard.

---

## 5. Summary of Preconditions & Postconditions

| Operation | Precondition | Business Rule IDs | Expected Outcome |
| :--- | :--- | :--- | :--- |
| **Save Draft** | Authenticated user | `BR-001`, `BR-007` | Draft created/updated in `stories` with `status='draft'`. |
| **Publish Story** | Authenticated user, valid fields | `BR-005`, `BR-006` | Story updated with `status='published'`, `published_at=NOW()`. |
| **Edit Story** | Authenticated author | `BR-006` | Story content updated, `updated_at=NOW()`. |
| **Delete Story** | Authenticated author | `BR-004`, `BR-006` | Story soft-deleted (`deleted_at=NOW()`, `status='archived'`). |
| **Like Story** | Authenticated user | `BR-008` | Like row added/removed; counter updated. |
| **Add Comment** | Authenticated user, valid text | `BR-010` | Comment row added to `comments` table. |
| **Report Story** | Authenticated user, story exists | `BR-011` | Report row created in `reports`. |

---

# PART 2: SYSTEM DESIGN & ARCHITECTURE

---

## 6. System Overview & Architecture

Writtle utilizes a clean **2-Tier Client-Cloud Architecture**:
- **Mobile Client (Frontend):** Flutter application running on Android, implementing a layered clean architecture pattern (UI View $\leftrightarrow$ Riverpod State Providers $\leftrightarrow$ Repositories $\leftrightarrow$ Supabase Client SDK).
- **Backend as a Service (BaaS):** Supabase providing managed PostgreSQL, Auth Engine, REST/PostgREST APIs, and Row Level Security (RLS) enforcement.

```mermaid
graph TD
    subgraph "Flutter Android Client"
        UI["Presentation Layer\n(Screens, Widgets, Themes)"]
        State["State Management\n(Riverpod Providers & Notifiers)"]
        Repo["Data & Repository Layer\n(AuthRepo, StoryRepo, InteractionRepo)"]
        ClientSDK["Supabase Flutter SDK\n(GoTrue Client, PostgREST Client)"]
    end

    subgraph "Supabase Cloud Backend"
        Auth["Supabase Auth Engine\n(JWT, auth.users)"]
        PostgREST["PostgREST Engine\n(REST API Gateway)"]
        DB["PostgreSQL Database\n(Tables, Views, Functions)"]
        RLS["Row Level Security (RLS)\n(Role & Policy Enforcement)"]
    end

    UI --> State
    State --> Repo
    Repo --> ClientSDK
    ClientSDK -->|HTTPS / TLS| Auth
    ClientSDK -->|HTTPS / TLS| PostgREST
    PostgREST --> RLS
    RLS --> DB
```

---

## 7. Application Modules & Responsibilities

| Module | Location in Code | Responsibility |
| :--- | :--- | :--- |
| **Core** | `lib/core/` | Global constants, theme tokens, error types, network failure mappers, and utility helpers. |
| **Auth** | `lib/features/auth/` | Login, sign up, session management, and auth state listener. |
| **Profile** | `lib/features/profile/` | Viewing personal profile, editing Pen Name and bio, listing user's own stories and drafts. |
| **Feed / Stories** | `lib/features/stories/` | Story feed, category filtering, reading view, story creation and draft editing. |
| **Interactions** | `lib/features/interactions/` | Likes, bookmarks library, and comment discussions. |
| **Moderation** | `lib/features/moderation/` | User reporting dialog and submission handling. |

---

## 8. Critical System Workflows

### 8.1. Authentication Flow
```mermaid
sequenceDiagram
    autonumber
    actor User as User (Mobile App)
    participant UI as Login / Register UI
    participant AuthRepo as AuthRepository
    participant Supabase as Supabase Auth (GoTrue)
    participant DB as PostgreSQL (public.profiles)

    User->>UI: Enter email & password
    UI->>AuthRepo: signUp(email, password)
    AuthRepo->>Supabase: auth.signUp()
    Supabase-->>DB: Auto-trigger: insert into public.profiles
    Supabase-->>AuthRepo: Return AuthResponse (JWT + User)
    AuthRepo-->>UI: Success: Session active
    UI-->>User: Navigate to Main Story Feed
```

### 8.2. Story Publishing Flow (Anonymity Enforced)
```mermaid
sequenceDiagram
    autonumber
    actor Author as Story Author
    participant Editor as Story Editor Screen
    participant Notifier as StoryNotifier
    participant Repo as StoryRepository
    participant DB as Supabase PostgreSQL

    Author->>Editor: Fill Title, Body, Category
    Author->>Editor: Toggle "Publish Anonymously" (ON)
    Author->>Editor: Click "Publish Story"
    Editor->>Notifier: publishStory(payload)
    Notifier->>Repo: createStory(title, content, isAnonymous=true)
    Repo->>DB: INSERT into stories (user_id, title, content, is_anonymous=true, status='published')
    DB-->>DB: RLS verifies auth.uid() == user_id
    DB-->>Repo: 201 Created (Record confirmation)
    Repo-->>Notifier: Success Result
    Notifier-->>Editor: Navigate to Feed & show confirmation toast
```

### 8.3. Public Story Reading Flow (Privacy Preserved)
```mermaid
sequenceDiagram
    autonumber
    actor Reader as Story Reader
    participant Feed as Feed Screen
    participant Repo as StoryRepository
    participant DB as Supabase PostgreSQL

    Reader->>Feed: Open Feed (Pull to Refresh)
    Feed->>Repo: getPublishedStories(category, page)
    Repo->>DB: SELECT from public_stories_view WHERE status='published'
    Note over DB: Database View conceals user_id and email.<br/>If is_anonymous=true, author is 'Anonymous'.
    DB-->>Repo: Return sanitized story items
    Repo-->>Feed: Display stories with Editorial layout
```

---

## 9. Use Case Diagram

```mermaid
graph LR
    actorUser["Reader / User"]
    actorAuthor["Writer / Author"]
    actorAdmin["Administrator"]

    subgraph "Writtle System"
        UC_Auth["Sign Up / Login / Logout"]
        UC_Read["Read Public Stories"]
        UC_Filter["Filter by Category"]
        UC_Like["Like / Bookmark Story"]
        UC_Comment["Leave Comment"]
        UC_Report["Report Inappropriate Story"]

        UC_Draft["Create & Save Draft"]
        UC_PubAnon["Publish Story Anonymously"]
        UC_PubPen["Publish Story with Pen Name"]
        UC_Manage["Edit / Soft Delete Own Story"]

        UC_Mod["Review Reports & Moderate Content"]
    end

    actorUser --> UC_Auth
    actorUser --> UC_Read
    actorUser --> UC_Filter
    actorUser --> UC_Like
    actorUser --> UC_Comment
    actorUser --> UC_Report

    actorAuthor --> UC_Draft
    actorAuthor --> UC_PubAnon
    actorAuthor --> UC_PubPen
    actorAuthor --> UC_Manage

    actorAdmin --> UC_Mod
```

---

## 10. Navigation Flow

The mobile application utilizes a 3-tab Bottom Navigation Bar paired with modal or full-screen routes for focused tasks:

```mermaid
graph TD
    Splash["Splash Screen"] --> AuthCheck{"Authenticated?"}
    AuthCheck -->|No| Login["Login / Sign Up Screen"]
    AuthCheck -->|Yes| Main["Main Shell (Bottom Navigation)"]
    Login -->|Success| Main

    subgraph "Bottom Navigation Bar"
        Tab1["Feed Tab\n(Stories Feed & Categories)"]
        Tab2["Bookmarks Tab\n(Saved Stories Library)"]
        Tab3["Profile Tab\n(Pen Name, My Stories & Drafts)"]
    end

    Main --> Tab1
    Main --> Tab2
    Main --> Tab3

    Tab1 -->|Tap Story| Detail["Story Detail / Reader Screen"]
    Tab1 -->|Tap Floating Action Button| Editor["Story Editor Screen (Write / Edit)"]
    Detail -->|Tap Comments| CommentsSheet["Comments Modal Sheet"]
    Detail -->|Tap Report| ReportDialog["Report Inappropriate Content Dialog"]
    Tab3 -->|Tap Edit Profile| EditProfile["Edit Pen Name & Bio"]
    Tab3 -->|Tap Draft| Editor
```

---

## 11. Architectural Decisions & Rationale

| Decision | Selected Choice | Rejected Alternative | Rationale |
| :--- | :--- | :--- | :--- |
| **State Management** | **Flutter Riverpod** | BLoC, Vanilla Provider | Riverpod offers compile-safe dependency injection, zero `BuildContext` leakage in business logic, and test-friendly provider overriding. |
| **Database & Auth** | **Supabase** | Firebase, Custom NodeJS | PostgreSQL provides robust relational integrity for comments, likes, and reports. Row Level Security guarantees data isolation directly at database level. |
| **Anonymity Architecture** | **PostgreSQL Public View / Secure Projection** | Client-side data masking | Masking on client is dangerous as raw JSON can be sniffed via proxies; masking at DB level guarantees zero exposure. |
| **Story Format** | **Structured Plain Text** | Rich HTML / Heavy Markdown | Preserves the calm, book-like editorial aesthetic and avoids layout fragmentation or script injection vulnerabilities. |
