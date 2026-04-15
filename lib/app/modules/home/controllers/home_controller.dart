import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';
import 'package:image_picker/image_picker.dart';

import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/khoi_tao_moi/controllers/khoi_tao_moi_controller.dart';

import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';
import 'package:phone_auto_portal/app/modules/home/GeminiChatService.dart';

import 'package:phone_auto_portal/app/modules/home/hopdong_model.dart';
import 'package:phone_auto_portal/app/modules/home/host_info.dart';

import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';
import 'package:phone_auto_portal/app/modules/myview/controllers/myview_controller.dart';

import 'package:phone_auto_portal/data/UpdateService.dart';

import 'package:phone_auto_portal/data/firebaseManager.dart';

import '../../portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';

import '../khach_hangs_model.dart';
import '../user_info.dart';

class HomeController extends GetxController {
  final count = 0.obs;

  final timeUpdate = "".obs;

  final khachHangs = <KhachHangs>[].obs;

  final seKhachHangs = KhachHangs().obs;

  final textMH = "".obs;

  final isHaveHopDong = false.obs;

  final isEditHopDong = false.obs;

  final stateText = "".obs;

  var textMHController = TextEditingController();
  var accountTE = TextEditingController();
  var passwordTE = TextEditingController();
  late final UpdateService _updateService;

  var addressController = TextEditingController();

  var numberHopDongController = TextEditingController();

  var maKHController = TextEditingController();

  var keyController = TextEditingController();
  var dayLastController = TextEditingController();

  var capcharController = TextEditingController();

  final imageBytes = "".obs;
  final selectedMayChu = HostInfo("maychu").obs;

  // --- Trạng thái Chọn Người dùng ---
  final GetStorage _storage = GetStorage();
  final selectedUser = Rx<UserInfo?>(null);
  final _selectedUserStorageKey =
      'selectedPortalUsername'; // Lưu username đã chọn vào GetStorage
  // --- Kết thúc Trạng thái Chọn Người dùng ---

  final maychus = <HostInfo>[
    HostInfo("maychu"),
    HostInfo("mayphu"),
    HostInfo("mayphusan"),
    HostInfo("maygiaodich 1"),
    HostInfo("maygiaodich 2"),
    HostInfo("maygiaodich 3"),
    HostInfo("maygiaodich 4"),
    HostInfo("maygiaodich 5"),
    HostInfo("maytest"),
  ].obs;
  var lastSelectKH = "";
  late GeminiChatService geminiSevice;
  @override
  Future<void> onReady() async {
    // khachHangs.clear();

    keyController.text = GetStorage().read("key") ?? "mayphu";
    dayLastController.text = GetStorage().read("day") ?? 2.toString();
    selectedMayChu.value = HostInfo(keyController.text);

    // var temps = await FirebaseManager().getKhachHangs();

    numberHopDongController.text = "0";
    accountTE.text = GetStorage().read("account") ?? "";
    passwordTE.text = GetStorage().read("password") ?? "";
    sendPing();
    initializeData();
    listenForSelectedUserChanges();
    // if (temps.isNotEmpty) {

    //   seKhachHangs.value = temps[0];

    //   khachHangs.addAll(temps);

    // }

    super.onReady();
    _updateService = Get.find<UpdateService>();
    _checkAppUpdate();
    geminiSevice = GeminiChatService(apiUrl: _apiUrl.toString());
  }

  Future<void> _checkAppUpdate() async {
    // Có thể thêm một chút delay nếu cần, để tránh xung đột với các tác vụ khởi tạo khác
    // await Future.delayed(Duration(seconds: 2));
    await _updateService.checkForUpdate();
  }

  // Hàm khởi tạo gộp
  Future<void> initializeData() async {
    loadSelectedUserFromStorage(); // Tải lựa chọn từ bộ nhớ cục bộ
  }

  // Tải thông tin user đã lưu từ GetStorage
  void loadSelectedUserFromStorage() {
    final String? savedUsername =
        GetStorage().read<String>(_selectedUserStorageKey);
    final String? savedPassword =
        GetStorage().read<String>('selectedPortalPassword');

    if (savedUsername != null && savedUsername.isNotEmpty) {
      selectedUser.value = UserInfo(
        name: savedUsername,
        username: savedUsername,
        password: savedPassword ?? '',
      );
    } else {
      // Nếu chưa có gì được lưu, mặc định là "Không chọn"
      selectedUser.value =
          UserInfo(name: 'Không chọn', username: '', password: '');
    }
  }

