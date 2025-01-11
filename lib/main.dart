import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'System File Explorer Demo',
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const FileExplorerPage(),
    );
  }
}

class FileExplorerPage extends StatefulWidget {
  const FileExplorerPage({super.key});

  @override
  State<FileExplorerPage> createState() => _FileExplorerPageState();
}

class _FileExplorerPageState extends State<FileExplorerPage> {
  static const platform =
      MethodChannel('plugins.scar.lt/open_in_system_file_explorer');

  Future<void> _openFileInSystemFileExplorer() async {
    try {
      await platform.invokeMethod('openFile', {'path': 'YOUR_PATH_HERE'});
    } catch (e) {
      print('Error opening file: $e');
    }
  }

  Future<void> _openDirInSystemFileExplorer() async {
    try {
      await platform.invokeMethod('openDirectory', {'path': 'YOUR_PATH_HERE'});
    } catch (e) {
      print('Error opening directory: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: [
          TextButton(
            onPressed: _openFileInSystemFileExplorer,
            child: const Text('Open file in system file explorer'),
          ),
          TextButton(
            onPressed: _openDirInSystemFileExplorer,
            child: const Text('Open directory in system file explorer'),
          ),
        ],
      ),
    );
  }
}
