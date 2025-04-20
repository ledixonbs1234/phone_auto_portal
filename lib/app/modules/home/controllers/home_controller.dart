import 'dart:convert';
import 'dart:ffi';
import 'dart:math';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import 'package:get_storage/get_storage.dart';

import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';

import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';

import 'package:phone_auto_portal/app/modules/home/hopdong_model.dart';
import 'package:phone_auto_portal/app/modules/home/host_info.dart';

import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';

import 'package:phone_auto_portal/app/modules/printPage/controllers/print_page_controller.dart';

import 'package:phone_auto_portal/data/firebaseManager.dart';

import '../../portalinfo/controllers/portalinfo_controller.dart';

import '../khach_hangs_model.dart';
import '../user_info.dart';

class HomeController extends GetxController {
  //TODO: Implement HomeController

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
  final userList = <UserInfo>[].obs;
  final selectedUser = Rx<UserInfo?>(null);
  final isLoadingUsers = false.obs; // Cờ báo đang tải user từ RTDB
  final _selectedUserStorageKey =
      'selectedPortalUsername'; // Lưu username đã chọn vào GetStorage
  // --- Kết thúc Trạng thái Chọn Người dùng ---

  final maychus = <HostInfo>[
    HostInfo("maychu"),
    HostInfo("mayphu"),
    HostInfo("mayphusan"),
    HostInfo("maytest"),
    HostInfo("maygiaodich 1"),
    HostInfo("maygiaodich 2"),
    HostInfo("maygiaodich 3"),
  ].obs;
  var lastSelectKH = "";

  @override
  Future<void> onReady() async {
    // khachHangs.clear();

    keyController.text = GetStorage().read("key") ?? "maychu";
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
  }

  // Hàm khởi tạo gộp
  Future<void> initializeData() async {
    await loadPortalUsersFromRTDB(); // Tải user từ RTDB trước
    loadSelectedUserFromStorage(); // Sau đó tải lựa chọn từ bộ nhớ cục bộ
  }

  Future<void> loadPortalUsersFromRTDB() async {
    isLoadingUsers.value = true;
    userList.clear(); // Xóa list cũ trước khi tải
    // Luôn thêm lựa chọn "Không chọn" vào đầu danh sách
    final noSelectionUser =
        UserInfo(name: 'Không chọn', username: '', password: '');
    userList.add(noSelectionUser);

    try {
      final List<UserInfo> fetchedUsers =
          await FirebaseManager().getPortalUsers();
      userList.addAll(fetchedUsers); // Thêm user lấy từ RTDB
    } catch (e) {
      print("Lỗi trong HomeController khi tải portal users: $e");
      Get.snackbar('Lỗi', 'Không thể tải danh sách tài khoản portal.');
      // userList sẽ chỉ chứa 'Không chọn' nếu có lỗi
    } finally {
      isLoadingUsers.value = false;
      // Đảm bảo lựa chọn hiện tại hợp lệ sau khi tải xong
    }
  }

  // Tải username đã chọn từ GetStorage và tìm UserInfo tương ứng trong list đã tải từ RTDB
  void loadSelectedUserFromStorage() {
    final String? selectedUsername =
        GetStorage().read<String>(_selectedUserStorageKey);
    if (selectedUsername != null) {
      // Tìm user trong list (đã bao gồm 'Không chọn')
      final user = userList.firstWhere((u) => u.username == selectedUsername,
          orElse: () {
        print(
            "Username '$selectedUsername' đã lưu không tồn tại trong danh sách mới tải.");
        return userList.firstWhere((u) =>
            u.username.isEmpty); // Trả về 'Không chọn' nếu không tìm thấy
      });
      selectedUser.value = user;
    } else {
      // Nếu chưa có gì được lưu, mặc định là "Không chọn"
      selectedUser.value = userList.firstWhere((u) => u.username.isEmpty,
          orElse: () =>
              UserInfo(name: 'Không chọn', username: '', password: ''));
    }
  }

  void saveSelectedUserToStorage() {
    final usernameToSave = selectedUser.value?.username;
    if (usernameToSave != null) {
      // Lưu cả username rỗng của 'Không chọn'
      GetStorage().write(_selectedUserStorageKey, usernameToSave);
      print("Đã lưu lựa chọn username: '$usernameToSave'");
    } else {
      _storage.remove(
          _selectedUserStorageKey); // Xóa nếu selectedUser là null (hiếm khi)
    }
  }

  // Kiểm tra xem user đang chọn có còn trong danh sách không (sau khi tải lại từ RTDB)

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

  void goToPrintPage() {
    var detail = Get.find<PrintPageController>();

    detail.khachHang.value = seKhachHangs.value;

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

    portalInfo.refreshPortal(null);
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
}
