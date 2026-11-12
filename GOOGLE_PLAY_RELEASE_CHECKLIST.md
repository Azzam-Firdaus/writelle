# GOOGLE PLAY RELEASE CHECKLIST — WRITELLE

**Panduan Langkah Demi Langkah Menuju Publikasi Google Play Store Bebas Penolakan**  
**Target:** Google Play Console  
**Tanggal:** 7 November 2026  

---

## 1. Fase Persiapan Teknis & Kode Sumber (Technical Readiness)

### [x] 1.1 Ganti Nama Paket (Application ID) — SELESAI
- **Status:** Berhasil diubah ke `com.writelle.sanctuary` di `android/app/build.gradle.kts`, `MainActivity.java`, dan `project.pbxproj` (iOS).
- **Hasil:** Aplikasi siap diunggah ke Google Play Console tanpa risiko penolakan akibat namespace `com.example.*`.

### [ ] 1.2 Konfigurasi Kunci Rilis (Upload Keystore & App Signing)
- **Tindakan:**
  1. Buat keystore rilis menggunakan Java Keytool:
     ```bash
     keytool -genkey -v -keystore android/upload-keystore.jks -keyalg RSA -keysize 2048 -validity 10000 -alias upload
     ```
  2. Buat file `android/key.properties` (pastikan file ini masuk ke `.gitignore`):
     ```properties
     storePassword=PASSWORD_ANDA
     keyPassword=PASSWORD_ANDA
     keyAlias=upload
     storeFile=upload-keystore.jks
     ```
  3. Pastikan `android/app/build.gradle.kts` membaca file konfigurasi penandatanganan ini saat kompilasi release.

### [ ] 1.3 Verifikasi Target SDK (API 34 / 35)
- Google Play mewajibkan target API level terbaru (minimal API 34).
- Cek di `android/app/build.gradle.kts`:
  - `compileSdk = 35` (atau `flutter.compileSdkVersion`)
  - `targetSdk = 34` (atau 35)
  - `minSdk = 21`

### [ ] 1.4 Verifikasi Supabase Database Migration
- Buka dashboard Supabase Production Anda.
- Jalankan SQL script dari file `supabase/retention_and_reports_fix.sql`:
  - Mengaktifkan RPC `public.delete_user_account()` untuk fitur hapus akun.
  - Mengaktifkan foreign key `public.follows` untuk real-time readers & following.
  - Memastikan kolom `deleted_at` pada tabel `stories` aktif untuk masa retensi 14 hari.

### [ ] 1.5 Build Android App Bundle (.aab)
- Google Play tidak menerima `.apk` untuk aplikasi baru; hanya menerima format `.aab`.
- Jalankan perintah di terminal:
  ```bash
  flutter clean
  flutter pub get
  flutter build appbundle --release
  ```
- File output akan berada di: `build/app/outputs/bundle/release/app-release.aab`.

---

## 2. Fase Hosting Dokumen Legal & URL Wajib (Public URLs)

Google Play Console mewajibkan 2 tautan publik yang dapat diakses oleh siapa saja tanpa autentikasi:

### [ ] 2.1 Hosting Kebijakan Privasi (Privacy Policy URL)
- Ambil file `docs/privacy_policy.html` (atau gunakan konten dari `PRIVACY_POLICY.md`).
- Unggah ke hosting gratis (GitHub Pages, Cloudflare Pages, Netlify, atau Firebase Hosting).
- Contoh URL yang dihasilkan: `https://writelle.pages.dev/privacy_policy.html`.
- Masukkan URL ini pada menu: **Play Console -> Policy and programs -> App content -> Privacy policy**.

### [ ] 2.2 Hosting Permintaan Hapus Akun (Account Deletion Request URL)
- Ambil file `docs/account_deletion.html`.
- Unggah ke hosting publik yang sama.
- Contoh URL yang dihasilkan: `https://writelle.pages.dev/account_deletion.html`.
- Masukkan URL ini pada bagian pertanyaan **Data Safety -> Account deletion URL** di Play Console.

---

## 3. Fase Pengisian Metadata & Materi Promosi (Store Listing)

### [ ] 3.1 Metadata Teks
- **Nama Aplikasi (App Name):** `Writelle: Slow Reading & Words` (Maksimal 30 karakter).
- **Deskripsi Singkat (Short Description):**  
  *Ruang kontemplasi membaca dan menulis narasi sastra lambat yang hening.* (Maksimal 80 karakter).
- **Deskripsi Lengkap (Full Description):**  
  Jelaskan fitur utama Writelle secara transparan (Membaca karya, menulis naskah, moderasi komunitas, bookmark, profil santun). Hindari *keyword stuffing* yang berlebihan.

