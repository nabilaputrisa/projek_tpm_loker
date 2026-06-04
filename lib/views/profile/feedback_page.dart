import 'package:flutter/material.dart';


class FeedbackPage extends StatefulWidget {
  const FeedbackPage({super.key});

  @override
  State<FeedbackPage> createState() => _FeedbackPageState();
}

class _FeedbackPageState extends State<FeedbackPage> {
  // Data feedback statis
  final List<Map<String, dynamic>> _staticFeedbacks = [
    {
      'name': 'Nabila Putri Salsabila',
      'nim': '123230002',
      'rating': 5,
      'comment':
          'Mata kuliah Teknologi dan Pemrograman Mobile menyajikan tantangan tersendiri, sekaligus memberikan wawasan mengenai pengembangan aplikasi dari tahap awal hingga implementasi. Metode pembelajaran melalui praktik yang meningkatkan kemampuan berpikir logis, ketelitian, dan analisis pemecahan masalah. Mata kuliah ini sangat relevan, dan diharapkan porsi praktiknya tetap dipertahankan agar lebih siap menghadapi dunia kerja.',
      'date': '27 Mei 2026',
      'avatar': 'NPS',
      'likes': 24,
    },
    {
      'name': 'Miftah Sari Nurjanah',
      'nim': '123230022',
      'rating': 5,
      'comment':
          'Mengikuti mata kuliah Teknologi Pemrograman Mobile semester ini menjadi tantangan tersendiri bagi saya karena beban tugasnya yang cukup intens. Meski begitu, saya merasa sangat bersyukur. Dari proses yang menguras energi ini, saya bisa mengambil banyak sisi positif, terutama dalam hal manajemen waktu dan adaptasi dengan hal-hal baru. Pengalaman ini mengajarkan saya bagaimana cara bertahan dan menyelesaikan tanggung jawab dengan baik',
      'date': '27 Mei 2026',
      'avatar': 'MSN',
      'likes': 27,
    },
  ];

  // Statistik rating
  double get _averageRating {
    if (_staticFeedbacks.isEmpty) return 0;
    final total = _staticFeedbacks.fold<int>(
      0,
      (sum, item) => sum + (item['rating'] as int),
    );
    return total / _staticFeedbacks.length;
  }

