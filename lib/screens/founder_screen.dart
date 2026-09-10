import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// Static "About the Founder" page. This content does not come from
/// Firestore — it is hardcoded to match the website's founder.html exactly,
/// since it is informational content that rarely changes (per the project's
/// convention of only wiring to Firestore for user-generated data).
///
/// Photo is loaded directly from the website's GitHub repo (same file the
/// website itself uses), so no image asset needs to be bundled into the app.
class FounderScreen extends StatelessWidget {
  const FounderScreen({super.key});

  static const _photoUrl =
      'https://raw.githubusercontent.com/cuscus144/Spiritus-Sanctus-Ignis/main/founder-okoro-titus-amaobi.jpg';

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.cream,
      appBar: AppBar(
        backgroundColor: AppColors.cream,
        elevation: 0,
        foregroundColor: AppColors.charcoal,
        title: Text('About the Founder', style: AppTheme.heading(size: 18)),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: Image.network(
                  _photoUrl,
                  height: 260,
                  width: double.infinity,
                  fit: BoxFit.cover,
                  errorBuilder: (_, __, ___) => Container(
                    height: 260,
                    color: AppColors.cream2,
                    child: const Icon(Icons.person, size: 64, color: AppColors.muted),
                  ),
                  loadingBuilder: (context, child, progress) => progress == null
                      ? child
                      : Container(
                          height: 260,
                          color: AppColors.cream2,
                          child: const Center(child: CircularProgressIndicator(color: AppColors.navy)),
                        ),
                ),
              ),
            ),
            const SizedBox(height: 18),
            Text('Prophet Okoro Titus Amaobi', style: AppTheme.heading(size: 21)),
            const SizedBox(height: 6),
            Text(
              'Founder and Presiding Prophet of Spiritus Sanctus Ignis Ministry — '
              "a life devoted to prayer, healing, and the restoration of God's people.",
              style: AppTheme.body(size: 13.5, color: AppColors.muted),
            ),
            const SizedBox(height: 24),
            const _Section(
              title: 'A Life Devoted to Kingdom Purpose',
              body:
                  'Okoro Titus Amaobi is the founder and presiding prophet of Spiritus '
                  'Sanctus Ignis Ministry. Born on March 4, 1971, in Ogwofia, Ozom '
                  "Mgbagbu-Owa, Enugu State, Nigeria, he is a distinguished Nigerian man "
                  "of God whose life has been devoted to prayer, healing, and the "
                  "restoration of God's people.",
            ),
            const _Section(
              title: 'Early Life and Background',
              body:
                  'Prophet Okoro Titus Amaobi was born into a comfortable family in '
                  'Ezeagu Local Government Area, Enugu State. Despite the stability of '
                  'his upbringing, he faced significant personal challenges in his '
                  'early life — trials that ultimately deepened his faith and '
                  'cultivated within him a strong, enduring desire to serve God.',
            ),
            const _Section(
              title: 'Conversion and Call to Ministry',
              body:
                  'In 1992, he encountered Christ in a profound way at the Catholic '
                  'Prayer Ministry of the Holy Spirit in Elele, Rivers State, and from '
                  "that moment dedicated his life fully to God's service. His "
                  'conversion marked the beginning of an unwavering passion for '
                  'bringing others to Christ, anchored in a deep conviction in the '
                  'power of faith, prayer, and the Word of God.',
            ),
            const _Section(
              title: 'Ministry Journey',
              body:
                  'His ministry began in 1997 with the founding of an independent '
                  'prayer group in Lagos, known as the I Am That I Am Ministry. Over '
                  'the following decades, the ministry grew and evolved in step with '
                  'his calling — becoming the Ministry of the Holy Spirit in 2018, and '
                  'later Spiritus Sanctus Ignis Ministry in 2025. Throughout this '
                  'journey, he has led with a prophetic gift widely recognized for '
                  'intense prayer, holiness, and healing miracles.',
            ),
            const _Section(
              title: 'Personal Life and Character',
              body:
                  'Prophet Okoro Titus Amaobi is known for his boldness, humility, '
                  'generosity, and unshakable belief in the power of God. He is '
                  'married with four children.',
            ),
            const SizedBox(height: 8),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.navy,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('His Vision', style: AppTheme.heading(size: 16, color: AppColors.goldSoft)),
                  const SizedBox(height: 8),
                  Text(
                    "To reconcile the world and bring God's people back home — and to "
                    'demonstrate to believers everywhere that God is the God of Divine '
                    'Increase, fully able to turn the impossible into the possible here '
                    'on earth.',
                    style: AppTheme.body(size: 13.5, color: Colors.white.withOpacity(0.85)),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Section extends StatelessWidget {
  final String title;
  final String body;
  const _Section({required this.title, required this.body});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: AppTheme.heading(size: 15)),
          const SizedBox(height: 6),
          Text(body, style: AppTheme.body(size: 13.5, color: AppColors.charcoal).copyWith(height: 1.5)),
        ],
      ),
    );
  }
}
