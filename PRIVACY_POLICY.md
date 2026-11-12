# KEBIJAKAN PRIVASI (PRIVACY POLICY) — WRITELLE

**Versi:** 1.0.0  
**Tanggal Berlaku:** 7 November 2026  
**Terakhir Diperbarui:** 7 November 2026  

Selamat datang di **Writelle** ("Aplikasi", "Kami", "Pengembang"). Writelle adalah sebuah ruang kontemplatif bagi para pembaca dan penulis untuk menuangkan kata, menyelami narasi lambat (*slow reading*), dan berbagi karya sastra. Kami menghormati ruang pribadi dan integritas data Anda.

Kebijakan Privasi ini menerangkan bagaimana Kami mengumpulkan, menggunakan, menyimpan, membagikan, dan melindungi data pribadi Anda saat menggunakan aplikasi mobile Writelle maupun situs web terkait, serta hak-hak Anda berdasarkan regulasi perlindungan data yang berlaku, termasuk **Undang-Undang Perlindungan Data Pribadi (UU PDP No. 27/2022)** di Indonesia, **General Data Protection Regulation (GDPR)** di Uni Eropa, **California Consumer Privacy Act (CCPA)**, dan **California Online Privacy Protection Act (CalOPPA)** di Amerika Serikat.

Dengan mendaftarkan akun, mengakses, atau menggunakan Writelle, Anda menyatakan bahwa Anda telah membaca, memahami, dan menyetujui praktik pemrosesan data yang dijabarkan dalam dokumen ini.

---

## 1. Informasi yang Kami Kumpulkan

Kami hanya mengumpulkan data yang benar-benar esensial untuk menjalankan fungsionalitas aplikasi (*principle of data minimization*). Kategori data yang dikumpulkan meliputi:

### A. Informasi yang Diberikan Pengguna Secara Sukarela
1. **Data Akun & Autentikasi:**
   - Alamat surat elektronik (email).
   - Kata sandi (disimpan secara aman dalam bentuk *cryptographic hash* melalui sistem autentikasi Supabase, kami tidak pernah memiliki akses ke teks asli kata sandi Anda).
2. **Data Profil:**
   - Nama pena (*display name* / nama pengguna).
   - Biografi singkat (*bio*).
   - Foto profil / avatar (diunggah secara opsional oleh pengguna).
3. **Konten Buatan Pengguna (*User-Generated Content* / UGC):**
   - Naskah dan karya sastra yang Anda tulis, publikasikan, atau simpan sebagai draf.
   - Komentar, catatan refleksi, dan respon terhadap karya penulis lain.
   - Interaksi sosial (daftar akun yang diikuti / *following*, pembaca / *readers*, dan apresiasi suka / *likes*).
4. **Laporan & Komunikasi:**
   - Laporan konten tidak pantas atau pelanggaran komunitas yang Anda kirimkan kepada kurator.
   - Komunikasi dukungan teknis saat Anda menghubungi tim pengembang.

### B. Data yang Dikumpulkan Secara Otomatis
1. **Penyimpanan Lokal (*Local Storage*) & Sesi:**
   - Token sesi autentikasi terenkripsi (*JWT tokens*) untuk mempertahankan status *login*.
   - Preferensi lokal aplikasi (pengaturan tema warna, ukuran teks membaca, cache karya).
   - Daftar lokal akun yang Anda blokir (*Blocked Authors list*) yang disimpan di perangkat Anda menggunakan `SharedPreferences`.
2. **Data Log & Diagnostik Minimal:**
   - Metadata transaksi jaringan standar saat berkomunikasi dengan server backend Supabase (misalnya cap waktu permintaan dan kode status HTTP).
   - *Catatan:* Writelle **TIDAK** menggunakan Google Maps API, suar web (*web beacons* pelacak), cookie pihak ketiga untuk periklanan, atau SDK analitik agresif pihak ketiga.

### C. Data yang TIDAK Kami Kumpulkan
- Kami **TIDAK** mengumpulkan lokasi geografis presisi (*Fine GPS Location*).
- Kami **TIDAK** meminta akses ke buku kontak, mikrofon, SMS, daftar panggilan, atau Bluetooth Anda.
- Kami **TIDAK** meminta akses luas ke seluruh media perangkat (`READ_MEDIA_IMAGES` / broad storage). Pemilihan foto profil atau gambar naskah murni menggunakan dialog sistem Android Photo Picker yang aman dan terisolasi.

---

## 2. Bagaimana Kami Mengumpulkan Informasi

1. **Input Langsung:** Ketika Anda mengisi formulir registrasi, memperbarui profil di halaman Pengaturan Sanctuary, mempublikasikan karya, atau meninggalkan komentar.
2. **Interaksi Sistem:** Ketika aplikasi melakukan sinkronisasi data dengan backend Supabase melalui antarmuka REST API / HTTPS terenkripsi.
3. **Penyimpanan Lokal Perangkat:** Ketika preferensi baca atau daftar blokir disimpan langsung di ruang penyimpanan privat aplikasi (*sandbox storage* Android).

