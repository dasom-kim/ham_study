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

  // 위젯 클릭 시 호출 (앱이 꺼져있을 때 or 이미 실행 중일 때)
  override func application(
    _ app: UIApplication,
    open url: URL,
    options: [UIApplication.OpenURLOptionsKey: Any] = [:]
  ) -> Bool {
    guard url.scheme == "hamstudy", let host = url.host, let tab = Int(host) else {
      return false
    }
    if let ch = widgetChannel {
      // 앱이 이미 실행 중 → Flutter에 직접 전달
      ch.invokeMethod("navigateToTab", arguments: tab)
    } else {
      // 앱 콜드 스타트 → Flutter 엔진 준비 후 전달
      pendingWidgetTab = tab
    }
    return true
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
