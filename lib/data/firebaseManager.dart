import 'dart:async';
import 'dart:convert';

import 'package:firebase_database/firebase_database.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:phone_auto_portal/app/modules/createnew/controllers/createnew_controller.dart';
import 'package:phone_auto_portal/app/modules/detail/controllers/detail_controller.dart';
import 'package:phone_auto_portal/app/modules/edit_page/controllers/edit_page_controller.dart';
import 'package:phone_auto_portal/app/modules/home/hopdong_model.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/controllers/portalinfo_controller.dart';
import 'package:phone_auto_portal/app/modules/portalinfo/portal_model.dart';

import '../app/modules/home/controllers/home_controller.dart';
import '../app/modules/home/khach_hangs_model.dart';
import '../app/modules/home/messageReceiveModel.dart';

class FirebaseManager {
  static final FirebaseManager _singleton = FirebaseManager._internal();
  final database = FirebaseDatabase.instance.ref();
  late DatabaseReference rootPath = database;
  late HomeController? home;
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
        snackPosition: SnackPosition.TOP,
        backgroundColor: Colors.blue,
        duration: const Duration(milliseconds: 1500),
        colorText: Colors.white);
  }

  void readKey() {
    keyData = GetStorage().read('key') ?? "maychu";
    rootPath = database.child("PORTAL/CHILD/${keyData!}");
  }

  void disposeFirebase() {
    lastTimeStamp = "";
    rootPath.child('message/tophone').onValue.drain();
  }

 late StreamSubscription<DatabaseEvent>? streamTimeUpdate =null;

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
          //         GetStorage().write('getLastTimeStamp', lastTimeStamp);
          //         maHieu = Get.find<MaHieuController>();
          home = Get.find<HomeController>();
          detail = Get.find<DetailController>();
          createNew = Get.find<CreatenewController>();
          portalInfo = Get.find<PortalinfoController>();
          editPage = Get.find<EditPageController>();
          //         autoBDController = Get.find<AutoBdController>();
          //         detailController = Get.find<DetailController>();
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

  void addMessage(MessageReceiveModel message) {
    rootPath.child('message/topc').set(message.toJson());
  }

  void addMessageToAppBD(String maychu, MessageReceiveModel message) {
    database.child('$maychu/message/topc').set(message.toJson());
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

  factory FirebaseManager() {
    return _singleton;
  }

  FirebaseManager._internal();

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

  Future<HopDong> getHopDong(String MaKH) async {
    DatabaseEvent data = await database.child('PORTAL/HopDongs/$MaKH').once();
    if (data.snapshot.value == null) {
      return HopDong(
          maKH: MaKH, address: "", isChooseHopDong: false, sTTHopDong: 0);
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

  void setListBG(List<BuuGuis> buuGuis) {
    database.child('PORTAL/BuuGuis').set(jsonEncode(buuGuis));
  }

  refreshPortal() {
    addMessage(MessageReceiveModel("getPortal", ""));
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
}
