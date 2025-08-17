// app/services/update_service.dart
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:firebase_database/firebase_database.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:dio/dio.dart';
import 'package:path_provider/path_provider.dart';
import 'package:open_filex/open_filex.dart';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:permission_handler/permission_handler.dart';
import 'package:get/get.dart';
import 'package:archive/archive_io.dart';
import 'package:phone_auto_portal/data/firebaseManager.dart'; // Quan trọng: để làm việc với file ZIP

class UpdateService {
  final DatabaseReference _dbRef =
      FirebaseDatabase.instance.ref('/PORTAL/AppVersion/app_update_info');
  bool _isCheckingUpdate = false;
  bool _isDownloading = false;

  Future<List<String>> _getDeviceSupportedAbis() async {
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      print("Device Supported ABIs: ${androidInfo.supportedAbis}");
      return androidInfo.supportedAbis;
    }
    return [];
  }

  String? _selectUpdateUrlForAbi(
      Map<dynamic, dynamic> abisData, List<String> deviceAbis) {
    // Ưu tiên các ABI cụ thể mà thiết bị hỗ trợ, theo thứ tự ưu tiên của thiết bị
    for (String abi in deviceAbis) {
      if (abisData.containsKey(abi) && abisData[abi] is Map) {
        final abiInfo = abisData[abi] as Map<dynamic, dynamic>;
        if (abiInfo.containsKey('updateFileUrl')) {
          print("Selected ABI: $abi, URL: ${abiInfo['updateFileUrl']}");
          return abiInfo['updateFileUrl'] as String?;
        }
      }
    }

    // Nếu không tìm thấy ABI nào khớp, thử fallback về 'default'
    if (abisData.containsKey('default') && abisData['default'] is Map) {
      final defaultInfo = abisData['default'] as Map<String, dynamic>;
      if (defaultInfo.containsKey('updateFileUrl')) {
        print("Selected ABI: default, URL: ${defaultInfo['updateFileUrl']}");
        return defaultInfo['updateFileUrl'] as String?;
      }
    }

    print(
        "No suitable update URL found for device ABIs: $deviceAbis and available ABIs in DB.");
    return null; // Không tìm thấy URL phù hợp
  }

  Future<void> checkForUpdate() async {
    if (_isCheckingUpdate) return;
    _isCheckingUpdate = true;

    try {
      PackageInfo packageInfo = await PackageInfo.fromPlatform();
      int currentVersionCode = int.parse(packageInfo.buildNumber);
      //tinh chỉnh thông tin phiên bản ví dụ 2015 thì thành 15, 3015 thành 15, 5015 thành 15
      currentVersionCode = currentVersionCode % 100; // Lấy 2 chữ số cuối

      printInfo(info: "Current version code: $currentVersionCode");

      String platformKey = Platform.isAndroid ? "android" : "ios";
      final snapshot = await _dbRef.child(platformKey).get();

      if (snapshot.exists && snapshot.value != null) {
        final data = Map<String, dynamic>.from(snapshot.value as Map);
        int latestVersionCode = data['latestVersionCode'] as int;

        if (latestVersionCode > currentVersionCode) {
          String latestVersionName = data['latestVersionName'] as String;
          String updateNotes = data['updateNotes'] as String? ??
              "Đã có phiên bản mới!\n Hiện tại bạn đang sử dụng bản $currentVersionCode.\nPhiên bản mới nhất là $latestVersionName.\n Vui lòng cập nhật để có trải nghiệm tốt nhất.";
          String? updateUrl; // Sẽ được xác định dựa trên ABI

          if (Platform.isAndroid) {
            if (data.containsKey('abis') && data['abis'] is Map) {
              final abisData = data['abis'] as Map<dynamic, dynamic>;
              List<String> deviceAbis = await _getDeviceSupportedAbis();
              updateUrl = _selectUpdateUrlForAbi(abisData, deviceAbis);
            } else {
              // Cấu trúc cũ không có 'abis', có thể lấy một URL mặc định nếu có
              updateUrl =
                  data['updateFileUrl'] as String? ?? data['apkUrl'] as String?;
              print(
                  "Warning: 'abis' field not found in Firebase. Falling back to old URL structure if available.");
            }
          } else if (Platform.isIOS) {
            updateUrl = data['storeUrl'] as String?;
          }

          if (updateUrl != null && updateUrl.isNotEmpty) {
            _showUpdateDialog(latestVersionName, updateNotes, updateUrl);
          } else {
            print("No suitable update URL found for this device/platform.");
            // Có thể thông báo cho người dùng rằng không có bản cập nhật phù hợp
          }
        } else {
          FirebaseManager().showSnackBar(
            "Bạn đang sử dụng phiên bản mới nhất: $currentVersionCode \n và lastest version code: $latestVersionCode",
          );
          print("App is up to date.");
        }
      } else {
        print("No update info found in Firebase for $platformKey.");
      }
    } catch (e) {
      print("Error checking for update: $e");
    } finally {
      _isCheckingUpdate = false;
    }
  }

  void _showUpdateDialog(String versionName, String notes, String url) {
    Get.dialog(
      AlertDialog(
        title: Text("Cập nhật mới: $versionName"),
        content: SingleChildScrollView(
          child: ListBody(
            children: <Widget>[
              Text("Đã có phiên bản mới ($versionName)!\nNội dung cập nhật:"),
              SizedBox(height: 8),
              Text(notes, style: TextStyle(fontSize: 14)),
            ],
          ),
        ),
        actions: <Widget>[
          TextButton(
            child: Text("Để sau"),
            onPressed: () => Get.back(),
          ),
          TextButton(
            child: Text("Cập nhật ngay"),
            onPressed: () async {
              Get.back();
              if (Platform.isAndroid) {
                await _downloadAndInstallUpdate(url); // Gọi hàm mới
              }
            },
          ),
        ],
      ),
      barrierDismissible: false,
    );
  }

  Future<void> _downloadAndInstallUpdate(String zipFileUrl) async {
    if (_isDownloading) {
      Get.snackbar("Thông báo", "Đang xử lý bản cập nhật...",
          snackPosition: SnackPosition.BOTTOM);
      return;
    }
    _isDownloading = true;

    // 1. Xin quyền (quan trọng cho Android 8+)
    if (Platform.isAndroid) {
      DeviceInfoPlugin deviceInfo = DeviceInfoPlugin();
      AndroidDeviceInfo androidInfo = await deviceInfo.androidInfo;
      if (androidInfo.version.sdkInt >= 26) {
        // Android Oreo (API 26) trở lên
        var status = await Permission.requestInstallPackages.status;
        if (!status.isGranted) {
          status = await Permission.requestInstallPackages.request();
          if (!status.isGranted) {
            _isDownloading = false;
            Get.snackbar("Yêu cầu quyền",
                "Cần cấp quyền cài đặt ứng dụng không rõ nguồn gốc.",
                snackPosition: SnackPosition.BOTTOM,
                duration: const Duration(seconds: 5),
                mainButton: TextButton(
                    onPressed: () => openAppSettings(),
                    child: const Text("Mở Cài đặt")));
            return;
          }
        }
      }
    }

    final Directory tempDir = await getTemporaryDirectory();
    final String zipSavePath = "${tempDir.path}/app-update.zip";
    final String extractDirPath = "${tempDir.path}/extracted_update";
    File? apkFileToInstall;

    try {
      final dio = Dio();
      CancelToken cancelToken = CancelToken();

      // Thông báo bắt đầu tải
      Get.snackbar("Đang tải", "Đang tải xuống bản cập nhật...",
          snackPosition: SnackPosition.BOTTOM,
          showProgressIndicator: true,
          progressIndicatorBackgroundColor: Colors.grey,
          progressIndicatorValueColor:
              AlwaysStoppedAnimation<Color>(Get.theme.primaryColor),
          duration:
              const Duration(minutes: 10) // Thời gian chờ tối đa cho snackbar
          );

      // 2. Tải file ZIP
      await dio.download(
        zipFileUrl,
        zipSavePath,
        cancelToken: cancelToken,
        onReceiveProgress: (received, total) {
          if (total != -1) {
            print(
                "Download Progress: ${(received / total * 100).toStringAsFixed(0)}%");
            // Có thể cập nhật UI nếu cần, GetX snackbar có progress indicator rồi
          }
        },
      );

      if (Get.isSnackbarOpen) Get.back(); // Đóng snackbar tải xuống

      // 3. Giải nén file ZIP
      Get.snackbar("Đang xử lý", "Tải xuống hoàn tất. Đang giải nén...",
          snackPosition: SnackPosition.BOTTOM,
          duration: const Duration(seconds: 20));

      final inputStream = InputFileStream(zipSavePath);
      final archive = ZipDecoder().decodeStream(inputStream);
      final extractDir = Directory(extractDirPath);

      if (await extractDir.exists()) {
        await extractDir.delete(
            recursive: true); // Xóa thư mục giải nén cũ nếu có
      }
      await extractDir.create(recursive: true);

      for (final file in archive.files) {
        if (file.isFile && file.name.toLowerCase().endsWith('.apk')) {
          final outputStream = OutputFileStream("$extractDirPath/${file.name}");
          file.writeContent(outputStream);
          outputStream.flush(); // Ép dữ liệu được ghi xuống đĩa
          await outputStream.close(); // Đóng
          apkFileToInstall = File("$extractDirPath/${file.name}");
          print("APK extracted to: ${apkFileToInstall.path}");
          break; // Giả sử chỉ có một file APK hoặc lấy file đầu tiên
        }
      }
      inputStream.close(); // Đóng stream sau khi đọc xong

      if (Get.isSnackbarOpen) Get.back(); // Đóng snackbar giải nén

      // 4. Cài đặt file APK
      if (apkFileToInstall != null && await apkFileToInstall.exists()) {
        // Thử thêm delay nhỏ
        Get.snackbar(
            "Sẵn sàng cài đặt", "Giải nén hoàn tất. Đang mở trình cài đặt...",
            snackPosition: SnackPosition.BOTTOM);
        await Future.delayed(
            const Duration(milliseconds: 500)); // Ví dụ: 0.5 giây
        final OpenResult result = await OpenFilex.open(apkFileToInstall.path);
        print('OpenFile result: ${result.type} - ${result.message}');

        if (result.type != ResultType.done &&
            result.type != ResultType.noAppToOpen) {
          // ResultType.noAppToOpen có thể xảy ra nếu không có trình cài đặt (hiếm)
          // hoặc trên một số trình giả lập không hỗ trợ mở file APK trực tiếp.
          // ResultType.done thường là thành công khi đã chuyển sang trình cài đặt hệ thống.
          Get.snackbar(
              "Lỗi cài đặt", "Không thể mở file cài đặt: ${result.message}",
              snackPosition: SnackPosition.BOTTOM);
        }
      } else {
        Get.snackbar(
            "Lỗi giải nén", "Không tìm thấy file APK trong bản cập nhật (ZIP).",
            snackPosition: SnackPosition.BOTTOM);
      }
    } catch (e) {
      if (Get.isSnackbarOpen) Get.back(); // Đóng bất kỳ snackbar nào đang mở
      print("Error during update process: $e");
      if (e is DioException && e.type == DioExceptionType.cancel) {
        Get.snackbar("Đã hủy", "Việc tải xuống bản cập nhật đã bị hủy.",
            snackPosition: SnackPosition.BOTTOM);
      } else {
        Get.snackbar("Lỗi", "Lỗi trong quá trình cập nhật: $e",
            snackPosition: SnackPosition.BOTTOM,
            backgroundColor: Colors.red,
            colorText: Colors.white);
      }
    } finally {
      _isDownloading = false;
      // 5. Dọn dẹp
      try {
        // final zipFile = File(zipSavePath);
        // if (await zipFile.exists()) {
        //   await zipFile.delete();
        //   print("Deleted ZIP file: $zipSavePath");
        // }
        // final extractedDir = Directory(extractDirPath);
        // if (await extractedDir.exists()) {
        //   await extractedDir.delete(recursive: true);
        //   print("Deleted extracted update directory: $extractDirPath");
        // }
      } catch (e) {
        print("Error during cleanup: $e");
      }
    }
  }
}
