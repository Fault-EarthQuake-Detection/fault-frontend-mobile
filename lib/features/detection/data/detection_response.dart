class DetectionResponse {
  final Map<String, dynamic> predictData;
  final Map<String, dynamic> locationData;

  DetectionResponse({required this.predictData, required this.locationData});

  // Helper untuk mengambil data visual (Overlay Image)
  String? get overlayBase64 => predictData['images_base64']?['overlay'];

  // Helper data visual
  String get visualStatus => predictData['fault_analysis']?['status_level'] ?? "Tidak Diketahui";
  String get visualDescription => predictData['fault_analysis']?['deskripsi_singkat'] ?? "-";
  String get statement => predictData['statement'] ?? "";

  // Helper data lokasi
  String get locationStatus => locationData['status'] ?? "Tidak Diketahui";
  String get faultName => locationData['nama_patahan'] ?? "-";
  String get distanceKm => locationData['jarak_km']?.toString() ?? "-";

  // Logika gabungan untuk menentukan status bahaya (Sesuai logika web temanmu)
  bool get isDanger {
    final v = visualStatus.toUpperCase();
    final l = locationStatus.toUpperCase();
    return (v.contains("PERINGATAN") || v.contains("BAHAYA")) &&
        (l.contains("ZONA PERINGATAN") || l.contains("BAHAYA"));
  }

  bool get isWarning {
    final v = visualStatus.toUpperCase();
    final l = locationStatus.toUpperCase();
    return (v.contains("PERINGATAN") || v.contains("BAHAYA")) ||
        (l.contains("ZONA PERINGATAN") || l.contains("BAHAYA"));
  }
}