import UIKit
import Flutter
import NotepadKit

@UIApplicationMain
@objc class AppDelegate: FlutterAppDelegate {
    override func application(
            _ application: UIApplication,
            didFinishLaunchingWithOptions launchOptions: [UIApplicationLaunchOptionsKey: Any]?
    ) -> Bool {
        MyscriptIinkPlugin.initWithCertificate(Data(bytes: myCertificate.bytes, count: myCertificate.length))
        GeneratedPluginRegistrant.register(with: self)
        registerImageSaver()
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }
    
    func registerImageSaver() {
        let registry = (self as FlutterPluginRegistry).registrar(forPlugin: "image_saver_flutter")
        let channel = FlutterMethodChannel(name: "image_saver_servers_channel", binaryMessenger: registry.messenger());
        channel.setMethodCallHandler { (call, result) in
            guard let dic: [String: Any] = call.arguments as? [String : Any] else {
                result(nil)
                return;
            }
            switch call.method {
            case "saveImage":
                guard let data: FlutterStandardTypedData = dic["imageBytes"] as? FlutterStandardTypedData, let img = UIImage(data: data.data) else {
                    result(false)
                    return;
                }
                UIImageWriteToSavedPhotosAlbum(img, nil, nil, nil)
                result(true);
                break;
            default:
                break;
            }
        }
    }

}
