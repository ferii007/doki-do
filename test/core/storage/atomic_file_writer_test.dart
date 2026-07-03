import 'dart:io';

import 'package:doki_do/core/storage/atomic_file_writer.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  late Directory directory;
  late File target;

  setUp(() {
    directory = Directory.systemTemp.createTempSync('doki_do_atomic_test_');
    target = File('${directory.path}/data.json');
  });

  tearDown(() {
    if (directory.existsSync()) {
      directory.deleteSync(recursive: true);
    }
  });

  test('replaces a file without leaving migration artifacts', () async {
    await target.writeAsString('old');

    await AtomicFileWriter.writeString(target, 'new');

    expect(await target.readAsString(), 'new');
    expect(File('${target.path}.tmp').existsSync(), isFalse);
    expect(File('${target.path}.previous').existsSync(), isFalse);
    expect(await AtomicFileWriter.backupFor(target).readAsString(), 'old');
  });

  test('restores the previous file after an interrupted replacement', () async {
    final previous = File('${target.path}.previous');
    await previous.writeAsString('old');

    await AtomicFileWriter.recover(target);

    expect(await target.readAsString(), 'old');
    expect(previous.existsSync(), isFalse);
  });
}
