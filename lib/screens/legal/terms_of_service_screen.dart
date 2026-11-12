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
          'Syarat & Ketentuan',
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
                      'Versi $termsVersion • Pembaruan: $lastUpdated',
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
                      _buildTitle('1. Ketentuan Umum'),
                      _buildParagraph(
                        'Dengan mendaftar, mengakses, atau menggunakan aplikasi Writelle, Anda menyetujui untuk terikat oleh Syarat dan Ketentuan ini. Jika Anda tidak menyetujui salah satu pasal, mohon untuk tidak menggunakan layanan ini.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('2. Suaka Kata & Etos Komunitas'),
                      _buildParagraph(
                        'Writelle dibangun sebagai suaka sastra untuk refleksi mendalam, kisah kehidupan, dan kata-kata hening. Kami menjunjung tinggi rasa saling menghargai antarpenulis dan pembaca.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('3. Kebijakan Konten Buatan Pengguna (UGC) — Toleransi Nol'),
                      _buildParagraph(
                        'Sesuai dengan Kebijakan Pengembang Google Play mengenai Konten Buatan Pengguna (User-Generated Content), Writelle menerapkan kebijakan TOLERANSI NOL (Zero Tolerance) terhadap segala bentuk konten dan perilaku yang melanggar hukum serta membahayakan komunitas, meliputi:',
                      ),
                      _buildBullet('Pelecehan & Perundungan:', 'Dilarang merendahkan, mengancam, atau mengintimidasi penulis lain.'),
                      _buildBullet('Ujaran Kebencian (Hate Speech):', 'Dilarang menyebarkan kebencian berdasarkan SARA, ras, gender, atau disabilitas.'),
                      _buildBullet('Konten Seksual & Eksplisit:', 'Dilarang mengunggah pornografi, eksploitasi seksual, atau ketelanjangan vulgar.'),
                      _buildBullet('Kekerasan & Bahaya Diri:', 'Dilarang mempromosikan aksi terorisme, kekerasan ekstrem, atau anjuran bunuh diri.'),
                      _buildBullet('Spam & Penipuan:', 'Dilarang menggunakan suaka untuk promosi komersial ilegal, bot, atau penipuan.'),
                      const SizedBox(height: 18),

                      _buildTitle('4. Pelaporan dan Pemblokiran Pengguna'),
                      _buildParagraph(
                        'Untuk menjaga kenyamanan dan ketenteraman bersama:',
                      ),
                      _buildBullet('Lapor Kisah (Report):', 'Setiap pembaca dapat melaporkan tulisan yang melanggar aturan melalui menu "Report Whisper". Kurator kami meninjau laporan ini secara berkala.'),
                      _buildBullet('Blokir Penulis (Block):', 'Pengguna dapat memblokir penulis yang tidak diinginkan sehingga konten mereka tidak lagi tampak di suaka Anda.'),
                      _buildBullet('Tindakan Kurasi:', 'Pengelola suaka (Admin/Kurator) berhak menghapus konten pelanggar dan membekukan akun yang melanggar tanpa pemberitahuan sebelumnya.'),
                      const SizedBox(height: 18),

                      _buildTitle('5. Hak Kekayaan Intelektual'),
                      _buildParagraph(
                        'Hak cipta atas naskah dan cerita yang Anda tulis TETAP SEPENUHNYA MILIK ANDA. Dengan menerbitkan tulisan di Writelle, Anda memberikan lisensi non-eksklusif, bebas royalti kepada Writelle untuk menampilkan, mengarsipkan, dan memformat tulisan Anda di dalam platform untuk keperluan pembacaan.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('6. Akun dan Keamanan'),
                      _buildParagraph(
                        'Anda bertanggung jawab menjaga kerahasiaan kata sandi dan akses akun Anda. Anda dilarang membuat akun tiruan (impersonasi) atau menggunakan nama pena yang melanggar hak cipta pihak lain.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('7. Penafian dan Batasan Tanggung Jawab'),
                      _buildParagraph(
                        'Aplikasi Writelle disediakan "sebagaimana adanya" (as-is). Kami berupaya semaksimal mungkin menjaga keandalan sistem, namun tidak bertanggung jawab atas kerugian tidak langsung yang timbul akibat gangguan teknis di luar kendali wajar kami.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('8. Kontak Dukungan'),
                      _buildParagraph(
                        'Untuk pertanyaan atau aduan terkait ketentuan layanan, silakan hubungi tim pengembang kami di isamualfian2@gmail.com.',
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
