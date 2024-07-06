import 'dart:async';
import 'dart:typed_data';

import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:image/image.dart' as img;
import 'package:qr_scanner_overlay/qr_scanner_overlay.dart';

class CameraScreen extends StatefulWidget {
  final CameraDescription camera;

  const CameraScreen({required this.camera});

  @override
  _CameraScreenState createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;
  Timer? _timer;
  List<img.Image> images = [];
  bool isRecording = false;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.medium,
      enableAudio: false,
      imageFormatGroup: ImageFormatGroup.jpeg,
    );
    _initializeControllerFuture = _controller.initialize();
  }

  @override
  void dispose() {
    _controller.dispose();
    _timer?.cancel();
    super.dispose();
  }

  void startFrameCapture() {
    if (isRecording) return;
    setState(() {
      isRecording = true;
    });
    _timer = Timer.periodic(Duration(seconds: 1), (timer) async {
      try {
        if (_controller.value.isInitialized) {
          await _controller.setFlashMode(FlashMode.off);
          final image = await _controller.takePicture();
          final bytes = await image.readAsBytes();
          processImage(bytes);
        }
      } catch (e) {
        print(e);
      }
    });
  }

  void stopFrameCapture() {
    if (!isRecording) return;
    setState(() {
      isRecording = false;
    });
    _timer?.cancel();
  }

  void processImage(Uint8List bytes) {
    final img.Image? image = img.decodeImage(bytes);
    if (image != null) {
      final img.Image resized = img.copyResize(image, width: 500, height: 480);
      setState(() {
        images.add(resized);
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        backgroundColor: Colors.black,
        appBar: AppBar(
          title: Padding(
            padding: const EdgeInsets.only(left: 20.0),
            child: Text(
              'QR Scanner',
              style: TextStyle(
                  color: Colors.white,
                  fontSize: 25
              ),
            ),
          ),
          backgroundColor: Colors.blue,
        ),
        body: Column(
          children: [
            Expanded(
              flex: 2,
              child: Stack(
                children: [
                  Container(
                    height: 500,
                    width: double.infinity,
                    child: FutureBuilder<void>(
                      future: _initializeControllerFuture,
                      builder: (context, snapshot) {
                        if (snapshot.connectionState == ConnectionState.done) {
                          return CameraPreview(_controller);
                        } else {
                          return Center(child: CircularProgressIndicator());
                        }
                      },
                    ),
                  ),
                  QRScannerOverlay(
                    overlayColor: Colors.black26,
                  ),
                ],
              ),
            ),
            Padding(
              padding: EdgeInsets.only(bottom: 20.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.purple.shade300),
                    ),
                    onPressed: startFrameCapture,
                    child: Text(
                      'Start Camera',
                      style: TextStyle(
                          color: Colors.white
                      ),
                    ),
                  ),
                  SizedBox(width: 40),
                  ElevatedButton(
                    style: ButtonStyle(
                      backgroundColor: MaterialStateProperty.all<Color>(Colors.purple.shade300),
                    ),
                    onPressed: stopFrameCapture,
                    child: Text(
                      'Stop Camera',
                      style: TextStyle(
                          color: Colors.white
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.builder(
                scrollDirection: Axis.horizontal,
                itemCount: images.length,
                itemBuilder: (context, index) {
                  return Container(
                    height: 100,
                    width: 200,
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Image.memory(Uint8List.fromList(img.encodeJpg(images[index]))),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
