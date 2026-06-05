import 'dart:io';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../api/api_client.dart';

final fileServiceProvider = Provider<FileService>((ref) {
  return FileService(ref.watch(apiClientProvider));
});

class FileService {
  FileService(this._api);

  final ApiClient _api;

  Future<File> downloadPdf(String path, String fileName) async {
    final response = await _api.download(path);
    final dir = await getTemporaryDirectory();
    final safeName = fileName.replaceAll(RegExp(r'[^\w\-.]+'), '-');
    final file = File('${dir.path}/$safeName');
    await file.writeAsBytes(response.data ?? const []);
    return file;
  }

  Future<void> openPdf(String path, String fileName) async {
    final file = await downloadPdf(path, fileName);
    await OpenFilex.open(file.path);
  }

  Future<void> sharePdf(String path, String fileName) async {
    final file = await downloadPdf(path, fileName);
    await SharePlus.instance.share(ShareParams(files: [XFile(file.path)]));
  }
}
