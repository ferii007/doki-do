import Flutter
import UIKit
import UserNotifications

@main
@objc class AppDelegate: FlutterAppDelegate, UIDocumentPickerDelegate {
  private var reportSaveResult: FlutterResult?
  private var temporaryReportURL: URL?

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    UNUserNotificationCenter.current().delegate = self as UNUserNotificationCenterDelegate
    GeneratedPluginRegistrant.register(with: self)
    if let controller = window?.rootViewController as? FlutterViewController {
      let channel = FlutterMethodChannel(
        name: "com.dokido.finance/notification_settings",
        binaryMessenger: controller.binaryMessenger
      )
      channel.setMethodCallHandler { call, result in
        guard call.method == "openNotificationSettings" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard let url = URL(string: UIApplication.openSettingsURLString) else {
          result(
            FlutterError(
              code: "settings_unavailable",
              message: "Application settings are unavailable.",
              details: nil
            )
          )
          return
        }
        UIApplication.shared.open(url)
        result(nil)
      }

      let reportChannel = FlutterMethodChannel(
        name: "com.dokido.finance/report_files",
        binaryMessenger: controller.binaryMessenger
      )
      reportChannel.setMethodCallHandler { [weak self, weak controller] call, result in
        guard call.method == "saveReport" else {
          result(FlutterMethodNotImplemented)
          return
        }
        guard
          let arguments = call.arguments as? [String: Any],
          let fileName = arguments["fileName"] as? String,
          let content = arguments["content"] as? String,
          let data = Data(base64Encoded: content),
          let self,
          let controller
        else {
          result(
            FlutterError(
              code: "invalid_arguments",
              message: "Report arguments are incomplete.",
              details: nil
            )
          )
          return
        }
        guard self.reportSaveResult == nil else {
          result(
            FlutterError(
              code: "picker_active",
              message: "A report file picker is already active.",
              details: nil
            )
          )
          return
        }

        do {
          let safeName = URL(fileURLWithPath: fileName).lastPathComponent
          let temporaryURL = FileManager.default.temporaryDirectory
            .appendingPathComponent(safeName)
          try data.write(to: temporaryURL, options: .atomic)
          self.reportSaveResult = result
          self.temporaryReportURL = temporaryURL
          let picker = UIDocumentPickerViewController(
            url: temporaryURL,
            in: .exportToService
          )
          picker.delegate = self
          controller.present(picker, animated: true)
        } catch {
          result(
            FlutterError(
              code: "report_file_error",
              message: error.localizedDescription,
              details: nil
            )
          )
        }
      }
    }
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  func documentPicker(
    _ controller: UIDocumentPickerViewController,
    didPickDocumentsAt urls: [URL]
  ) {
    finishReportSave(saved: !urls.isEmpty)
  }

  func documentPickerWasCancelled(_ controller: UIDocumentPickerViewController) {
    finishReportSave(saved: false)
  }

  private func finishReportSave(saved: Bool) {
    reportSaveResult?(saved)
    reportSaveResult = nil
    if let url = temporaryReportURL {
      try? FileManager.default.removeItem(at: url)
    }
    temporaryReportURL = nil
  }
}
