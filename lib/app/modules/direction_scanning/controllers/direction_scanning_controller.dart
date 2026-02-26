import 'dart:async';
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:just_audio/just_audio.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/barcode_scanner_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';

class DirectionScanningController extends GetxController {
  // Data passed from PortalInfo
  final selectedPortalIds = <String>[].obs;
  final allMaHieus = <StateMaHieu>[].obs;
  late List<StateMaHieu> _originalMaHieus = []; // Backup dữ liệu gốc để restore

  // Direction-based scanning
  final selectedDirection = "".obs;
  final isDirectionScanActive = false.obs;
  final currentScanSession = Rxn<DirectionScanSession>();
  final scannedPackagesInSession = <ScannedPackage>[].obs;

  // Packages organized by direction for quick lookup
  final packagesByDirection = <String, List<StateMaHieu>>{}.obs;

  // Direction names
  final availableDirections = ['RA', 'VÔ', 'Quảng Nam', 'Quảng Ngãi'].obs;

  // Mobile Scanner Controller
  MobileScannerController? mobileScannerController;
  StreamSubscription<BarcodeCapture>? _barcodeSubscription;

  // Camera state tracking
  final isCameraInitialized = false.obs;
  final isCameraStarted = false.obs;

  // Province data
  Map<String, dynamic>? _provinceData;
  final isDataPrepared = false.obs;
  final isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();

    // Get data from arguments
    final args = Get.arguments as Map<String, dynamic>?;
    if (args != null) {
      // Handle packages argument (List<StateMaHieu>)
      if (args['packages'] != null) {
        allMaHieus.value = List<StateMaHieu>.from(args['packages']);
      }

      // Handle selectedPortals argument and extract IDs
      if (args['selectedPortals'] != null) {
        final portals = args['selectedPortals'] as List;
        // Use dynamic access since we don't know the exact type
        selectedPortalIds.value = portals
            .map((portal) {
              // Portal object should have 'id' field
              if (portal.id != null) {
                return portal.id.toString();
              }
              return '';
            })
            .where((id) => id.isNotEmpty)
            .toList();
      }

      print('DirectionScanningController received:');
      print('- allMaHieus count: ${allMaHieus.length}');
      print('- selectedPortalIds: $selectedPortalIds');
      print(
          '- First few packages: ${allMaHieus.take(3).map((p) => p.code).toList()}');
    }

    // Backup dữ liệu gốc để có thể restore khi quét lại
    _originalMaHieus = List.from(allMaHieus);

