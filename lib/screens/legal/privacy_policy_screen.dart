import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_paper_surface.dart';

/// Publicly accessible in-app Privacy Policy screen.
/// Requires no authentication and reflects actual Writelle data practices.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  static const String policyVersion = '1.0.0';
  static const String lastUpdated = 'November 2026';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background(context),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: AppColors.textPrimaryColor(context)),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Privacy Policy',
          style: AppTypography.storyHeading.copyWith(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: AppColors.textPrimaryColor(context),
          ),
        ),
        centerTitle: true,
      ),
      body: WrittleAmbientBackground(
        variant: AmbientVariant.home,
        child: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 20.0, vertical: 16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Header badge
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarmColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: Text(
                      'Version $policyVersion • Updated: $lastUpdated',
                      style: AppTypography.captionMeta.copyWith(
                        fontSize: 11,
                        color: AppColors.burntSienna,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 16),

                WrittlePaperSurface(
                  variant: PaperSurfaceVariant.white,
                  padding: const EdgeInsets.all(20.0),
                  borderRadius: 16,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildTitle('1. Introduction'),
                      _buildParagraph(
                        'Welcome to Writelle ("Application", "We", "Our"). Writelle is a contemplative literature haven and pseudonymous writing sanctuary dedicated to mindful slow reading, honest expression, and user privacy. We deeply respect your privacy and are committed to safeguarding the personal data you entrust to us.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('2. Information We Collect'),
                      _buildParagraph(
                        'Writelle collects only the essential data necessary to provide a serene and secure literary experience:',
                      ),
                      _buildBullet('Account Credentials:', 'Email address and encrypted password generated upon account registration.'),
                      _buildBullet('Pseudonymous Profile:', 'Pen name (display name), optional biography quotes, and optional avatar images uploaded by the user.'),
                      _buildBullet('User-Generated Content (UGC):', 'Tales, reflective writings, titles, category tags, and comments you inscribe to the sanctuary.'),
                      _buildBullet('Sanctuary Interactions:', 'Story likes (appreciations), keepsakes (bookmarks), and reader associations (readers & following counts).'),
                      _buildBullet('Privacy Preferences:', 'Pure Anonymity publication mode to conceal author identity on select tales.'),
                      const SizedBox(height: 18),

                      _buildTitle('3. How We Collect Information'),
                      _buildParagraph(
                        'We collect data directly when you register, personalize your sanctuary profile, compose stories, or appreciate works by other authors. If you choose to authenticate via Google Sign-In, we receive only your verified email address and basic profile identifier.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('4. Purpose and Use of Data'),
                      _buildParagraph(
                        'The information gathered is utilized strictly to:',
                      ),
                      _buildBullet('Core Services:', 'Authenticate accounts, deliver contemplative feeds, and present your authored works.'),
                      _buildBullet('Identity Protection:', 'Conceal your pen name and avatar whenever you activate anonymous publishing.'),
                      _buildBullet('Community Safety:', 'Moderate abusive content and process community violation reports swiftly.'),
                      _buildBullet('No Third-Party Advertising:', 'We NEVER sell or monetize your data with third-party advertisers, data brokers, or commercial marketing firms.'),
                      const SizedBox(height: 18),

                      _buildTitle('5. Data Storage and Security'),
                      _buildParagraph(
                        'All data is securely stored within Supabase managed PostgreSQL infrastructure utilizing industry-standard TLS 1.2/1.3 encryption in transit and AES-256 encryption at rest. Database access is strictly governed by granular PostgreSQL Row-Level Security (RLS) policies.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('6. Third-Party Service Providers'),
                      _buildParagraph(
                        'We do not share your personal information with external parties, except for essential infrastructure providers:',
                      ),
                      _buildBullet('Supabase Inc.:', 'Backend-as-a-Service infrastructure handling encrypted databases, authentication, and media storage.'),
                      _buildBullet('Google Identity (Optional):', 'Employed solely when you explicitly choose to authenticate via Google Sign-In.'),
                      const SizedBox(height: 18),

                      _buildTitle('7. Local Device Storage and Sessions'),
                      _buildParagraph(
                        'The application utilizes secure local device storage (SharedPreferences) to cache your authentication session token, reading theme preferences, and locally blocked author lists. We do not use third-party tracking cookies or advertising SDKs.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('8. Data Retention & 14-Day Trash Window'),
                      _buildBullet('Quarantined Tales:', 'Stories deleted by authors or curators are placed into a soft-deleted quarantine state for a grace window of 14 calendar days for emergency restoration, after which they are permanently and irreversibly purged from our database.'),
                      _buildBullet('Active Accounts:', 'Active profiles and published tales are preserved for as long as your account remains active.'),
                      const SizedBox(height: 18),

                      _buildTitle('9. Your Privacy Rights'),
                      _buildParagraph(
                        'You maintain complete autonomy to access, update your pen name, change your avatar, edit your manuscripts, or erase your writings at any time through the application.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('10. Account & Data Deletion Rights'),
                      _buildParagraph(
                        'In full compliance with Google Play Store policies and international data privacy regulations (GDPR, CCPA, CalOPPA), you have the absolute right to request the permanent deletion of your account and all associated data at any time:',
                      ),
                      _buildBullet('In-App Deletion:', 'Open Profile > Tap the gear icon in the top right > Select "Delete Sanctuary Account". Your profile, published tales, comments, and authentication records are permanently erased immediately.'),
                      _buildBullet('Web Deletion Portal:', 'If you cannot access the app, you may submit an account erasure request via our public web portal or by emailing our developer contact directly.'),
                      const SizedBox(height: 18),

                      _buildTitle('11. Children\'s Privacy'),
                      _buildParagraph(
                        'Writelle is not intended for children under 13 years of age. We do not knowingly collect personal data from anyone under the age of 13. If you are a parent or guardian and discover that your child has provided us with personal information, please contact us immediately for prompt deletion.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('12. Changes to This Privacy Policy'),
                      _buildParagraph(
                        'We may update this Privacy Policy from time to time. Any revisions will be reflected on this page with an updated effective date.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('13. Contact Us'),
                      _buildParagraph(
                        'If you have any questions, feedback, or data privacy requests regarding this Privacy Policy or your personal information, please contact us at:\n• Developer Email: mazzamfirdaus06@gmail.com\n• Platform: Writelle Sanctuary',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6.0),
      child: Text(
        title,
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.bold,
          color: AppColors.espresso,
        ),
      ),
    );
  }

  Widget _buildParagraph(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8.0),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 13,
          color: AppColors.mutedCocoa,
          height: 1.5,
        ),
      ),
    );
  }

  Widget _buildBullet(String label, String content) {
    return Padding(
      padding: const EdgeInsets.only(left: 8.0, bottom: 6.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• ', style: TextStyle(color: AppColors.burntSienna, fontWeight: FontWeight.bold)),
          Expanded(
            child: RichText(
              text: TextSpan(
                style: const TextStyle(fontSize: 12.5, color: AppColors.mutedCocoa, height: 1.45),
                children: [
                  TextSpan(
                    text: '$label ',
                    style: const TextStyle(fontWeight: FontWeight.w600, color: AppColors.espresso),
                  ),
                  TextSpan(text: content),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
