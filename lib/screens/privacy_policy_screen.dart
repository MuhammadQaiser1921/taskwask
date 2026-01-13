import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class PrivacyPolicyScreen extends StatelessWidget {
  const PrivacyPolicyScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Privacy Policy'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'TaskWask Privacy Policy',
            style: Theme.of(context).textTheme.headlineMedium,
          ),
          const SizedBox(height: AppSpacing.sm),
          Text(
            'Last updated: ${DateTime.now().year}-01-02',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: AppTheme.textSecondary,
                ),
          ),
          const SizedBox(height: AppSpacing.xl),
          
          _buildSection(
            context,
            '1. Information We Collect',
            'TaskWask collects the following information:\n\n'
            '• Account Information: Email address, username, and profile picture\n'
            '• Task Data: Tasks, categories, and reminders you create\n'
            '• Usage Data: How you interact with the app\n'
            '• Device Information: Device type and operating system',
          ),
          
          _buildSection(
            context,
            '2. How We Use Your Information',
            'We use your information to:\n\n'
            '• Provide and maintain the app service\n'
            '• Send you task reminders and notifications\n'
            '• Improve and personalize your experience\n'
            '• Ensure the security of your account\n'
            '• Communicate important updates',
          ),
          
          _buildSection(
            context,
            '3. Data Storage and Security',
            'Your data is stored securely using Firebase services with industry-standard encryption. We implement appropriate technical and organizational measures to protect your personal information.',
          ),
          
          _buildSection(
            context,
            '4. Data Sharing',
            'We do not sell, trade, or rent your personal information to third parties. Your data is only shared with service providers necessary to operate the app (e.g., Firebase for authentication and storage).',
          ),
          
          _buildSection(
            context,
            '5. Your Rights',
            'You have the right to:\n\n'
            '• Access your personal data\n'
            '• Correct inaccurate data\n'
            '• Delete your account and data\n'
            '• Export your task data\n'
            '• Opt-out of notifications',
          ),
          
          _buildSection(
            context,
            '6. Cookies and Tracking',
            'TaskWask uses minimal tracking to improve app performance and user experience. We do not use cookies for advertising purposes.',
          ),
          
          _buildSection(
            context,
            '7. Children\'s Privacy',
            'TaskWask is not intended for users under 13 years of age. We do not knowingly collect information from children under 13.',
          ),
          
          _buildSection(
            context,
            '8. Changes to Privacy Policy',
            'We may update this Privacy Policy from time to time. We will notify you of any changes by posting the new Privacy Policy on this page and updating the "Last updated" date.',
          ),
          
          _buildSection(
            context,
            '9. Contact Us',
            'If you have questions about this Privacy Policy, please contact us through the app feedback feature or email us at support@taskwask.com',
          ),
          
          const SizedBox(height: AppSpacing.xl),
        ],
      ),
    );
  }

  Widget _buildSection(BuildContext context, String title, String content) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
              ),
        ),
        const SizedBox(height: AppSpacing.sm),
        Text(
          content,
          style: Theme.of(context).textTheme.bodyMedium,
        ),
        const SizedBox(height: AppSpacing.xl),
      ],
    );
  }
}
