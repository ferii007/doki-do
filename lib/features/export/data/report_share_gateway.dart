import 'dart:io';
import 'dart:ui';

import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../domain/generated_report.dart';

abstract interface class ReportShareGateway {
  Future<void> share(GeneratedReport report);
}

class PlatformReportShareGateway implements ReportShareGateway {
  const PlatformReportShareGateway();

  @override
  Future<void> share(GeneratedReport report) async {
    final directory = await getTemporaryDirectory();
    final file = File('${directory.path}/${report.fileName}');
    await file.writeAsBytes(report.bytes, flush: true);
    await SharePlus.instance.share(
      ShareParams(
        files: [XFile(file.path, mimeType: report.mimeType)],
        fileNameOverrides: [report.fileName],
        subject: report.fileName,
        sharePositionOrigin: const Rect.fromLTWH(0, 0, 1, 1),
      ),
    );
  }
}

class MemoryReportShareGateway implements ReportShareGateway {
  GeneratedReport? lastShared;

  @override
  Future<void> share(GeneratedReport report) async {
    lastShared = report;
  }
}
