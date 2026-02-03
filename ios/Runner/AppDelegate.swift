import Flutter
import UIKit
import FirebaseCore
import AppsFlyerLib

@main
@objc class AppDelegate: FlutterAppDelegate {
  override func application(
    _ application: UIApplication,
    didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
  ) -> Bool {
    FirebaseApp.configure()

    AppsFlyerLib.shared().appsFlyerDevKey = "wWnc2go5ZMLf9xRNFtwAj3"
    AppsFlyerLib.shared().appleAppID = "6757518897"
    AppsFlyerLib.shared().isDebug = true
    AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
    AppsFlyerLib.shared().start()

    GeneratedPluginRegistrant.register(with: self)
    return super.application(application, didFinishLaunchingWithOptions: launchOptions)
  }
}
