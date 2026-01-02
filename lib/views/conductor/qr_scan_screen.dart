import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

class QRScanScreen extends StatefulWidget {
  const QRScanScreen({super.key});

  @override
  State<QRScanScreen> createState() => _QRScanScreenState();
}

class _QRScanScreenState extends State<QRScanScreen> {
  // Explicit controller to manage lifecycle and web compatibility
  final MobileScannerController _controller = MobileScannerController(
    detectionSpeed: DetectionSpeed.noDuplicates,
    facing: CameraFacing.back,
    torchEnabled: false,
    formats: [BarcodeFormat.qrCode],
    autoStart: false, // We will start manually to handle permissions better
  );

  bool _isScanned = false; // Prevent multiple pops
  bool _showManualStart = false; // To show button if auto-start hangs

  @override
  void initState() {
    super.initState();
    // specific delay to let the page load, then start
    Future.delayed(const Duration(milliseconds: 500), () {
      _startCamera();
    });

    // Failsafe: if still loading after 3 seconds, show manual button
    Future.delayed(const Duration(seconds: 3), () {
      if (mounted) {
        setState(() => _showManualStart = true);
      }
    });
  }

  void _startCamera() async {
    // 1. Give user feedback immediately
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Requesting Camera Access..."),
        duration: Duration(seconds: 1),
      ),
    );

    try {
      // 2. Stop first to clear any confused state
      await _controller.stop();
      // 3. Start again
      await _controller.start();
    } catch (e) {
      debugPrint("Camera start error: $e");
      // Show audible/visible error to user
      if (mounted) {
        showDialog(
          context: context,
          builder: (ctx) => AlertDialog(
            title: const Text("Camera Error"),
            content:
                Text("Could not start camera: $e\nCheck browser permissions."),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(ctx), child: const Text("OK"))
            ],
          ),
        );
      }
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Scan Window Size
    final double scanWindowSize = 250;

    return Scaffold(
      backgroundColor: Colors.black, // Dark background
      body: Stack(
        children: [
          // 1. Camera Feed
          MobileScanner(
            controller: _controller,
            onDetect: (capture) {
              if (_isScanned) return;
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  setState(() => _isScanned = true);
                  // Return the scanned code
                  Navigator.pop(context, barcode.rawValue);
                  return;
                }
              }
            },
            // Fix: remove 'child' argument to match mobile_scanner 7.x
            errorBuilder: (context, error) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(Icons.broken_image,
                        color: Colors.grey, size: 48),
                    const SizedBox(height: 16),
                    Text(
                      "Camera not available.\n(${error.errorCode})",
                      textAlign: TextAlign.center,
                      style: const TextStyle(color: Colors.white70),
                    ),
                    const SizedBox(height: 16),
                    ElevatedButton.icon(
                      onPressed: () => _startCamera(),
                      icon: const Icon(Icons.refresh),
                      label: const Text("Retry Camera"),
                    ),
                  ],
                ),
              );
            },
            // Fix: remove 'child' argument to match mobile_scanner 7.x
            placeholderBuilder: (context) {
              return Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const CircularProgressIndicator(color: Colors.white),
                    const SizedBox(height: 16),
                    const Text("Starting Camera...",
                        style: TextStyle(color: Colors.white)),
                  ],
                ),
              );
            },
          ),

          // 2. Dark Overlay with Cutout
          CustomPaint(
            size: Size.infinite,
            painter: ScannerOverlayPainter(scanWindowSize: scanWindowSize),
          ),

          // 3. UI Layer (Controls & Hints)
          SafeArea(
            child: Column(
              children: [
                // Top Bar
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Close Button
                      CircleAvatar(
                        backgroundColor: Colors.black54,
                        child: IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => Navigator.pop(context),
                        ),
                      ),
                      // Controls
                      Row(
                        children: [
                          // Torch Toggle
                          ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, state, child) {
                              // Access torchState from the MobileScannerState
                              final isOn = state.torchState == TorchState.on;
                              return IconButton(
                                icon: Icon(
                                  isOn ? Icons.flash_on : Icons.flash_off,
                                  color: isOn ? Colors.yellow : Colors.white,
                                ),
                                onPressed: () => _controller.toggleTorch(),
                              );
                            },
                          ),
                          // Camera Switch
                          ValueListenableBuilder(
                            valueListenable: _controller,
                            builder: (context, state, child) {
                              return IconButton(
                                icon: const Icon(Icons.cameraswitch,
                                    color: Colors.white),
                                onPressed: () => _controller.switchCamera(),
                              );
                            },
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const Spacer(),

                // Hint Text around the box
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                  decoration: BoxDecoration(
                    color: Colors.black54,
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: const Text(
                    "Align QR code within the frame",
                    style: TextStyle(
                        color: Colors.white,
                        fontWeight: FontWeight.bold,
                        fontSize: 14),
                  ),
                ),

                const SizedBox(height: 40), // Space for the cutout

                const Spacer(),

                // Bottom: Manual Entry
                Container(
                  margin:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius:
                        BorderRadius.vertical(top: Radius.circular(16)),
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Scanning failed?",
                        style: TextStyle(
                            color: Colors.grey,
                            fontSize: 12,
                            fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        decoration: InputDecoration(
                          hintText: "Enter Ticket ID Manually",
                          filled: true,
                          fillColor: Colors.grey.shade100,
                          contentPadding: const EdgeInsets.symmetric(
                              horizontal: 16, vertical: 0),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide.none,
                          ),
                          suffixIcon: Container(
                            margin: const EdgeInsets.all(4),
                            decoration: const BoxDecoration(
                              color: Colors.black,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.arrow_forward,
                                color: Colors.white, size: 20),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.trim().isNotEmpty) {
                            Navigator.pop(context, value.trim());
                          }
                        },
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          // 4. Manual Start Button (Top Layer - Completely Visible and Clickable)
          if (_showManualStart)
            Align(
              alignment: Alignment.center,
              child: Padding(
                padding: const EdgeInsets.only(
                    top:
                        150), // Shift down below center to avoid covering cutout area totally
                child: ElevatedButton.icon(
                  onPressed: () {
                    // Start and hide button immediately to check
                    _startCamera();
                    setState(() => _showManualStart = false);
                    // Add shorter failsafe to show it again if it fails
                    Future.delayed(const Duration(seconds: 2), () {
                      if (mounted && !_controller.value.isInitialized) {
                        setState(() => _showManualStart = true);
                      }
                    });
                  },
                  icon: const Icon(Icons.camera_alt),
                  label: const Text("Tap to Start Camera"),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: Colors.black,
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 12),
                    textStyle: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }
}

class ScannerOverlayPainter extends CustomPainter {
  final double scanWindowSize;

  ScannerOverlayPainter({required this.scanWindowSize});

  @override
  void paint(Canvas canvas, Size size) {
    final double scanArea = scanWindowSize;
    final double left = (size.width - scanArea) / 2;
    final double top = (size.height - scanArea) / 2 - 50; // Shift up slightly
    final Rect scanRect = Rect.fromLTWH(left, top, scanArea, scanArea);

    // 1. Draw Semi-Transparent Dark Overlay everywhere EXCEPT the scanRect
    final Paint backgroundPaint = Paint()
      ..color = Colors.black.withValues(alpha: 0.6)
      ..style = PaintingStyle.fill;

    final Path backgroundPath = Path()
      ..addRect(Rect.fromLTWH(0, 0, size.width, size.height));

    final Path cutoutPath = Path()
      ..addRRect(RRect.fromRectAndRadius(scanRect, const Radius.circular(20)));

    final Path finalPath = Path.combine(
      PathOperation.difference,
      backgroundPath,
      cutoutPath,
    );

    canvas.drawPath(finalPath, backgroundPaint);

    // 2. Draw Borders (Corners)
    final Paint borderPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.stroke
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;

    final double cornerLength = 30;

    // Top Left
    canvas.drawLine(scanRect.topLeft,
        scanRect.topLeft + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanRect.topLeft,
        scanRect.topLeft + Offset(cornerLength, 0), borderPaint);

    // Top Right
    canvas.drawLine(scanRect.topRight,
        scanRect.topRight + Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanRect.topRight,
        scanRect.topRight - Offset(cornerLength, 0), borderPaint);

    // Bottom Left
    canvas.drawLine(scanRect.bottomLeft,
        scanRect.bottomLeft - Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanRect.bottomLeft,
        scanRect.bottomLeft + Offset(cornerLength, 0), borderPaint);

    // Bottom Right
    canvas.drawLine(scanRect.bottomRight,
        scanRect.bottomRight - Offset(0, cornerLength), borderPaint);
    canvas.drawLine(scanRect.bottomRight,
        scanRect.bottomRight - Offset(cornerLength, 0), borderPaint);

    // 3. Draw Red Line (Scanning animation)
    final Paint linePaint = Paint()
      ..color = Colors.red.withValues(alpha: 0.8)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    canvas.drawLine(
      Offset(left + 10, top + scanArea / 2),
      Offset(left + scanArea - 10, top + scanArea / 2),
      linePaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) {
    return false;
  }
}
