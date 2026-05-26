import Flutter
import UIKit
import WidgetKit

@main
@objc class AppDelegate: FlutterAppDelegate, FlutterImplicitEngineDelegate {
  // 위젯 클릭 시 이동할 탭 인덱스 (nil = 위젯 클릭 아님)
  private var pendingWidgetTab: Int? = nil
  private var widgetChannel: FlutterMethodChannel? = nil

  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }

  // 위젯 클릭 또는 Google Sign-In 콜백 등 URL open 처리
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    // 위젯 딥링크 처리 (hamstudy:// 스킴)
    if url.scheme == "hamstudy", let host = url.host, let tab = Int(host) {
      if let ch = widgetChannel {
        ch.invokeMethod("navigateToTab", arguments: tab)
      } else {
        pendingWidgetTab = tab
      }
      return true
    }

    // Google Sign-In 등 나머지 URL은 super(Firebase/Flutter 플러그인)에 위임
    return super.application(app, open: url, options: options)
  }

  func didInitializeImplicitFlutterEngine(_ engineBridge: FlutterImplicitEngineBridge) {
    GeneratedPluginRegistrant.register(with: engineBridge.pluginRegistry)

    let channel = FlutterMethodChannel(
      name: "com.hamstudy/widget",
      binaryMessenger: engineBridge.pluginRegistry.registrar(forPlugin: "WidgetChannel")!.messenger()
    )
    widgetChannel = channel

    channel.setMethodCallHandler { [weak self] call, result in
      switch call.method {
      case "updateWidget":
        guard let args = call.arguments as? [String: Any] else {
          result(FlutterError(code: "INVALID_ARGS", message: "Arguments missing", details: nil))
          return
        }
        let defaults = UserDefaults(suiteName: "group.hamstudy")
        for (key, value) in args {
          if let str = value as? String {
            defaults?.set(str, forKey: key)
          } else if let num = value as? Int {
            defaults?.set(num, forKey: key)
          }
        }
        defaults?.synchronize()
        if #available(iOS 14.0, *) {
          WidgetCenter.shared.reloadAllTimelines()
        }
        result(nil)

      case "getInitialTab":
        // 콜드 스타트 시 Flutter가 탭 인덱스 요청
        result(self?.pendingWidgetTab)
        self?.pendingWidgetTab = nil

      default:
        result(FlutterMethodNotImplemented)
      }
    }
  }
}