    // Auto prepare data when initialized
    if (allMaHieus.isNotEmpty) {
      prepareDirectionData();
    } else {
      print('⚠️ No allMaHieus data to prepare');
    }
  }

  @override
  void onClose() {
    _barcodeSubscription?.cancel();
    isDirectionScanActive.value = false;
    currentScanSession.value = null;
    scannedPackagesInSession.clear();

    // Stop camera if started
    if (isCameraStarted.value) {
      try {
        mobileScannerController?.stop();
        isCameraStarted.value = false;
      } catch (e) {
        print('❌ Error stopping camera in onClose: $e');
      }
    }

    // Dispose camera if initialized
    if (isCameraInitialized.value) {
      try {
        mobileScannerController?.dispose();
        isCameraInitialized.value = false;
      } catch (e) {
        print('❌ Error disposing camera in onClose: $e');
      }
    }

    mobileScannerController = null;
    super.onClose();
  }

  /// Load province data from JSON
  Future<void> _loadProvinceData() async {
    if (_provinceData == null) {
      try {
        final String jsonString =
            await rootBundle.loadString('assets/tinhthanh.json');
        _provinceData = jsonDecode(jsonString);
      } catch (e) {
        print('Error loading province data: $e');
        _provinceData = {'vo': [], 'ra': []};
      }
    }
  }

  /// Chuẩn bị dữ liệu cho việc quét theo hướng
  Future<void> prepareDirectionData() async {
    isLoading.value = true;
    print('🔍 Starting prepareDirectionData...');
    print('🔍 allMaHieus count: ${allMaHieus.length}');

    try {
      await _loadProvinceData();
      packagesByDirection.clear();

      if (_provinceData == null) {
        print('❌ Province data is null');
        isLoading.value = false;
        return;
      }

      print('✅ Province data loaded');

      // Extract province codes
      final Set<String> voCodes = <String>{};
      final Set<String> raCodes = <String>{};
      final Set<String> quangNamCodes = <String>{};
      final Set<String> quangNgaiCodes = <String>{};

      // Process province codes
      if (_provinceData!['vo'] != null) {
        for (final province in _provinceData!['vo']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              voCodes.add(code.toString());
            }
          }
        }
      }

      if (_provinceData!['ra'] != null) {
        for (final province in _provinceData!['ra']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              raCodes.add(code.toString());
            }
          }
        }
      }

      if (_provinceData!['quangnam'] != null) {
        for (final province in _provinceData!['quangnam']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              quangNamCodes.add(code.toString());
            }
          }
        }
      }

      if (_provinceData!['quangngai'] != null) {
        for (final province in _provinceData!['quangngai']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              quangNgaiCodes.add(code.toString());
            }
          }
        }
      }

      print('🔍 Province codes loaded:');
      print('  - RA codes: ${raCodes.length}');
      print('  - VÔ codes: ${voCodes.length}');
      print('  - Quảng Nam codes: ${quangNamCodes.length}');
      print('  - Quảng Ngãi codes: ${quangNgaiCodes.length}');

      // Phân loại packages theo hướng
      packagesByDirection['RA'] = [];
      packagesByDirection['VÔ'] = [];
      packagesByDirection['Quảng Nam'] = [];
      packagesByDirection['Quảng Ngãi'] = [];

      for (final item in allMaHieus) {
        if (item.provinceCode == null || item.provinceCode!.isEmpty) continue;

        final provinceCode = item.provinceCode!.trim();

        if (raCodes.contains(provinceCode)) {
          packagesByDirection['RA']!.add(item);
        }
        if (voCodes.contains(provinceCode)) {
          packagesByDirection['VÔ']!.add(item);
        }
        if (quangNamCodes.contains(provinceCode)) {
          packagesByDirection['Quảng Nam']!.add(item);
        }
        if (quangNgaiCodes.contains(provinceCode)) {
          packagesByDirection['Quảng Ngãi']!.add(item);
        }
      }

      print('🔍 Packages distribution:');
      print('  - RA: ${packagesByDirection['RA']?.length ?? 0}');
      print('  - VÔ: ${packagesByDirection['VÔ']?.length ?? 0}');
      print('  - Quảng Nam: ${packagesByDirection['Quảng Nam']?.length ?? 0}');
      print(
          '  - Quảng Ngãi: ${packagesByDirection['Quảng Ngãi']?.length ?? 0}');

      isDataPrepared.value = true;
      print(
          '✅ Data preparation completed, isDataPrepared: ${isDataPrepared.value}');

      Get.snackbar(
        'Thành công',
        'Đã chuẩn bị dữ liệu theo hướng',
        backgroundColor: Colors.green,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } catch (e) {
      print('❌ Error in prepareDirectionData: $e');
      Get.snackbar(
        'Lỗi',
        'Không thể chuẩn bị dữ liệu: $e',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        snackPosition: SnackPosition.BOTTOM,
      );
    } finally {
      isLoading.value = false;
      print('🔍 prepareDirectionData completed, isLoading: ${isLoading.value}');
    }
  }

  /// Bắt đầu quét barcode cho hướng đã chọn
  Future<void> startDirectionScan(String direction) async {
    if (direction.isEmpty) {
      Get.snackbar('Lỗi', 'Vui lòng chọn hướng trước khi quét');
      return;
    }

    if (!isDataPrepared.value) {
      Get.snackbar('Lỗi', 'Vui lòng chuẩn bị dữ liệu trước khi quét');
      return;
    }

    selectedDirection.value = direction;
    isDirectionScanActive.value = true;

    // Reset scan session để tránh duplicate check với session cũ
    scannedPackagesInSession.clear();
    
    // QUAN TRỌNG: Reset packagesByDirection để có thể quét lại
    // Rebuild từ allMaHieus nếu có dữ liệu gốc
    await _rebuildPackagesByDirection();

    // Tạo session mới
    currentScanSession.value = DirectionScanSession(
      direction: direction,
      startTime: DateTime.now(),
      scannedPackages: [],
      totalPackagesInDirection: packagesByDirection[direction]?.length ?? 0,
    );

    print('🎯 Starting scan session for direction: $direction');
    print(
        '🎯 Total packages in this direction: ${packagesByDirection[direction]?.length ?? 0}');

    // Khởi tạo mobile scanner với proper state management
    try {
      // Stop existing scanner if any
      await _stopCameraIfActive();

      _barcodeSubscription?.cancel();

      mobileScannerController = MobileScannerController(
        detectionSpeed: DetectionSpeed.noDuplicates,
        formats: [
          BarcodeFormat.qrCode,
          BarcodeFormat.code128,
          BarcodeFormat.code39
        ],
        facing: CameraFacing.back,
        torchEnabled: false,
        returnImage: false,
        detectionTimeoutMs: 500,
        autoStart: false, // Không tự động start
      );

      isCameraInitialized.value = true;

      _barcodeSubscription =
          mobileScannerController?.barcodes.listen((BarcodeCapture capture) {
        final List<Barcode> barcodes = capture.barcodes;
        for (final barcode in barcodes) {
          final String? code = barcode.rawValue;
          if (code != null && code.isNotEmpty) {
            _processDirectionScanResult(code.trim().toUpperCase());
          }
        }
      });

      _showDirectionScannerDialog();

      // Start camera sau khi dialog đã hiển thị với proper state checking
      Future.delayed(const Duration(milliseconds: 500), () async {
        await _startCameraIfNotActive();
      });
    } catch (e) {
      Get.snackbar(
        'Lỗi',
        'Không thể khởi động camera: ${e.toString()}',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      isDirectionScanActive.value = false;
    }
  }

  /// Reset packagesByDirection để có thể quét lại
  /// Rebuild từ _originalMaHieus (backup dữ liệu gốc)
  Future<void> _rebuildPackagesByDirection() async {
    try {
      // Reset các list packages theo hướng
      for (final direction in availableDirections) {
        packagesByDirection[direction] = [];
      }

      // Restore allMaHieus từ backup gốc
      allMaHieus.value = List.from(_originalMaHieus);
      print('✅ Restored allMaHieus from backup (${allMaHieus.length} items)');

      // Rebuild từ allMaHieus
      if (_provinceData == null) {
        await _loadProvinceData();
      }

      if (_provinceData == null) {
        print('❌ Cannot rebuild - province data is null');
        return;
      }

      // Extract province codes từ data
      final Set<String> voCodes = <String>{};
      final Set<String> raCodes = <String>{};
      final Set<String> quangNamCodes = <String>{};
      final Set<String> quangNgaiCodes = <String>{};

      if (_provinceData!['vo'] != null) {
        for (final province in _provinceData!['vo']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              voCodes.add(code.toString());
            }
          }
        }
      }

      if (_provinceData!['ra'] != null) {
        for (final province in _provinceData!['ra']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              raCodes.add(code.toString());
            }
          }
        }
      }

      if (_provinceData!['quangnam'] != null) {
        for (final province in _provinceData!['quangnam']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              quangNamCodes.add(code.toString());
            }
          }
        }
      }

      if (_provinceData!['quangngai'] != null) {
        for (final province in _provinceData!['quangngai']) {
          if (province['ma_tinh'] != null) {
            for (final code in province['ma_tinh']) {
              quangNgaiCodes.add(code.toString());
            }
          }
        }
      }

      // Re-classify packages theo hướng từ allMaHieus đã restore
      for (final item in allMaHieus) {
        if (item.provinceCode == null || item.provinceCode!.isEmpty) continue;

        final provinceCode = item.provinceCode!.trim();

        if (raCodes.contains(provinceCode)) {
          packagesByDirection['RA']!.add(item);
        }
        if (voCodes.contains(provinceCode)) {
          packagesByDirection['VÔ']!.add(item);
        }
        if (quangNamCodes.contains(provinceCode)) {
          packagesByDirection['Quảng Nam']!.add(item);
        }
        if (quangNgaiCodes.contains(provinceCode)) {
          packagesByDirection['Quảng Ngãi']!.add(item);
        }
      }

      print('✅ Rebuilt packagesByDirection');
      print('  - RA: ${packagesByDirection['RA']?.length ?? 0}');
      print('  - VÔ: ${packagesByDirection['VÔ']?.length ?? 0}');
      print('  - Quảng Nam: ${packagesByDirection['Quảng Nam']?.length ?? 0}');
      print(
          '  - Quảng Ngãi: ${packagesByDirection['Quảng Ngãi']?.length ?? 0}');
    } catch (e) {
      print('❌ Error rebuilding packagesByDirection: $e');
    }
  }

  /// Kiểm tra tính hợp lệ của mã hiệu
  /// Quy tắc:
  /// - 13 ký tự
  /// - Chữ cái đầu tiên chỉ là C hoặc E
  /// - 2 chữ cái cuối cùng là VN
  /// - Từ vị trí 2 đến trước VN là số
  bool _isValidBarcodeFormat(String barcode) {
    // Kiểm tra độ dài
    if (barcode.length != 13) {
      return false;
    }

    // Kiểm tra chữ cái đầu tiên (C hoặc E)
    final firstChar = barcode[0].toUpperCase();
    if (firstChar != 'C' && firstChar != 'E') {
      return false;
    }

    // Kiểm tra 2 chữ cái cuối cùng (VN)
    final lastTwoChars = barcode.substring(11, 13).toUpperCase();
    if (lastTwoChars != 'VN') {
      return false;
    }

    // Kiểm tra từ vị trí 2 đến trước VN (vị trí 1-10) là số
    final middlePart = barcode.substring(2, 11);
    final isAllDigits = RegExp(r'^\d+$').hasMatch(middlePart);
    if (!isAllDigits) {
      return false;
    }

    return true;
  }

  /// Public method để test validation (có thể dùng trong debugging)
  bool isValidBarcode(String barcode) {
    return _isValidBarcodeFormat(barcode);
  }

  /// Xử lý kết quả quét cho direction scanning
  Future<void> _processDirectionScanResult(String barcode) async {
    if (!isDirectionScanActive.value || selectedDirection.value.isEmpty) return;

    // Kiểm tra format mã hiệu trước khi xử lý
    if (!_isValidBarcodeFormat(barcode)) {
      return;
    }

    // Kiểm tra mã hiệu đã quét trước đó (tránh duplicate)
    final alreadyScanned =
        scannedPackagesInSession.any((pkg) => pkg.barcode == barcode);
    if (alreadyScanned) {
      print('🔍 Barcode $barcode already scanned, skipping...');
      // Feedback nhẹ để người dùng biết mã đã quét
      return; // Bỏ qua không xử lý nữa
    }

    final currentDir = selectedDirection.value;

    // Kiểm tra trong hướng hiện tại
    final currentDirPackages = packagesByDirection[currentDir] ?? [];
    final foundInCurrent = currentDirPackages.any((pkg) => pkg.code == barcode);

    String? foundInDirection;

    // Nếu không có trong hướng hiện tại, kiểm tra các hướng khác
    if (!foundInCurrent) {
      for (final entry in packagesByDirection.entries) {
        if (entry.key != currentDir) {
          final hasPackage = entry.value.any((pkg) => pkg.code == barcode);
          if (hasPackage) {
            foundInDirection = entry.key;
            break;
          }
        }
      }
    }

    // Tạo ScannedPackage object
    final scannedPackage = ScannedPackage(
      barcode: barcode,
      scannedTime: DateTime.now(),
      foundInDirection: foundInDirection,
      isFoundInCurrentDirection: foundInCurrent,
      currentDirection: currentDir,
    );

    // Thêm vào danh sách
    scannedPackagesInSession.add(scannedPackage);
    currentScanSession.value?.scannedPackages.add(scannedPackage);

    if (foundInCurrent) {
      // Xóa khỏi danh sách hướng hiện tại
      currentDirPackages.removeWhere((pkg) => pkg.code == barcode);
      allMaHieus.removeWhere((pkg) => pkg.code == barcode);

      // Cập nhật số lượng đã xử lý và trigger reactive update
      if (currentScanSession.value != null) {
        currentScanSession.value!.processedCount++;
        currentScanSession.refresh(); // Trigger reactive update
      }

      // Feedback tích cực
      HapticFeedback.lightImpact();

      // Phát âm thanh đọc số dựa vào số lượng đã xử lý
      final processedCount = currentScanSession.value?.processedCount ?? 0;
      final audioPath = processedCount < 100
          ? "assets/$processedCount.wav"
          : "assets/beep.mp3";
      await _playAudio(audioPath);
    } else {
      // Feedback cho trường hợp không tìm thấy hoặc sai hướng
      HapticFeedback.heavyImpact();
      _playAudio("assets/lachuong.mp3");
    }

    update();
  }

  Future<void> _playAudio(String path) async {
    try {
      await _audioPlayer.setAsset(path);
      await _audioPlayer.play();
    } catch (e) {
      // Ignore audio errors
    }
  }

  // Audio Player
  final AudioPlayer _audioPlayer = AudioPlayer();

  /// Helper method để stop camera nếu đang active
  Future<void> _stopCameraIfActive() async {
    if (isCameraStarted.value && mobileScannerController != null) {
      try {
        await mobileScannerController!.stop();
        isCameraStarted.value = false;
        print('📷 Camera stopped successfully');
      } catch (e) {
        print('❌ Error stopping camera: $e');
      }
    }
  }

  /// Helper method để start camera nếu chưa active
  Future<void> _startCameraIfNotActive() async {
    if (!isCameraStarted.value &&
        isCameraInitialized.value &&
        mobileScannerController != null) {
      try {
        await mobileScannerController!.start();
        isCameraStarted.value = true;
        print('📷 Camera started successfully');
      } catch (e) {
        print('❌ Error starting camera: $e');
        // Nếu lỗi start, thử reset controller
        await _resetCameraController();
      }
    }
  }

  /// Helper method để reset camera controller
  Future<void> _resetCameraController() async {
    try {
      print('🔄 Resetting camera controller...');

      // Stop nếu đang chạy
      if (isCameraStarted.value) {
        try {
          await mobileScannerController?.stop();
        } catch (e) {
          print('❌ Error stopping during reset: $e');
        }
      }

      // Dispose nếu đã khởi tạo
      if (isCameraInitialized.value) {
        try {
          await mobileScannerController?.dispose();
        } catch (e) {
          print('❌ Error disposing during reset: $e');
        }
      }

      // Reset states
      isCameraStarted.value = false;
      isCameraInitialized.value = false;
      mobileScannerController = null;

      print('✅ Camera controller reset completed');
    } catch (e) {
      print('❌ Error during camera reset: $e');
    }
  }

  /// Hiển thị dialog quét barcode theo hướng
  void _showDirectionScannerDialog() {
    Get.dialog(
      Dialog(
        child: Container(
          width: 350,
          height: 600,
          padding: const EdgeInsets.all(16),
          child: Column(
            children: [
              // Header
              Text(
                'Quét ${selectedDirection.value}',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),

              // Progress info
              Obx(() {
                final session = currentScanSession.value;
                if (session == null) return const SizedBox();

                return Column(
                  children: [
                    Text(
                      'Tiến độ: ${session.processedCount}/${session.totalPackagesInDirection}',
                      style: const TextStyle(fontSize: 16),
                    ),
                    const SizedBox(height: 8),
                    LinearProgressIndicator(
                      value: session.progress / 100,
                      backgroundColor: Colors.grey[300],
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.blue),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      '${session.progress.toStringAsFixed(1)}% hoàn thành',
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                );
              }),

              const SizedBox(height: 16),

              // Camera preview
              Expanded(
                flex: 3,
                child: Container(
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: mobileScannerController != null
                        ? MobileScanner(
                            controller: mobileScannerController!,
                            fit: BoxFit.cover,
                            errorBuilder: (context, error, child) {
                              return Container(
                                color: Colors.black,
                                child: Center(
                                  child: Column(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.camera_alt_outlined,
                                        color: Colors.white,
                                        size: 64,
                                      ),
                                      const SizedBox(height: 16),
                                      Text(
                                        'Lỗi camera: ${error.toString()}',
                                        style: const TextStyle(
                                            color: Colors.white),
                                        textAlign: TextAlign.center,
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            },
                          )
                        : const Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                CircularProgressIndicator(),
                                SizedBox(height: 16),
                                Text('Đang khởi động camera...'),
                              ],
                            ),
                          ),
                  ),
                ),
              ),

              const SizedBox(height: 16),

              // Scanned items list
              Expanded(
                flex: 2,
                child: Obx(() {
                  if (scannedPackagesInSession.isEmpty) {
                    return const Center(
                      child: Text('Chưa quét bưu gửi nào'),
                    );
                  }

                  return ListView.builder(
                    itemCount: scannedPackagesInSession.length,
                    itemBuilder: (context, index) {
                      final pkg = scannedPackagesInSession[
                          scannedPackagesInSession.length - 1 - index];
                      return ListTile(
                        dense: true,
                        leading: Icon(
                          pkg.isFoundInCurrentDirection
                              ? Icons.check_circle
                              : Icons.error,
                          color: pkg.statusColor,
                          size: 20,
                        ),
                        title: Text(
                          pkg.barcode,
                          style: const TextStyle(fontSize: 12),
                        ),
                        subtitle: Text(
                          pkg.statusText,
                          style: TextStyle(
                            fontSize: 10,
                            color: pkg.statusColor,
                          ),
                        ),
                      );
                    },
                  );
                }),
              ),

              const SizedBox(height: 16),

              // Control buttons
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: [
                  ElevatedButton(
                    onPressed: _stopDirectionScan,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.red,
                      foregroundColor: Colors.white,
                    ),
                    child: const Text('Dừng'),
                  ),
                  IconButton(
                    onPressed: () {
                      mobileScannerController?.toggleTorch();
                    },
                    icon: const Icon(Icons.flash_on),
                  ),
                  ElevatedButton(
                    onPressed: showScanResults,
                    child: const Text('Kết quả'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
      barrierDismissible: false,
    );
  }

  /// Dừng quét barcode theo hướng
  void _stopDirectionScan() async {
    isDirectionScanActive.value = false;
    _barcodeSubscription?.cancel();

    // Stop camera properly với state management
    await _stopCameraIfActive();

    // Dispose camera với delay
    Future.delayed(const Duration(milliseconds: 300), () async {
      await _resetCameraController();
    });

    Get.back(); // Đóng dialog scanner

    // Hiển thị kết quả
    if (scannedPackagesInSession.isNotEmpty) {
      showScanResults();
    }
  }

  /// Hiển thị kết quả quét
  void showScanResults() {
    final session = currentScanSession.value;
    if (session == null) return;

    Get.dialog(
      AlertDialog(
        title: Text('Kết quả quét ${session.direction}'),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Tổng quan
              Text('Tổng số quét: ${session.scannedPackages.length}'),
              Text('Xử lý thành công: ${session.processedPackages.length}'),
              Text('Không tìm thấy: ${session.notFoundPackages.length}'),
              Text('Tiến độ: ${session.progress.toStringAsFixed(1)}%'),

              const SizedBox(height: 16),
              const Text('Chi tiết:',
                  style: TextStyle(fontWeight: FontWeight.bold)),

              // Danh sách chi tiết
              ...session.scannedPackages
                  .map((pkg) => ListTile(
                        dense: true,
                        leading: Icon(
                          pkg.isFoundInCurrentDirection
                              ? Icons.check_circle
                              : Icons.error,
                          color: pkg.statusColor,
                          size: 16,
                        ),
                        title: Text(pkg.barcode,
                            style: const TextStyle(fontSize: 12)),
                        subtitle: Text(pkg.statusText,
                            style: TextStyle(
                                fontSize: 10, color: pkg.statusColor)),
                      ))
                  .toList(),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
          if (session.notFoundPackages.isNotEmpty)
            TextButton(
              onPressed: () {
                _exportNotFoundPackages(session.notFoundPackages);
              },
              child: const Text('Xuất danh sách lỗi'),
            ),
        ],
      ),
    );
  }

  /// Xuất danh sách bưu gửi không tìm thấy
  void _exportNotFoundPackages(List<ScannedPackage> notFoundPackages) {
    final content = notFoundPackages.map((pkg) {
      return '${pkg.barcode} - ${pkg.statusText}';
    }).join('\n');

    Get.dialog(
      AlertDialog(
        title: const Text('Danh sách bưu gửi không tìm thấy'),
        content: SingleChildScrollView(
          child: SelectableText(content),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
        ],
      ),
    );
  }

  /// Hiển thị danh sách bưu gửi còn lại chưa quét
  void showRemainingPackages() {
    final session = currentScanSession.value;
    if (session == null) {
      Get.snackbar(
        'Lỗi',
        'Không có phiên quét đang hoạt động',
        backgroundColor: Colors.red,
        colorText: Colors.white,
      );
      return;
    }

    final direction = session.direction;
    final remainingPackages = packagesByDirection[direction] ?? [];

    if (remainingPackages.isEmpty) {
      Get.snackbar(
        'Thông báo',
        'Đã quét xong tất cả bưu gửi trong hướng $direction!',
        backgroundColor: Colors.green,
        colorText: Colors.white,
      );
      return;
    }

    // Tạo nội dung hiển thị
    final buffer = StringBuffer();
    buffer.writeln('📋 DANH SÁCH BƯU GỬI CÒN LẠI');
    buffer.writeln('Hướng: $direction');
    buffer.writeln('Số lượng: ${remainingPackages.length}');
    buffer.writeln(
        'Tiến độ: ${session.processedCount}/${session.totalPackagesInDirection}');
    buffer.writeln('');
    buffer.writeln('═══════════════════════════');
    buffer.writeln('');

    for (int i = 0; i < remainingPackages.length; i++) {
      final pkg = remainingPackages[i];
      buffer.writeln('${i + 1}. ${pkg.code}');
      if (pkg.provinceCode != null && pkg.provinceCode!.isNotEmpty) {
        buffer.writeln('   📍 Mã tỉnh: ${pkg.provinceCode}');
      }
      buffer.writeln('');
    }

    Get.dialog(
      AlertDialog(
        title: Text(
          'BG Còn Lại - $direction',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: SizedBox(
          width: double.maxFinite,
          height: 400,
          child: SingleChildScrollView(
            child: SelectableText(
              buffer.toString(),
              style: const TextStyle(
                fontFamily: 'monospace',
                fontSize: 12,
              ),
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Đóng'),
          ),
          TextButton(
            onPressed: () {
              // Copy to clipboard
              Clipboard.setData(ClipboardData(text: buffer.toString()));
              Get.back();
              Get.snackbar(
                'Thành công',
                'Đã copy danh sách vào clipboard',
                backgroundColor: Colors.green,
                colorText: Colors.white,
              );
            },
            child: const Text('Copy'),
          ),
        ],
      ),
    );
  }

  /// Quay về trang Portal Info
  void goBack() {
    Get.back();
  }
}
