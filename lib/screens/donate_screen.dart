import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../theme/app_theme.dart';

/// Donate screen — bank transfer only (the ministry's online payment
/// gateway has been retired in favor of direct bank transfer).
class DonateScreen extends StatelessWidget {
  const DonateScreen({super.key});

  static const _accountName = 'Spiritus Sanctus Ignis Ministry';
  static const _accountNumber = '3000968272';
  static const _bankName = 'Moniepoint MFB';

  void _copy(BuildContext context, String label, String value) {
    Clipboard.setData(ClipboardData(text: value));
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('$label copied to clipboard')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('Donate', style: AppTheme.heading(size: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              const Icon(Icons.favorite, color: AppColors.danger, size: 20),
              const SizedBox(width: 8),
              Text('Support the Ministry', style: AppTheme.heading(size: 17)),
            ]),
            const SizedBox(height: 6),
            Text(
              'Support the Divine Increase Business Network and help Kingdom businesses grow.',
              style: AppTheme.body(size: 12.5, color: AppColors.muted),
            ),
            const SizedBox(height: 20),

            // Bank transfer card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                border: Border.all(color: AppColors.gold, width: 1.2),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(color: AppColors.gold.withOpacity(0.15), borderRadius: BorderRadius.circular(10)),
                      child: const Icon(Icons.account_balance_outlined, color: AppColors.gold, size: 18),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Bank Transfer', style: AppTheme.heading(size: 15)),
                          Text('Give directly using the account details below.',
                              style: AppTheme.body(size: 11.5, color: AppColors.muted)),
                        ],
                      ),
                    ),
                  ]),
                  const SizedBox(height: 16),
                  _DetailRow(label: 'Account Name', value: _accountName, onCopy: () => _copy(context, 'Account name', _accountName)),
                  const Divider(height: 22, color: AppColors.line),
                  _DetailRow(label: 'Account Number', value: _accountNumber, onCopy: () => _copy(context, 'Account number', _accountNumber), emphasize: true),
                  const Divider(height: 22, color: AppColors.line),
                  _DetailRow(label: 'Bank', value: _bankName, onCopy: () => _copy(context, 'Bank name', _bankName)),
                ],
              ),
            ),
            const SizedBox(height: 20),

            Text('Why Your Donation Matters', style: AppTheme.heading(size: 15)),
            const SizedBox(height: 10),
            _WhyCard(points: const [
              'Connect Kingdom businesses',
              'Support monthly business prayer meetings',
              'Develop resources for business growth',
              'Expand the network to more communities',
              'Improve the platform and member experience',
            ]),
            const SizedBox(height: 16),

            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: AppColors.cream2,
                border: Border.all(color: AppColors.line),
                borderRadius: BorderRadius.circular(14),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    const Icon(Icons.menu_book_outlined, size: 15, color: AppColors.navy),
                    const SizedBox(width: 6),
                    Text('Kingdom Giving', style: AppTheme.body(size: 12.5, weight: FontWeight.w700, color: AppColors.navy)),
                  ]),
                  const SizedBox(height: 8),
                  Text(
                    '"Each of you should give what you have decided in your heart to give, not reluctantly or under compulsion, for God loves a cheerful giver."',
                    style: AppTheme.body(size: 13, color: AppColors.charcoal).copyWith(fontStyle: FontStyle.italic),
                  ),
                  const SizedBox(height: 6),
                  Text('— 2 Corinthians 9:7', style: AppTheme.body(size: 11.5, color: AppColors.muted)),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(children: [
              const Icon(Icons.lock_outline, size: 14, color: AppColors.muted),
              const SizedBox(width: 6),
              Expanded(
                child: Text('Your giving goes directly to the ministry\'s bank account.',
                    style: AppTheme.body(size: 11, color: AppColors.muted)),
              ),
            ]),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  final String label;
  final String value;
  final VoidCallback onCopy;
  final bool emphasize;
  const _DetailRow({required this.label, required this.value, required this.onCopy, this.emphasize = false});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(label, style: AppTheme.body(size: 11, color: AppColors.muted)),
              const SizedBox(height: 2),
              Text(value, style: AppTheme.body(size: emphasize ? 16 : 14, weight: FontWeight.w700)),
            ],
          ),
        ),
        IconButton(
          onPressed: onCopy,
          icon: const Icon(Icons.copy_outlined, size: 18, color: AppColors.navy),
          tooltip: 'Copy',
        ),
      ],
    );
  }
}

class _WhyCard extends StatelessWidget {
  final List<String> points;
  const _WhyCard({required this.points});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.cream2,
        border: Border.all(color: AppColors.line),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: points
            .map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(top: 3),
                        child: Icon(Icons.check_circle, size: 14, color: AppColors.sage),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(p, style: AppTheme.body(size: 13, color: AppColors.charcoal))),
                    ],
                  ),
                ))
            .toList(),
      ),
    );
  }
}
