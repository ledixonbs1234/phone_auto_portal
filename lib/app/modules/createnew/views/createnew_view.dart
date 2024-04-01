import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:group_button/group_button.dart';

import '../controllers/createnew_controller.dart';

class CreatenewView extends GetView<CreatenewController> {
  const CreatenewView({Key? key}) : super(key: key);
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(controller.khachHang.value.tenKH.toString(),
            style: const TextStyle(
                color: Colors.teal, fontSize: 20, fontWeight: FontWeight.bold)),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            children: [
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Text(
                      "Còn Lại : ${controller.getSLBuuGui()}",
                      style: const TextStyle(
                          color: Colors.redAccent,
                          fontSize: 15,
                          fontWeight: FontWeight.bold),
                    )
                  ],
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const Text('Gợi ý'),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 8.0),
                    child: SizedBox(
                        width: 100,
                        height: 40,
                        child: TextField(
                          focusNode: controller.focusHint,
                          style: const TextStyle(
                              fontWeight: FontWeight.bold, fontSize: 18),
                          controller: controller.textHintController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (s) {
                            controller.textHintController.text = s;
                            controller.onChangeHintMH(s);
                          },
                        )),
                  ),
                  Row(
                    children: [
                      Obx(
                        () => Checkbox(
                            value: controller.isChangeKL.value,
                            onChanged: (e) {
                              controller.isChangeKL.value = e!;
                            }),
                      ),
                      const Text('Thay đổi KL')
                    ],
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('MH'),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: SizedBox(
                        width: 180,
                        height: 40,
                        child: TextField(
                          style: const TextStyle(
                              fontSize: 17,
                              color: Colors.blue,
                              fontWeight: FontWeight.bold),
                          controller: controller.textMHController,
                          keyboardType: TextInputType.number,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (s) {
                            controller.textMHController.text = s;
                          },
                        )),
                  ),
                  const Text('KL'),
                  Padding(
                    padding: const EdgeInsets.only(left: 10.0),
                    child: SizedBox(
                        width: 50,
                        height: 40,
                        child: TextField(
                          style:
                              const TextStyle(fontSize: 16, color: Colors.pink),
                          controller: controller.textKLController,
                          keyboardType: TextInputType.number,
                          focusNode: controller.focusKL,
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          onChanged: (s) {
                            controller.textKLController.text = s;
                          },
                          onSubmitted: (s) {
                            //thuc hien add number trong nay
                            controller.addKhachHang();
                            controller.focusHint.requestFocus();
                          },
                        )),
                  )
                ],
              ),
              Row(
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        const SizedBox(
                          width: 50,
                        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  GroupButton(
                      buttons: const ['500'],
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(500)),
                  GroupButton(
                      buttons: const ['1000'],
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(1000)),
                  GroupButton(
                      buttons: const ['1500'],
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(1500)),
                  GroupButton(
                      buttons: const ['2000'],
                      onSelected: (value, index, isSelected) =>
                          controller.addKL(2000))
                ],
              ),
              SizedBox(
                height: Get.width,
                child: GetBuilder<CreatenewController>(
                  builder: (dx) => DataTable2(
                    showCheckboxColumn: false,
                    sortAscending: false,
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
                          label: Text('KL'), fixedWidth: 60, numeric: true),
                      DataColumn2(label: Text('COD'), numeric: true),
                      DataColumn2(label: Text('State'), fixedWidth: 50),
                    ],
                    rows: List<DataRow>.generate(
                        dx.buuGuis.length,
                        (index) => DataRow(
                                selected: index == dx.iBuuGui.value,
                                onSelectChanged: (value) {
                                  dx.iBuuGui.value = index;

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
                                    style: const TextStyle(
                                        fontWeight: FontWeight.w400,
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
                                ])),
                  ),
                ),
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  Row(
                    children: [
                      ElevatedButton(
                          child: const Text(
                            'Xóa Đã Chọn',
                          ),
                          onPressed: () => controller.deleteSelected()),
                      SizedBox(
                        width: 10,
                      ),
                      ElevatedButton(
                          child: const Text(
                            'Xóa',
                            style: TextStyle(color: Colors.red),
                          ),
                          onPressed: () => controller.deleteAll())
                    ],
                  ),
                  ElevatedButton(
                      child: const Text(
                        'Send',
                        style: TextStyle(color: Colors.blue),
                      ),
                      onPressed: () => controller.sendToPC())
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
