import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';

class CameraFullScreen extends StatefulWidget {
  final CameraDescription camera;
  const CameraFullScreen({super.key, required this.camera});

  @override
  State<CameraFullScreen> createState() => _CameraFullScreenState();
}

class _CameraFullScreenState extends State<CameraFullScreen> {
  late CameraController _controller;
  late Future<void> _initializeControllerFuture;

  @override
  void initState() {
    super.initState();
    _controller = CameraController(
      widget.camera,
      ResolutionPreset.max,
      enableAudio: false,
    );
    _initializeControllerFuture = _controller.initialize();
    debugPrint('[CameraFullScreen] initState: controller initialized');
  }

  @override
  void dispose() {
    debugPrint('[CameraFullScreen] dispose: disposing controller');
    _controller.dispose();
    super.dispose();
  }

  Future<void> _takePictureAndReturn() async {
    try {
      await _initializeControllerFuture;

      debugPrint('[CameraFullScreen] _takePictureAndReturn: getting position');
      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
        ),
      );
      debugPrint('[CameraFullScreen] _takePictureAndReturn: taking picture');
      final image = await _controller.takePicture();

      if (!mounted) {
        debugPrint(
          '[CameraFullScreen] not mounted after capture — skipping pop',
        );
        return;
      }

      final nav = Navigator.of(context);
      if (nav.canPop()) {
        debugPrint('[CameraFullScreen] popping with result');
        nav.pop({'image': image, 'position': position});
      } else {
        debugPrint('[CameraFullScreen] cannot pop (no routes) — skipping pop');
      }
    } catch (e, st) {
      debugPrint('Erro ao tirar foto: $e\n$st');
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Erro ao tirar foto: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: SafeArea(
        maintainBottomViewPadding: false,
        child: Stack(
          children: [
            FutureBuilder<void>(
              future: _initializeControllerFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState != ConnectionState.done) {
                  return const Center(
                    child: CircularProgressIndicator(color: Colors.white),
                  );
                }

                final size = MediaQuery.of(context).size;
                final deviceRatio = size.width / size.height;

                final previewSize = _controller.value.previewSize!;
                final previewRatio = previewSize.height / previewSize.width;

                final scale = deviceRatio / previewRatio;

                return Transform.scale(
                  scale: scale < 1 ? 1 / scale : scale,
                  alignment: Alignment.center,
                  child: Center(child: CameraPreview(_controller)),
                );
              },
            ),

            Positioned(
              top: 16 + MediaQuery.of(context).padding.top,
              left: 12,
              child: IconButton(
                icon: const Icon(Icons.close, color: Colors.white, size: 30),
                onPressed: () {
                  final nav = Navigator.of(context);
                  if (nav.canPop()) {
                    debugPrint('[CameraFullScreen] close pressed -> popping');
                    nav.pop();
                  } else {
                    debugPrint(
                      '[CameraFullScreen] close pressed but cannot pop',
                    );
                  }
                },
              ),
            ),

            Positioned(
              bottom: 28 + MediaQuery.of(context).padding.bottom,
              left: 0,
              right: 0,
              child: Center(
                child: GestureDetector(
                  onTap: _takePictureAndReturn,
                  child: Container(
                    height: 78,
                    width: 78,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.08),
                      shape: BoxShape.circle,
                      border: Border.all(color: Colors.white, width: 3),
                    ),
                    child: Center(
                      child: Container(
                        height: 54,
                        width: 54,
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
