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
          'Kebijakan Privasi',
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
                      'Versi $policyVersion • Pembaruan: $lastUpdated',
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
                      _buildTitle('1. Pendahuluan'),
                      _buildParagraph(
                        'Selamat datang di Writelle ("Aplikasi"). Writelle adalah wadah literatur dan suaka kata yang mengedepankan ketenangan, kejujuran berekspresi, dan privasi pembaca serta penulis. Kami menghormati hak privasi Anda dan berkomitmen untuk melindungi data pribadi yang Anda percayakan kepada kami.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('2. Data yang Kami Kumpulkan'),
                      _buildParagraph(
                        'Writelle hanya mengumpulkan informasi yang esensial untuk menyediakan layanan storytelling yang aman dan nyaman:',
                      ),
                      _buildBullet('Informasi Akun:', 'Alamat email dan kata sandi terenkripsi saat Anda mendaftar akun.'),
                      _buildBullet('Profil Pseudonim:', 'Nama pena (pen name), kutipan biografi opsional, dan foto avatar opsional yang Anda pilih secara sukarela.'),
                      _buildBullet('Konten Pengguna (UGC):', 'Kisah, tulisan, judul, pilihan kategori, serta komentar yang Anda unggah ke suaka.'),
                      _buildBullet('Interaksi Suaka:', 'Data tanda suka (apresiasi), simpanan (bookmark), serta relasi pembaca (readers & following).'),
                      _buildBullet('Pilihan Privasi:', 'Status penulisan anonim (Pure Anonymity) yang Anda aktifkan pada cerita tertentu.'),
                      const SizedBox(height: 18),

                      _buildTitle('3. Cara Kami Mengumpulkan Informasi'),
                      _buildParagraph(
                        'Kami mengumpulkan informasi secara langsung saat Anda mendaftarkan diri, memperbarui profil, menuliskan kisah, atau memberikan apresiasi pada karya penulis lain. Jika Anda memilih masuk menggunakan Google OAuth, kami menerima nama dan alamat email yang Anda otorisasi.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('4. Tujuan dan Penggunaan Data'),
                      _buildParagraph(
                        'Data yang terkumpul digunakan semata-mata untuk:',
                      ),
                      _buildBullet('Layanan Inti:', 'Mengotentikasi akun, menyajikan linimasa cerita, dan menampilkan karya Anda.'),
                      _buildBullet('Privasi Terjaga:', 'Menyamarkan nama dan avatar Anda saat Anda mengaktifkan mode publikasi anonim.'),
                      _buildBullet('Keamanan Suaka:', 'Memoderasi konten yang melanggar aturan dan memproses laporan komunitas.'),
                      _buildBullet('Tidak Ada Iklan Pihak Ketiga:', 'Kami TIDAK menjual data Anda kepada broker data, pengiklan, atau pihak komersial mana pun.'),
                      const SizedBox(height: 18),

                      _buildTitle('5. Penyimpanan dan Keamanan Data'),
                      _buildParagraph(
                        'Data disimpan secara aman menggunakan infrastruktur Supabase (PostgreSQL) dengan standar enkripsi industri SSL/TLS saat transit data dan enkripsi at-rest. Akses data dibatasi secara ketat menggunakan Row Level Security (RLS) pada tingkat basis data.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('6. Pembagian Data & Layanan Pihak Ketiga'),
                      _buildParagraph(
                        'Kami tidak membagikan informasi pribadi Anda kepada pihak luar, kecuali untuk mitra infrastruktur esensial berikut:',
                      ),
                      _buildBullet('Supabase Inc:', 'Penyedia infrastruktur otentikasi dan basis data terenkripsi.'),
                      _buildBullet('Google Identity (Opsional):', 'Hanya diproses saat Anda secara sadar memilih masuk via Google Sign-In.'),
                      const SizedBox(height: 18),

                      _buildTitle('7. Penyimpanan Sesi & SharedPreferences'),
                      _buildParagraph(
                        'Aplikasi menggunakan penyimpanan lokal perangkat (SharedPreferences) untuk menyimpan token sesi terenkripsi agar Anda tidak perlu masuk berulang kali, serta menyimpan preferensi tampilan lokal. Kami tidak menggunakan cookie pelacak iklan pihak ketiga.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('8. Retensi Data & Tempat Sampah 14 Hari'),
                      _buildBullet('Kisah Dihapus:', 'Cerita yang dihapus oleh penulis atau kurator akan disimpan sementara di ruang karantina (Trash) selama 14 hari untuk pemulihan darurat sebelum dihapus secara permanen dari server.'),
                      _buildBullet('Akun Aktif:', 'Data profil dan karya aktif disimpan selama akun Anda berstatus aktif.'),
                      const SizedBox(height: 18),

                      _buildTitle('9. Hak Privasi Anda'),
                      _buildParagraph(
                        'Anda memiliki hak penuh untuk mengakses, memperbarui nama pena, mengganti avatar, menyunting karya, atau menghapus seluruh tulisan Anda sewaktu-waktu melalui aplikasi.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('10. Hak Penghapusan Akun (Account Deletion)'),
                      _buildParagraph(
                        'Sesuai kebijakan Google Play Store, Anda berhak menghapus akun Anda beserta seluruh data pribadi terkait kapan pun:',
                      ),
                      _buildBullet('Di Dalam Aplikasi:', 'Masuk ke menu Profil > Ketuk ikon kunci/setelan di pojok kanan atas > Pilih "Hapus Akun & Data Suaka". Seluruh data profil, kisah, dan data otentikasi akan dihapus permanen.'),
                      _buildBullet('Permohonan Luar Aplikasi (Web):', 'Jika Anda tidak dapat mengakses aplikasi, Anda dapat mengajukan permohonan penghapusan akun melalui formulir web resmi kami atau mengirimkan email ke kontak pengembang kami.'),
                      const SizedBox(height: 18),

                      _buildTitle('11. Privasi Anak-Anak'),
                      _buildParagraph(
                        'Writelle tidak ditujukan untuk anak-anak di bawah usia 13 tahun. Kami tidak secara sadar mengumpulkan data anak di bawah 13 tahun. Jika Anda adalah orang tua/wali dan mengetahui anak Anda memberikan data pribadi, silakan hubungi kami untuk penghapusan segera.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('12. Perubahan Kebijakan Privasi'),
                      _buildParagraph(
                        'Kami dapat memperbarui kebijakan privasi ini dari waktu ke waktu. Pembaruan akan ditampilkan di halaman ini dengan tanggal revisi terbaru.',
                      ),
                      const SizedBox(height: 18),

                      _buildTitle('13. Hubungi Kami'),
                      _buildParagraph(
                        'Jika Anda memiliki pertanyaan, masukan, atau permohonan terkait data privasi Anda di Writelle, silakan hubungi kami melalui:\n• Email Pengembang: isamualfian2@gmail.com\n• Aplikasi: Writelle Sanctuary Platform',
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
