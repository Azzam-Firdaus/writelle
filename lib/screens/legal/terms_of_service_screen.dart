import 'package:flutter/material.dart';
import '../../core/theme/app_colors.dart';
import '../../core/theme/app_typography.dart';
import '../../core/widgets/writtle_ambient_background.dart';
import '../../core/widgets/writtle_paper_surface.dart';

/// Publicly accessible in-app Terms of Service / End User Agreement (EULA).
/// Meets Google Play User-Generated Content (UGC) policy requirements.
class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  static const String termsVersion = '1.0.0';
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
          'Terms of Service',
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
                Center(
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: AppColors.surfaceWarmColor(context),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppColors.borderColor(context)),
                    ),
                    child: Text(
                      'Version $termsVersion • Updated: $lastUpdated',
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
                      _buildTitle('1. General Terms'),
                      _buildParagraph(
                        'By registering, accessing, or using the Writelle application, you agree to be bound by these Terms of Service. If you do not agree to any of these terms, please do not use this sanctuary or its services.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('2. The Sanctuary & Community Ethos'),
                      _buildParagraph(
                        'Writelle is crafted as a quiet literary sanctuary for contemplative essays, personal reflections, and mindful storytelling. We hold mutual respect, psychological safety, and creative dignity as our core virtues across all readers and scribes.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('3. User-Generated Content (UGC) — Zero Tolerance'),
                      _buildParagraph(
                        'In accordance with Google Play Developer Policies on User-Generated Content, Writelle enforces a strict ZERO TOLERANCE policy against unlawful, harmful, or abusive content and behaviors, including:',
                      ),
                      _buildBullet('Harassment & Bullying:', 'Degrading, threatening, or intimidating other writers and readers is strictly prohibited.'),
                      _buildBullet('Hate Speech:', 'Promoting hatred, discrimination, or violence based on race, ethnicity, religion, disability, or gender is forbidden.'),
                      _buildBullet('Sexually Explicit Content:', 'Pornography, vulgar sexual imagery, or non-consensual sexual depictions are not permitted.'),
                      _buildBullet('Violence & Self-Harm:', 'Incitement to violence, glorification of terrorism, or encouragement of self-harm or suicide is strictly prohibited.'),
                      _buildBullet('Spam & Deception:', 'Using the platform for automated bot posts, commercial solicitation, scams, or malicious links is forbidden.'),
                      const SizedBox(height: 18),

                      _buildTitle('4. Reporting & Content Moderation'),
                      _buildParagraph(
                        'To preserve a serene and secure reading sanctuary for everyone:',
                      ),
                      _buildBullet('Report Tale (Whisper):', 'Any reader can flag violating content through the "Report Whisper" menu. Our moderation team reviews every submission promptly.'),
                      _buildBullet('Block Author:', 'You can instantaneously block any author. Their stories and comments will be completely hidden from your feed and interactions.'),
                      _buildBullet('Curator Actions:', 'Sanctuary administrators and curators reserve the right to remove non-compliant content and suspend or terminate offending accounts immediately and without prior notice.'),
                      const SizedBox(height: 18),

                      _buildTitle('5. Intellectual Property Rights'),
                      _buildParagraph(
                        'You retain complete copyright and ownership of all stories, essays, and words you write. By publishing on Writelle, you grant us a non-exclusive, royalty-free, worldwide license solely to display, archive, and format your stories for reading within the platform.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('6. Account Integrity & Security'),
                      _buildParagraph(
                        'You are responsible for safeguarding your credentials and access to your account. Impersonation of other writers, creators, or entities is strictly prohibited.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('7. Disclaimers & Limitation of Liability'),
                      _buildParagraph(
                        'Writelle is provided on an "as is" and "as available" basis. While we strive to maintain uninterrupted service and literary tranquility, we are not liable for any indirect or incidental damages resulting from technical interruptions beyond our reasonable control.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('8. Contact & Legal Inquiries'),
                      _buildParagraph(
                        'For questions, disputes, or safety concerns regarding these Terms of Service, please reach out to our team at mazzamfirdaus06@gmail.com.',
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