  void saveSelectedUserToStorage() {
    final usernameToSave = selectedUser.value?.username;
    final passwordToSave = selectedUser.value?.password;

    if (usernameToSave != null && usernameToSave.isNotEmpty) {
      GetStorage().write(_selectedUserStorageKey, usernameToSave);
      GetStorage().write('selectedPortalPassword', passwordToSave ?? '');
      'Đã lưu lựa chọn username: \'$usernameToSave\''.printInfo();
    } else {
      // Xóa nếu username rỗng (đăng xuất)
      _storage.remove(_selectedUserStorageKey);
      _storage.remove('selectedPortalPassword');
    }
  }

  void listenForSelectedUserChanges() {
    // Tự động lưu vào GetStorage khi lựa chọn thay đổi
    ever(selectedUser, (_) => saveSelectedUserToStorage());
  }

  void getPortalData() async {
    imageBytes.value = "";
    //kiểm tra dayLastController có khác 2 không, nếu khác thì save key is day
    if (dayLastController.text != "2" && dayLastController.value != "") {
      GetStorage().write("day", dayLastController.text);
      FirebaseManager().addMessage(MessageReceiveModel(
          "getpns",
          const JsonEncoder().convert(
              {"day": (int.parse(dayLastController.text) * (-1)).toString()})));
    } else {
      FirebaseManager().addMessage(MessageReceiveModel(
          "getpns",
          const JsonEncoder().convert(
            {"day": "-2"},
          )));
    }
    FirebaseManager().showSnackBar("Đang lấy dữ liệu");
    stateText.value = "Đang lấy dữ liệu";
  }

  updateKhachHang() async {
    khachHangs.clear();
    var temps = await FirebaseManager().getKhachHangs();

    if (temps.isNotEmpty) {
      khachHangs.addAll(temps);
      //selected lại khách hàng dựa vào lastSelectKH
      KhachHangs? currentKH;
      if (lastSelectKH.isNotEmpty) {
        var finded = khachHangs
            .firstWhereOrNull((element) => element.maKH == lastSelectKH);

        if (finded != null) {
          currentKH = finded;
        }
      } else {
        currentKH = temps[0];
      }
      if (currentKH != null) {
        seKhachHangs.value = currentKH;
      } else {
        seKhachHangs.value = temps[0];
      }
      checkHopDong(seKhachHangs.value);
      FirebaseManager().showSnackBar('Cập nhật dữ liệu thành công');

      stateText.value = "Cập nhật dữ liệu thành công";
    }
  }

  Future<void> onListenNotification(MessageReceiveModel message) async {
    switch (message.Lenh) {
      case "message":
        stateText.value = message.DoiTuong;
        break;
      case "showcapchar":
        imageBytes.value = message.DoiTuong.split(',')[1];
        stateText.value = "Nhập capchar";
        break;
      case "checkhopdong":
        if (message.DoiTuong == "ok") {
          FirebaseManager().showSnackBar("Chuẩn bị hợp đồng thành công");

          stateText.value = "Chuẩn bị hợp đồng thành công";
        } else {
          stateText.value = message.DoiTuong;
        }
        break;
      case "autologin":
        FirebaseManager().addMessage(MessageReceiveModel(
            "autologin",
            const JsonEncoder().convert(
                {"account": accountTE.text, "password": passwordTE.text})));

        break;
      case "pong":
        printInfo(info: "Pong from ${message.DoiTuong}");
        //tìm kiếm maychus có hostName = message.DoiTuong và thay thế isOnline = true
        var finded = maychus.firstWhereOrNull((element) =>
            element.hostName.toLowerCase() == message.DoiTuong.toLowerCase());
        if (finded != null) {
          finded.isOnline.value = true;
        }
        break;
      case "":
      default:
    }
  }

  Future<void> findKhachHangsByMH(String value) async {
    int countFind = 0;

    KhachHangs? khachHangFinded;

    for (var khachHang in khachHangs) {
      var finded = khachHang.buuGuis!.firstWhereOrNull((element) =>
          element.maBuuGui!.toUpperCase().contains(value.toUpperCase()));

      if (finded != null) {
        countFind++;

        khachHangFinded = khachHang;

        if (countFind > 1) return;
      }
    }

    if (khachHangFinded != null) {
      seKhachHangs.value = khachHangFinded;

      stateText.value = "Tìm thấy ${khachHangFinded.tenKH}";

      textMHController.text = "";
      FocusScope.of(Get.context!).unfocus();
    }
  }

