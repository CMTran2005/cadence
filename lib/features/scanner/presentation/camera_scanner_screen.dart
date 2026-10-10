import 'dart:io';
import 'package:camera/camera.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';
import '../../../core/constants/app_colors.dart';
import '../../../core/database/database_helper.dart';
import '../../../core/localization/app_localizations.dart';
import '../../transactions/models/transaction_item.dart';
import '../services/mlkit_ocr_service.dart';
import 'receipt_review_dialog.dart';

class CameraScannerScreen extends StatefulWidget {
  const CameraScannerScreen({super.key});

  @override
  State<CameraScannerScreen> createState() => _CameraScannerScreenState();
}

class _CameraScannerScreenState extends State<CameraScannerScreen> with WidgetsBindingObserver {
  CameraController? _cameraController;
  List<CameraDescription> _cameras = [];
  bool _isCameraInitialized = false;
  bool _isProcessing = false;
  bool _isFlashOn = false;

  late final MlKitOcrService _ocrService;
  final ImagePicker _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    _ocrService = MlKitOcrService();
    _initCamera();
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _cameraController?.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.inactive || state == AppLifecycleState.paused) {
      _cameraController?.dispose();
      _cameraController = null;
      if (mounted) setState(() => _isCameraInitialized = false);
    } else if (state == AppLifecycleState.resumed) {
      _initCamera();
    }
  }

  Future<void> _initCamera() async {
    try {
      _cameras = await availableCameras();
      if (_cameras.isNotEmpty) {
        _cameraController = CameraController(
          _cameras.first,
          ResolutionPreset.high,
          enableAudio: false,
        );
        await _cameraController!.initialize();
        if (mounted) {
          setState(() => _isCameraInitialized = true);
        }
      }
    } catch (e) {
      debugPrint('Camera init error: $e');
    }
  }

  Future<void> _toggleFlash() async {
    if (_cameraController == null || !_isCameraInitialized) return;
    try {
      final nextState = !_isFlashOn;
      await _cameraController!.setFlashMode(nextState ? FlashMode.torch : FlashMode.off);
      setState(() => _isFlashOn = nextState);
    } catch (_) {}
  }

  Future<void> _captureAndScan() async {
    if (_cameraController == null || !_isCameraInitialized || _isProcessing) return;

    try {
      setState(() => _isProcessing = true);
      HapticFeedback.mediumImpact();

      final XFile photo = await _cameraController!.takePicture();
      await _processImage(photo.path);
    } catch (e) {
      _showError('Camera error: $e');
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickFromGallery() async {
    try {
      final XFile? image = await _picker.pickImage(
        source: ImageSource.gallery,
        maxWidth: 2048,
        maxHeight: 2048,
      );
      if (image == null) {
        return;
      }
      if (mounted) setState(() => _isProcessing = true);
      await _processImage(image.path);
    } catch (e) {
      final errStr = e.toString().toLowerCase();
      if (errStr.contains('cancel') || errStr.contains('cancelled') || errStr.contains('canceled') || errStr.contains('already_active')) {
        return;
      }
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _pickSampleReceipt() async {
    try {
      setState(() => _isProcessing = true);
      const assetPath = 'assets/sample_receipts/sample_winmart.jpg';
      final byteData = await rootBundle.load(assetPath);
      final tempDir = await getTemporaryDirectory();
      final tempFile = File(p.join(tempDir.path, 'sample_winmart_temp.jpg'));
      await tempFile.writeAsBytes(byteData.buffer.asUint8List());

      await _processImage(tempFile.path);
    } catch (e) {
      await _processFallbackSimulation();
    } finally {
      if (mounted) setState(() => _isProcessing = false);
    }
  }

  Future<void> _processFallbackSimulation() async {
    final draft = await _ocrService.processReceiptImage('simulated_receipt.jpg');
    if (!mounted) return;
    final savedTx = await ReceiptReviewDialog.show(context, draft);
    if (savedTx != null) {
      await DatabaseHelper.instance.insertTransaction(savedTx);
      if (mounted) {
        Navigator.of(context).pop(true);
      }
    }
  }

  Future<void> _processImage(String imagePath) async {
    try {
      final draft = await _ocrService.processReceiptImage(imagePath);
      if (!mounted) return;

      final TransactionItem? savedTx = await ReceiptReviewDialog.show(context, draft);
      if (savedTx != null) {
        await DatabaseHelper.instance.insertTransaction(savedTx);
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(tr('scan_saved', {'title': savedTx.title})),
              backgroundColor: AppColors.income,
            ),
          );
          Navigator.of(context).pop(true);
        }
      }
    } catch (e) {
      _showError(tr('scan_error', {'error': '$e'}));
    }
  }

  void _showError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).hideCurrentSnackBar();
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppColors.expense,
        duration: const Duration(seconds: 3),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // Camera Preview or Fallback
          if (_isCameraInitialized && _cameraController != null)
            SizedBox.expand(
              child: CameraPreview(_cameraController!),
            )
          else
            Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(Icons.camera_alt_outlined, size: 48, color: AppColors.textTertiary),
                  const SizedBox(height: 12),
                  Text(
                    tr('connecting_camera'),
                    style: const TextStyle(color: AppColors.textSecondary, fontSize: 14),
                  ),
                ],
              ),
            ),

          // Scan Frame Viewfinder
          Positioned.fill(
            child: IgnorePointer(
              child: Center(
                child: Container(
                  width: MediaQuery.of(context).size.width * 0.82,
                  height: MediaQuery.of(context).size.height * 0.55,
                  decoration: BoxDecoration(
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.white.withOpacity(0.4), width: 1.5),
                  ),
                  child: Stack(
                    children: [
                      Positioned(
                        top: 16,
                        left: 0,
                        right: 0,
                        child: Center(
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                            decoration: BoxDecoration(
                              color: Colors.black.withOpacity(0.6),
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Text(
                              tr('scan_receipt'),
                              style: const TextStyle(color: Colors.white, fontSize: 12),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),

          // Top App Bar Controls
          Positioned(
            top: MediaQuery.of(context).padding.top + 10,
            left: 16,
            right: 16,
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton.filledTonal(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded, color: Colors.white),
                  style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5)),
                ),
                TextButton.icon(
                  onPressed: _pickSampleReceipt,
                  icon: const Icon(Icons.receipt_long, size: 16, color: AppColors.warning),
                  label: Text(tr('sample_bill'), style: const TextStyle(color: Colors.white, fontSize: 13)),
                  style: TextButton.styleFrom(
                    backgroundColor: Colors.black.withOpacity(0.6),
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                ),
                IconButton.filledTonal(
                  onPressed: _toggleFlash,
                  icon: Icon(
                    _isFlashOn ? Icons.flash_on_rounded : Icons.flash_off_rounded,
                    color: _isFlashOn ? AppColors.warning : Colors.white,
                  ),
                  style: IconButton.styleFrom(backgroundColor: Colors.black.withOpacity(0.5)),
                ),
              ],
            ),
          ),

          // Bottom Controls (Gallery, Shutter, Manual Entry)
          Positioned(
            bottom: MediaQuery.of(context).padding.bottom + 20,
            left: 0,
            right: 0,
            child: Column(
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    IconButton(
                      onPressed: _isProcessing ? null : _pickFromGallery,
                      icon: const Icon(Icons.photo_library_outlined, size: 28, color: Colors.white),
                      tooltip: tr('pick_gallery'),
                    ),

                    GestureDetector(
                      onTap: _isProcessing ? null : _captureAndScan,
                      child: Container(
                        width: 76,
                        height: 76,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 3.5),
                        ),
                        child: Center(
                          child: Container(
                            width: 60,
                            height: 60,
                            decoration: const BoxDecoration(
                              shape: BoxShape.circle,
                              color: Colors.white,
                            ),
                          ),
                        ),
                      ),
                    ),

                    IconButton(
                      onPressed: () => Navigator.of(context).pop('MANUAL'),
                      icon: const Icon(Icons.edit_note_rounded, size: 30, color: Colors.white),
                      tooltip: tr('manual_entry'),
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                const Text(
                  'On-device ML Kit OCR',
                  style: TextStyle(color: AppColors.textTertiary, fontSize: 11),
                ),
              ],
            ),
          ),

          if (_isProcessing)
            Container(
              color: Colors.black.withOpacity(0.7),
              child: const Center(
                child: CircularProgressIndicator(color: Colors.white),
              ),
            ),
        ],
      ),
    );
  }
}
