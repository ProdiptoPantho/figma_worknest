// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:async';
import 'dart:html' as html;
import 'dart:typed_data';
import 'document_model.dart';

Future<AttachedDocument?> pickDocumentFile() async {
  final uploadInput = html.FileUploadInputElement()
    ..accept = '.pdf,.doc,.docx,.png,.jpg,.jpeg,.webp';
  uploadInput.click();

  await uploadInput.onChange.first;
  final files = uploadInput.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;
  final sizeKb = (file.size / 1024).round();
  final sizeStr = sizeKb >= 1024
      ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
      : '$sizeKb KB';

  final completer = Completer<Uint8List?>();
  final reader = html.FileReader();
  reader.onLoadEnd.listen((_) {
    final res = reader.result;
    if (res is Uint8List) {
      completer.complete(res);
    } else if (res is ByteBuffer) {
      completer.complete(res.asUint8List());
    } else if (res is List<int>) {
      completer.complete(Uint8List.fromList(res));
    } else {
      completer.complete(null);
    }
  });
  reader.onError.listen((_) => completer.complete(null));
  reader.readAsArrayBuffer(file);

  final bytes = await completer.future;

  return AttachedDocument(
    name: file.name,
    sizeDisplay: sizeStr,
    bytes: bytes,
    mimeType: file.type.isNotEmpty ? file.type : null,
    uploadedAt: DateTime.now(),
  );
}

void downloadDocumentFile({required String name, Uint8List? bytes, String? mimeType}) {
  if (bytes == null || bytes.isEmpty) return;
  final blob = html.Blob([bytes], mimeType ?? 'application/octet-stream');
  final url = html.Url.createObjectUrlFromBlob(blob);
  html.AnchorElement(href: url)
    ..setAttribute('download', name)
    ..click();
  html.Url.revokeObjectUrl(url);
}
