# Writtle — Product Requirements Document (PRD)

**Document Version:** 1.0.0  
**Status:** Draft / Pending Review  
**Product Name:** Writtle  
**Tagline:** *“Your story matters, even when your name doesn’t.”*  
**Platform:** Flutter (Target: Android MVP)  

---

## 1. Product Overview

Writtle is an anonymous and pseudonymous storytelling platform designed for individuals who wish to share authentic life experiences, confessions, emotional reflections, and creative narratives without fear of personal exposure, social pressure, or prejudice.

Unlike generic social media platforms centered on vanity metrics, self-promotion, and infinite media scrolling, Writtle offers a sanctuary focused purely on the written word. It embraces an **Editorial Minimalism** philosophy—creating a calm, book-like reading and writing environment where content quality and emotional resonance take precedence over author identity.

---

## 2. Problem Statement

1. **Social Pressure & Identity Anxiety:** On mainstream social media (Instagram, Twitter/X, TikTok, LinkedIn), content is tethered to a user's real or publicly identifiable persona. Users experience judgment, fear of professional or social repercussions, and performative anxiety when sharing vulnerable, unconventional, or intimate thoughts.
2. **Superficiality Over Depth:** Existing platforms optimize for quick consumption (reels, images, punchy tweets) rather than long-form, deep storytelling.
3. **Loss of Safety in Anonymity:** Existing anonymous forums (Reddit, generic confessions apps) often degenerate into hostile environments, toxicity, or chaotic spam feeds due to lack of editorial elegance and responsible community boundaries.
4. **Distracting & Cluttered UI:** Most modern reading apps bombard users with loud ads, flashing banners, and gamified animations that break immersion and contemplation.

---

## 3. Vision & Mission

### 3.1. Vision
To become the most trusted and elegant sanctuary for human storytelling, where thoughts are valued by the depth of their truth rather than the fame of the storyteller.

### 3.2. Mission
- Provide a safe, privacy-preserving platform where individuals can articulate experiences freely.
- Foster empathy and connection among readers through clean, uninterrupted long-form reading.
- Ensure responsible community behavior through robust privacy architecture and proactive moderation.

---

## 4. Target Users & User Personas

### 4.1. Target Audience
- University students, young professionals, and reflective thinkers (ages 18–35) seeking an emotional outlet.
- Creative writers desiring unfiltered feedback on narratives without identity bias.
- Avid readers who appreciate thoughtful, sincere personal essays over commercial clickbait.

### 4.2. User Personas

#### Persona 1: The Vulnerable Storyteller (Alya, 21 — University Student)
- **Background:** Balancing academic pressures and complex family dynamics.
- **Pain Points:** Wants to vent and share personal struggles without friends or classmates discovering her identity.
- **Goal:** Write personal reflections anonymously, receive genuine words of comfort, and feel heard.
- **Writtle Fit:** Uses "Publish Anonymously" mode, receives warm comments without revealing her identity.

#### Persona 2: The Reflective Essayist (Rian, 27 — Junior Product Designer)
- **Background:** Enjoys observing urban life, workplace culture, and human behavior.
- **Pain Points:** Wants a consistent writing outlet under a recognizable pseudonym without linking his real LinkedIn or corporate profile.
- **Goal:** Build a portfolio of introspective essays under a pen name ("UrbanMonk").
- **Writtle Fit:** Uses "Publish with Pen Name", categorizes his stories under "Reflections" and "Life Lessons".

#### Persona 3: The Empathetic Reader (Dina, 24 — Content Researcher)
- **Background:** Commutes daily and reads during quiet evening hours.
- **Pain Points:** Fatigued by aggressive algorithmic feeds and short-form video noise.
- **Goal:** Read soothing, sincere human stories in a distraction-free, aesthetically pleasing reader.
- **Writtle Fit:** Bookmarks touching stories, likes narratives that resonate, and leaves supportive comments.

---

## 5. Value Proposition

| Value Pillar | Description |
| :--- | :--- |
| **Privacy by Design** | Complete separation of internal account credentials from public story rendering when publishing anonymously. |
| **Dual Identity Mode** | Flexibility to publish either completely anonymously or via a curated Pen Name pseudonym per story. |
| **Editorial Minimalism** | Warm paper palette, distraction-free typography, and generous breathing room for the eyes. |
| **Authentic Community** | Thoughtful comments, bookmarks, and likes without toxic viral leaderboards or follower counts. |

---

## 6. Product Objectives & Success Metrics

### 6.1. Product Objectives
1. Provide a zero-friction, private storytelling experience for mobile users.
2. Maintain high reader immersion with zero UI clutter.
3. Protect user anonymity through strict database-level security policies (Supabase RLS).
4. Deliver a rock-solid MVP ready for user testing on Android.

### 6.2. Success Metrics (KPIs)
- **Publishing Conversion:** > 40% of registered users publish at least one draft or story within their first 7 days.
- **Reading Retention:** Average session reading time > 4 minutes per story read.
- **Privacy Trust:** Zero leakages of user email or auth identifiers across client-facing endpoints.
- **Content Health:** Report-to-story ratio maintained under 2%, with reported items reviewed promptly.

