# PANDUAN PENEGAKAN KEBIJAKAN & BANDING GOOGLE PLAY
**(GOOGLE PLAY ENFORCEMENT & APPEALS PLAYBOOK)**

**Aplikasi:** Writelle  
**Target:** Google Play Developer Console  
**Versi:** 1.0.0  
**Tanggal:** 7 November 2026  

---

## 1. Memahami Spektrum Tindakan Penegakan Google Play (Enforcement Actions)

Sangat penting bagi pengembang untuk membedakan antara penolakan rilis, pencopotan aplikasi, penangguhan, dan pemutusan akun, agar tidak panik dan dapat merespons dengan strategi yang tepat sesuai dokumentasi resmi Google Play:

```
[ Rejection (Penolakan Rilis) ]
      ↓  (Lebih berat jika terjadi pada versi live)
[ Removal (Pencopotan Aplikasi Live) ]
      ↓  (Pelanggaran serius berulang / kegagalan perbaikan)
[ Suspension (Penangguhan Aplikasi & Strike) ]
      ↓  (Akumulasi Strike / Pelanggaran Berat / Akun Terkait)
[ Account Termination (Pemutusan Akun Permanen) ]
```

### A. Penolakan Rilis (*Rejection*)
- **Definisi:** Update atau pengajuan aplikasi baru yang Anda kirimkan tidak disetujui selama proses *review*. Versi aplikasi yang sebelumnya sudah aktif di Play Store (jika ada) tetap berjalan normal.
- **Dampak Akun:** **TIDAK MENGHASILKAN STRIKE**. Penolakan rilis adalah proses peninjauan standar.
- **Tindakan yang Diperlukan:** Cukup perbaiki poin masalah yang disebutkan dalam email penolakan, lalu unggah bundle baru atau perbarui metadata di Play Console.

### B. Pencopotan Aplikasi (*Removal*)
- **Definisi:** Aplikasi yang sudah tayang (*live*) di Google Play dicopot dari peredaran karena terdeteksi melanggar kebijakan terbaru atau ada laporan yang terbukti.
- **Dampak Akun:** Biasanya **bukan strike langsung**, selama Anda memperbaiki dan mengajukan versi pembaruan (*compliant update*) yang memenuhi syarat. Pengguna yang sudah menginstal masih dapat menggunakannya, tetapi pengguna baru tidak dapat menemukannya di Play Store.
- **Tindakan yang Diperlukan:** Analisis email pemberitahuan, perbaiki kode sumber atau metadata, naikkan versi (*versionCode*), dan ajukan pembaruan untuk ditinjau ulang.

### C. Penangguhan Aplikasi (*Suspension*)
- **Definisi:** Tindakan penegakan tegas di mana aplikasi dicopot secara permanen dari Google Play. Nama paket (*package name*) tersebut tidak akan pernah bisa digunakan kembali di Google Play.
- **Dampak Akun:** **Dihitung sebagai 1 POLICY STRIKE** terhadap akun Google Play Developer Anda. Akumulasi beberapa strike akan memicu penutupan akun pengembang.
- **Penyebab Umum:** Pelanggaran berat berulang, mengabaikan peringatan pencopotan sebelumnya, atau pelanggaran konten terlarang (seperti pornografi, ujaran kebencian, malware, atau penipuan hak cipta).
- **Tindakan yang Diperlukan:** Tidak bisa diselesaikan hanya dengan mengunggah update biner biasa. Satu-satunya jalan keluar adalah mengajukan **Banding Resmi (*Formal Appeal*)** jika Anda meyakini adanya kekeliruan keputusan dari peninjau Google.

