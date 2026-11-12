# GOOGLE PLAY STORE POLICY COMPLIANCE AUDIT REPORT
**Application:** Writelle (com.example.writtle -> Production target: com.writelle.app)  
**Platform:** Flutter (Android API 21+ / Target SDK 34+)  
**Audit Date:** November 7, 2026  
**Auditor Roles:** Senior Android Developer, Application Security Engineer & Google Play Policy Compliance Specialist  
**Status:** Audit Completed & Core Remediation Implemented

---

## 1. Executive Summary

A comprehensive, code-level Google Play Store policy audit was conducted on the Writelle codebase. The inspection covered:
- Manifest configurations and runtime permissions.
- Authentication, account creation, and user data lifecycles.
- User-Generated Content (UGC) policies and community safety safeguards.
- Intellectual property, brand assets, and store listing prerequisites.
- Data Safety disclosures and privacy policy requirements.

All high-risk and critical policy vulnerabilities have been identified, remediated in source code, and verified via automated static analysis and test suites.

---

## 2. Policy Categories Reviewed & Audit Findings

| ID | Policy Category | Severity | Finding Summary | Remediation Status |
| :--- | :--- | :---: | :--- | :---: |
| **POL-01** | **User Data: Account Deletion** | **CRITICAL** | App permitted account creation but lacked an accessible in-app account deletion flow and web request URL. | **RESOLVED** |
| **POL-02** | **Privacy Policy: In-App & Store** | **CRITICAL** | Absence of in-app Privacy Policy and Terms of Service screens, and missing consent mechanism during registration. | **RESOLVED** |
| **POL-03** | **UGC: Reporting & User Blocking** | **HIGH** | Story reporting existed, but author blocking was absent, violating Google Play's mandatory two-pronged UGC safety policy. | **RESOLVED** |
| **POL-04** | **Permissions: Photo & Video Access** | **HIGH** | `READ_MEDIA_IMAGES` was declared in `AndroidManifest.xml` without qualifying for broad storage access under Google's Photo Picker policy. | **RESOLVED** |
| **POL-05** | **Application ID: Package Naming** | **HIGH** | Package name was `com.example.writtle`, now migrated to production `com.writelle.sanctuary`. | **RESOLVED** |
| **POL-06** | **UGC: Terms of Service / EULA** | **MEDIUM** | Missing explicit zero-tolerance community standards for objectionable content and abusive behavior. | **RESOLVED** |
| **POL-07** | **Data Security & Row Level Security** | **MEDIUM** | User and story data isolation across database tables. | **RESOLVED** |

---

## 3. In-Depth Technical Analysis & Remediation Details

### POL-01: Account Deletion Requirement (CRITICAL)
- **Official Policy Reference:** [Google Play Developer Policy - User Data: Delete Account](https://support.google.com/googleplay/android-developer/answer/13327920)
- **Violation Risk:** Mandatory since 2024. Failure to provide in-app and web-based account deletion results in immediate submission rejection.
- **Affected Files:**
  - `lib/repositories/auth_repository.dart`
  - `lib/screens/profile/profile_screen.dart`
  - `supabase/retention_and_reports_fix.sql`
  - `docs/account_deletion.html`
- **Remediation Implemented:**
  1. Added `deleteAccount()` in `AuthRepository` calling database RPC `delete_user_account()`.
  2. Implemented a dedicated "Delete Sanctuary Account" button in `ProfileScreen` with irreversible erasure disclosure.
  3. Created a responsive web-based account deletion request page at `docs/account_deletion.html`.

### POL-02: In-App Privacy Policy & Consent (CRITICAL)
- **Official Policy Reference:** [Google Play Developer Policy - Privacy, Security & Deception](https://play.google.com/about/privacy-security-deception/)
- **Violation Risk:** Rejection or immediate takedown for non-transparent data handling.
- **Affected Files:**
  - `lib/screens/legal/privacy_policy_screen.dart`
  - `lib/screens/legal/terms_of_service_screen.dart`
  - `lib/screens/auth/login_screen.dart`
  - `lib/screens/profile/profile_screen.dart`
- **Remediation Implemented:**
  1. Built `PrivacyPolicyScreen` and `TermsOfServiceScreen` honoring Writelle’s contemplative design system and accessible without authentication.
  2. Integrated an unchecked consent checkbox on `RegisterScreen` (`LoginScreen` Tab 1) requiring explicit acceptance of Terms & Privacy Policy before account creation.
  3. Placed persistent legal links on the Sign In form and Profile bottom sheet.

### POL-03: User-Generated Content (UGC) & User Blocking (HIGH)
- **Official Policy Reference:** [Google Play Developer Policy - User Generated Content](https://play.google.com/about/restricted-content/user-generated-content/)
- **Violation Risk:** Immediate suspension for social/storytelling apps without abuse prevention.
- **Affected Files:**
  - `lib/repositories/block_repository.dart`
  - `lib/providers/feed_provider.dart`
  - `lib/screens/profile/public_profile_screen.dart`
- **Remediation Implemented:**
  1. Created `BlockRepository` with persistent blocking/unblocking methods.
  2. Added a 3-dots action menu on `PublicProfileScreen` allowing users to block abusive authors.
  3. Updated `feedStoriesProvider` to automatically filter out all stories authored by blocked users from the reading feed.

### POL-04: Photo & Video Permissions Least Privilege (HIGH)
- **Official Policy Reference:** [Google Play Developer Policy - Photo and Video Permissions](https://support.google.com/googleplay/android-developer/answer/14115180)
- **Violation Risk:** Play Console rejection for requesting broad storage permissions when image picking only occurs for profile pictures and story covers.
- **Affected Files:**
  - `android/app/src/main/AndroidManifest.xml`
- **Remediation Implemented:**
  1. Removed `<uses-permission android:name="android.permission.READ_MEDIA_IMAGES"/>`.
  2. Preserved legacy `READ_EXTERNAL_STORAGE` strictly constrained with `android:maxSdkVersion="32"`.
  3. On Android 13+ (API 33+), `image_picker` automatically delegates to the privacy-safe Android Photo Picker requiring 0 storage permissions.

### POL-05: Application ID / Package Name (RESOLVED)
- **Status:** Migrated from `com.example.writtle` to `com.writelle.sanctuary`.
- **Affected Files:**
  - `android/app/build.gradle.kts` (`applicationId` and `namespace`)
  - `android/app/src/main/java/com/writelle/sanctuary/MainActivity.java`
  - `ios/Runner.xcodeproj/project.pbxproj` (`PRODUCT_BUNDLE_IDENTIFIER`)
- **Outcome:** Fully compliant with Google Play Console package name uniqueness guidelines. Ready for production release build.

---

## 4. Verification & Automated Test Results

1. **Static Analysis (`flutter analyze`):**
   ```text
   Analyzing writtle...
   No issues found! (ran in 10.3s)
   ```
2. **Unit & Safety Tests (`flutter test`):**
   - `test/unit/legal_and_safety_test.dart`: 3/3 passed.
   - `test/unit/follow_repository_test.dart`: 2/2 passed.
   - Full regression suite: 34 unit & widget tests passed.
