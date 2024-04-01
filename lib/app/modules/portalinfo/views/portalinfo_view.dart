import 'package:data_table_2/data_table_2.dart';

import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/portalinfo_controller.dart';

class PortalinfoView extends GetView<PortalinfoController> {
  const PortalinfoView({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Portal Page'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ElevatedButton(
                    onPressed: () {
                      controller.refreshPortal();
                    },
                    child: const Text("Refresh")),
              ],
            ),
            Row(
              children: [
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Row(
                    children: [
                      const Text('Trạng Thái : '),
                      Obx(
                        () => Text(
                          '${controller.stateText}',
                          style: const TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue),
                        ),
                      )
                    ],
                  ),
                ),
              ],
            ),
            Expanded(
              child: GetBuilder<PortalinfoController>(
                builder: (dx) => DataTable2(
                  showCheckboxColumn: true,
                  sortAscending: false,
                  sortColumnIndex: 1,
                  onSelectAll: (value) {
                    for (var row in dx.portals) {
                      row.selected = value!;
                    }
                    dx.update();
                  },
                  columnSpacing: 5,
                  horizontalMargin: 10,
                  columns: const [
                    DataColumn2(
                      label: Text('Thứ Tự'),
                      fixedWidth: 30,
                      size: ColumnSize.L,
                    ),
                    DataColumn2(label: Text('Tên'), numeric: false),
                    DataColumn2(
                        label: Text('SL'), fixedWidth: 30, numeric: true),
                    DataColumn2(label: Text('State'), fixedWidth: 70),
                  ],
                  rows: List<DataRow>.generate(
                      dx.portals.length,
                      (index) => DataRow(
                              selected: dx.portals[index].selected ?? false,
                              onSelectChanged: (value) {
                                dx.iPotal.value = index;
                                if (dx.portals[index].selected != value) {
                                  dx.portals[index].selected = value!;
                                }

                                dx.update();
                              },
                              color: MaterialStateProperty.resolveWith<Color?>(
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
                                  index.toString(),
                                  style: const TextStyle(
                                      fontSize: 15,
                                      color: Color.fromARGB(255, 102, 102, 96),
                                      fontWeight: FontWeight.bold),
                                )),
                                DataCell(Text(
                                  dx.portals[index].name!,
                                  style: const TextStyle(
                                      fontSize: 12,
                                      color: Color(0xff008DDA),
                                      fontStyle: FontStyle.italic),
                                )),
                                DataCell(Text(
                                  dx.portals[index].soLuong == null
                                      ? ""
                                      : dx.portals[index].soLuong.toString(),
                                  style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red),
                                )),
                                DataCell(
                                  dx.portals[index].trangThai == null
                                      ? const Text("")
                                      : dx.portals[index].trangThai == "2"
                                          ? const Text(
                                              "Đang xử lý",
                                              style: TextStyle(
                                                  fontSize: 12,
                                                  color: Colors.green),
                                            )
                                          : dx.portals[index].trangThai == "3"
                                              ? const Text("Chấp Nhận",
                                                  style: TextStyle(
                                                      fontSize: 12,
                                                      color: Color(0xff5356FF)))
                                              : const Text(""),
                                ),
                              ])),
                ),
              ),
            ),
            Obx(
              () => Card(
                child: Column(children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      DropdownButton<String>(
                        value: controller.selectedMayChu.value,
                        onChanged: (value) {
                          controller.selectedMayChu.value = value!;
                        },
                        items: controller.maychus.map((e) {
                          return DropdownMenuItem<String>(
                            value: e,
                            child: Text(e),
                          );
                        }).toList(),
                      ),
                      Checkbox(
                          value: controller.isSortDiNgoai.value,
                          onChanged: (e) {
                            controller.isSortDiNgoai.value = e!;
                          }),
                      const Text("Sắp xếp"),
                    ],
                  ),
                  Row(
                      mainAxisAlignment: MainAxisAlignment.spaceAround,
                      children: [
                        ElevatedButton(
                            onPressed: () {
                              controller.layDuLieu();
                            },
                            onLongPress: () {
                              controller.layDuLieuLo();
                            },
                            child: const Text('Lấy Dữ Liệu')),
                        ElevatedButton(
                            onPressed: () {
                              controller.sendDiNgoai();
                            },
                            child: const Text('Chạy Đi Ngoài')),
                      ])
                ]),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(8.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  ElevatedButton(
                      onPressed: () {
                        controller.editHangHoas();
                      },
                      child: const Text("Sửa")),
                  ElevatedButton(
                    onPressed: () {
                      controller.printPageSelected();
                    },
                    child:
                        const Text("In", style: TextStyle(color: Colors.red)),
                  )
                ],
              ),
            )
          ],
        ),
      ),
    );
  }
}
