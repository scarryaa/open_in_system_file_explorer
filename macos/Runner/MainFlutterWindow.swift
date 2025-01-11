import Cocoa
import FlutterMacOS

class MainFlutterWindow: NSWindow {
    override func awakeFromNib() {
        let flutterViewController = FlutterViewController()
        let windowFrame = self.frame
        self.contentViewController = flutterViewController
        self.setFrame(windowFrame, display: true)
        
        let fileExplorerChannel = FlutterMethodChannel(
            name: "plugins.scar.lt/open_in_system_file_explorer",
            binaryMessenger: flutterViewController.engine.binaryMessenger)
        
        fileExplorerChannel.setMethodCallHandler { (call, result) in
            switch call.method {
            case "openFile":
                guard let arguments = call.arguments as? [String: Any],
                      let filePath = arguments["path"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Path argument is required",
                                      details: nil))
                    return
                }
                
                let fileURL = URL(fileURLWithPath: filePath)
                
                // Check if file exists
                if !FileManager.default.fileExists(atPath: filePath) {
                    result(FlutterError(code: "FILE_NOT_FOUND",
                                      message: "File not found at specified path",
                                      details: nil))
                    return
                }
                
                // Open file in Finder
                NSWorkspace.shared.selectFile(fileURL.path,
                                           inFileViewerRootedAtPath: fileURL.deletingLastPathComponent().path)
                result(true)
                
            case "openDirectory":
                guard let arguments = call.arguments as? [String: Any],
                      let directoryPath = arguments["path"] as? String else {
                    result(FlutterError(code: "INVALID_ARGUMENTS",
                                      message: "Path argument is required",
                                      details: nil))
                    return
                }
                
                let directoryURL = URL(fileURLWithPath: directoryPath)
                
                // Check if directory exists
                var isDirectory: ObjCBool = false
                if !FileManager.default.fileExists(atPath: directoryPath, isDirectory: &isDirectory) || !isDirectory.boolValue {
                    result(FlutterError(code: "DIRECTORY_NOT_FOUND",
                                      message: "Directory not found at specified path",
                                      details: nil))
                    return
                }
                
                // Open directory in Finder
                NSWorkspace.shared.activateFileViewerSelecting([directoryURL])
                result(true)
                
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        RegisterGeneratedPlugins(registry: flutterViewController)

        super.awakeFromNib()
    }
}
