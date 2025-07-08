import 'dart:async';
import 'dart:convert';
import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/createnew/model/dingoaistateinfo.dart';
import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';
import 'package:phone_auto_portal/app/modules/home/hopdong_model.dart';
import 'package:phone_auto_portal/app/modules/myview/controllers/myview_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:intl/intl.dart';

import '../app/modules/home/controllers/home_controller.dart';
import '../app/modules/home/khach_hangs_model.dart';
import '../app/modules/home/messageReceiveModel.dart';
import '../app/modules/home/user_info.dart';

class FirebaseManager with WidgetsBindingObserver {
  static final FirebaseManager _singleton = FirebaseManager._internal();
  bool IsDebug = false;
  final database = FirebaseDatabase.instance.ref();
  late DatabaseReference rootPath = database;
  late HomeController? home;
  late MyviewController? myView;
  late DetailController? detail;
  late CreatenewController? createNew;
  late PortalinfoController? portalInfo;
  late EditPageController? editPage;
  // String? getKey() {
  //   var box = GetStorage();
  //   String? key = box.read('keymqtt');
  //   return key ??= "maychu";
  // }

  // String last = "";
  String lastTimeStamp = "";
  String lastTimeUpdateStamp = "";
  String? keyData = "";
  void showSnackBar(String message) {
    Get.snackbar('Thông báo', message,
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: Colors.blue,
        duration: const Duration(milliseconds: 1000),
        colorText: Colors.white);
  }

  String readKey() {
    keyData = GetStorage().read('key') ?? "maychu";
    rootPath = database.child("PORTAL/CHILD/${keyData!}");
    return keyData!;
  }

  void disposeFirebase() {
    lastTimeStamp = "";
    rootPath.child('message/tophone').onValue.drain();
  }

