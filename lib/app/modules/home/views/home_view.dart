import 'dart:convert';

import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';

import '../controllers/home_controller.dart';

import '../khach_hangs_model.dart';
import '../user_info.dart';

class HomeView extends GetView<HomeController> {
  const HomeView({super.key});
  Widget _buildActionButton({
    required IconData icon,
    required String label,
    required Color color,
    required VoidCallback onPressed,
    VoidCallback? onLongPress,
  }) {
    return ElevatedButton.icon(
      icon: Icon(icon, color: color),
      label: Text(
        label,
        style: TextStyle(color: color, fontWeight: FontWeight.bold),
      ),
      style: ElevatedButton.styleFrom(
        backgroundColor: Colors.white,
        side: BorderSide(color: color.withOpacity(0.5)),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8.0)),
      ),
      onPressed: onPressed,
      onLongPress: onLongPress,
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
        resizeToAvoidBottomInset: false,
        appBar: AppBar(
          centerTitle: true,
          title: const HostSelectionWidget(),
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
                  // Host Selection Widget at the top
                  Padding(
                    padding: const EdgeInsets.all(12.0),
                    child: Obx(() {
                      // Có thể hiển thị dropdown mờ đi khi đang tải user
                      return IgnorePointer(
                        // Ngăn tương tác khi đang tải
                        ignoring: controller.isLoadingUsers.value,
                        child: DropdownButtonFormField<UserInfo>(
                          value: controller.selectedUser.value,
                          hint: Text(controller.isLoadingUsers.value
                              ? 'Đang tải...'
                              : 'Chọn tài khoản portal'),
                          isExpanded: true,
                          decoration: InputDecoration(
                            contentPadding: const EdgeInsets.symmetric(
                                horizontal: 12, vertical: 8),
                            border: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0)),
                            enabledBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                    color: controller.isLoadingUsers.value
                                        ? Colors.grey.shade300
                                        : Colors.grey
                                            .shade400) // Màu border khi đang tải
                                ),
                            focusedBorder: OutlineInputBorder(
                                borderRadius: BorderRadius.circular(8.0),
                                borderSide: BorderSide(
                                    color: Theme.of(context).primaryColor,
                                    width: 1.5)),
                            labelText: "Tài khoản Portal",
                            prefixIcon: controller.isLoadingUsers.value
                                ? const Padding(
                                    padding: EdgeInsets.all(10),
                                    child: SizedBox(
                                        width: 15,
                                        height: 15,
                                        child: CircularProgressIndicator(
                                            strokeWidth: 1.5)))
                                : const Icon(Icons.person_outline,
                                    size: 20), // Icon hoặc loading
                            filled: controller.isLoadingUsers
                                .value, // Tô màu nền khi đang tải
                            fillColor: Colors.grey.shade100,
                          ),
                          // Chỉ hiển thị item nếu list không rỗng
                          items: controller.userList.isNotEmpty
                              ? controller.userList
                                  .map<DropdownMenuItem<UserInfo>>(
                                      (UserInfo user) {
                                  return DropdownMenuItem<UserInfo>(
                                    value: user,
                                    child: Text(user.toString(),
                                        overflow: TextOverflow.ellipsis),
                                  );
                                }).toList()
                              : [], // Trả về list rỗng nếu userList chưa có gì (ngoài 'Không chọn' lúc đầu)
                          onChanged: controller.isLoadingUsers.value
                              ? null
                              : (UserInfo? newValue) {
                                  // Vô hiệu hóa onChanged khi đang tải
                                  controller.selectedUser.value = newValue;
                                },
                        ),
                      );
                    }),
                  ),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceAround,
                    children: [
                      _buildActionButton(
                        icon: Icons.cloud_download,
                        label: 'Get Portal Data',
                        color: Colors.blue,
                        onPressed: () {
                          controller.getPortalData();
                        },
                      ),
                      _buildActionButton(
                        icon: Icons.add_box,
                        label: 'Get My Post',
                        color: Colors.green,
                        onPressed: () {
                          controller.goToMyPost();
                        },
                      ),
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
                                _buildActionButton(
                                  icon: Icons.login,
                                  label: 'Login PNS',
                                  color: Colors.green,
                                  onPressed: () {
                                    controller.loginPNS();
                                  },
                                ),
                                _buildActionButton(
                                  icon: Icons.login_rounded,
                                  label: 'Login GD',
                                  color: Colors.purple,
                                  onPressed: () {
                                    controller.loginPNS(isGiaoDich: true);
                                  },
                                ),
                              ],
                            )
                          ],
                        )
                      : Container(),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: DropdownButton(
                        isExpanded: true,
                        style:
                            const TextStyle(fontSize: 15, color: Colors.black),
                        value: controller.seKhachHangs.value,
                        items: controller.khachHangs
                            .map<DropdownMenuItem<KhachHangs>>((KhachHangs e) {
                          return DropdownMenuItem<KhachHangs>(
                              value: e,
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(
                                    e.tenKH!.length > 30
                                        ? e.tenKH!
                                            .substring(e.tenKH!.length - 30)
                                        : e.tenKH!,
                                    style: TextStyle(color: Colors.green[700]),
                                  ),
                                  Row(
                                    children: [
                                      Text(
                                        "${e.countState!.countDangGom.toString().padLeft(3, ' ')} ${e.countState!.countPhanHuong.toString().padLeft(3, ' ')} ",
                                        style:
                                            TextStyle(color: Colors.blue[700]),
                                      ),
                                      Text(
                                        "${e.countState!.countNhanHang.toString().padLeft(3, ' ')} ",
                                        style:
                                            TextStyle(color: Colors.red[600]),
                                      ),
                                      Text(
                                        e.countState!.countChapNhan
                                            .toString()
                                            .padLeft(3, ' '),
                                        style:
                                            TextStyle(color: Colors.blue[400]),
                                      )
                                    ],
                                  ),
                                ],
                              ));
                        }).toList(),
                        onChanged: (KhachHangs? value) async {
                          if (value == null) return;

                          controller.seKhachHangs.value = value;
                          controller.lastSelectKH = value.maKH!;

                          controller.checkHopDong(value);
                        }),
                  ),
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
                      const Text('Tìm kiếm MH:'),
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
                      ),
                    ],
                  ),
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
                                  activeColor: Colors.green, // Màu nền khi chọn
                                  checkColor: Colors.white, // Màu dấu tích
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(
                                        4.0), // Bo góc cho checkbox
                                  ),
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
                  Padding(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                    child: SizedBox(
                      height: 40,
                      child: SingleChildScrollView(
                        scrollDirection: Axis.horizontal,
                        child: Row(
                          children: [
                            SizedBox(
                              width: 100,
                              child: _buildActionButton(
                                icon: Icons.info_outline,
                                label: 'Chi Tiết',
                                color: Colors.indigo,
                                onPressed: () {
                                  controller.goToDetail();
                                },
                              ),
                            ),
                            const SizedBox(
                                width:
                                    8), // khoảng cách giữa các button (nếu cần)
                            SizedBox(
                              width: 100,
                              child: _buildActionButton(
                                icon: Icons.print,
                                label: 'In MH',
                                color: Colors.orange,
                                onPressed: () {
                                  controller.goToPrintPage();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 100,
                              child: _buildActionButton(
                                icon: Icons.create,
                                label: 'Tạo Mới',
                                color: Colors.purple,
                                onPressed: () {
                                  controller.goToCreateNew();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 130,
                              child: _buildActionButton(
                                icon: Icons.create,
                                label: 'Quét Thư',
                                color: Colors.blue,
                                onPressed: () {
                                  controller.goToQuetThu();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 130,
                              child: _buildActionButton(
                                icon: Icons.qr_code_scanner,
                                label: 'Quét MH',
                                color: Colors.teal,
                                onPressed: () {
                                  controller.goToQuetMH();
                                },
                              ),
                            ),
                            const SizedBox(width: 8),
                            SizedBox(
                              width: 130,
                              child: _buildActionButton(
                                icon: Icons.photo_library,
                                label: 'Import Img',
                                color: Colors.deepPurple,
                                onPressed: () {
                                  controller.goToImportImages();
                                },
                              ),
                            ),
                          ],
                        ),
                      ),
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