  void goToDetail() {
    var detail = Get.find<DetailController>();
    //nếu lastSelectedMaKH khác null thì kiểm tra có trùng với Ma KH của selectedKH không

    detail.setUp(
      seKhachHangs.value,
      selectedUser.value!.username,
      selectedUser.value!.password,
    );

    Get.toNamed("/detail");
  }

  void goToCreateNew() {
    var createNew = Get.find<CreatenewController>();

    if (seKhachHangs.value.maKH == null) {
      FirebaseManager().showSnackBar("Chưa chọn khách hàng");
      return;
    }
    createNew.setUp(seKhachHangs.value, selectedUser.value!.username,
        selectedUser.value!.password);

    Get.toNamed("/createnew");
  }

  void goToKhoiTaoMoi() {
    var khoiTaoMoi = Get.find<KhoiTaoMoiController>();
    khoiTaoMoi.loadAllSuggestions();
    if (selectedUser.value != null) {
      khoiTaoMoi.setUpGlobal(
          selectedUser.value!.username, selectedUser.value!.password);
    } else {
      khoiTaoMoi.setUpGlobal("", "");
    }

    Get.toNamed("/khoi-tao-moi");
  }

  void goToPrintPage() {
    Get.toNamed("/print-page");
  }

  void editHopDong() {
    isEditHopDong.value = true;
  }

  void saveHopDong() {
    if (isEditHopDong.value) {
      isEditHopDong.value = false;

      FirebaseManager().addHopDong(
          seKhachHangs.value,
          HopDong(
              address: addressController.text,
              maKH: maKHController.text,
              isChooseHopDong: isHaveHopDong.value,
              sTTHopDong: int.parse(numberHopDongController.text)));
    }
  }

  Future<void> checkHopDong(KhachHangs value) async {
    //get hopdong from firebase

    var hopDong = await FirebaseManager().getHopDong(value.maKH!);

    isHaveHopDong.value = hopDong.isChooseHopDong!;

    addressController.text = hopDong.address!;

    numberHopDongController.text = hopDong.sTTHopDong.toString();

    maKHController.text = hopDong.maKH!;
  }

  khoiTaoPortal() {
    stateText.value = "Đang khởi tạo";
    if (seKhachHangs.value.maKH == null) {
      FirebaseManager().showSnackBar("Chưa chọn khách hàng");
      return;
    }
    FirebaseManager().addMessage(MessageReceiveModel(
        "khoitao",
        const JsonEncoder().convert({
          "maKH": seKhachHangs.value.maKH,
          "account": selectedUser.value!.username,
          "password": selectedUser.value!.password,
        })));
  }

  void goToOption() {
    Get.toNamed("/options");
  }

  void saveKey(String e) {
    GetStorage().write("key", e);

    FirebaseManager().disposeFirebase();

    FirebaseManager().setUp();
  }

  Future<void> loginPNS({bool isGiaoDich = false}) async {
    // thực hiện send capchar to firebase

    imageBytes.value = "";

    FirebaseManager().addMessage(MessageReceiveModel(
        isGiaoDich ? "loginpnsgd" : "loginpns", capcharController.text));

    stateText.value = "Đang đăng nhập";

    //waiting 2s

    await Future.delayed(const Duration(seconds: 2));

    getPortalData();
  }

  void gotoPortalInfo() {
    Get.toNamed("/portalinfo");

    var portalInfo = Get.find<PortalinfoController>();

    // Mỗi lần vào portal: chạy checkPortal thay vì refresh
    portalInfo.checkPortal();
  }

  void saveAccount() {
    GetStorage().write("account", accountTE.text);
    GetStorage().write("password", passwordTE.text);
  }

  void getToken() {
    FirebaseManager().addMessage(MessageReceiveModel("getToken", ""));
  }

  void test() {
    FirebaseManager().testShowLog();
  }

  void sendPing() {
    //set isOnline false all maychus
    for (var element in maychus) {
      element.isOnline.value = false;
    }
    FirebaseManager().addPing();
  }

  void addPortalData() {
    imageBytes.value = "";
    //kiểm tra dayLastController có khác 2 không, nếu khác thì save key is day
    if (dayLastController.text != "2" && dayLastController.value != "") {
      GetStorage().write("day", dayLastController.text);
      FirebaseManager().addMessage(MessageReceiveModel(
          "addpns",
          const JsonEncoder().convert(
              {"day": (int.parse(dayLastController.text) * (-1)).toString()})));
    } else {
      FirebaseManager().addMessage(MessageReceiveModel(
          "addpns",
          const JsonEncoder().convert(
            {"day": "-2"},
          )));
    }
    FirebaseManager().showSnackBar("Đang lấy dữ liệu");
    stateText.value = "Đang lấy dữ liệu";
  }