  late StreamSubscription<DatabaseEvent>? streamTimeUpdate = null;
  late StreamSubscription<DatabaseEvent>? streamTimeUpdateMyPost = null;
  String lastCalledNumber = '';
  void setUp() async {
    readKey();
    if (streamTimeUpdate != null) streamTimeUpdate!.cancel();
    streamTimeUpdate =
        database.child('PNS/TimeUpdate').onValue.listen((event) async {
      if (event.snapshot.value == null) return;
      // if (lastTimeUpdateStamp == "") {
      //   lastTimeUpdateStamp = event.snapshot.value as String;
      //   return;
      // }
      String time = event.snapshot.value as String;

      home = Get.find<HomeController>();
      home?.timeUpdate.value = time;
      await home?.updateKhachHang();
    });
    if (streamTimeUpdateMyPost != null) streamTimeUpdateMyPost!.cancel();
    streamTimeUpdateMyPost =
        database.child('MYVNPOST/TimeUpdate').onValue.listen((event) async {
      if (event.snapshot.value == null) return;
      // if (lastTimeUpdateStamp == "") {
      //   lastTimeUpdateStamp = event.snapshot.value as String;
      //   return;
      // }
      String time = event.snapshot.value as String;

      myView = Get.find<MyviewController>();
      myView?.timeUpdate.value = time;
      await myView?.updateKhachHang();
    });

    database.child("PORTAL/MAINPAGE").onValue.listen((event) {
      if (event.snapshot.value == null) return;
      portalInfo = Get.find<PortalinfoController>();
      portalInfo!.portals.clear();
      for (var element in event.snapshot.children) {
        Map<dynamic, dynamic> mapChild = element.value as Map<dynamic, dynamic>;
        portalInfo!.portals.add(Portal.fromJson(mapChild));
      }
      portalInfo!.stateText.value = "Cập nhật dữ liệu thành công";
      portalInfo!.update();
    });
    // data.child('PORTAL/MAINPAGE').onChildChanged.listen((event) {
    //   Map<dynamic, dynamic> child =
    //       event.snapshot.value! as Map<dynamic, dynamic>;
    //   portalInfo = Get.find<PortalinfoController>();
    //   portalInfo!.portals.clear();
    //   event.snapshot.children.forEach((element) {
    //     Map<dynamic, dynamic> mapChild = element.value as Map<dynamic, dynamic>;
    //     portalInfo!.portals.add(Portal.fromJson(mapChild));

    //     //  thongTin = controller.xuLyMaHieu(thongTin);
    //     //         root.child("danhsachmahieu/${thongTin.id}").update(thongTin.toJson());
    //   });
    // }).onError((e) {
    //   printInfo(info: 'Loi $e in firebaseManager|setUp');
    // });
    rootPath.child('message/tophone').onValue.listen((event) {
      if (event.snapshot.value == null) return;
      try {
        Map<dynamic, dynamic> value =
            event.snapshot.value as Map<dynamic, dynamic>;

        MessageReceiveModel message = MessageReceiveModel.fromJson(value);
        if (lastTimeStamp == "") {
          lastTimeStamp = message.TimeStamp;
          return;
        }
        if (message.TimeStamp != lastTimeStamp) {
          lastTimeStamp = message.TimeStamp;
          if (message.Lenh == "phonecall") {
            final phoneNumber = message.DoiTuong;
            //xoa dấu . hoặc dấu cách trong số điện thoại
            final cleanedPhoneNumber =
                phoneNumber.replaceAll(RegExp(r'[.\s]'), '');
            // if (cleanedPhoneNumber != lastCalledNumber) {
            lastCalledNumber = cleanedPhoneNumber;
            print("New call request received for: $cleanedPhoneNumber");
            _makePhoneCall(cleanedPhoneNumber);

            // (Tùy chọn) Xóa yêu cầu sau khi đã xử lý
            // callRef.remove();
            // }
          }
          //         GetStorage().write('getLastTimeStamp', lastTimeStamp);
          //         maHieu = Get.find<MaHieuController>();
          home = Get.find<HomeController>();
          detail = Get.find<DetailController>();
          createNew = Get.find<CreatenewController>();
          portalInfo = Get.find<PortalinfoController>();
          editPage = Get.find<EditPageController>();
          myView = Get.find<MyviewController>();
          //         autoBDController = Get.find<AutoBdController>();
          //         detailController = Get.find<DetailController>();
          myView?.onListenNotification(message);
          portalInfo?.onListenNotification(message);
          detail?.onListenNotification(message);
          home?.onListenNotification(message);
          createNew?.onListenNotification(message);
          editPage?.onListenNotification(message);
          //         maHieu?.onListenNotification(message);
          //         diNgoai?.onListenNotification(message);
          //         webController?.onListenNotification(message);
          //         autoBDController?.onListenNotification(message);
          //         detailController?.onListenNotification(message);
        }
      } catch (e) {
        Get.snackbar("Thông báo", "$e firebase|setup ",
            duration: const Duration(milliseconds: 500));
      }
      // }
    });

    //  thongTin = controller.xuLyMaHieu(thongTin);
    //     //         root.child("danhsachmahieu/${thongTin.id}").update(thongTin.toJson());
    //   }).onError((e) {
    //     print('Loi $e in firebaseManager|setUp');
    //   });
  }

  // void updateMaHieu(ThongTin thongTin) async {
  //   DatabaseEvent thongTinEvent =
  //       await rootPath.child('danhsachmahieu/${thongTin.id}/TimeStamp').once();
  //   if (thongTinEvent.snapshot.value == null) return;
  //   thongTin.timeStamp = thongTinEvent.snapshot.value as int;
  //   rootPath.child('danhsachmahieu/${thongTin.id}').update(thongTin.toJson());
  // }

  // Future<String> getFirstTimeStamp() async {
  //   DataSnapshot temp = await rootPath.child('message/tophone').get();
  //   String last = "";
  //   if (temp.value == null)
  //     last = "";
  //   else {
  //     var aa = temp.value as Map<dynamic, dynamic>;
  //     last = aa["TimeStamp"];
  //   }
  //   return last;
  // }
  String convertTimestampToTime(int timestamp) {
    // Chuyển từ milliseconds sang DateTime
    final dateTime = DateTime.fromMillisecondsSinceEpoch(timestamp);

    // Định dạng thành HH:mm:ss
    return DateFormat('HH:mm:ss').format(dateTime);
  }

