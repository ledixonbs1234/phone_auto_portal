import 'dart:convert';

import 'package:awesome_notifications/awesome_notifications.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';

import 'package:phone_auto_portal/app/modules/home/messageReceiveModel.dart';

import 'package:phone_auto_portal/app/modules/portalinfo/dingoaicodes_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/portal_check_model.dart';

import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/split_address.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/state_ma_hieu_model.dart';
import 'package:phone_auto_portal/app/routes/app_pages.dart';

import 'package:phone_auto_portal/data/firebaseManager.dart';

class PortalinfoController extends GetxController {
  final portals = <Portal>[].obs;
  final currentMaHieusInPortal = <StateMaHieu>[].obs;

  final iPotal = 0.obs;

  final maychus = <String>["maychu", "mayphu", "mayphusan", "maytest"].obs;

  final selectedMayChu = "maychu".obs;

  bool isAutoRunBD = false;
  final isShowEdit = false.obs;

  final stateText = "".obs;

  final isSortDiNgoai = false.obs;

  final countPortalSelected = 0.obs;

  final isPrinted = true.obs;

  var waitingCodes = "";

  Future<void> refreshPortal() async {
    await FirebaseManager().refreshPortal();

    stateText.value = "Đang cập nhật dữ liệu";
  }

  List<Portal> getSelectedsPortal() {
    return portals.where((element) => element.selected).toList();
  }

  List<String?> getSelectedsIdPortal() {
    return getSelectedsPortal().map((e) => e.id).toList();
  }

  sendDiNgoai() {
    isAutoRunBD = false;

    List<String?> selecteds = getSelectedsIdPortal();
    if (selecteds.isNotEmpty) {
      waitingCodes = "DONGDINGOAI";

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }
  }

