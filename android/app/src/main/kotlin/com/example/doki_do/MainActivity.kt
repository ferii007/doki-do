package com.example.doki_do

import android.app.Activity
import android.content.Intent
import android.net.Uri
import android.os.Build
import android.provider.DocumentsContract
import android.provider.OpenableColumns
import android.provider.Settings
import android.util.Base64
import io.flutter.embedding.android.FlutterFragmentActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.MethodChannel

class MainActivity : FlutterFragmentActivity() {
    private var directoryPickerResult: MethodChannel.Result? = null
    private var backupFilePickerResult: MethodChannel.Result? = null

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)
        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            "com.dokido.finance/notification_settings",
        ).setMethodCallHandler { call, result ->
            if (call.method != "openNotificationSettings") {
                result.notImplemented()
                return@setMethodCallHandler
            }

            val intent =
                if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O) {
                    Intent(Settings.ACTION_APP_NOTIFICATION_SETTINGS).apply {
                        putExtra(Settings.EXTRA_APP_PACKAGE, packageName)
                    }
                } else {
                    Intent(Settings.ACTION_APPLICATION_DETAILS_SETTINGS).apply {
                        data = Uri.parse("package:$packageName")
                    }
                }
            try {
                startActivity(intent)
                result.success(null)
            } catch (error: Exception) {
                result.error(
                    "settings_unavailable",
                    error.message ?: "Application settings are unavailable.",
                    null,
                )
            }
        }

        MethodChannel(
            flutterEngine.dartExecutor.binaryMessenger,
            BACKUP_CHANNEL,
        ).setMethodCallHandler { call, result ->
            when (call.method) {
                "chooseDirectory" -> chooseBackupDirectory(result)
                "chooseBackupFile" -> chooseBackupFile(result)
                "writeRotatingBackup" -> {
                    val directoryUri = call.argument<String>("directoryUri")
                    val currentFileName = call.argument<String>("currentFileName")
                    val previousFileName = call.argument<String>("previousFileName")
                    val content = call.argument<String>("content")
                    if (
                        directoryUri == null ||
                        currentFileName == null ||
                        previousFileName == null ||
                        content == null
                    ) {
                        result.error("invalid_arguments", "Backup arguments are incomplete.", null)
                        return@setMethodCallHandler
                    }
                    runFileOperation(result) {
                        writeRotatingBackup(
                            Uri.parse(directoryUri),
                            currentFileName,
                            previousFileName,
                            Base64.decode(content, Base64.DEFAULT),
                        )
                        null
                    }
                }
                "readBackupFromDirectory" -> {
                    val directoryUri = call.argument<String>("directoryUri")
                    val fileName = call.argument<String>("fileName")
                    if (directoryUri == null || fileName == null) {
                        result.error("invalid_arguments", "Backup location is incomplete.", null)
                        return@setMethodCallHandler
                    }
                    runFileOperation(result) {
                        val uri = findDocument(Uri.parse(directoryUri), fileName)
                            ?: return@runFileOperation null
                        fileResult(uri, fileName)
                    }
                }
                else -> result.notImplemented()
            }
        }
    }

    override fun onActivityResult(requestCode: Int, resultCode: Int, data: Intent?) {
        super.onActivityResult(requestCode, resultCode, data)
        when (requestCode) {
            DIRECTORY_PICKER_REQUEST -> {
                val pending = directoryPickerResult ?: return
                directoryPickerResult = null
                if (resultCode != Activity.RESULT_OK || data?.data == null) {
                    pending.success(null)
                    return
                }
                val uri = data.data!!
                try {
                    val flags = data.flags and
                        (Intent.FLAG_GRANT_READ_URI_PERMISSION or
                            Intent.FLAG_GRANT_WRITE_URI_PERMISSION)
                    contentResolver.takePersistableUriPermission(uri, flags)
                    pending.success(
                        mapOf(
                            "uri" to uri.toString(),
                            "name" to treeDisplayName(uri),
                        ),
                    )
                } catch (error: Exception) {
                    pending.error(
                        "directory_access_failed",
                        error.message ?: "The selected directory is unavailable.",
                        null,
                    )
                }
            }
            BACKUP_FILE_PICKER_REQUEST -> {
                val pending = backupFilePickerResult ?: return
                backupFilePickerResult = null
                if (resultCode != Activity.RESULT_OK || data?.data == null) {
                    pending.success(null)
                    return
                }
                val uri = data.data!!
                runFileOperation(pending) {
                    fileResult(uri, queryDisplayName(uri, "DokiDo_Backup.dokido"))
                }
            }
        }
    }

    private fun chooseBackupDirectory(result: MethodChannel.Result) {
        if (directoryPickerResult != null) {
            result.error("picker_active", "A directory picker is already active.", null)
            return
        }
        directoryPickerResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT_TREE).apply {
            addFlags(
                Intent.FLAG_GRANT_READ_URI_PERMISSION or
                    Intent.FLAG_GRANT_WRITE_URI_PERMISSION or
                    Intent.FLAG_GRANT_PERSISTABLE_URI_PERMISSION,
            )
        }
        startActivityForResult(intent, DIRECTORY_PICKER_REQUEST)
    }

    private fun chooseBackupFile(result: MethodChannel.Result) {
        if (backupFilePickerResult != null) {
            result.error("picker_active", "A file picker is already active.", null)
            return
        }
        backupFilePickerResult = result
        val intent = Intent(Intent.ACTION_OPEN_DOCUMENT).apply {
            addCategory(Intent.CATEGORY_OPENABLE)
            type = "application/octet-stream"
            addFlags(Intent.FLAG_GRANT_READ_URI_PERMISSION)
        }
        startActivityForResult(intent, BACKUP_FILE_PICKER_REQUEST)
    }

    private fun writeRotatingBackup(
        treeUri: Uri,
        currentFileName: String,
        previousFileName: String,
        bytes: ByteArray,
    ) {
        val current = findDocument(treeUri, currentFileName)
        if (current != null) {
            val previousBytes = contentResolver.openInputStream(current)?.use { it.readBytes() }
                ?: throw IllegalStateException("The current backup cannot be read.")
            writeDocument(treeUri, previousFileName, previousBytes)
        }
        writeDocument(treeUri, currentFileName, bytes)
    }

    private fun writeDocument(treeUri: Uri, fileName: String, bytes: ByteArray) {
        val documentUri = findDocument(treeUri, fileName)
            ?: DocumentsContract.createDocument(
                contentResolver,
                rootDocumentUri(treeUri),
                "application/octet-stream",
                fileName,
            )
            ?: throw IllegalStateException("The backup file cannot be created.")

        contentResolver.openOutputStream(documentUri, "wt")?.use { output ->
            output.write(bytes)
            output.flush()
        } ?: throw IllegalStateException("The backup file cannot be written.")
    }

    private fun findDocument(treeUri: Uri, fileName: String): Uri? {
        val childrenUri = DocumentsContract.buildChildDocumentsUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
        val projection = arrayOf(
            DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            DocumentsContract.Document.COLUMN_DISPLAY_NAME,
        )
        contentResolver.query(childrenUri, projection, null, null, null)?.use { cursor ->
            val idIndex = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DOCUMENT_ID,
            )
            val nameIndex = cursor.getColumnIndexOrThrow(
                DocumentsContract.Document.COLUMN_DISPLAY_NAME,
            )
            while (cursor.moveToNext()) {
                if (cursor.getString(nameIndex) == fileName) {
                    return DocumentsContract.buildDocumentUriUsingTree(
                        treeUri,
                        cursor.getString(idIndex),
                    )
                }
            }
        }
        return null
    }

    private fun rootDocumentUri(treeUri: Uri): Uri {
        return DocumentsContract.buildDocumentUriUsingTree(
            treeUri,
            DocumentsContract.getTreeDocumentId(treeUri),
        )
    }

    private fun fileResult(uri: Uri, fallbackName: String): Map<String, String> {
        val bytes = contentResolver.openInputStream(uri)?.use { it.readBytes() }
            ?: throw IllegalStateException("The selected backup cannot be read.")
        return mapOf(
            "name" to queryDisplayName(uri, fallbackName),
            "content" to Base64.encodeToString(bytes, Base64.NO_WRAP),
        )
    }

    private fun queryDisplayName(uri: Uri, fallback: String): String {
        contentResolver.query(
            uri,
            arrayOf(OpenableColumns.DISPLAY_NAME),
            null,
            null,
            null,
        )?.use { cursor ->
            val index = cursor.getColumnIndex(OpenableColumns.DISPLAY_NAME)
            if (index >= 0 && cursor.moveToFirst()) {
                return cursor.getString(index) ?: fallback
            }
        }
        return fallback
    }

    private fun treeDisplayName(uri: Uri): String {
        return try {
            DocumentsContract.getTreeDocumentId(uri)
                .substringAfterLast(':')
                .ifBlank { "DokiDo Backup" }
        } catch (_: Exception) {
            "DokiDo Backup"
        }
    }

    private fun runFileOperation(
        result: MethodChannel.Result,
        operation: () -> Any?,
    ) {
        Thread {
            try {
                val value = operation()
                runOnUiThread { result.success(value) }
            } catch (error: Exception) {
                runOnUiThread {
                    result.error(
                        "backup_file_error",
                        error.message ?: "The backup file operation failed.",
                        null,
                    )
                }
            }
        }.start()
    }

    companion object {
        private const val BACKUP_CHANNEL = "com.dokido.finance/backup_files"
        private const val DIRECTORY_PICKER_REQUEST = 4101
        private const val BACKUP_FILE_PICKER_REQUEST = 4102
    }
}
