import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';
import 'package:phone_auto_portal/app/widgets/host_selection_widget.dart';

import '../controllers/myview_controller.dart';

class MyviewView extends GetView<MyviewController> {
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

  const MyviewView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('My VNPOST'),
        centerTitle: true,
      ),
      body: Obx(
        () => Center(
          child: Column(
            children: [
              // Host Selection Widget at the top
              const HostSelectionWidget(),
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
                    controller.lastSelectKH = value.maKH!;
                  }),

              _buildActionButton(
                icon: Icons.cloud_download,
                label: 'Get Portal Data',
                color: Colors.blue,
                onPressed: () {
                  controller.getMyPostData();
                },
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    const Text('Thời Gian Cập Nhật : '),
                    Text(
                      '${controller.timeUpdate}',
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue),
                    )
                  ],
                ),
              ),
              //Create padding with inside a row with textfield and a button
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Expanded(
                        child: Padding(
                      // Thêm Padding để tạo khoảng cách với các widget khác
                      padding: const EdgeInsets.all(16.0),
                      child: TextField(
                        controller: controller.textController,
                        decoration: InputDecoration(
                          labelText: 'Mã Khách Hàng',
                          // Thêm gợi ý để người dùng biết cần nhập gì
                          hintText: 'Ví dụ: KH00123',
                          // Thêm icon ở đầu để trực quan hơn
                          // prefixIcon: const Icon(Icons.person_search),
                          // Thêm nút xoá nhanh nội dung
                          suffixIcon: IconButton(
                            icon: const Icon(Icons.clear),
                            onPressed: () => controller.textController.clear(),
                          ),
                          // Bo tròn các góc của viền
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                          ),
                          // Tuỳ chỉnh viền khi được chọn (focused)
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12.0),
                            borderSide: BorderSide(
                              color: Theme.of(context)
                                  .primaryColor, // Lấy màu chủ đạo của app
                              width: 2.0,
                            ),
                          ),
                        ),
                        onSubmitted: (value) {
                          if (value.isNotEmpty) {
                            controller.findKhachHang(value);
                          }
                        },
                      ),
                    )),
                    _buildActionButton(
                        icon: Icons.find_in_page_outlined,
                        label: "Tim Kiếm",
                        color: Colors.blue,
                        onPressed: () {
                          controller
                              .findKhachHang(controller.textController.text);
                        }),
                  ],
                ),
              ),
              Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: [
                      Expanded(
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
                          width: 8), // khoảng cách giữa các button (nếu cần)

                      const SizedBox(width: 8),
                      Expanded(
                        child: _buildActionButton(
                          icon: Icons.create,
                          label: 'Tạo Mới',
                          color: Colors.purple,
                          onPressed: () {
                            controller.goToCreateNew();
                          },
                        ),
                      ),
                    ],
                  ))
            ],
          ),
        ),
      ),
    );
  }
}
