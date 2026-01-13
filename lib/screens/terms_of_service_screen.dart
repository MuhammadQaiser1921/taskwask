import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

class TermsOfServiceScreen extends StatelessWidget {
  const TermsOfServiceScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Terms of Service'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(AppSpacing.lg),
        children: [
          Text(
            'TaskWask Terms of Service',
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
            '1. Acceptance of Terms',
            'By accessing and using TaskWask ("the App"), you accept and agree to be bound by these Terms of Service. If you do not agree to these terms, please do not use the App.',
          ),
          
          _buildSection(
            context,
            '2. Description of Service',
            'TaskWask is a task management application that allows users to create, organize, and manage tasks with features including reminders, categories, and cloud synchronization.',
          ),
          
          _buildSection(
            context,
            '3. User Accounts',
            '• You must create an account to use the App\n'
            '• You are responsible for maintaining the security of your account\n'
            '• You must provide accurate and complete information\n'
            '• You are responsible for all activities under your account\n'
            '• You must notify us immediately of any unauthorized use',
          ),
          
          _buildSection(
            context,
            '4. User Conduct',
            'You agree not to:\n\n'
            '• Use the App for any illegal purpose\n'
            '• Interfere with or disrupt the App or servers\n'
            '• Attempt to gain unauthorized access to any portion of the App\n'
            '• Upload malicious code or viruses\n'
            '• Harass, abuse, or harm other users\n'
            '• Violate any applicable laws or regulations',
          ),
          
          _buildSection(
            context,
            '5. Intellectual Property',
            'The App and its original content, features, and functionality are owned by TaskWask and are protected by international copyright, trademark, and other intellectual property laws.',
          ),
          
          _buildSection(
            context,
            '6. User Content',
            '• You retain ownership of the tasks and content you create\n'
            '• You grant us a license to use, store, and display your content to provide the service\n'
            '• You are solely responsible for your content\n'
            '• We reserve the right to remove content that violates these terms',
          ),
          
          _buildSection(
            context,
            '7. Subscription and Payments',
            'If applicable:\n\n'
            '• Premium features may require payment\n'
            '• Subscriptions automatically renew unless canceled\n'
            '• Refunds are subject to our refund policy\n'
            '• Prices are subject to change with notice',
          ),
          
          _buildSection(
            context,
            '8. Disclaimer of Warranties',
            'THE APP IS PROVIDED "AS IS" WITHOUT WARRANTIES OF ANY KIND, EITHER EXPRESS OR IMPLIED. WE DO NOT WARRANT THAT THE APP WILL BE UNINTERRUPTED, ERROR-FREE, OR COMPLETELY SECURE.',
          ),
          
          _buildSection(
            context,
            '9. Limitation of Liability',
            'TO THE MAXIMUM EXTENT PERMITTED BY LAW, WE SHALL NOT BE LIABLE FOR ANY INDIRECT, INCIDENTAL, SPECIAL, CONSEQUENTIAL, OR PUNITIVE DAMAGES ARISING OUT OF YOUR USE OF THE APP.',
          ),
          
          _buildSection(
            context,
            '10. Termination',
            'We reserve the right to terminate or suspend your account and access to the App at our sole discretion, without notice, for conduct that we believe violates these Terms or is harmful to other users, us, or third parties.',
          ),
          
          _buildSection(
            context,
            '11. Changes to Terms',
            'We reserve the right to modify these Terms at any time. We will notify users of any material changes. Your continued use of the App after changes constitutes acceptance of the new Terms.',
          ),
          
          _buildSection(
            context,
            '12. Governing Law',
            'These Terms shall be governed by and construed in accordance with applicable laws, without regard to conflict of law principles.',
          ),
          
          _buildSection(
            context,
            '13. Contact Information',
            'For questions about these Terms, please contact us at support@taskwask.com',
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