  void testShowLog() {
    final logRef = rootPath
        .child('message/log')
        .orderByChild('_timestamp')
        .limitToLast(20);
    logRef.onValue.listen((event) {
      for (var child in event.snapshot.children) {
        final data = child.value as Map;
        String device = "";
        if (data['keyRef'] == null) {
          device = 'WEB';
        } else {
          device = 'PHONE';
        }
        print(
            '[${convertTimestampToTime(data['_timestamp'])}] To $device ${data['Lenh']} ${data['DoiTuong']}');
      }
    });
  }

  void addMessage(MessageReceiveModel message) async {
    rootPath
        .child('message/topc')
        .set(message.toJson())
        .timeout(const Duration(seconds: 5), onTimeout: () {
      throw TimeoutException('Ghi dữ liệu quá lâu, thử lại sau.');
    });
  }

  void addPing() async {
    var message = MessageReceiveModel("ping", keyData!);
    database
        .child("PORTAL/STATUS/topc")
        .set(message.toJson())
        .timeout(const Duration(seconds: 5), onTimeout: () {
      throw TimeoutException('Ghi dữ liệu quá lâu, thử lại sau.');
    });
  }

  void _checkAndReconnectFirebase() async {
    try {
      await FirebaseDatabase.instance.goOffline();
      await FirebaseDatabase.instance.goOnline();

      printInfo(info: 'Forced Firebase reconnect on app resume');
    } catch (e) {
      print('Reconnect error: $e');
    }
  }

  void addMessageToAppBD(String maychu, MessageReceiveModel message) {
    database
        .child('$maychu/message/topc')
        .set(message.toJson())
        .timeout(const Duration(seconds: 3), onTimeout: () {
      showSnackBar('Ghi dữ liệu quá lâu, thử lại sau.');
    });
  }

//   void addNotification(String messageString) {
//     MessageReceiveModel message = MessageReceiveModel('message', messageString);
//     rootPath.child('message/topc').set(message.toJson());
//   }

// //thuc hien lenh voi noi dung ben trong
//   Future<void> addMessageDetail(String lenh, String messageJson) async {
//     MessageReceiveModel message = MessageReceiveModel(lenh, messageJson);

//     await rootPath.child('message/topc').set(message.toJson());
//     if (lenh == "themcode") {
//       Get.snackbar('test', lenh, duration: Duration(seconds: 1));
//     }
//   }

  Future<void> _makePhoneCall(String phoneNumber) async {
    final Uri launchUri = Uri(
      scheme: 'tel',
      path: phoneNumber,
    );
    if (await canLaunchUrl(launchUri)) {
      await launchUrl(launchUri);
    } else {
      print('Could not launch $phoneNumber');
      // Hiển thị thông báo lỗi cho người dùng
    }
  }

  factory FirebaseManager() {
    return _singleton;
  }

