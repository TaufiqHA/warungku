import 'dart:io';
import 'dart:typed_data';
import 'package:flutter/services.dart';
import 'package:open_filex/open_filex.dart';
import 'package:path_provider/path_provider.dart';

class ExcelOpenResult {
  final bool isSuccess;
  final String message;
  final bool noAppInstalled;
  final bool fallbackSaved;
  final String? savedPath;

  const ExcelOpenResult({
    required this.isSuccess,
    required this.message,
    this.noAppInstalled = false,
    this.fallbackSaved = false,
    this.savedPath,
  });
}

class ExcelExportService {
  /// Menyimpan bytes file Excel ke direktori penyimpanan lokal
  /// dan langsung membukanya menggunakan aplikasi pembaca dokumen di perangkat
  static Future<ExcelOpenResult> saveAndOpenExcelFile({
    required Uint8List bytes,
    String fileName = 'katalog_produk.xlsx',
  }) async {
    try {
      final tempDir = await getTemporaryDirectory();
      final filePath = '${tempDir.path}/$fileName';
      final file = File(filePath);

      await file.writeAsBytes(bytes, flush: true);

      // Coba juga simpan salinan ke folder Download publik Android agar mudah diakses
      String savedLocation = filePath;
      try {
        final downloadDir = Directory('/storage/emulated/0/Download');
        if (await downloadDir.exists()) {
          final downloadFile = File('${downloadDir.path}/$fileName');
          await downloadFile.writeAsBytes(bytes, flush: true);
          savedLocation = downloadFile.path;
        }
      } catch (_) {}

      String? mimeType;
      final lowerName = fileName.toLowerCase();
      if (lowerName.endsWith('.xlsx')) {
        mimeType = 'application/vnd.openxmlformats-officedocument.spreadsheetml.sheet';
      } else if (lowerName.endsWith('.csv')) {
        mimeType = 'text/csv';
      } else if (lowerName.endsWith('.xls')) {
        mimeType = 'application/vnd.ms-excel';
      }

      try {
        final openResult = await OpenFilex.open(filePath, type: mimeType);

        if (openResult.type == ResultType.done) {
          return ExcelOpenResult(
            isSuccess: true,
            savedPath: savedLocation,
            message: 'Membuka file Excel...',
          );
        } else if (openResult.type == ResultType.noAppToOpen) {
          return ExcelOpenResult(
            isSuccess: false,
            noAppInstalled: true,
            savedPath: savedLocation,
            message: 'Tidak ditemukan aplikasi pembuka file Excel (pasang Google Sheets atau WPS Office)',
          );
        } else {
          return ExcelOpenResult(
            isSuccess: false,
            savedPath: savedLocation,
            message: 'Gagal membuka file Excel: ${openResult.message}',
          );
        }
      } on MissingPluginException {
        return ExcelOpenResult(
          isSuccess: true,
          fallbackSaved: true,
          savedPath: savedLocation,
          message: 'File tersimpan di Download ($fileName). Silakan rebuild aplikasi (flutter run) untuk membuka otomatis.',
        );
      } catch (e) {
        if (e.toString().contains('MissingPluginException') || e is MissingPluginException) {
          return ExcelOpenResult(
            isSuccess: true,
            fallbackSaved: true,
            savedPath: savedLocation,
            message: 'File tersimpan di Download ($fileName). Silakan rebuild aplikasi (flutter run) untuk membuka otomatis.',
          );
        }
        return ExcelOpenResult(
          isSuccess: false,
          savedPath: savedLocation,
          message: 'Gagal membuka file: $e',
        );
      }
    } catch (e) {
      return ExcelOpenResult(
        isSuccess: false,
        message: 'Gagal menyimpan file Excel: $e',
      );
    }
  }
}