### D. Pemutusan Akun Pengembang (*Developer Account Termination*)
- **Definisi:** Akun Google Play Developer Anda ditutup secara permanen. Seluruh aplikasi di dalam akun akan dicopot, dan pengembang dilarang membuka akun baru di ekosistem Google Play.
- **Penyebab:**
  1. Akumulasi strike pelanggaran kebijakan (*repeated policy violations*).
  2. Pelanggaran berat yang fatal (*egregious violation*), seperti distribusi malware, ransomware, phishing, manipulasi sistem pembayaran, atau impersonasi bank/lembaga keuangan.
  3. **Akun Terkait (*Associated Developer Accounts*):** Google mendeteksi adanya keterkaitan erat antara akun Anda dengan akun pengembang lain yang sebelumnya pernah dihentikan/dibanned.

---

## 2. Kebijakan Akun Terkait (Associated Accounts Policy)

Referensi Resmi: [Google Play Support - Associated Accounts](https://support.google.com/googleplay/android-developer/answer/9899234)

Google menggunakan sistem algoritma canggih dan verifikasi manusia untuk mengidentifikasi jaringan akun pengembang. Jika sebuah akun dihentikan, Google akan melacak akun-akun lain yang terafiliasi untuk mencegah penghindaran sanksi (*circumvention*).

### Indikator Keterkaitan yang Perlu Diperhatikan:
1. **Identitas Finansial:** Kartu kredit, rekening bank pembayaran, atau identitas verifikasi pajak (DUNS / KTP / Paspor) yang sama.
2. **Kredensial Perangkat & Jaringan:** Login ke Play Console menggunakan browser, profil Chrome, atau IP VPN yang sebelumnya pernah digunakan untuk mengelola akun yang ditutup.
3. **Sertifikat Penandatanganan (Keystore):** Menggunakan kunci rilis (`upload-keystore.jks`) yang sama dengan aplikasi dari akun bermasalah.
4. **Basis Kode Sumber (Codebase Rehash):** Mengunggah template aplikasi (*reskin*) berkualitas rendah yang identik dengan aplikasi terblokir tanpa diferensiasi fungsional.

> [!CAUTION]
> **Prinsip Integritas:** Jangan pernah mencoba mengakali sistem deteksi Google dengan data palsu atau identitas pinjaman. Writelle menggunakan arsitektur orisinal, repositori bersih, dan kode independen, sehingga aman dari risiko keterkaitan kode daur ulang.

---

## 3. Protokol Investigasi Ketika Menerima Email Pelanggaran

Jika Anda menerima email notifikasi penolakan atau pelanggaran dari Google Play:

### Langkah 1: Jangan Panik & Jangan Langsung Klik Banding
Pengajuan banding yang terburu-buru tanpa data konkret sering kali langsung ditolak oleh sistem otomatis. Luangkan waktu untuk mengkaji masalah.

### Langkah 2: Analisis Anatomi Email Pemberitahuan
Buka email dari `googleplay-developer-support@google.com` dan catat:
1. **Kebijakan Spesifik yang Dilanggar** (misalnya: *User Data Policy: Account Deletion*, atau *Broken Functionality*).
2. **Versi yang Terdampak** (apakah trek Production, Open Testing, Closed Testing, atau Internal Testing).
3. **Lampiran Tangkapan Layar (Screenshot):** Reviewer Google hampir selalu melampirkan screenshot atau video pendek yang menunjukkan di layar mana aplikasi mengalami penolakan/crash.

### Langkah 3: Reproduksi Masalah Secara Lokal
Uji skenario yang ditampilkan reviewer Google menggunakan perangkat fisik atau emulator Android dengan versi OS terbaru (Android 14 / 15).

### Langkah 4: Tentukan Jalur Penyelesaian: Update vs Banding
- **Pilih JALUR UPDATE jika:** Masalah memang ada pada aplikasi Anda (misalnya ada bug pada halaman registrasi, link privasi belum terisi di Console, atau lupa menyertakan kredensial login akun demo). Selesaikan di kode, lalu upload versi baru.
- **Pilih JALUR BANDING jika:** Terjadi *false positive* (kesalahan deteksi bot Google atau reviewer manusia salah memahami kategori aplikasi Anda, sementara aplikasi Anda sebenarnya sudah 100% mematuhi aturan).

---

## 4. Panduan & Template Pengajuan Banding Resmi (Appeals Playbook)

Jika Anda yakin penolakan atau penangguhan tersebut merupakan kekeliruan penafsiran (*error in enforcement*), ajukan banding resmi melalui formulir:  
👉 [Formulir Banding Resmi Google Play](https://support.google.com/googleplay/android-developer/contact/appappeals)

### Prinsip Menulis Surat Banding yang Efektif:
1. **Gunakan Bahasa Inggris yang Formal, Santun, dan Objektif:** Hindari nada emosional, menyalahkan reviewer, atau memohon belas kasihan.
2. **Kutip Klausul Kebijakan Resmi:** Buktikan bahwa Anda memahami kebijakan terkait.
3. **Sediakan Bukti Nyata (*Reproducible Evidence*):** Sertakan tautan video demonstrasi (YouTube Unlisted / Google Drive terbuka) yang memperlihatkan alur fitur dengan jelas.
4. **Sediakan Akun Demo Aktif:** Berikan kembali kredensial pengujian yang valid.

---

### Template Surat Banding (Contoh Kasus: UGC & Account Deletion)

```text
Subject: Appeal for Application Status - Writelle (Package ID: com.writelle.sanctuary)

Dear Google Play Policy Review Team,

Thank you for your review and guidance regarding our application, Writelle (Package: com.writelle.sanctuary). 

We received a notification regarding [Sebutkan Kebijakan, contoh: User Generated Content (UGC) Policy / Account Deletion Requirement]. We respectfully submit this appeal as we believe our application fully complies with the specified policy, and there may have been a misunderstanding during the review session.

1. Clarification & Compliance Evidence:
- Regarding UGC Moderation & Blocking:
  Our application enforces a strict Zero-Tolerance EULA against objectionable content (available at lib/screens/legal/terms_of_service_screen.dart). Users have an immediate in-app mechanism to report objectionable stories via the "Report Story" dialog, which flags content for curator review. Furthermore, users can block abusive authors directly from any author's profile page (via the 3-dots action menu -> "Block Author"), which instantly filters out all content from that author in real-time.

- Regarding Account Deletion:
  Writelle provides both:
  a) Direct In-App Deletion: Users can permanently delete their account and associated data by going to Sanctuary Profile -> Settings -> "Delete Sanctuary Account" (verified via our automated tests).
  b) Public Web Deletion Portal: We maintain a publicly accessible, zero-login web deletion portal located at https://writelle.pages.dev/account_deletion.html, fulfilling Google Play's 2024 User Data requirement.

2. Demonstration Video:
To assist the review team in verifying this implementation, we have recorded a detailed walkthrough demonstrating both features:
Video URL: [MASUKKAN_LINK_YOUTUBE_UNLISTED_ANDA]

3. Testing Credentials for Reviewer:
- Email: reviewer@writelle.app
- Password: TestReview123!

We kindly ask the team to re-evaluate our application. We are committed to maintaining a safe, contemplative, and fully policy-compliant sanctuary for our readers and writers.

Thank you very much for your time, patience, and assistance.

Sincerely,
Writelle Development Team
Email: privacy@writelle.app / developer@writelle.app
```

---

## 5. Saluran Eskalasi Tambahan

Jika banding pertama Anda ditolak oleh respon otomatis tanpa penjelasan detail:
1. **Google Play Developer Community Forum:**  
   Buka diskusi di [Google Play Developer Community](https://support.google.com/googleplay/android-developer/community) dengan menjelaskan nomor kasus (*Case ID*) Anda. Product Experts (PE) sering kali dapat mengeskalasikan kasus valid ke tim internal.
2. **Obrolan Langsung / Live Chat Dukungan Konsol:**  
   Pada jam kerja tertentu, pemilik akun Google Play Developer yang terverifikasi dapat mengakses tombol obrolan langsung (*live chat support*) di bagian pojok kanan atas Google Play Console untuk menanyakan rincian penolakan.
