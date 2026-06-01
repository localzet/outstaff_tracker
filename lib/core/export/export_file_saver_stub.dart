import 'dart:typed_data';

class ExportSaveResult {
  const ExportSaveResult.shared();

  bool get shared => true;
}

Future<ExportSaveResult?> saveOrShareExportFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  return const ExportSaveResult.shared();
}