---

## 7. MVP Scope & Boundaries

### 7.1. In-Scope (Included in MVP)
- **Authentication:** Registration (Email/Password), Login, Logout, Session Persistence.
- **User Profile:** Pen Name, Bio, Avatar placeholder (system-generated initials or minimalist abstract icon).
- **Story Creation & Editing:**
  - Rich text or multi-paragraph editor with Title, Category, and Story Body.
  - Draft management (Save draft, Edit draft, Discard draft).
  - Dual Publishing Mode toggle: *Anonymous* vs. *Pen Name*.
- **Feed & Reading:**
  - Chronological / curated feed of published stories.
  - Category filtering (Reflections, Romance, Life Lessons, Fiction, Confessions).
  - Dedicated Story Reader screen with optimized reading typography and estimated read time.
- **Interactions:**
  - Like / Unlike toggle with live counter.
  - Bookmark / Unbookmark with a dedicated "Saved Stories" library.
  - Threaded or flat comment list on story detail.
- **Moderation & Safety:**
  - User report submission with specific violation categories (Spam, Harassment, Hate Speech, Inappropriate Content).
  - Soft-deletion of user's own stories.
  - Database status flagging for moderated content.

### 7.2. Out-of-Scope (Excluded from MVP / Future Roadmap)
- Direct messaging (DMs) or private chats.
- Follower/following graphs and influencer badges.
- Image/video attachment uploads within story body (text-only MVP).
- Push notifications server (can be added post-MVP).
- Custom dedicated web-based CMS (Admin will use Supabase Dashboard for MVP).
- Monetization, tipping, or paid subscriptions.

---

## 8. User Stories

| ID | As a... | I want to... | So that... |
| :--- | :--- | :--- | :--- |
| **US-01** | New user | Register an account using email and password | I can save my drafts and manage my stories securely. |
| **US-02** | Registered user | Set up a Pen Name and short bio | I have a creative alias when I choose not to publish completely anonymously. |
| **US-03** | Writer | Draft a story and save it privately | I can refine my thoughts before sharing them with the world. |
| **US-04** | Writer | Publish a story anonymously | Readers can experience the story without knowing my identity or my pen name. |
| **US-05** | Writer | Publish a story under my Pen Name | I can build a recognized body of written work without exposing my real identity. |
| **US-06** | Writer | Edit or delete a story I published | I maintain control over my personal thoughts over time. |
| **US-07** | Reader | Browse stories by category and view reading time | I can find narratives that fit my current mood and schedule. |
| **US-08** | Reader | Enjoy an uninterrupted, comfortable reading view | My eyes do not get strained and I can focus entirely on the words. |
| **US-09** | Reader | Like and bookmark stories | I can express quiet appreciation and revisit meaningful stories later. |
| **US-10** | Reader | Leave a comment on a story | I can provide words of encouragement or share an empathetic perspective. |
| **US-11** | Reader | Report harmful or abusive stories | I can help keep Writtle a safe and constructive space. |

---

## 9. Functional Requirements (FR)

### Authentication & Profile
- `FR-001`: System shall allow users to register an account using a valid email and password (minimum 8 characters).
- `FR-002`: System shall allow users to log in and maintain an authenticated session via secure token storage.
- `FR-003`: System shall allow users to log out safely and clear client-side credentials.
- `FR-004`: System shall automatically create a user profile with an auto-generated unique Pen Name upon registration.
- `FR-005`: System shall allow users to edit their Pen Name and Bio.

### Story Management
- `FR-006`: System shall provide an editor with fields for Title, Content, Category, and Anonymity Toggle (`is_anonymous`).
- `FR-007`: System shall allow users to save stories as drafts (`status = 'draft'`).
- `FR-008`: System shall allow users to publish stories (`status = 'published'`).
- `FR-009`: System shall allow authors to edit their own published stories and drafts.
- `FR-010`: System shall allow authors to soft-delete their own stories (`status = 'archived'` or `deleted_at IS NOT NULL`).
- `FR-011`: System shall enforce that draft stories are viewable only by their author.

### Reading & Discovery
- `FR-012`: System shall display a public feed of published, non-deleted, non-moderated stories.
- `FR-013`: System shall calculate and display estimated reading time (standard: 200 words per minute).
- `FR-014`: System shall render author as "Anonymous" if `is_anonymous = true`, concealing all author profile data.
- `FR-015`: System shall render author as Pen Name if `is_anonymous = false`.
- `FR-016`: System shall allow filtering the public feed by predefined categories.
- `FR-017`: System shall provide a dedicated story detail screen optimized for typography and vertical scrolling.

