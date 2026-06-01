import 'dart:io';
import 'dart:typed_data';

import 'package:file_selector/file_selector.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

class ExportSaveResult {
  const ExportSaveResult.saved(this.path) : shared = false;
  const ExportSaveResult.shared()
      : path = null,
        shared = true;

  final String? path;
  final bool shared;
}

Future<ExportSaveResult?> saveOrShareExportFile({
  required String fileName,
  required Uint8List bytes,
  required String mimeType,
}) async {
  if (Platform.isAndroid || Platform.isIOS) {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}${Platform.pathSeparator}$fileName');
    await file.writeAsBytes(bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        title: fileName,
        files: [XFile(file.path, mimeType: mimeType, name: fileName)],
        fileNameOverrides: [fileName],
      ),
    );

    return const ExportSaveResult.shared();
  }

  final location = await getSaveLocation(suggestedName: fileName);
  if (location == null) {
    return null;
  }

  final file = File(location.path);
  await file.writeAsBytes(bytes, flush: true);

  return ExportSaveResult.saved(file.path);
}