  Map<int, int> get _ratingDistribution {
    final Map<int, int> distribution = {1: 0, 2: 0, 3: 0, 4: 0, 5: 0};
    for (var feedback in _staticFeedbacks) {
      final rating = feedback['rating'] as int;
      distribution[rating] = (distribution[rating] ?? 0) + 1;
    }
    return distribution;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    
    return Scaffold(
      backgroundColor: cs.surfaceContainerHighest,
      appBar: AppBar(
        backgroundColor: cs.surface,
        elevation: 0,
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back_ios_new_rounded,
            color: cs.onSurface,
          ),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Feedback TPM',
          style: TextStyle(color: cs.onSurface, fontWeight: FontWeight.w600),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header dengan informasi mata kuliah TPM
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cs.primary, // Warna solid
                borderRadius: BorderRadius.circular(20),
              ),
              child: Column(
                children: [
                  Icon(
                    Icons.school_outlined,
                    size: 50,
                    color: cs.onPrimary,
                  ),
                  const SizedBox(height: 10),
                  Text(
                    'Mata Kuliah',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Teknologi dan Pemrograman Mobile',
                    style: TextStyle(
                      color: cs.onPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                    ),
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  // Rating summary
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: cs.onPrimary.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.star, color: Colors.amber, size: 18),
                        const SizedBox(width: 4),
                        Text(
                          _averageRating.toStringAsFixed(1),
                          style: TextStyle(
                            color: cs.onPrimary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(width: 4),
                        Text(
                          '(${_staticFeedbacks.length} ulasan)',
                          style: TextStyle(
                            color: cs.onPrimary.withOpacity(0.8),
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Statistik Rating
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Statistik Rating',
                    style: TextStyle(
                      color: cs.onSurface,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 16),
                  ...List.generate(5, (index) {
                    final rating = 5 - index;
                    final count = _ratingDistribution[rating] ?? 0;
                    final percentage = _staticFeedbacks.isEmpty
                        ? 0
                        : (count / _staticFeedbacks.length * 100);
                    return Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(
                        children: [
                          SizedBox(
                            width: 40,
                            child: Row(
                              children: [
                                Text(
                                  rating.toString(),
                                  style: TextStyle(
                                    color: cs.onSurfaceVariant,
                                    fontSize: 12,
                                  ),
                                ),
                                const Icon(
                                  Icons.star,
                                  size: 12,
                                  color: Colors.amber,
                                ),
                              ],
                            ),
                          ),
                          Expanded(
                            child: ClipRRect(
                              borderRadius: BorderRadius.circular(4),
                              child: LinearProgressIndicator(
                                value: percentage / 100,
                                backgroundColor: cs.outlineVariant,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  cs.primary,
                                ),
                                minHeight: 6,
                              ),
                            ),
                          ),
                          SizedBox(
                            width: 35,
                            child: Text(
                              '$count',
                              style: TextStyle(
                                color: cs.onSurfaceVariant,
                                fontSize: 12,
                              ),
                              textAlign: TextAlign.right,
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ],
              ),
            ),

            const SizedBox(height: 24),

            // Daftar Feedback
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Ulasan Mahasiswa',
                  style: TextStyle(
                    color: cs.onSurface,
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: cs.primary.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${_staticFeedbacks.length} ulasan',
                    style: TextStyle(
                      color: cs.primary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // List Feedback
            ListView.separated(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: _staticFeedbacks.length,
              separatorBuilder: (context, index) => const SizedBox(height: 12),
              itemBuilder: (context, index) {
                final feedback = _staticFeedbacks[index];
                return _buildFeedbackCard(feedback, cs);
              },
            ),

            const SizedBox(height: 20),

            // Informasi tambahan
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cs.surface,
                borderRadius: BorderRadius.circular(16),
                boxShadow: [
                  BoxShadow(
                    color: cs.shadow.withOpacity(0.06),
                    blurRadius: 12,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  Icon(
                    Icons.info_outline,
                    color: cs.primary,
                    size: 20,
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      'Data feedback merupakan ulasan dari mahasiswa yang telah mengambil mata kuliah TPM.',
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 40),
          ],
        ),
      ),
    );
  }

  Widget _buildFeedbackCard(Map<String, dynamic> feedback, ColorScheme cs) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              // Avatar
              Container(
                width: 45,
                height: 45,
                decoration: BoxDecoration(
                  color: cs.secondary, // Warna solid
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Center(
                  child: Text(
                    feedback['avatar'],
                    style: TextStyle(
                      color: cs.onSecondary,
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      feedback['name'],
                      style: TextStyle(
                        color: cs.onSurface,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      feedback['nim'],
                      style: TextStyle(
                        color: cs.onSurfaceVariant,
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
              // Rating
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.amber.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  children: [
                    const Icon(Icons.star, color: Colors.amber, size: 14),
                    const SizedBox(width: 4),
                    Text(
                      feedback['rating'].toString(),
                      style: const TextStyle(
                        color: Colors.amber,
                        fontWeight: FontWeight.bold,
                        fontSize: 14,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          // Comment
          Text(
            feedback['comment'],
            style: TextStyle(
              color: cs.onSurfaceVariant,
              fontSize: 14,
              height: 1.4,
            ),
          ),
          const SizedBox(height: 12),
          // Footer
          Row(
            children: [
              Icon(
                Icons.access_time,
                size: 14,
                color: cs.onSurfaceVariant.withOpacity(0.6),
              ),
              const SizedBox(width: 4),
              Text(
                feedback['date'],
                style: TextStyle(
                  color: cs.onSurfaceVariant.withOpacity(0.6),
                  fontSize: 11,
                ),
              ),
              const Spacer(),
              // Like button
              GestureDetector(
                onTap: () {
                  // Like functionality (tidak disimpan, hanya visual)
                  setState(() {
                    feedback['likes'] = (feedback['likes'] as int) + 1;
                  });
                },
                child: Row(
                  children: [
                    Icon(
                      Icons.favorite_border,
                      size: 14,
                      color: cs.onSurfaceVariant.withOpacity(0.6),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      feedback['likes'].toString(),
                      style: TextStyle(
                        color: cs.onSurfaceVariant.withOpacity(0.6),
                        fontSize: 12,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}