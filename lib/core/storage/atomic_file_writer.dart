import 'dart:io';

class AtomicFileWriter {
  const AtomicFileWriter._();

  static File backupFor(File target) => File('${target.path}.backup');

  static Future<void> recover(File target) async {
    if (await target.exists()) return;

    final previous = File('${target.path}.previous');
    if (await previous.exists()) {
      await previous.rename(target.path);
    }
  }

  static Future<void> restoreBackup(File target) async {
    final backup = backupFor(target);
    if (!await backup.exists()) {
      throw FileSystemException('Storage backup does not exist.', backup.path);
    }
    await writeString(
      target,
      await backup.readAsString(),
      preserveExistingAsBackup: false,
    );
  }

  static Future<void> writeString(
    File target,
    String content, {
    bool preserveExistingAsBackup = true,
  }) async {
    final temporary = File('${target.path}.tmp');
    final previous = File('${target.path}.previous');
    final backup = backupFor(target);

    if (await temporary.exists()) {
      await temporary.delete();
    }
    await temporary.writeAsString(content, flush: true);

    final targetExists = await target.exists();
    if (targetExists) {
      if (await previous.exists()) {
        await previous.delete();
      }
      await target.rename(previous.path);
    }

    try {
      await temporary.rename(target.path);
      if (await previous.exists()) {
        if (preserveExistingAsBackup) {
          if (await backup.exists()) {
            await backup.delete();
          }
          await previous.rename(backup.path);
        } else {
          await previous.delete();
        }
      }
      if (!await backup.exists()) {
        await backup.writeAsString(content, flush: true);
      }
    } on Object {
      if (!await target.exists() && await previous.exists()) {
        await previous.rename(target.path);
      }
      rethrow;
    } finally {
      if (await temporary.exists()) {
        await temporary.delete();
      }
    }
  }
}
