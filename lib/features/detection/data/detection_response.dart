class DetectionResponse {
  final Map<String, dynamic> predictData;
  final Map<String, dynamic> locationData;

  DetectionResponse({required this.predictData, required this.locationData});

  String? get overlayBase64 => predictData['images_base64']?['overlay'];

  String get visualStatus => predictData['fault_analysis']?['status_level'] ?? "Tidak Diketahui";
  String get visualDescription => predictData['fault_analysis']?['deskripsi_singkat'] ?? "-";
  String get statement => predictData['statement'] ?? "";

  String get locationStatus => locationData['status'] ?? "Tidak Diketahui";
  String get faultName => locationData['nama_patahan'] ?? "-";
  String get distanceKm => locationData['jarak_km']?.toString() ?? "-";

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