---

## 3. Bagaimana Kami Menggunakan Informasi Anda

Data yang dikumpulkan dipergunakan semata-mata untuk:
1. **Penyediaan Layanan Inti:**
   - Mengautentikasi identitas Anda saat masuk ke Sanctuary Writelle.
   - Menampilkan naskah, cerita, dan profil Anda kepada komunitas pembaca sesuai pengaturan privasi naskah.
   - Mengelola daftar ikuti (*following*) dan pembaca (*readers*) secara *real-time*.
2. **Keselamatan Komunitas & Moderasi Konten:**
   - Memproses laporan karya tidak layak atau melanggar norma komunitas (*zero tolerance for abusive content*).
   - Memfilter dan memblokir interaksi dari penulis yang telah Anda tandai sebagai diblokir.
   - Mengelola masa retensi 14 hari bagi karya yang dihapus oleh kurator sebelum dilakukan pemusnahan permanen.
3. **Pemberitahuan & Operasional Layanan:**
   - Mengirimkan email konfirmasi registrasi atau pemulihan kata sandi.
   - Mencegah spam, bot, dan upaya eksploitasi keamanan terhadap sistem kami.

Kami **TIDAK PERNAH** menjual, menyewakan, atau memperdagangkan data pribadi Anda kepada pialang data (*data brokers*), biro periklanan, atau pihak komersial mana pun.

---

## 4. Penyimpanan dan Keamanan Data

Kami menerapkan standar keamanan teknis dan organisasional yang ketat:
1. **Enkripsi dalam Transit:** Seluruh transmisi data antara aplikasi Writelle dan server backend dilindungi menggunakan protokol enkripsi standar industri **Transport Layer Security (TLS 1.2/1.3 / HTTPS)**.
2. **Enkripsi saat Istirahat (*At Rest*):** Data database disimpan dalam infrastruktur terkelola **Supabase** yang berjalan di atas PostgreSQL enterprise dengan enkripsi disk AES-256.
3. **Row-Level Security (RLS):** Basis data kami dilindungi oleh aturan keamanan tingkat baris (*PostgreSQL RLS*), memastikan bahwa pengguna hanya dapat menyunting atau menghapus data milik mereka sendiri, kecuali jika diproses oleh kurator terotorisasi.
4. **Isolasi Perangkat:** Data lokal aplikasi (seperti token sesi dan daftar blokir) tersimpan di ruang privat aplikasi (*App Sandbox*) pada OS Android, terisolasi dari aplikasi lain di perangkat Anda.

---

## 5. Berbagi Data dan Layanan Pihak Ketiga

Kami hanya membagikan data Anda kepada penyedia infrastruktur esensial berikut:

| Penyedia Layanan | Tujuan | Lokasi / Kebijakan Privasi |
| :--- | :--- | :--- |
| **Supabase Inc.** | Backend-as-a-Service (BaaS), Database PostgreSQL terenkripsi, Autentikasi Pengguna, dan Media Storage. | [Kebijakan Privasi Supabase](https://supabase.com/privacy) |
| **Google Play Services** | Distribusi aplikasi Android dan integritas biner via Google Play Store. | [Kebijakan Privasi Google](https://policies.google.com/privacy) |

Kami dapat membuka data Anda jika diwajibkan oleh hukum yang berlaku, surat perintah pengadilan, atau perintah resmi dari otoritas penegak hukum yang sah.

---

## 6. Retensi Data (*Data Retention Schedule*)

Kami menyimpan data Anda berdasarkan masa retensi terukur berikut:
1. **Data Akun Aktif:** Disimpan selama akun Anda berstatus aktif di Writelle.
2. **Karya / Naskah yang Dihapus (Soft-Delete 14 Hari):**
   - Karya yang dihapus atau ditindak oleh kurator/admin disimpan sementara selama **14 (empat belas) hari kalender** dalam folder retensi sistem.
   - Selama masa 14 hari tersebut, karya tidak dapat diakses oleh publik, dan kurator memiliki kewenangan untuk memulihkan (*restore*) apabila terbukti terjadi kesalahpahaman pelaporan.
   - Setelah lewat dari 14 hari, sistem akan menghapus karya tersebut secara **permanen dan tidak dapat dipulihkan (*irreversible hard deletion*)**.
3. **Penghapusan Akun (*Account Deletion*):**
   - Saat pengguna melakukan permintaan penghapusan akun, seluruh data profil, naskah pribadi, komentar, dan riwayat sosial akan dimusnahkan secara langsung dari database utama tanpa penundaan.

---

## 7. Hak Privasi Pengguna (*User Privacy Rights*)

Tergantung pada yurisdiksi tempat tinggal Anda, Anda memiliki hak-hak hukum berikut:
1. **Hak untuk Mengetahui dan Mengakses:** Anda berhak meminta salinan data pribadi yang kami simpan tentang Anda.
2. **Hak Perbaikan (Rektifikasi):** Anda dapat memperbarui profil, nama pena, avatar, dan konten Anda kapan saja langsung di dalam aplikasi.
3. **Hak Penghapusan (Hak untuk Dilupakan):** Anda berhak meminta penghapusan total atas akun dan seluruh data pribadi Anda.
4. **Hak Penarikan Persetujuan:** Anda dapat mencabut izin pemrosesan data dengan cara menghapus akun Anda.
5. **Hak Non-Diskriminasi:** Kami tidak akan pernah membeda-bedakan kualitas layanan apabila Anda menggunakan hak privasi Anda.

---

## 8. Mekanisme Penghapusan Akun dan Data Pribadi (*Account & Data Deletion*)

Sesuai dengan **Kebijakan Data Pengguna Google Play Store**, Writelle menyediakan dua jalur penghapusan akun yang mudah diakses:

### A. Jalur Dalam Aplikasi (*In-App Deletion*)
1. Buka aplikasi **Writelle**.
2. Masuk ke tab **Profil / Sanctuary**.
3. Ketuk ikon Pengaturan / Menu.
4. Pilih opsi **"Hapus Akun Sanctuary" (Delete Sanctuary Account)** yang ditandai dengan warna peringatan merah.
5. Konfirmasi dialog peringatan. Seluruh kredensial, profil, naskah, dan data interaksi Anda akan langsung dihapus dari sistem secara permanen.

### B. Jalur Web Publik (*Public Web Deletion Portal*)
Bagi pengguna yang telah mencopot pemasangan aplikasi atau tidak dapat mengakses perangkatnya, Kami menyediakan formulir permintaan penghapusan akun berbasis web yang dapat diakses publik tanpa perlu login:
- **Tautan Portal Web:** `https://writelle.pages.dev/account_deletion.html` (atau berkas `docs/account_deletion.html` pada repositori distribusi resmi).
- Permintaan yang masuk melalui portal web akan diverifikasi melalui email pemilik akun dan diselesaikan dalam jangka waktu maksimal 7 (tujuh) hari kerja.

---

## 9. Perlindungan Privasi Anak-Anak (*Children's Privacy*)

Writelle dirancang untuk khalayak umum yang telah cakap hukum (minimal berusia **13 tahun** atau batas usia yang ditentukan di negara Anda, misalnya 16 tahun di yurisdiksi GDPR tertentu). 

Kami tidak pernah secara sengaja mengumpulkan data pribadi dari anak-anak di bawah umur 13 tahun. Jika Kami mengetahui bahwa seorang anak di bawah 13 tahun telah mendaftarkan akun tanpa persetujuan orang tua yang sah, Kami akan segera mengambil langkah untuk menghapus akun dan data tersebut dari sistem Kami. Jika Anda adalah orang tua atau wali yang mengetahui anak Anda memberikan data kepada Kami, silakan hubungi saluran bantuan kami.

---

## 10. Kepatuhan Regulasi Spesifik (CalOPPA, GDPR, CCPA, UU PDP)

### A. CalOPPA (California Online Privacy Protection Act)
- Kami mencantumkan Kebijakan Privasi ini secara mencolok di halaman pendaftaran, pengaturan profil, dan tautan publik Play Store.
- Kami mematuhi sinyal preferensi dan menyediakan opsi pelaporan pelanggaran secara transparan.

### B. GDPR (General Data Protection Regulation — EU/EEA)
- **Dasar Hukum Pemrosesan:** Kontrak layanan (*performance of contract*) saat Anda mendaftar akun, dan persetujuan eksplisit (*consent*) untuk fitur opsional.
- **Pengawas Data (*Data Controller*):** Tim Pengembang Writelle.

### C. CCPA (California Consumer Privacy Act)
- Writelle **tidak menjual (*Do Not Sell*)** data pribadi konsumen California dalam 12 bulan terakhir dan tidak akan pernah menjualnya di masa mendatang.

### D. UU PDP No. 27/2022 (Indonesia)
- Pemrosesan data dilakukan berdasarkan prinsip perlindungan data pribadi yang sah, transparan, terbatas, dan akuntabel sesuai hukum Republik Indonesia.

---

## 11. Perubahan atas Kebijakan Privasi Ini

Kami dapat memperbarui Kebijakan Privasi ini dari waktu ke waktu untuk menyesuaikan dengan pembaruan fitur aplikasi atau perubahan regulasi hukum. Versi terbaru akan selalu menampilkan tanggal "Terakhir Diperbarui" di bagian atas dokumen. Kami menyarankan Anda untuk meninjau Kebijakan Privasi ini secara berkala.

---

## 12. Informasi Kontak & Bantuan Pengembang

Apabila Anda memiliki pertanyaan, keluhan, masukan, atau hendak mengajukan permohonan pelaksanaan hak privasi data Anda, silakan hubungi tim kepatuhan data kami melalui:

- **Nama Aplikasi:** Writelle
- **Pengembang:** Writelle Sanctuary Team
- **Email Dukungan & Kepatuhan Privasi:** `privacy@writelle.app` *(atau kontak email resmi akun Google Play Developer Anda)*
- **Alamat Portal Dukungan Web:** `https://writelle.pages.dev`
