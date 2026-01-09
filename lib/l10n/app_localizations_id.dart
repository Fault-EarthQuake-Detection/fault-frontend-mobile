// ignore: unused_import
import 'package:intl/intl.dart' as intl;
import 'app_localizations.dart';

// ignore_for_file: type=lint

/// The translations for Indonesian (`id`).
class AppLocalizationsId extends AppLocalizations {
  AppLocalizationsId([String locale = 'id']) : super(locale);

  @override
  String get settingsTitle => 'Pengaturan';

  @override
  String get themeTitle => 'Mode Gelap';

  @override
  String get themeSubtitle => 'Aktifkan tampilan gelap';

  @override
  String get langTitle => 'Bahasa';

  @override
  String get langSubtitle => 'Pilih bahasa aplikasi';

  @override
  String get profileTitle => 'Profil Pengguna';

  @override
  String get editProfile => 'Edit Profil';

  @override
  String get sendFeedback => 'Kirim Masukan';

  @override
  String get aboutApp => 'Tentang Aplikasi';

  @override
  String get logout => 'Keluar';

  @override
  String get logoutConfirmTitle => 'Konfirmasi Keluar';

  @override
  String get logoutConfirmMsg => 'Apakah Anda yakin ingin keluar?';

  @override
  String get cancel => 'Batal';

  @override
  String get yesLogout => 'Ya, Keluar';

  @override
  String get login => 'Masuk';

  @override
  String get register => 'Daftar';

  @override
  String get username => 'Nama Pengguna';

  @override
  String get email => 'Email';

  @override
  String get password => 'Kata Sandi';

  @override
  String get confirmPassword => 'Ulangi Kata Sandi';

  @override
  String get forgotPassword => 'Lupa Kata Sandi?';

  @override
  String get noAccount => 'Belum punya akun?';

  @override
  String get haveAccount => 'Sudah punya akun?';

  @override
  String get orLoginWith => 'Atau masuk dengan';

  @override
  String get fieldRequired => 'Tidak boleh kosong';

  @override
  String get invalidEmail => 'Format email salah';

  @override
  String get passwordLength => 'Minimal 8 karakter';

  @override
  String get passwordMismatch => 'Kata sandi tidak cocok';

  @override
  String get appTagline =>
      'Aplikasi Edukasi Geologi\nInteraktif & Validasi Jalur Sesar';

  @override
  String get welcomeTitle => 'GeoValid';

  @override
  String get changePhoto => 'Ketuk ikon kamera untuk ubah foto';

  @override
  String get saveChanges => 'Simpan Perubahan';

  @override
  String get writeFeedback => 'Tulis saran atau keluhan...';

  @override
  String get oldPassword => 'Kata Sandi Lama';

  @override
  String get newPassword => 'Kata Sandi Baru';

  @override
  String get repeatPassword => 'Ulangi Kata Sandi';

  @override
  String get feedbackSent => 'Masukan terkirim!';

  @override
  String get feedbackDesc =>
      'Kami menghargai masukan Anda untuk pengembangan aplikasi ini.';

  @override
  String get aboutDesc =>
      'GeoValid adalah aplikasi edukasi dan validasi geologi interaktif yang membantu pengguna mengidentifikasi jalur sesar menggunakan teknologi AI.';

  @override
  String get latestInfo => 'Informasi Terkini';

  @override
  String get citizenReport => 'Laporan Warga';

  @override
  String get bmkgOfficial => 'BMKG Resmi';

  @override
  String get you => 'Anda';

  @override
  String get magnitude => 'Magnitudo';

  @override
  String get depth => 'Kedalaman';

  @override
  String get potential => 'Potensi';

  @override
  String get time => 'Waktu';

  @override
  String get date => 'Tanggal';

  @override
  String get coordinates => 'Koordinat';

  @override
  String get felt => 'Dirasakan (MMI)';

  @override
  String get analysisDetail => 'Detail Analisis';

  @override
  String get viewOnMap => 'Lihat di Peta';

  @override
  String get bmkgDisclaimer =>
      'Data bersumber resmi dari BMKG (Badan Meteorologi, Klimatologi, dan Geofisika).';

  @override
  String get tsunamiAlert => 'BERPOTENSI TSUNAMI';

  @override
  String get safe => 'Aman';

  @override
  String get faultPattern => 'Pola Sesar';

  @override
  String get aiAnalysis => 'Analisis AI';

  @override
  String earthquakeInfo(String magnitude, String region) {
    return 'Gempa Mag $magnitude di $region';
  }

  @override
  String get detectionTitle => 'Laporan Deteksi';

  @override
  String get detectionSource => 'Pengguna GeoValid';

  @override
  String get faultType => 'Jenis Sesar';

  @override
  String get analysisResult => 'Hasil Analisis';

  @override
  String get finalStatus => 'Status Akhir';

  @override
  String get visualAnalysis => 'Analisis Visual (AI)';

  @override
  String get geoAnalysis => 'Analisis Geospasial';

  @override
  String get zone => 'Zona';

  @override
  String get nearestFault => 'Sesar Terdekat';

  @override
  String get distance => 'Jarak';

  @override
  String get doneReturn => 'Selesai & Kembali';

  @override
  String get showingArchive => 'Menampilkan arsip riwayat deteksi.';

  @override
  String get dataSaved => 'Data hasil analisis telah tersimpan otomatis.';

  @override
  String get noDescription => 'Tidak ada deskripsi.';

  @override
  String get unidentified => 'Tidak Teridentifikasi';

  @override
  String get selectLocation => 'Pilih Lokasi';

  @override
  String get searchLocation => 'Cari lokasi...';

  @override
  String get useThisLocation => 'Gunakan Lokasi Ini';

  @override
  String get searchingGPS => 'Mencari lokasi GPS...';

  @override
  String get cameraPermission => 'Izin Kamera Diperlukan';

  @override
  String get openSettings => 'Buka Pengaturan';

  @override
  String get retakePhoto => 'Foto Ulang';

  @override
  String get noImage => 'Gambar hilang. Silakan foto ulang.';

  @override
  String get analyzing => 'Menganalisis...';

  @override
  String get uploadFailed => 'Gagal mengunggah';

  @override
  String get dragMap => 'Geser peta untuk menyesuaikan lokasi';

  @override
  String get mapDistribution => 'Peta Persebaran';

  @override
  String get searchPlace => 'Cari tempat...';

  @override
  String get verified => 'Terverifikasi';

  @override
  String get detectionDetail => 'Detail Deteksi';

  @override
  String get status => 'Status:';

  @override
  String get type => 'Jenis:';

  @override
  String get validatedAt => 'Divalidasi:';

  @override
  String get menu => 'Menu';

  @override
  String get searchHistory => 'Cari riwayat saya...';

  @override
  String get myDetectionHistory => 'RIWAYAT DETEKSI SAYA';

  @override
  String get notFound => 'Tidak ditemukan';

  @override
  String get unknown => 'Tidak diketahui';

  @override
  String get navHome => 'Beranda';

  @override
  String get navDetection => 'Deteksi';

  @override
  String get navMap => 'Peta';

  @override
  String get navProfile => 'Profil';

  @override
  String get imageNotAvailable => 'Gambar tidak tersedia';
}
