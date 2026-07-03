import 'dart:async';

import 'package:doki_do/core/storage/async_write_queue.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  test('executes writes in submission order', () async {
    final queue = AsyncWriteQueue();
    final events = <String>[];

    final first = queue.run(() async {
      events.add('first-start');
      await Future<void>.delayed(const Duration(milliseconds: 30));
      events.add('first-end');
    });
    final second = queue.run(() async {
      events.add('second-start');
      events.add('second-end');
    });

    await Future.wait([first, second]);

    expect(events, ['first-start', 'first-end', 'second-start', 'second-end']);
  });

  test('continues processing after a failed write', () async {
    final queue = AsyncWriteQueue();
    final completer = Completer<void>();

    final failed = queue.run(() async {
      throw StateError('write failed');
    });
    final recovered = queue.run(() async {
      completer.complete();
    });

    await expectLater(failed, throwsStateError);
    await recovered;
    expect(completer.isCompleted, isTrue);
  });
}