  void getPortalGD() {
    imageBytes.value = "";
    //kiểm tra dayLastController có khác 2 không, nếu khác thì save key is day
    if (dayLastController.text != "2" && dayLastController.value != "") {
      GetStorage().write("day", dayLastController.text);
      FirebaseManager().addMessage(MessageReceiveModel(
          "getpnsgd",
          const JsonEncoder().convert(
              {"day": (int.parse(dayLastController.text) * (-1)).toString()})));
    } else {
      FirebaseManager().addMessage(MessageReceiveModel(
          "getpnsgd",
          const JsonEncoder().convert(
            {"day": "-2"},
          )));
    }
    FirebaseManager().showSnackBar("Đang lấy dữ liệu");
    stateText.value = "Đang lấy dữ liệu";
  }

  void goToMyPost() {
    Get.toNamed("/myview");

    var portalInfo = Get.find<MyviewController>();

    portalInfo.updateKhachHang();
  }

  // --- THAY THẾ BẰNG KHÓA API CỦA BẠN ---
  final String _geminiApiKey = 'AIzaSyDH5GCSoVSCDM-2PdKqzbEVEpmf8RGeZ_Y';
  // ------------------------------------

  final String _modelId = 'gemini-3-flash-preview'; // Hoặc 'gemini-1.5-flash'
  late final Uri _apiUrl = Uri.parse(
      'https://generativelanguage.googleapis.com/v1beta/models/$_modelId:streamGenerateContent?key=$_geminiApiKey');

  final ImagePicker _picker = ImagePicker();