  FirebaseManager._internal() {
    WidgetsBinding.instance
        .addObserver(this); // Đăng ký lắng nghe trạng thái ứng dụng
  }
  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _checkAndReconnectFirebase();
    }
  }

  Future<List<KhachHangs>> getKhachHangs() async {
    var datas = await database.child('PNS/KhachHangs').get();
    List<KhachHangs> lans = [];

    Iterable<DataSnapshot> childs = datas.children;
    for (var child in childs) {
      Map<dynamic, dynamic> mapChild = child.value as Map<dynamic, dynamic>;
      var lan = KhachHangs.fromJson(mapChild);
      lans.add(lan);
      // if (thongTin.isSelected) {
      //   var diNgoaiTemp = DiNgoaiInfo();
      //   diNgoaiTemp.code = thongTin.maHieu;
      //   diNgoaiTemp.maBuuCuc = "";
      //   diNgoaiTemp.tenBuuCuc = "";
      //   diNgoaiTemp.danhSachBuuCuc = [];
      //   diNgoaiTemp.address = thongTin.diaChiNhan;
      //   diNgoaiTemp.address ??= "";
      //   diNgoaiTemps.add(diNgoaiTemp);
      // }
    }

    return lans;
  }

  Future<List<KhachHangs>> getKhachHangsVnPost() async {
    var datas = await database.child('MYVNPOST/KhachHangs').get();
    List<KhachHangs> lans = [];

    Iterable<DataSnapshot> childs = datas.children;
    for (var child in childs) {
      Map<dynamic, dynamic> mapChild = child.value as Map<dynamic, dynamic>;
      var lan = KhachHangs.fromJson(mapChild);
      lans.add(lan);
      // if (thongTin.isSelected) {
      //   var diNgoaiTemp = DiNgoaiInfo();
      //   diNgoaiTemp.code = thongTin.maHieu;
      //   diNgoaiTemp.maBuuCuc = "";
      //   diNgoaiTemp.tenBuuCuc = "";
      //   diNgoaiTemp.danhSachBuuCuc = [];
      //   diNgoaiTemp.address = thongTin.diaChiNhan;
      //   diNgoaiTemp.address ??= "";
      //   diNgoaiTemps.add(diNgoaiTemp);
      // }
    }

    return lans;
  }

  Future<List<DiNgoaiStateInfo>> getDiNgoaisTemp() async {
    var datas = await database.child('PORTAL/STATES').get();
    List<DiNgoaiStateInfo> diNgoais = [];

    Iterable<DataSnapshot> childs = datas.children;
    for (var child in childs) {
      Map<dynamic, dynamic> mapChild = child.value as Map<dynamic, dynamic>;
      var diNgoai = DiNgoaiStateInfo.fromJson(mapChild);
      diNgoais.add(diNgoai);
    }

    return diNgoais;
  }

  Future<HopDong> getHopDong(String maKH) async {
    DatabaseEvent data = await database.child('PORTAL/HopDongs/$maKH').once();
    if (data.snapshot.value == null) {
      return HopDong(
          maKH: maKH, address: "", isChooseHopDong: false, sTTHopDong: 0);
    }

    Map<dynamic, dynamic> mapChild =
        data.snapshot.value as Map<dynamic, dynamic>;
    return HopDong.fromJson(mapChild);
    // if (thongTin.isSelected) {
    //   var diNgoaiTemp = DiNgoaiInfo();
    //   diNgoaiTemp.code = thongTin.maHieu;
    //   diNgoaiTemp.maBuuCuc = "";
    //   diNgoaiTemp.tenBuuCuc = "";
    //   diNgoaiTemp.danhSachBuuCuc = [];
    //   diNgoaiTemp.address = thongTin.diaChiNhan;
    //   diNgoaiTemp.address ??= "";
    //   diNgoaiTemps.add(diNgoaiTemp);
    // }
  }

  // Future<List<HopDong>> getHopDongs() async {
  //   var datas = await database.child('PORTAL/HopDongs').get();
  //   List<HopDong> hopDongs = [];

  //   Iterable<DataSnapshot> childs = datas.children;
  //   for (var child in childs) {
  //     Map<dynamic, dynamic> mapChild = child.value as Map<dynamic, dynamic>;
  //     var hopDong = HopDong.fromJson(mapChild);
  //     hopDongs.add(hopDong);
  //     // if (thongTin.isSelected) {
  //     //   var diNgoaiTemp = DiNgoaiInfo();
  //     //   diNgoaiTemp.code = thongTin.maHieu;
  //     //   diNgoaiTemp.maBuuCuc = "";
  //     //   diNgoaiTemp.tenBuuCuc = "";
  //     //   diNgoaiTemp.danhSachBuuCuc = [];
  //     //   diNgoaiTemp.address = thongTin.diaChiNhan;
  //     //   diNgoaiTemp.address ??= "";
  //     //   diNgoaiTemps.add(diNgoaiTemp);
  //     // }
  //   }

  //   return hopDongs;
  // }

  void addHopDong(KhachHangs value, HopDong hopDong) {
    database.child('PORTAL/HopDongs/${value.maKH}/').set(hopDong.toJson());
  }

  void sendListBDToPortal(List<BuuGuis> buuGuis) {
    database.child('PORTAL/BuuGuis').set(jsonEncode(buuGuis));
  }

  void sendListScannedToPortal(List<BuuGuis> buuGuis) {
    var message = MessageReceiveModel("", jsonEncode(buuGuis));
    rootPath
        .child('scannedItems')
        .set(message.toJson())
        .timeout(const Duration(seconds: 5), onTimeout: () {
      throw TimeoutException('Ghi dữ liệu quá lâu, thử lại sau.');
    });
  }

  refreshPortal(DateTime? time) {
    if (time == null) {
      addMessage(MessageReceiveModel("getPortal", ""));
    } else {
      String formattedDate =
          "${time.day.toString().padLeft(2, '0')}/${time.month.toString().padLeft(2, '0')}/${time.year}";
      addMessage(MessageReceiveModel("getPortal", formattedDate));
    }
  }

  Future<List<UserInfo>> getPortalUsers() async {
    final ref = database
        .child('PORTAL')
        .child('portalUsers')
        .ref; // Tham chiếu đến node 'portalUsers'
    try {
      final snapshot = await ref.get();
      if (snapshot.exists && snapshot.value != null) {
        final Map<dynamic, dynamic> usersData =
            snapshot.value as Map<dynamic, dynamic>;
        final List<UserInfo> userList = [];
        usersData.forEach((key, value) {
          // Giả sử value là một Map, nếu không cần kiểm tra kiểu dữ liệu
          if (value is Map) {
            // Truyền key và value vào fromJson
            userList.add(UserInfo.fromJson(key.toString(), value));
          }
        });
        // Sắp xếp theo tên hoặc username nếu muốn
        userList.sort((a, b) => a.name.compareTo(b.name));
        return userList;
      } else {
        print('Node portalUsers không tồn tại hoặc rỗng trong RTDB.');
        return []; // Trả về danh sách rỗng nếu không có dữ liệu
      }
    } catch (e) {
      print("Lỗi khi lấy portalUsers từ RTDB: $e");
      // Ném lỗi để controller xử lý (ví dụ: hiển thị thông báo)
      throw Exception(
          'Không thể tải danh sách người dùng portal: ${e.toString()}');
    }
  }

  // getPortal() async {
  //   var childs = await database.child("PORTAL/MAINPAGE").get();
  //   portalInfo = Get.find<PortalinfoController>();
  //   childs.children.forEach((element) {
  //     Map<dynamic, dynamic> mapChild = element.value as Map<dynamic, dynamic>;
  //     portalInfo!.portals.add(Portal.fromJson(mapChild));
  //   });
  //   portalInfo!.update();
  // }

  void pushBlackList(String s) {
    database.child('PORTAL/BLACKLIST/').push().set({"maBuuGui": s});
  }

  getBlackList() {
    return database.child('PORTAL/BLACKLIST/').get().then((value) {
      List<String> blackList = [];
      if (value.value == null) return blackList;
      Iterable<DataSnapshot> childs = value.children;
      for (var child in childs) {
        Map<dynamic, dynamic> mapChild = child.value as Map<dynamic, dynamic>;
        blackList.add(mapChild["maBuuGui"]);
      }
      return blackList;
    });
  }

  deleteBlackList(String maBuuGui) {
    database.child('PORTAL/BLACKLIST/').get().then((value) {
      if (value.value == null) return;
      Iterable<DataSnapshot> childs = value.children;
      for (var child in childs) {
        Map<dynamic, dynamic> mapChild = child.value as Map<dynamic, dynamic>;
        if (mapChild["maBuuGui"] == maBuuGui) {
          database.child('PORTAL/BLACKLIST/${child.key}').remove();
        }
      }
    });
  }

  Future<void> deleteBuuGuis(List<BuuGuis> value) async {
    try {
      final ref = FirebaseDatabase.instance.ref('PORTAL/STATES');
      await Future.wait(
        value.map((e) => ref.child(e.maBuuGui!).remove()),
      );
      printInfo(info: 'Đã xóa ${value.length} bưu gửi thành công');
    } catch (e) {
      printInfo(info: 'Lỗi khi xóa: $e');
      // Xử lý lỗi tại đây
    }
  }
}
