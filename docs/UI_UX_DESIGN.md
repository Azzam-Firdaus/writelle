# Writtle — UI/UX Design Specification

**Document Version:** 1.0.0  
**Status:** Draft / Pending Review  
**Product:** Writtle (Anonymous Storytelling Application)  
**Aesthetic Style:** Editorial Minimalism  
**Target Platform:** Flutter (Android Mobile)  

---

## 1. Product Design Principles

1. **The Word Above All:** Visual elements, decorations, and animations exist only to serve and elevate the reading and writing experience. If an element does not aid comprehension or immersion, it is eliminated.
2. **Book-Like Comfort (Quiet Sanctuary):** The interface should evoke the feeling of reading a thoughtfully typeset printed publication or literary journal. No aggressive neon accents, flashing badges, or jarring gradients.
3. **Frictionless Anonymity:** Toggling anonymity must feel intuitive, reassuring, and completely transparent to the author at all times.
4. **Mindful Interaction:** Engagement (likes, bookmarks, comments) is subtle and dignified, avoiding addictive gamification loops (no follower counters, viral streaks, or flashy point systems).

---

## 2. Visual Direction & Style Guide

### 2.1. Color Palette

Writtle employs an **Editorial Warm Neutral** palette inspired by premium book stock, smooth ink, and subtle organic accents.

| Token Name | Hex Code | Swatch & Usage |
| :--- | :--- | :--- |
| `backgroundLight` | `#FBF9F5` | Primary app background (warm parchment / cream white). Gentle on the eyes. |
| `surfaceLight` | `#FFFFFF` | Elevated surfaces (sheets, cards, modal dialogs). |
| `surfaceWarm` | `#F3EFE6` | Secondary container, category chip background, quote blocks. |
| `textPrimary` | `#1A1816` | Deep charcoal / ink. Maximum readability without harshness of `#000000`. |
| `textSecondary` | `#635F59` | Muted charcoal for metadata, reading time, and secondary captions. |
| `textTertiary` | `#9C978F` | Placeholders, inactive icons, subtle dividers. |
| `accentPrimary` | `#8B4513` | Deep Ochre / Terracotta. Primary CTA, active tab indicator, accent highlights. |
| `accentSubtle` | `#D97736` | Warm amber highlight for interactive states and badges. |
| `borderLight` | `#E8E3DA` | Ultra-subtle hairline borders for structural separation. |
| `error` | `#B9382F` | Muted crimson for destructive actions and error feedback. |
| `success` | `#2D6A4F` | Deep forest green for success indicators and confirmation toasts. |

### 2.2. Typography

Writtle uses an editorial typographic pairing:
- **Headings & Story Body (Serif):** Georgia / Merriweather / Lora style (evokes classic literary publications).
- **Interface & Metadata (Sans-Serif):** Clean geometric sans (Inter / system Roboto) for crisp legibility at small sizes.

| Role | Family | Size / Weight | Line Height | Usage |
| :--- | :--- | :--- | :--- | :--- |
| **Display Title** | Serif | 28sp / Bold (700) | 1.25 (35sp) | Featured story titles, major section headers |
| **Story Heading** | Serif | 22sp / Semi-Bold (600) | 1.30 (28.6sp) | Story detail title, editor title input |
| **Story Body Text**| Serif | 17sp / Regular (400) | 1.65 (28sp) | Main narrative body in reading mode |
| **UI Headline** | Sans | 16sp / Medium (500) | 1.40 (22.4sp) | App bar titles, screen section headers |
| **UI Body** | Sans | 14sp / Regular (400) | 1.45 (20.3sp) | Buttons, form inputs, comment body |
| **Caption / Meta** | Sans | 12sp / Medium (500) | 1.35 (16.2sp) | Author alias, reading time, timestamps |

### 2.3. Spacing System (8-Point Grid)

All layout dimensions, margins, and padding follow an 8-point harmonic grid:
- `space-4` (4dp): Extra tight padding, icon-text gap.
- `space-8` (8dp): Tight gap between related elements, badge padding.
- `space-12` (12dp): Chip horizontal padding, input field padding.
- `space-16` (16dp): Standard screen horizontal gutter, card internal padding.
- `space-24` (24dp): Vertical rhythm between sections, form fields separation.
- `space-32` (32dp): Generous breathing room between content blocks.
- `space-48` (48dp): Hero header separation.

---

## 3. Reusable UI Components

1. **`WrittleAppBar`:** Minimalist flat top bar with warm background, subtle hairline border bottom (`borderLight`), and clean title.
2. **`StoryCard`:** Clean editorial card displaying Category pill, Title, excerpt (first 3 lines), author badge (`"Anonymous"` with minimalist incognito glyph or Pen Name), reading time (e.g. `4 min read`), and subtle like/bookmark counter.
3. **`CategoryChip`:** Horizontal scrolling pill button with `surfaceWarm` background and `accentPrimary` active fill.
4. **`EditorialButton`:**
   - *Primary:* Solid deep charcoal (`#1A1816`) or deep terracotta (`#8B4513`) with warm white text and 8dp rounded corners.
   - *Secondary / Outlined:* Hairline border with ink text.
   - *Text Action:* Understated text button for tertiary links.
5. **`AnonymityToggle`:** Distinct switch widget in the editor that clearly communicates:
   - When ON: 🛡️ *"Publishing as Anonymous (Your name and profile remain completely private)"*
   - When OFF: ✍️ *"Publishing as [Pen Name] (Visible under your alias)"*
