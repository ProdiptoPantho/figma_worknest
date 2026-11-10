import 'dart:typed_data';

class AttachedDocument {
  const AttachedDocument({
    required this.name,
    required this.sizeDisplay,
    this.bytes,
    this.mimeType,
    this.uploadedAt,
  });

  final String name;
  final String sizeDisplay;
  final Uint8List? bytes;
  final String? mimeType;
  final DateTime? uploadedAt;

  bool get isImage {
    final lower = name.toLowerCase();
    final mime = mimeType?.toLowerCase() ?? '';
    return lower.endsWith('.png') ||
        lower.endsWith('.jpg') ||
        lower.endsWith('.jpeg') ||
        lower.endsWith('.webp') ||
        lower.endsWith('.gif') ||
        mime.startsWith('image/');
  }

  bool get isPdf =>
      name.toLowerCase().endsWith('.pdf') ||
      (mimeType?.toLowerCase().contains('pdf') ?? false);
}

class DocumentRegistry {
  static final Map<String, AttachedDocument> _store = {};

  static void register(String key, AttachedDocument doc) {
    if (key.trim().isEmpty) return;
    _store[key.trim().toLowerCase()] = doc;
  }

  static AttachedDocument? get(String key) {
    if (key.trim().isEmpty) return null;
    return _store[key.trim().toLowerCase()];
  }

  static AttachedDocument? findForLeave({
    String? requestId,
    String? filename,
    String? userEmail,
  }) {
    if (requestId != null && requestId.trim().isNotEmpty) {
      final reqKey = requestId.trim().toLowerCase();
      if (_store.containsKey(reqKey)) return _store[reqKey];
    }
    if (filename != null && filename.trim().isNotEmpty) {
      final fnKey = filename.trim().toLowerCase();
      if (_store.containsKey(fnKey)) return _store[fnKey];
    }
    if (userEmail != null && userEmail.trim().isNotEmpty) {
      final emKey = userEmail.trim().toLowerCase();
      if (_store.containsKey(emKey)) return _store[emKey];
    }
    return null;
  }
}
