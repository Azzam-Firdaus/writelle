# DOKUMEN KEPATUHAN PRIVASI & DATA SAFETY (PRIVACY COMPLIANCE GUIDE)
**Aplikasi:** Writelle  
**Target Platform:** Google Play Store (Android)  
**Versi Dokumen:** 1.0.0  
**Tanggal:** 7 November 2026  

---

## 1. Panduan Pengisian Kuisioner Pembuat Kebijakan (Berdasarkan Screenshot Pengguna)

### A. Kuisioner 1: Tracking Technologies
> *Pertanyaan:* **Tracking Technologies: Which of the following does your website/app use or plan to use?**

| Pilihan | Jawaban Rekomendasi | Alasan Teknis Berdasarkan Kode Sumber Writelle |
| :--- | :---: | :--- |
| **Google Maps APIs** | **TIDAK DICENTANG (Unchecked)** | Writelle adalah aplikasi membaca & menulis narasi/sastra kontemplatif. Tidak ada dependensi atau pemanggilan Google Maps SDK maupun koordinat lokasi. |
| **Cookies and/or web beacons** | **TIDAK DICENTANG (Unchecked)** *(atau dicentang hanya jika situs web promosi menggunakan cookie analitik)* | Aplikasi mobile Flutter Writelle tidak menyematkan web beacons pelacak ataupun iklan cookies pihak ketiga. |
| **Local Storage** | **DICENTANG (Checked) [x]** | **Wajib Dicentang.** Writelle menggunakan `SharedPreferences` (penyimpanan lokal perangkat) untuk menyimpan preferensi pengguna (tema, ukuran font baca) dan daftar penulis yang diblokir (*Blocked Authors*). |
| **Sessions** | **DICENTANG (Checked) [x]** | **Wajib Dicentang.** Writelle menggunakan sesi terenkripsi melalui Supabase Auth (*JWT access token & refresh token*) untuk menjaga status login akun pengguna. |

---

### B. Kuisioner 2: Standar Kepatuhan Hukum Internasional
> *Pertanyaan:* **Do you want your privacy policy to be CalOPPA compliant?**  
> *Pilihan:* `(x) Yes, adapt my Privacy Policy to be compliant with CalOPPA`  
> **Rekomendasi:** **PILIH YES.** Google Play Store mendistribusikan aplikasi secara global termasuk pengguna di California, AS. CalOPPA mewajibkan pencantuman Kebijakan Privasi yang mudah diakses dan klausul hak pengguna.

> *Pertanyaan:* **Do you want your privacy policy to be GDPR compliant?**  
> *Pilihan:* `(x) Yes, adapt my Privacy Policy to be compliant with GDPR`  
> **Rekomendasi:** **PILIH YES.** Sangat krusial jika aplikasi Anda dapat diunduh oleh pengguna di Uni Eropa (EEA/UK). Mengatur hak akses, perbaikan, penghapusan akun (*right to be forgotten*), dan dasar hukum pemrosesan data.

> *Pertanyaan:* **Do you want your privacy policy to be CCPA compliant?**  
> *Pilihan:* `(x) Yes, adapt my Privacy Policy to be compliant with CCPA`  
> **Rekomendasi:** **PILIH YES.** Menegaskan bahwa Writelle tidak pernah menjual (*Do Not Sell My Personal Information*) data pribadi pengguna ke pihak ketiga atau broker iklan.

---

## 2. Panduan Pengisian Data Safety Section di Google Play Console

Saat mengisi formulir **Data Safety** (*Keamanan Data*) di Google Play Console, gunakan panduan berikut yang telah diselaraskan dengan arsitektur kode Writelle:

### Ringkasan Pertanyaan Tingkat Atas:
1. **Apakah aplikasi Anda mengumpulkan atau membagikan salah satu jenis data pengguna yang ditentukan?**
   - **Jawaban:** **YA (Yes)**.
2. **Apakah semua data pengguna yang dikumpulkan oleh aplikasi Anda dienkripsi saat transit?**
   - **Jawaban:** **YA (Yes)**. Semua komunikasi ke Supabase menggunakan protokol HTTPS/TLS 1.2+.
3. **Apakah Anda menyediakan cara bagi pengguna untuk meminta penghapusan data mereka?**
   - **Jawaban:** **YA (Yes)**.
   - Cantumkan URL Penghapusan Akun Publik: `https://writelle.pages.dev/account_deletion.html` (atau URL hosting dari berkas `docs/account_deletion.html`).

---

### Rincian Kategori Data yang Dikumpulkan (Data Collection Breakdown)

#### 1. Info Pribadi (Personal Info)
- **Alamat Email:**
  - *Dikumpulkan:* **Ya**
  - *Dibagikan:* **Tidak**
  - *Pemrosesan secara singkat (ephemeral):* **Tidak** (disimpan di database Supabase Auth)
  - *Diperlukan atau Opsional:* **Diperlukan** (untuk autentikasi dan pembuatan akun)
  - *Tujuan:* **Fungsionalitas aplikasi (App functionality), Manajemen Akun (Account management)**.
- **Nama / Nama Pena (Name):**
  - *Dikumpulkan:* **Ya**
  - *Dibagikan:* **Tidak**
  - *Diperlukan atau Opsional:* **Opsional / Pengguna dapat memilih nama pena**
  - *Tujuan:* **Fungsionalitas aplikasi, Personalisasi**.