6. **`EmptyStateWidget`:** Minimalist line illustration accompanied by poetic, encouraging copy (e.g., *"No stories saved yet. When you find words that stay with you, bookmark them here."*).
7. **`SkeletonLoader`:** Subtle pulsing warm bone-tone rectangles simulating editorial cards without jarring spinny circles.

---

## 4. Navigation Architecture

```
[Main Navigation Shell (Bottom Navigation Bar)]
├── Tab 1: Stories Feed (Home)
│    ├── Category Filter Bar (Reflections, Romance, Life Lessons, etc.)
│    └── Story Card List 
│         └── [Tap] ➔ Story Reader (Detail Page)
│                       ├── Comments Bottom Sheet
│                       └── Report Dialog
├── Floating Action Button (+) ➔ Story Editor (Write / Edit)
├── Tab 2: Bookmarks Library (Saved Stories)
└── Tab 3: My Profile & Stories
     ├── Pen Name & Bio Overview
     ├── My Stories Segment (Published / Drafts)
     └── [Tap Edit] ➔ Edit Profile Screen
```

---

## 5. Screen Inventory & Layout Descriptions

### 5.1. Authentication Screens (`Login` & `Register`)
- **Visuals:** Centered minimalist brand mark (*Writtle* in elegant serif) followed by the tagline *“Your story matters, even when your name doesn’t.”*
- **Form Fields:** Email and Password input boxes with warm background and thin outline.
- **Actions:** "Sign In" / "Create Account" primary button, accompanied by a discreet switch link between login and sign-up.

### 5.2. Story Feed Screen (`HomeFeedScreen`)
- **Top Bar:** App title *Writtle* in serif typography with subtle notifications or search placeholder.
- **Category Filter Bar:** Horizontally scrollable row of CategoryChips (`All`, `Reflections`, `Romance`, `Life Lessons`, `Fiction`, `Confessions`).
- **Story List:** Vertical list of `StoryCard`s separated by gentle hairline dividers.
- **FAB:** Circular or pill floating action button labeled *"Write"* or with a minimalist quill/pen icon.

### 5.3. Story Reader Screen (`StoryReaderScreen`)
- **Header:** Back button, Bookmark button, and More/Report menu.
- **Story Meta Section:**
  - Category pill (e.g., `Reflections`).
  - Story Title in 24sp bold serif.
  - Author badge: *"Anonymous"* with shield icon OR *Pen Name* with avatar initials.
  - Published date & estimated reading time (e.g. `Oct 23 • 3 min read`).
- **Reading Body:** Generous line-height (1.65), 17sp serif font, comfortable horizontal padding (20dp). No distractions.
- **Bottom Reader Bar (Sticky or Auto-hide on scroll):**
  - Heart icon (Like toggle) with counter.
  - Chat bubble icon (Comments count) opening comments modal sheet.
  - Bookmark icon toggle.

### 5.4. Story Editor Screen (`StoryEditorScreen`)
- **Top Bar:** "Close / Discard" button, "Save Draft" text button, and "Publish" primary button.
- **Anonymity Banner:** Reassuring toggle banner at the top indicating whether the story will be published anonymously or under the author's pen name.
- **Category Selector:** Dropdown or horizontal picker to designate story topic.
- **Title Input:** Large transparent input field (`"Give your story a title..."`).
- **Content Input:** Expansive multi-line text field (`"Share what's on your mind... no judgment here."`).
- **Word / Character Counter:** Subtle counter at the bottom edge.

### 5.5. Bookmarks Library Screen (`BookmarksScreen`)
- **Header:** *"Saved Stories"* in bold serif.
- **Content:** List of saved story cards. Tapping navigates to Reader. Swiping or tapping unbookmark removes the story with an undo snackbar.

### 5.6. Profile & My Stories Screen (`ProfileScreen`)
- **Header:** User's Pen Name (`@PenName`), short bio, and "Edit Profile" button.
- **Tabs / Toggle Segment:**
  - *Published Stories:* Shows stories published by the user (with indication if published anonymously or with pen name).
  - *Drafts:* Private drafts with a clear "Resume Writing" prompt.

### 5.7. Comments Bottom Sheet (`CommentsSheet`)
- Slides up smoothly over the Reader.
- List of comments showing commenter's Pen Name, timestamp, and comment text.
- Sticky bottom input field for submitting a new comment.

### 5.8. Report Dialog (`ReportStoryDialog`)
- Minimalist modal prompt: *"Help us keep Writtle safe and constructive."*
- Selectable reason radio tiles: Spam, Harassment, Hate Speech, Inappropriate Content, Other.
- Optional comment field.
- "Cancel" and "Submit Report" buttons.

---

## 6. Interaction Behavior & State Design

### 6.1. Loading States
- Never freeze the UI.
- Use shimmer skeleton tiles matching exact card layouts during feed loads.
- Disable submit buttons and show an inline spinner during publishing or authenticating.

### 6.2. Empty States
- When a feed or category has no stories:
  - Header: *"A quiet moment..."*
  - Body: *"No stories have been written in this category yet. Be the first to share your thoughts."*
  - Action: *"Write a Story"* button.

### 6.3. Error States
- Non-intrusive banner or snackbar with a warm red tint.
- Human-friendly phrasing (e.g., *"We couldn't connect to Writtle. Please check your internet connection."* instead of *"SocketException: 500"*).
- Always provide an immediate *"Retry"* action.

### 6.4. Accessibility
- All interactive controls maintain $\ge 48 \times 48\text{ dp}$ touch areas.
- High-contrast text compliance (minimum 4.5:1 ratio against `#FBF9F5` background).
- Supports system font scaling without text clipping or layout overflow.
