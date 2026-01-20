import 'dart:math';

class StringSimilarity {
  /// Menghitung kemiripan antara dua string (0.0 - 1.0)
  /// Menggunakan algoritma sederhana "Sorensen-Dice" untuk performa cepat di HP.
  static double calculateSimilarity(String s1, String s2) {
    // 1. Normalisasi (lowercase & trim)
    s1 = s1.toLowerCase().trim();
    s2 = s2.toLowerCase().trim();

    if (s1 == s2) return 1.0; // Persis sama
    if (s1.isEmpty || s2.isEmpty) return 0.0;

    // 2. Buat bigram (pasangan 2 huruf)
    Set<String> s1Bigrams = _getBigrams(s1);
    Set<String> s2Bigrams = _getBigrams(s2);

    // 3. Hitung intersection
    int intersection = 0;
    for (String item in s1Bigrams) {
      if (s2Bigrams.contains(item)) {
        intersection++;
      }
    }

    // 4. Rumus Sorensen-Dice: (2 * intersection) / (total elements)
    return (2.0 * intersection) / (s1Bigrams.length + s2Bigrams.length);
  }

  static Set<String> _getBigrams(String input) {
    Set<String> bigrams = {};
    for (int i = 0; i < input.length - 1; i++) {
      bigrams.add(input.substring(i, i + 2));
    }
    return bigrams;
  }
}