import 'package:flutter/material.dart';
import '../../../core/constants/app_colors.dart';

/// Privacy Policy disclosure screen.
class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          children: const [
            Text(
              "Privacy Policy for Eklavya's Aim",
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Last Updated: November 2026',
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textMuted,
              ),
            ),
            SizedBox(height: 20),
            Text(
              '1. Overview\n'
              'Eklavya\'s Aim is built as an offline-first puzzle game. We value your privacy and do not collect, sell, or monetize any personally identifiable information (PII).\n\n'
              '2. Data Stored on Device\n'
              'Your game progression, completed levels, best completion times, statistics, and preferences (such as sound and haptics) are stored exclusively on your device using local storage (SharedPreferences). This data does not leave your device.\n\n'
              '3. Advertisements & Monetization\n'
              'The application integrates Google Mobile Ads (AdMob) to display advertisements. AdMob may collect and process pseudonymous identifiers (such as Android Advertising ID or IDFA) according to Google\'s privacy policies to provide non-intrusive and rewarded ad experiences.\n\n'
              '4. In-App Purchases\n'
              'Payments are processed directly by Apple App Store (StoreKit) or Google Play Billing. We never receive or store your payment details, credit card numbers, or billing addresses.\n\n'
              '5. Children\'s Privacy\n'
              'Eklavya\'s Aim does not knowingly collect any personal information from children under the age of 13.\n\n'
              '6. Contact Information\n'
              'If you have any questions or concerns regarding this privacy policy, please contact our support team at support@eklavyasaim.com.',
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