  // Hàm để chọn ảnh từ thư viện
  Future<File?> pickImage() async {
    final XFile? image = await _picker.pickImage(source: ImageSource.gallery);
    if (image != null) {
      return File(image.path);
    }
    return null;
  }

// Hàm chính gửi request và xử lý response
  Future<void> sendImageRequest(File imageFile) async {
    try {
      final List<int> imageBytes = await imageFile.readAsBytes();
      final String base64Image = base64Encode(imageBytes);

      final Map<String, dynamic> requestBody = {
        "contents": [
          {
            "role": "user",
            "parts": [
              {
                "inlineData": {
                  "mimeType": "image/jpeg",
                  "data": base64Image,
                }
              },
              {
                "text":
                    "Lấy mã hiệu, tên người nhận, địa chỉ nhận, số điện thoại từ hình ảnh được cung cấp. Phản hồi phải là một đối tượng JSON. Ví dụ: ```json{\"maHieu\": \"...\", \"tenNguoiNhan\": \"...\", \"diaChi\": \"...\", \"soDienThoai\": \"...\"}```" // <-- Quan trọng: Hướng dẫn rõ ràng AI trả về JSON
              },
            ]
          }
        ],
        // "generationConfig": {
        //   "thinkingConfig": {
        //     "thinkingBudget": -1
        //   }, // thinkingBudget -1 không được hỗ trợ trong phiên bản public của Gemini API, có thể gây lỗi.
        //   // Nếu bạn đang dùng Vertex AI và có truy cập, thì có thể.
        //   // Trong trường hợp thông thường, hãy bỏ qua hoặc dùng giá trị hợp lệ.
        // },
        "tools": [
          {
            "googleSearch": {}
          }, // Đảm bảo bạn có quyền truy cập Google Search Tool
        ],
      };

      final response = await http.post(
        _apiUrl,
        headers: {
          'Content-Type': 'application/json',
        },
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        debugPrint('Raw API Response Body: ${response.body}',
            wrapWidth: 1024); // In ra để debug

        // Giải mã phản hồi gốc
        final List<dynamic> responseChunks =
            jsonDecode(response.body); // <-- Sửa tại đây: mong đợi một Map

        String combinedExtractedText =
            ""; // Biến để nối tất cả các phần văn bản lại

        // Lặp qua từng 'chunk' (đối tượng) trong danh sách phản hồi
        for (var chunk in responseChunks) {
          // Kiểm tra an toàn xem chunk có phải là Map và chứa 'candidates' không
          if (chunk is Map<String, dynamic> &&
              chunk.containsKey('candidates') &&
              chunk['candidates'] is List &&
              chunk['candidates'].isNotEmpty) {
            final List<dynamic> candidates = chunk['candidates'];
            // Lấy ứng cử viên đầu tiên trong mỗi chunk (thường là đủ)
            final Map<String, dynamic> firstCandidate =
                candidates[0] as Map<String, dynamic>;

            // Kiểm tra an toàn cấu trúc lồng nhau: content -> parts -> text
            if (firstCandidate.containsKey('content') &&
                firstCandidate['content'] is Map &&
                firstCandidate['content'].containsKey('parts') &&
                firstCandidate['content']['parts'] is List &&
                firstCandidate['content']['parts'].isNotEmpty) {
              final List<dynamic> parts = firstCandidate['content']['parts'];
              // Lặp qua từng 'part' để nối tất cả các chuỗi 'text' lại
              for (var part in parts) {
                if (part is Map<String, dynamic> && part.containsKey('text')) {
                  combinedExtractedText += part['text'].toString();
                }
              }
            }
          }
        }

        // Log chuỗi văn bản đã được nối lại
        debugPrint(
            'Combined Extracted Text from all chunks: $combinedExtractedText');

        // Làm sạch chuỗi: loại bỏ ````json` và ```` (kết thúc)
        // Sử dụng `RegExp(r'```json|```')` để loại bỏ cả hai dạng
        String cleanedJsonString =
            combinedExtractedText.replaceAll(RegExp(r'```json|```'), '').trim();

        // Log chuỗi JSON đã làm sạch, sẵn sàng để giải mã
        debugPrint(
            'Cleaned JSON String ready for decoding: $cleanedJsonString');

        // <<<<<<<<<<<<<<<< ĐIỀU CHỈNH QUAN TRỌNG TẠI ĐÂY >>>>>>>>>>>>>>>>>
        // Cố gắng giải mã chuỗi JSON đã làm sạch thành một Map trong Dart
        try {
          final Map<String, dynamic> extractedData =
              jsonDecode(cleanedJsonString);
          debugPrint('Successfully Decoded Extracted Data Map: $extractedData');

          // Lấy các giá trị cụ thể từ Map đã giải mã
          final String? maHieu = extractedData['maHieu'];
          final String? tenNguoiNhan = extractedData['tenNguoiNhan'];
          final String? diaChi = extractedData['diaChi'];
          final String? soDienThoai = extractedData['soDienThoai'];

          'Mã hiệu: $maHieu'.printInfo();
          'Tên người nhận: $tenNguoiNhan'.printInfo();
          'Địa chỉ: $diaChi'.printInfo();
          'Số điện thoại: $soDienThoai'.printInfo();

          // TODO: Sử dụng các giá trị này theo nhu cầu của bạn (ví dụ: cập nhật UI, lưu vào biến trạng thái)
        } on FormatException catch (e) {
          // Xử lý lỗi nếu chuỗi đã làm sạch không phải là JSON hợp lệ
          'Error decoding cleaned JSON string: $e'.printInfo();
          'Problematic String: "$cleanedJsonString"'.printInfo();
        } catch (e) {
          // Bắt các lỗi không mong muốn khác trong quá trình phân tích JSON
          'An unexpected error occurred during final JSON parsing: $e'
              .printInfo();
        }
      } else {
        // API request thất bại
        'API request failed with status code: ${response.statusCode}'
            .printInfo();
        'Response Body: ${response.body}'
            .printInfo(); // In ra body để xem lỗi từ server
      }
    } catch (e) {
      // Bắt các lỗi xảy ra trong quá trình gửi request hoặc xử lý ban đầu
      'An error occurred during API request: $e'.printInfo();
    }
  }

  bool isFirstGeminiCall = true;

  void goToQuetThu() async {
    Get.toNamed("/quetthu");
    // final image = await pickImage();
    // if (image != null) {
    //   if (isFirstGeminiCall) {
    //     final info = await geminiSevice.extractInfoFromImage(image);
    //     isFirstGeminiCall = false;

    //     if (info != null) {
    //       print('Extracted Info: $info');
    //     }
    //   } else {
    //     final info = await geminiSevice.askFollowUp(image);
    //     if (info != null) {
    //       print('Extracted Info: $info');
    //     }
    //   }
    // }
  }

  void goToQuetMH() {
    Get.toNamed("/quetmh");
  }

  void goToImportImages() {
    // Navigate to the import images view
    Get.toNamed(Routes.IMPORT_IMAGES);
  }

  void goToCaptureImage() async {
    final result = await Get.toNamed(Routes.CAPTURE_IMAGE);
    if (result != null) {
      Get.snackbar("Thành công", "Đã chụp và lưu ảnh.",
          snackPosition: SnackPosition.BOTTOM);
    }
  }
}