### Interactions
- `FR-018`: System shall allow authenticated users to like and unlike published stories.
- `FR-019`: System shall allow authenticated users to bookmark and unbookmark stories.
- `FR-020`: System shall display a personal "Bookmarks" screen listing all stories saved by the user.
- `FR-021`: System shall allow authenticated users to submit comments on published stories.
- `FR-022`: System shall allow comment authors to delete their own comments.

### Safety & Moderation
- `FR-023`: System shall allow users to submit reports against stories with a designated reason and optional notes.
- `FR-024`: System shall prevent duplicate reports from the same user for the same story.
- `FR-025`: System shall support administrator moderation flag to hide stories from the public feed immediately upon violation.

---

## 10. Non-Functional Requirements (NFR)

### Privacy & Security
- `NFR-001`: **Data Anonymization:** API endpoints and Supabase queries for public stories must never expose `user_id`, email, or profile timestamps for anonymous stories.
- `NFR-002`: **Row Level Security:** Database must enforce authorization at PostgreSQL level via Supabase RLS. Client-side checks alone are never considered sufficient.
- `NFR-003`: **Secret Safety:** Flutter client code must never include Supabase `service_role` key, database passwords, or privileged administrative credentials.
- `NFR-004`: **Input Sanitization:** All user inputs (story title, story body, comments, bio) must be trimmed and validated against XSS/injection payloads.

### Performance & Scalability
- `NFR-005`: **Feed Latency:** Public story feed list retrieval shall complete in under 1.5 seconds on a standard 4G connection.
- `NFR-006`: **Pagination:** Feed queries must be cursor- or range-paginated (default: 15 stories per page) to prevent excessive memory and network usage.
- `NFR-007`: **Offline Resilience:** The app should handle temporary network dropouts gracefully with explicit retry cues instead of crashes.

### Usability & Accessibility
- `NFR-008`: **Readability Contrast:** Text contrast ratios must adhere to WCAG 2.1 AA standards (minimum contrast ratio of 4.5:1 for body text).
- `NFR-009`: **Touch Targets:** Interactive buttons, toggles, and icon bars must provide a minimum touch target size of 48x48 dp.
- `NFR-010`: **Responsive Layout:** UI must render consistently across standard Android phone screen sizes (from 5.0" to 6.8" diagonals).

---

## 11. Acceptance Criteria

| Feature Area | Acceptance Condition |
| :--- | :--- |
| **Anonymous Publishing** | When inspecting network payloads of a published story where `is_anonymous = true`, no identifiable author ID, username, or profile data is transmitted to the client. |
| **Draft Protection** | Attempting to fetch a draft using another user's authentication token must return a 403 Forbidden or empty query result via Supabase RLS. |
| **Story Editing** | Only the authenticated creator of a story can trigger an update mutation. Non-creators receive permission denied. |
| **Reader Typography** | Story reading page must render a legible serif font, comfortable line-height (1.6x font size), and minimum 16dp horizontal padding. |
| **Error Feedback** | Failed network operations (e.g. timeout, invalid credentials) must display clear, non-technical, human-friendly error messages with retry options. |

---

## 12. Constraints & Assumptions

### 12.1. Constraints
- **Target OS:** Android (minSdkVersion 21 - Android 5.0 Lollipop and above).
- **Backend Infrastructure:** Supabase cloud project with free/community tier limitations.
- **Client Framework:** Flutter SDK stable channel with pure Dart dependencies where possible.
- **Resource Constraints:** Designed and maintained by a university student developer; architecture must prioritize simplicity and modularity over enterprise microservices.

### 12.2. Assumptions
- Users have access to an active internet connection to read and publish stories.
- User email verification can be toggled optional during local development to facilitate rapid testing, but configured for production deployment.
- Initial content moderation will be managed by the developer/admin via the Supabase web dashboard.

---

## 13. Risks & Mitigations

| Risk | Impact | Likelihood | Mitigation Strategy |
| :--- | :--- | :--- | :--- |
| **Data Leak of Anonymous Authors** | Critical | Low | Enforce strict PostgreSQL Views or RLS projection policies where `user_id` is replaced with `NULL` or omitted on public reads. |
| **Toxic / Inappropriate Content** | High | Medium | Implement simple reporting mechanism (`FR-023`) and Supabase admin moderation flag (`FR-025`) to ban content swiftly. |
| **Overcomplicated State Management** | Medium | Medium | Utilize a structured Riverpod architecture with clear separation between UI, State Notifier/Provider, and Repository. |
| **App Clutter & Featuritis** | Medium | Low | Adhere strictly to the scope limits of this PRD; reject non-essential features (e.g., audio, DMs, complex algorithms) until post-MVP. |

---

## 14. Future Development Opportunities (Post-MVP)

- Dark / Night reading mode with true black or deep slate palettes.
- Ambient soundscapes (rain, soft vinyl, café murmur) during reading mode.
- Exporting stories as elegantly formatted PDF or minimalist images for external sharing.
- Content warning flags (e.g., Sensitive Topic / Mental Health trigger warnings) chosen by authors.
- Progressive Web App (PWA) or iOS distribution.
