import 'dart:convert';

import 'package:flutter/services.dart';

import '../domain/generated_report.dart';

abstract interface class ReportSaveGateway {
  Future<bool> save(GeneratedReport report);
}

class PlatformReportSaveGateway implements ReportSaveGateway {
  static const _channel = MethodChannel('com.dokido.finance/report_files');

  const PlatformReportSaveGateway();

  @override
  Future<bool> save(GeneratedReport report) async {
    return await _channel.invokeMethod<bool>('saveReport', {
          'fileName': report.fileName,
          'mimeType': report.mimeType,
          'content': base64Encode(report.bytes),
        }) ??
        false;
  }
}

class MemoryReportSaveGateway implements ReportSaveGateway {
  GeneratedReport? lastSaved;
  bool result;

  MemoryReportSaveGateway({this.result = true});

  @override
  Future<bool> save(GeneratedReport report) async {
    lastSaved = report;
    return result;
  }
}
