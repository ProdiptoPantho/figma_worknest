// ignore_for_file: deprecated_member_use, avoid_web_libraries_in_flutter
import 'dart:html' as html;
import 'document_model.dart';

Future<AttachedDocument?> pickDocumentFile() async {
  final uploadInput = html.FileUploadInputElement()
    ..accept = '.pdf,.doc,.docx,.png,.jpg,.jpeg';
  uploadInput.click();

  await uploadInput.onChange.first;
  final files = uploadInput.files;
  if (files == null || files.isEmpty) return null;
  final file = files.first;
  final sizeKb = (file.size / 1024).round();
  final sizeStr = sizeKb >= 1024
      ? '${(sizeKb / 1024).toStringAsFixed(1)} MB'
      : '$sizeKb KB';
  return AttachedDocument(name: file.name, sizeDisplay: sizeStr);
}
