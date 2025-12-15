class DetectionModel {
  final int id;
  final double lat;
  final double lng;
  final String imageUrl;
  final String result;
  final String userId;
  final DateTime createdAt;
  // final Map<String, dynamic> description; // Optional kalau backend kirim

  DetectionModel({
    required this.id,
    required this.lat,
    required this.lng,
    required this.imageUrl,
    required this.result,
    required this.userId,
    required this.createdAt,
  });

  factory DetectionModel.fromJson(Map<String, dynamic> json) {
    return DetectionModel(
      id: json['id'],
      // Prisma: latitude (double)
      lat: (json['latitude'] as num).toDouble(),
      lng: (json['longitude'] as num).toDouble(),

      // Prisma: originalImageUrl
      imageUrl: json['originalImageUrl'] ?? json['image_url'] ?? "",

      // Prisma: faultType atau statusLevel
      // Backend temanmu pakai 'faultType' untuk menyimpan hasil 'detectionResult'
      result: json['faultType'] ?? json['statusLevel'] ?? "Tidak Diketahui",

      userId: json['userId'] ?? "",

      // Prisma: createdAt
      createdAt: DateTime.parse(json['createdAt'] ?? json['created_at']),
    );
  }
}