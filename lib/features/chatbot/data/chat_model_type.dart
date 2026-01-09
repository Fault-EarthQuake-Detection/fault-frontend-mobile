enum ChatModelType {
  rag,        // Model yang baca dokumen (RAG)
  generative  // Model yang generate text biasa
}

// Extension untuk mendapatkan nama label yang rapi
extension ChatModelTypeExtension on ChatModelType {
  String get label {
    switch (this) {
      case ChatModelType.rag:
        return 'GeoValid RAG (Akurat)';
      case ChatModelType.generative:
        return 'GeoValid Gen (Cepat)';
    }
  }

  String get id {
    switch (this) {
      case ChatModelType.rag:
        return 'RAG';
      case ChatModelType.generative:
        return 'Generative';
    }
  }
}