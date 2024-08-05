import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/detail_controller.dart';

class DetailView extends GetView<DetailController> {
  const DetailView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.khachHang.value.tenKH!,
            style: const TextStyle(
                color: Colors.teal, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(
          () => Column(
            children: [
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Row(
                      children: [
                        const Text('Mã KH: '),
                        Text(
                          '${controller.khachHang.value.maKH}',
                          style: const TextStyle(
                              color: Colors.orange,
                              fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                    Row(
                      children: [
                        const Text('Số Lượng: '),
                        Text(
                          '${controller.khachHang.value.buuGuis?.length ?? "0"}',
                          style: const TextStyle(
                              color: Colors.red, fontWeight: FontWeight.bold),
                        )
                      ],
                    ),
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: controller.isCheckedDangGom.value,
                        onChanged: (e) {
                          controller.isCheckedDangGom.value = e!;
                          controller.updateBuuguiFromCheck();
                        },
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Đang gom: ${controller.khachHang.value.countState?.countDangGom ?? "0"}',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: controller.isCheckPhanHuong.value,
                        onChanged: (e) {
                          controller.isCheckPhanHuong.value = e!;
                          controller.updateBuuguiFromCheck();
                        },
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Phân hướng: ${controller.khachHang.value.countState?.countPhanHuong ?? "0"}',
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Row(
                    children: [
                      Checkbox(
                        value: controller.isCheckNhanHang.value,
                        onChanged: (e) {
                          controller.isCheckNhanHang.value = e!;
                          controller.updateBuuguiFromCheck();
                        },
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Nhận hàng: ${controller.khachHang.value.countState?.countNhanHang ?? "0"}',
                        ),
                      ),
                    ],
                  ),
                  Row(
                    children: [
                      Checkbox(
                        value: controller.isCheckChapNhan.value,
                        onChanged: (e) {
                          controller.isCheckChapNhan.value = e!;
                          controller.updateBuuguiFromCheck();
                        },
                      ),
                      SizedBox(
                        width: 100,
                        child: Text(
                          'Chấp nhận: ${controller.khachHang.value.countState?.countChapNhan ?? "0"}',
                        ),
                      ),
                    ],
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
              Expanded(
                child: GetBuilder<DetailController>(
                  builder: (dx) => DataTable2(
                    showCheckboxColumn: false,
                    sortAscending: false,
                    fixedColumnsColor: Colors.amberAccent,
                    sortColumnIndex: 1,
                    columnSpacing: 5,
                    horizontalMargin: 10,
                    columns: const [
                      DataColumn2(
                        label: Text('STT'),
                        fixedWidth: 30,
                        size: ColumnSize.L,
                      ),
                      DataColumn2(
                          label: Text('Code'), fixedWidth: 120, numeric: false),
                      DataColumn2(
                          label: Text('KL'), fixedWidth: 50, numeric: true),
                      DataColumn2(label: Text('COD'), numeric: true),
                      DataColumn2(label: Text('State'), fixedWidth: 40),
                      DataColumn2(label: Text('?'), fixedWidth: 20),
                    ],
                    rows: List<DataRow>.generate(
                        dx.buuGuis.length,
                        (index) => DataRow(
                                selected: dx.iSeBuuGui.value == index,
                                onSelectChanged: (value) {
                                  dx.iSeBuuGui.value = index;

                                  // thuc hien lenh trong nay
                                  // controller.selectedDanhSachBD(index);
                                  // if (!dx.trangThais[index].) {
                                  //   dx.listBDDen[index].SelectedItem = true;
                                  // } else {
                                  //   dx.listBDDen[index].SelectedItem = false;
                                  // }
                                  dx.update();
                                },
                                color:
                                    MaterialStateProperty.resolveWith<Color?>(
                                        (Set<MaterialState> states) {
                                  if (states.contains(MaterialState.selected)) {
                                    return Theme.of(context)
                                        .colorScheme
                                        .primary
                                        .withOpacity(0.6);
                                  }
                                  return null; // Use the default value.
                                }),
                                cells: [
                                  DataCell(Text(
                                    dx.buuGuis[index].index.toString(),
                                    style: const TextStyle(
                                        fontSize: 15,
                                        color:
                                            Color.fromARGB(255, 102, 102, 96),
                                        fontWeight: FontWeight.bold),
                                  )),
                                  DataCell(Text(
                                    dx.buuGuis[index].maBuuGui!,
                                    style: TextStyle(
                                        fontWeight: FontWeight.w400,
                                        color: dx.buuGuis[index].isBlackList
                                            ? Colors.red
                                            : Colors.black,
                                        fontStyle: FontStyle.italic),
                                  )),
                                  DataCell(Text(
                                    dx.buuGuis[index].khoiLuong == null
                                        ? ""
                                        : dx.buuGuis[index].khoiLuong!
                                            .toString(),
                                  )),
                                  DataCell(Text(
                                    dx.buuGuis[index].money == null
                                        ? ""
                                        : dx.buuGuis[index].money!.toString(),
                                  )),
                                  DataCell(Text(
                                    dx.buuGuis[index].trangThaiRequest == null
                                        ? ""
                                        : dx.buuGuis[index].trangThaiRequest!
                                            .toString(),
                                    style: const TextStyle(color: Colors.teal),
                                  )),
                                  DataCell(
                                    PopupMenuButton<String>(
                                      onSelected: (value) {
                                        // Handle menu item selection.
                                      },
                                      itemBuilder: (BuildContext context) =>
                                          <PopupMenuEntry<String>>[
                                        dx.buuGuis[index].isBlackList
                                            ? PopupMenuItem<String>(
                                                value: 'Xóa khỏi Blacklist',
                                                child: const Text(
                                                    'Xóa khỏi Blacklist'),
                                                onTap: () => {
                                                  controller
                                                      .removeMHFromBlackList(
                                                          index)
                                                },
                                              )
                                            : PopupMenuItem<String>(
                                                value: 'Thêm vào Blacklist',
                                                child: const Text(
                                                    'Thêm vào Blacklist'),
                                                onTap: () => {
                                                  controller
                                                      .addMHToBlackList(index)
                                                },
                                              ),
                                      ],
                                    ),
                                  ),
                                ])),
                  ),
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    ElevatedButton(
                        onPressed: () {
                          controller.stopToPortal();
                        },
                        child: const Text(
                          'Stop',
                          style: TextStyle(color: Colors.red),
                        )),
                    ElevatedButton(
                        onPressed: () {
                          controller.printBD1();
                        },
                        child: const Text('Print')),
                    ElevatedButton(
                        onPressed: controller.isEnableRunBtn.value
                            ? () async {
                                controller.isEnableRunBtn.value = false;

                                controller.sendToPortal();
                                await Future.delayed(
                                    const Duration(seconds: 3));
                                controller.isEnableRunBtn.value = true;
                              }
                            : null,
                        child: const Text(
                          'Send',
                          style: TextStyle(color: Colors.blue),
                        ))
                  ],
                ),
              )
            ],
          ),
        ),
      ),
    );
  }
}