  Future<void> printPageSelected() async {
    stateText.value = "Đang chuẩn bị In";
    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      FirebaseManager()
          .addMessage(MessageReceiveModel("printPage", jsonEncode(selecteds)));
    }
  }

  Future<void> printPageSelectedAndSort() async {
    stateText.value = "Đang chuẩn bị In";
    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      FirebaseManager().addMessage(
          MessageReceiveModel("printPageSort", jsonEncode(selecteds)));
    }
  }

  void onListenNotification(MessageReceiveModel message) {
    if (message.Lenh == "getMaHieus") {
      var codes = (jsonDecode(message.DoiTuong) as List)
          .map((element) => StateMaHieu.fromJson(element))
          .toList();
      switch (waitingCodes) {
        case "DONGDINGOAI":
          waitingCodes = "";
          stateText.value = "Đã lấy được mã hiệu và đang gửi";
          List<String> maHieus = codes.map((e) => e.code!).toList();
          //codeids
          List<String> codeIDs = codes.map((e) => e.IDCODE!).toList();

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel(
                  "dongdingoai",
                  jsonEncode(Dingoaicodes(
                      codes: maHieus,
                      codeIDs: codeIDs,
                      isAutoBD: isAutoRunBD,
                      isSorted: isSortDiNgoai.value,
                      isPrinted: isPrinted.value)),
                  nameMay: FirebaseManager().keyData!));
          break;
        case "SPLITADDRESS":
          waitingCodes = "";
          stateText.value = "Đã lấy được mã hiệu và đang gửi";
          List<String> maHieus = codes.map((e) => e.code!).toList();
          //codeids
          var splits = codes.map<SplitAddress>((e) {
            return SplitAddress(e.code!, e.Address!, e.Name!);
          }).toList();
          var textSplit = jsonEncode(splits);

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel("splitAddress", textSplit,
                  nameMay: FirebaseManager().keyData!));
          break;
        case "CHECKMAHIEUDINGOAI":
          waitingCodes = "";
          //khi co danh sach gom mahieu va id kem theo thong tin Trang thai
          //gui codes to pc de check trang thai
          var checkInfo = (jsonDecode(message.DoiTuong) as List)
              .map((element) => PortalCheck.fromJson(element))
              .toList();
          //tao newcheckInfo voi trong list có ID giống nhau thì chỉ lấy PortalCheck đầu tiên
          var newCheckInfo = <PortalCheck>[];
          for (var check in checkInfo) {
            if (!newCheckInfo.any((element) => element.iD == check.iD)) {
              newCheckInfo.add(check);
            }
          }

          FirebaseManager().addMessageToAppBD(
              selectedMayChu.value,
              MessageReceiveModel("checkstateportal", jsonEncode(newCheckInfo),
                  nameMay: FirebaseManager().keyData!));
          break;
        case "SENDTEST":
          waitingCodes = "";
          List<String?> selecteds = codes.map((e) => e.code).toList();
          if (selecteds.isNotEmpty) {
            FirebaseManager().addMessage(MessageReceiveModel(
                "printMaHieusToFile", jsonEncode(selecteds)));
          }
          break;

        case "TOSHOW":
          waitingCodes = "";
          currentMaHieusInPortal.value = codes;
          isShowEdit.value = true;
          update();
          break;

        default:
      }
    } else if (message.Lenh == "message") {
      stateText.value = message.DoiTuong;
    } else if (message.Lenh == "showNotification") {
      stateText.value = message.DoiTuong;

      sendNotification();
    } else if (message.Lenh == "checkstateportal") {
      var codes = (jsonDecode(message.DoiTuong) as List)
          .map((element) => PortalCheck.fromJson(element))
          .toList();
      for (var portal in portals) {
        // kiểm tra số lượng codes có ID và State = true
        var countSame = codes
            .where((element) => element.iD == portal.id && element.isDongCT!)
            .toList();
        if (countSame[0].isDongCT!) {
          portal.isXuLyDiNgoai = true;
        }
      }
      update();

      FirebaseManager().showSnackBar("Cập nhật trạng thái thành công");
    } else if (message.Lenh == "printDone") {
      stateText.value = "In xong";
    }
  }

  void sendNotification() {
    AwesomeNotifications().isNotificationAllowed().then((value) {
      if (!value) {
        AwesomeNotifications().requestPermissionToSendNotifications();
      }
    });

    AwesomeNotifications().createNotification(
        content: NotificationContent(
      id: 1,
      channelKey: "test",
      title: 'Lỗi',
      body: 'Có lỗi xảy ra khi chạy tự động bắn BĐ',
    ));
  }

  void layDuLieu() {
    stateText.value = "Đang lấy dữ liệu";

    FirebaseManager().addMessageToAppBD(
        selectedMayChu.value,
        MessageReceiveModel("laydulieu200", "",
            nameMay: FirebaseManager().keyData!));
  }

  void layDuLieuLo() {
    stateText.value = "Đang lấy dữ liệu Lô";

    FirebaseManager().addMessageToAppBD(
        selectedMayChu.value,
        MessageReceiveModel("laydulieulo", "",
            nameMay: FirebaseManager().keyData!));
  }

  void editHangHoas() {
    String? id = getSelectedsIdPortal()[0];

    if (id?.isNotEmpty == true) {
      FirebaseManager().addMessage(MessageReceiveModel("edithanghoa", id!));
    }
  }

  void sendDiNgoaiAndRunBD() {
    stateText.value = "Đang gửi đi ngoài và chạy Auto BĐ";

    isAutoRunBD = true;

    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      waitingCodes = "DONGDINGOAI";

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }
  }

  void sendSplitAddress() {
    stateText.value = "Đang gửi đi ngoài và chạy Auto BĐ";

    isAutoRunBD = true;

    List<String?> selecteds = getSelectedsIdPortal();

    if (selecteds.isNotEmpty) {
      waitingCodes = "SPLITADDRESS";

      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
    }
  }

  var listKHLon = <String>[
    "C005152833",
    "C002446626",
    "20210220115023",
    "C002760865",
    "59320A04000415000",
    "C004626705",
    "C0015048676",
    "C005325162",
    "20210220112811",
    "59320A04000685000",
    "59320A04000692000",
    "C006230404",
    "C008172528",
    "C006036737"
  ];

  void checkDongCT() {
    //lay danh sach tat ca portal
    //kiem tra xem co portal nao chua dong CT hay khong
    //neu co thi hien thi mau cam len portal do thong qua bien isDongCT
    var ids = <String>[];

    for (var portal in portals) {
      ids.add(portal.id!);
    }
    if (ids.isNotEmpty) {
      waitingCodes = "CHECKMAHIEUDINGOAI";
      FirebaseManager()
          .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(ids)));
    }
  }

  void goToEditPage() {
    var selecteds = getSelectedsPortal();
    if (selecteds.length > 1) {
      FirebaseManager().showSnackBar("Chỉ chọn 1 portal để sửa");
      return;
    }
    if (selecteds.isEmpty) {
      FirebaseManager().showSnackBar("Chưa chọn portal để sửa");
      return;
    }

    Portal selectedPortal = selecteds[0];
    if (selectedPortal.trangThai != "2") {
      FirebaseManager().showSnackBar("Không phải trạng thái đang xử lý");
      return;
    }

    EditPageController editPortal = Get.find<EditPageController>();
    editPortal.loadEditPage(selectedPortal);
    Get.toNamed(Routes.EDIT_PAGE);
  }

  void getMaHieuToShow(int index) {
    isAutoRunBD = false;

    List<String?> selecteds = [];
    if (index == -1) {
      return;
    }

    waitingCodes = "TOSHOW";
    selecteds.add(portals[index].id);

    FirebaseManager()
        .addMessage(MessageReceiveModel("getMaHieus", jsonEncode(selecteds)));
  }

  void sendTest() {
    isAutoRunBD = false;

    List<String?> selecteds = getSelectedsIdPortal();
    FirebaseManager().addMessage(MessageReceiveModel("test", ""));
    if (selecteds.isNotEmpty) {
      waitingCodes = "SENDTEST";
    }
  }
}