- **Identifikasi Pengguna (User IDs):**
  - *Dikumpulkan:* **Ya** (Supabase UUID pengguna)
  - *Dibagikan:* **Tidak**
  - *Tujuan:* **Fungsionalitas aplikasi, Manajemen Akun**.

#### 2. Foto dan Video (Photos and Videos)
- **Foto (Photos):**
  - *Dikumpulkan:* **Ya** (opsional saat pengguna mengunggah foto profil atau sampul cerita)
  - *Dibagikan:* **Tidak**
  - *Diperlukan atau Opsional:* **Opsional** (pengguna dapat menggunakan avatar default tanpa mengunggah foto)
  - *Tujuan:* **Fungsionalitas aplikasi**.

#### 3. Tindakan Pengguna dalam Aplikasi (App Activity)
- **Konten Buatan Pengguna (User Generated Content):**
  - *Interaksi Aplikasi:* Karya sastra, cerita, komentar, daftar following, daftar readers.
  - *Dikumpulkan:* **Ya**
  - *Dibagikan:* **Tidak** (Hanya ditampilkan secara publik di dalam aplikasi sesuai kehendak pengguna)
  - *Tujuan:* **Fungsionalitas aplikasi**.

#### 4. Kategori yang **TIDAK** Dikumpulkan (Pilih "Tidak" untuk Semua Kategori Berikut):
- Lokasi (Location) -> **TIDAK**
- Info Keuangan (Financial info) -> **TIDAK**
- Kesehatan & Kebugaran (Health & Fitness) -> **TIDAK**
- Pesan Pribadi SMS / MMS -> **TIDAK**
- File Audio / Rekaman Suara -> **TIDAK**
- Kalender & Kontak -> **TIDAK**
- Perangkat atau Pengidentifikasi Lain (Device or other IDs) untuk Iklan -> **TIDAK**

---

## 3. Inventaris Izin Perangkat (Android Permissions Inventory)

| Izin | Deklarasi di AndroidManifest.xml | Alasan & Status Kepatuhan |
| :--- | :--- | :--- |
| `android.permission.INTERNET` | Ya | Wajib untuk komunikasi jaringan REST API / Realtime ke Supabase backend. Termasuk izin normal, tidak memerlukan izin runtime khusus. |
| `android.permission.READ_EXTERNAL_STORAGE` | Ya (`android:maxSdkVersion="32"`) | Dipertahankan hanya untuk perangkat lawas Android 12 ke bawah (API <= 32). Menggunakan batasan `maxSdkVersion` resmi Google sehingga tidak memicu pelanggaran di Android 13+. |
| `android.permission.READ_MEDIA_IMAGES` | **DIHAPUS (Removed)** | Sesuai kebijakan Google Play *Photo and Video Permissions Policy* (2024–2026), aplikasi yang hanya mengunggah foto profil/sampul tidak boleh meminta izin broad storage ini. Aplikasi dialihkan menggunakan sistem **Android Photo Picker** bawaan OS. |

---

## 4. Audit Pustaka Pihak Ketiga (Third-Party SDK Audit)

| SDK / Package | Versi di pubspec | Tujuan Penggunaan | Status Privasi & Keamanan |
| :--- | :--- | :--- | :--- |
| `supabase_flutter` | ^2.8.0 | Backend-as-a-Service: Autentikasi, Database PostgreSQL, Penyimpanan Objek. | Aman. Komunikasi TLS 1.3, autentikasi berbasis JWT token, dilindungi RLS database. |
| `flutter_riverpod` | ^2.6.1 | Manajemen status aplikasi (*State Management*). | Murni kode Dart lokal, tidak mengumpulkan data apa pun. |
| `shared_preferences`| ^2.5.2 | Penyimpanan preferensi lokal di perangkat (cache tema, daftar blokir). | Aman. Tersimpan di private sandbox internal storage Android. |
| `image_picker` | ^1.1.2 | Memilih gambar foto profil dari galeri. | Aman. Terintegrasi dengan native Android Photo Picker (tanpa izin penyimpanan luas). |
| `google_fonts` | ^6.2.1 | Tipografi estetika sastra (Cinzel, EB Garamond, Cormorant Garamond). | Font aset di-cache secara aman. |

---

## 5. Mekanisme & Verifikasi Penghapusan Akun (Account Deletion Verification)

Untuk memenuhi persyaratan **Google Play User Data Policy**:
1. **Verifikasi Jalur Dalam Aplikasi (In-App):**
   - Masuk ke aplikasi Writelle -> Navigasi ke `ProfileScreen` -> Buka menu opsi / tombol bawah -> Temukan opsi **"Delete Sanctuary Account"**.
   - Sistem akan memicu fungsi `deleteAccount()` pada `AuthRepository`, yang memanggil PostgreSQL RPC `public.delete_user_account()`.
   - Data profil, cerita, komentar, suka, dan status follow akan dihapus secara *cascading*, dan sesi autentikasi ditutup.
2. **Verifikasi Jalur Web Publik (Public Web URL):**
   - File statis mandiri telah dibuat di `docs/account_deletion.html`.
   - Siap di-hosting pada penyedia web statis gratis seperti GitHub Pages, Cloudflare Pages, atau Firebase Hosting.
   - Menyediakan formulir transparan bagi pengguna yang ingin menghapus seluruh jejak data akun tanpa perlu menginstal kembali aplikasi.
