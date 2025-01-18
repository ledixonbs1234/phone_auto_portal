import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/home_controller.dart';

import '../khach_hangs_model.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          title: SizedBox(
            width: 250,
            child: Obx(
              () => Row(
                children: [
                  DropdownButton<String>(
                    value: controller.selectedMayChu.value,
                    onChanged: (value) {
                      controller.selectedMayChu.value = value!;

                      controller.saveKey(value);
                    },
                    items: controller.maychus.map((e) {
                      return DropdownMenuItem<String>(
                        value: e,
                        child: Text(e),
                      );
                    }).toList(),
                  ),
                  const Padding(
                    padding: EdgeInsets.all(8.0),
                    child: Text(
                      'cách ngày',
                      style: TextStyle(fontSize: 13),
                    ),
                  ),
                  SizedBox(
                      width: 30,
                      child: TextField(
                        controller: controller.dayLastController,
                      ))
                ],
              ),
            ),
          ),
          centerTitle: true,
        ),
        floatingActionButton: FloatingActionButton(
          onPressed: () {
            controller.gotoPortalInfo();
          },
          child: const Icon(Icons.settings),
        ),
        body: SingleChildScrollView(
          child: Center(
            child: Obx(
              () => Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      ElevatedButton(
                          onPressed: () {
                            controller.getPortalData();
                          },
                          child: const Text('Get Portal Data')),
                      IconButton.filledTonal(
                        onPressed: () {
                          controller.getToken();
                        },
                        icon: const Icon(Icons.refresh),
                      )
                    ],
                  ),

                  controller.imageBytes.value.isNotEmpty
                      ? Column(
                          children: [
                            Image.memory(
                              const Base64Decoder()
                                  .convert(controller.imageBytes.value),
                              width: 250,
                            ),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                SizedBox(
                                  width: 100,
                                  child: TextField(
                                    onSubmitted: (value) =>
                                        controller.loginPNS(),
                                    controller: controller.capcharController,
                                  ),
                                ),
                                ElevatedButton(
                                    onPressed: () {
                                      controller.loginPNS();
                                    },
                                    child: const Text('Login'))
                              ],
                            )
                          ],
                        )
                      : Container(),

                  DropdownButton(
                      style: const TextStyle(fontSize: 15, color: Colors.black),
                      value: controller.seKhachHangs.value,
                      items: controller.khachHangs
                          .map<DropdownMenuItem<KhachHangs>>((KhachHangs e) {
                        return DropdownMenuItem<KhachHangs>(
                            value: e,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  e.tenKH!.length > 30
                                      ? e.tenKH!.substring(e.tenKH!.length - 30)
                                      : e.tenKH!,
                                  style: TextStyle(color: Colors.green[700]),
                                ),
                                Row(
                                  children: [
                                    Text(
                                      "${e.countState!.countDangGom.toString().padLeft(3, ' ')} ${e.countState!.countPhanHuong.toString().padLeft(3, ' ')} ",
                                      style: TextStyle(color: Colors.blue[700]),
                                    ),
                                    Text(
                                      "${e.countState!.countNhanHang.toString().padLeft(3, ' ')} ",
                                      style: TextStyle(color: Colors.red[600]),
                                    ),
                                    Text(
                                      e.countState!.countChapNhan
                                          .toString()
                                          .padLeft(3, ' '),
                                      style: TextStyle(color: Colors.blue[400]),
                                    )
                                  ],
                                ),
                              ],
                            ));
                      }).toList(),
                      onChanged: (KhachHangs? value) async {
                        if (value == null) return;

                        controller.seKhachHangs.value = value;

                        controller.checkHopDong(value);
                      }),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "Time Update: ${controller.timeUpdate.value}",
                        style: TextStyle(color: Colors.pink[600], fontSize: 16),
                      )
                    ],
                  ),

                  Row(
                    children: [
                      const Text('Tìm kiếm dựa trên MH:'),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: TextField(
                            controller: controller.textMHController,
                            keyboardType: TextInputType.number,
                            onChanged: (value) {
                              controller.textMH.value = value;

                              if (value.isNotEmpty && value.length >= 2) {
                                controller.findKhachHangsByMH(value);
                              }
                            },
                          ),
                        ),
                      )
                    ],
                  ),

                  //create a card

                  Row(
                    children: [
                      Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Row(
                          children: [
                            const Text('Trạng Thái : '),
                            Text(
                              '${controller.stateText}',
                              style: const TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue),
                            )
                          ],
                        ),
                      ),
                    ],
                  ),

                  SizedBox(
                    width: Get.width,
                    height: 260,
                    child: Card(
                      elevation: 4,

                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(10),
                      ),

                      color: Colors.blue[50], // Add color to the card

                      child: Padding(
                        padding: const EdgeInsets.all(8.0),
                        child: Column(
                          children: [
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  enabled:
                                      false, // Set the TextField as read-only

                                  onChanged: (s) {},

                                  controller: controller.maKHController,

                                  style: const TextStyle(
                                      color: Colors.red, fontSize: 18),

                                  decoration: const InputDecoration(
                                    hintText: 'Mã KH',
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Expanded(
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: TextField(
                                  enabled: controller.isEditHopDong.value,
                                  onChanged: (s) {},
                                  controller: controller.addressController,
                                  decoration: const InputDecoration(
                                    hintText: 'Địa chỉ',
                                  ),
                                  style: const TextStyle(
                                    fontSize: 14,
                                    color: Colors.black,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 10),
                            Row(
                              children: [
                                const Text(
                                  'Có hợp đồng:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                Checkbox(
                                  //set readonly

                                  value: controller.isHaveHopDong.value,

                                  onChanged: controller.isEditHopDong.value
                                      ? (e) {
                                          controller.isHaveHopDong.value = e!;
                                        }
                                      : null,
                                ),
                                const SizedBox(width: 20),
                                const Text(
                                  'STT HĐ:',
                                  style: TextStyle(
                                    fontSize: 16,
                                    color: Colors.black,
                                  ),
                                ),
                                SizedBox(
                                  width: 50,
                                  child: TextField(
                                    enabled: controller.isEditHopDong.value,
                                    onChanged: (s) {},
                                    keyboardType: TextInputType.number,
                                    controller:
                                        controller.numberHopDongController,
                                    style: const TextStyle(
                                      color: Colors.black,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Row(
                                        children: [
                                          ElevatedButton(
                                              onPressed: () {
                                                controller.editHopDong();
                                              },
                                              child: const Text('Sửa')),
                                          const SizedBox(width: 10),
                                          ElevatedButton(
                                              onPressed: controller
                                                      .isEditHopDong.value
                                                  ? () {
                                                      controller.saveHopDong();
                                                    }
                                                  : null,
                                              style: ButtonStyle(
                                                  backgroundColor:
                                                      WidgetStateProperty.all(
                                                          Colors.lightBlue
                                                              .shade200)),
                                              child: const Text('Lưu')),
                                        ],
                                      ),
                                      ElevatedButton(
                                          onPressed: () =>
                                              controller.khoiTaoPortal(),
                                          child: const Text('Khởi tạo')),
                                    ]))
                          ],
                        ),
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => showDialog<String>(
                      context: context,
                      builder: (BuildContext context) => Dialog(
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: <Widget>[
                              Padding(
                                  padding: const EdgeInsets.symmetric(
                                      vertical: 8.0, horizontal: 16.0),
                                  child: Column(
                                    children: [
                                      SizedBox(
                                        width: Get.width - 140,
                                        child: TextField(
                                          onChanged: (s) {},
                                          controller: controller.accountTE,
                                          decoration: const InputDecoration(
                                            hintText: 'Tài khoản',
                                          ),
                                          style: const TextStyle(
                                            fontSize: 14,
                                            color: Colors.black,
                                          ),
                                        ),
                                      ),
                                      TextField(
                                        onChanged: (s) {},
                                        controller: controller.passwordTE,
                                        obscureText: true,
                                        decoration: const InputDecoration(
                                          hintText: 'Mật khẩu',
                                        ),
                                        style: const TextStyle(
                                          fontSize: 14,
                                          color: Colors.black,
                                        ),
                                      ),
                                    ],
                                  )),
                              const SizedBox(height: 15),
                              Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Padding(
                                    padding: const EdgeInsets.all(8.0),
                                    child: ElevatedButton(
                                        style: ButtonStyle(
                                            backgroundColor:
                                                WidgetStateProperty.all(
                                                    Colors.lightBlue.shade200)),
                                        onPressed: () {
                                          controller.saveAccount();
                                          Navigator.pop(context);
                                        },
                                        child: const Text('Lưu')),
                                  ),
                                  TextButton(
                                    onPressed: () {
                                      Navigator.pop(context);
                                    },
                                    child: const Text('Close'),
                                  ),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                    child: const Text('Tài khoản'),
                  ),

                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              controller.goToDetail();
                            },
                            child: const Text('Chi Tiết')),
                        ElevatedButton(
                            onPressed: () {
                              controller.goToPrintPage();
                            },
                            child: const Text('In Mã Hiệu')),
                        ElevatedButton(
                            onPressed: () {
                              controller.goToCreateNew();
                            },
                            child: const Text('Tạo Mới'))
                      ],
                    ),
                  ),
                  const SizedBox(
                    height: 60,
                  )
                ],
              ),
            ),
          ),
        ));
  }
}
