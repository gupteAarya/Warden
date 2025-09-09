import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_overlay_window/flutter_overlay_window.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:camera/camera.dart';

@pragma("vm:entry-point")
void overlayMain() {
  runApp(
    MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Material(
        color: Colors.blue, // Make the background transparent
        child: Center(
          child: Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.red,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  spreadRadius: 2,
                ),
              ],
            ),
            child: IconButton(
              icon: const Icon(Icons.close, color: Colors.white),
              onPressed: () {
                FlutterOverlayWindow.closeOverlay().then((_) {
                  debugPrint('Overlay closed');
                });
              },
            ),
          ),
        ),
      ),
    ),
  );
}

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return const MaterialApp(home: const HomePage());
  }
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  String _permissionStatus = 'Not Requested';
  String _overlayPermissionStatus = 'Not Requested';
  CameraController? cameraController;
  bool isCameraInitialized = false;
  XFile? capturedImage;

  Future<void> initializeCamera() async {
    final cameras = await availableCameras();
    if (cameras.isNotEmpty) {
      cameraController = CameraController(
        cameras.first,
        ResolutionPreset.medium,
      );
      await cameraController!.initialize();
      setState(() {
        isCameraInitialized = true;
      });
    }
  }

  Future<void> capturePhoto() async {
    //To be implemented...
    if (cameraController != null && isCameraInitialized) {
      capturedImage = await cameraController!.takePicture();
    }
    setState(() {});
  }

  Future<void> showOverlay() async {
    final bool status = await FlutterOverlayWindow.isPermissionGranted();
    if (status) {
      print("Permission is granted ! Showing overlay");
      await FlutterOverlayWindow.showOverlay();
    } else {
      print("Permission is not granted ! Requesting permission");
      await FlutterOverlayWindow.requestPermission();
      print("Attempting to show overlay!");
      showOverlay();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Warden MVP')),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              height: 200,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: isCameraInitialized
                  ? CameraPreview(cameraController!)
                  : const Text(
                      'Camera is not initialized ! Check permissions or try again later.',
                    ),
            ),
            Container(
              height: 200,
              width: 300,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey),
                borderRadius: BorderRadius.circular(8),
              ),
              child: capturedImage != null
                  ? Image.file(File(capturedImage!.path))
                  : const Text('No photo captured yet.'),
            ),
            Row(
              children: [
                ElevatedButton(
                  onPressed: initializeCamera,
                  child: const Text('Initialize Camera'),
                ),
                ElevatedButton(
                  onPressed: capturePhoto,
                  child: const Text('Capture Image.'),
                ),
              ],
            ),
            Text('Camera Permission: $_permissionStatus'),
            SizedBox(height: 20),
            ElevatedButton(
              onPressed: () async {
                setState(() {
                  _permissionStatus = 'Requesting...';
                });
                final status = await Permission.camera.request();
                setState(() {
                  _permissionStatus = status.toString().split('.').last;
                });
                if (status.isDenied) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text(
                        'Camera permission is needed to take photos.',
                      ),
                    ),
                  );

                  // Permission denied, show a message or open settings
                }
              },
              child: const Text('Request Camera Permission'),
            ),
            /**ElevatedButton(
              onPressed: showOverlay,
              child: const Text('Show Overlay'),
            ),**/
            ElevatedButton(
            onPressed: () async {
              // Check if we have overlay permission
              if (await FlutterOverlayWindow.isPermissionGranted()) {
                await FlutterOverlayWindow.showOverlay(
                  enableDrag: true,
                  overlayTitle: "Warden Overlay",
                  overlayContent: "Panic button is active",
                  flag: OverlayFlag.defaultFlag,
                  visibility: NotificationVisibility.visibilityPublic,
                );
              } else {
                // Request permission if not granted
                await FlutterOverlayWindow.requestPermission();
              }
            },
            child: const Text('Show Overlay'),
          ),
            SizedBox(height: 40),

            Text('Camera Permission: $_overlayPermissionStatus'),
            SizedBox(height: 20),
          ],
        ),
      ),
    );
  }
}