### [ ] 3.2 Aset Grafis (Graphic Assets)
- **Ikon Aplikasi (App Icon):** 512 x 512 piksel, PNG 32-bit dengan alpha, maksimal 1 MB.
- **Gambar Unggulan (Feature Graphic):** 1024 x 500 piksel, JPG atau PNG tanpa alpha.
- **Tangkapan Layar Ponsel (Phone Screenshots):**
  - Minimal 2 screenshot (disarankan 4–8 gambar berkualitas tinggi).
  - Format 16:9 atau 9:16 (misalnya 1080 x 2400 piksel).
  - Menampilkan antarmuka asli aplikasi: Beranda Narasi, Layar Baca Tenang, Editor Karya, dan Profil Sanctuary.

---

## 4. Fase Konfigurasi Konten & Kebijakan di Play Console (App Content)

### [ ] 4.1 Kredensial Akses Aplikasi untuk Tim Reviewer Google (App Access)
- **Kondisi:** Karena Writelle memiliki halaman login/pendaftaran, Tim Peninjau Google harus bisa masuk dan menguji seluruh fitur.
- **Tindakan di Play Console:**
  - Pilih **App Access** -> **All or some functionality is restricted**.
  - Masukkan petunjuk login dan sediakan akun demo khusus:
    - **Username/Email:** `reviewer@writelle.app`
    - **Password:** `TestReview123!`
    - **Instruksi Tambahan:** *"Akun demo untuk meninjau fitur membaca naskah, menulis karya, pelaporan konten (UGC reporting), pemblokiran pengguna (user blocking), dan penghapusan akun."*

### [ ] 4.2 Rating Konten (IARC Content Rating Questionnaire)
- Pilih kategori: **Social / Communication / Content Sharing**.
- **User-Generated Content (UGC):** Pilih **YA** (Pengguna dapat mempublikasikan cerita dan berkomentar).
- **Moderasi:** Nyatakan bahwa aplikasi menyediakan sistem pelaporan (*reporting*) dan pemblokiran pengguna (*user blocking*).
- **Bahasa Kasar / Seksualitas / Kekerasan:** Pilih **TIDAK** (Aplikasi menerapkan EULA tanpa toleransi terhadap konten terlarang).

### [ ] 4.3 Target Audiens & Konten Anak-Anak (Target Audience)
- Pilih rentang usia: **13-15 tahun, 16-17 tahun, dan 18 tahun ke atas**.
- **Apakah aplikasi dirancang untuk anak-anak?** Pilih **TIDAK (No)**.
- Hindari gambar promosi bergaya kartun balita agar tidak diklasifikasikan sebagai "App Designed for Children".

### [ ] 4.4 Pengisian Bagian Keamanan Data (Data Safety Section)
- Buka panduan di `PRIVACY_COMPLIANCE.md`.
- Deklarasikan pengumpulan:
  1. Alamat Email & User ID (untuk fungsi akun).
  2. Nama Pena (opsional untuk profil).
  3. Foto (opsional via Photo Picker untuk avatar).
  4. Konten Pengguna (teks cerita & komentar).
- Deklarasikan bahwa **semua data dienkripsi saat transit (TLS)**.
- Cantumkan tautan Web Account Deletion URL.

---

## 5. Fase Pengujian Tertutup (Closed Testing — Khusus Akun Pribadi)

> [!IMPORTANT]
> **Kebijakan Google Play 2023-2026 untuk Akun Developer Pribadi:**
> Jika akun Google Play Console Anda didaftarkan sebagai akun pribadi (Personal Developer Account) setelah 13 November 2023, Anda **diwajibkan** menjalankan uji coba tertutup (*Closed Testing*) dengan **minimal 20 penguji (testers)** yang memilih bergabung (*opt-in*) selama **minimal 14 hari berturut-turut** sebelum tombol pengajuan ke Jalur Produksi dapat diaktifkan.

### [ ] 5.1 Langkah Closed Testing:
1. Buat *Track Closed Testing* di Play Console.
2. Buat Google Group untuk para penguji (misalnya: `writelle-testers@googlegroups.com`).
3. Tambahkan 20+ alamat email penguji yang bersedia berpartisipasi aktif.
4. Rilis biner `.aab` ke trek Closed Testing.
5. Kirim tautan undangan uji coba (*join testing on Android / Web*) kepada seluruh penguji.
6. Pantau di dasbor Play Console hingga penghitung mencapai **14 hari aktif**.
7. Jawab kuesioner evaluasi uji coba di Google Play Console dengan jujur mengenai masukan penguji sebelum mengajukan produksi (*Apply for Production*).

---

## 6. Verifikasi Akhir Sebelum Tombol "Submit for Review" Ditekan

- [ ] Kode lulus `flutter analyze` dengan 0 peringatan/error.
- [ ] Kode lulus pengujian unit `flutter test`.
- [ ] Fitur lapor cerita (*Report Story*) berfungsi mulus di database Supabase.
- [ ] Fitur blokir penulis (*Block Author*) menyembunyikan cerita dari feed.
- [ ] Fitur hapus akun (*Delete Sanctuary Account*) berfungsi menghapus akun di Supabase.
- [ ] Tautan Kebijakan Privasi dan Ketentuan Layanan dapat dibuka langsung di aplikasi tanpa crash.
