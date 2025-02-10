import 'package:autocomplete_textfield/autocomplete_textfield.dart';
import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:get/get.dart';
import 'package:get_storage/get_storage.dart';
import 'package:group_button/group_button.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../controllers/createnew_controller.dart';

class CreatenewView extends GetView<CreatenewController> {
  const CreatenewView({super.key});
  @override
  Widget build(BuildContext context) {
    var keys = GlobalKey<AutoCompleteTextFieldState<String>>();
    return Scaffold(
      appBar: AppBar(
        title: Obx(
          () => Text(controller.tenKH.value,
              style: const TextStyle(
                  color: Colors.teal,
                  fontSize: 20,
                  fontWeight: FontWeight.bold)),
        ),
        centerTitle: true,
      ),
      body: SafeArea(
        child: SizedBox(
          height: MediaQuery.of(context).size.height,
          child: Column(
            children: [
              Obx(
                () => Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      color: Colors.blue,
                      child: Text(
                        "Còn Lại : ${controller.susggestMHs.length}",
                        style: const TextStyle(
                            color: Colors.white,
                            fontSize: 15,
                            fontWeight: FontWeight.bold),
                      ),
                    ),
                    ElevatedButton(
                        onPressed: controller.selectedState.value == "CC"
                            ? () => controller.khoiTaoPortal()
                            : null,
                        child: const Text('Khởi tạo')),
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
                        width: 150,
                        height: 40,
                        child: Autocomplete<String>(fieldViewBuilder: (context,
                            textEditingController,
                            focusNode,
                            onFieldSubmitted) {
                          controller.textHintController = textEditingController;
                          controller.focusHint = focusNode;
                          return TextField(
                            controller: textEditingController,
                            focusNode: focusNode,
                            keyboardType: TextInputType.number,
                            inputFormatters: <TextInputFormatter>[
                              FilteringTextInputFormatter.digitsOnly
                            ],
                          );
                        }, optionsBuilder: ((textEditingValue) {
                          if (textEditingValue.text == '') {
                            return const Iterable<String>.empty();
                          }
                          var list = controller.susggestMHs.where((element) =>
                              element.contains(textEditingValue.text));
                          if (list.length == 1 &&
                              textEditingValue.text.length != 13) {
                            controller.onFindedMH(list.first);
                            return const Iterable<String>.empty();
                          }
                          return list;
                        }), onSelected: (options) {
                          debugPrint(' You selected $options');
                          controller.onFindedMH(options);
                        }),
                      )),
                  Obx(
                    () => Row(
                      children: [
                        Checkbox(
                            value: controller.isChangeKL.value,
                            onChanged: (e) {
                              controller.isChangeKL.value = e!;
                            }),
                        const Text('KL'),
                        // Checkbox(
                        //     value: controller.isDo.value,
                        //     onChanged: (e) {
                        //       controller.isDo.value = e!;
                        //     }),
                        // const Text('Đo'),
                      ],
                    ),
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
                            // controller.textMHController.text = s;
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
                          inputFormatters: <TextInputFormatter>[
                            FilteringTextInputFormatter.digitsOnly
                          ],
                          focusNode: controller.focusKL,
                          onChanged: (s) {
                            // controller.textKLController.text = s;
                          },
                          onSubmitted: (s) {
                            //thuc hien add number trong nay
                            if (controller.isDo.value) {
                              controller.focusK1.requestFocus();
                            } else {
                              controller.addKhachHang();
                              controller.focusHint.requestFocus();
                            }
                          },
                        )),
                  )
                ],
              ),
              Row(
                mainAxisAlignment: MainAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        const SizedBox(
                          width: 20,
                        ),
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
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Padding(
                  //   padding: const EdgeInsets.symmetric(horizontal: 8.0),
                  //   child: SizedBox(
                  //     width: 50,
                  //     height: 50,
                  //     child: TextField(
                  //       textAlign: TextAlign.center,
                  //       focusNode: controller.focusK1,
                  //       minLines: null,
                  //       controller: controller.k1,
                  //       keyboardType: TextInputType.number,
                  //       inputFormatters: <TextInputFormatter>[
                  //         FilteringTextInputFormatter.digitsOnly
                  //       ],
                  //       onChanged: (s) {
                  //         controller.listKichThuoc[0] = s;
                  //       },
                  //       onEditingComplete: () =>
                  //           controller.focusK2.requestFocus(),
                  //       onSubmitted: (value) =>
                  //           controller.focusK2.requestFocus(),
                  //       //rounded textfield
                  //     ),
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: SizedBox(
                  //     width: 50,
                  //     child: TextField(
                  //       focusNode: controller.focusK2,
                  //       textAlign: TextAlign.center,
                  //       minLines: null,
                  //       controller: controller.k2,
                  //       keyboardType: TextInputType.number,
                  //       inputFormatters: <TextInputFormatter>[
                  //         FilteringTextInputFormatter.digitsOnly
                  //       ],
                  //       onEditingComplete: () =>
                  //           controller.focusK3.requestFocus(),
                  //       onChanged: (s) {
                  //         controller.listKichThuoc[1] = s;
                  //       },
                  //       onSubmitted: (value) =>
                  //           controller.focusK3.requestFocus(),
                  //       //rounded textfield
                  //     ),
                  //   ),
                  // ),
                  // Padding(
                  //   padding: const EdgeInsets.all(8.0),
                  //   child: SizedBox(
                  //     width: 50,
                  //     child: TextField(
                  //       textAlign: TextAlign.center,
                  //       focusNode: controller.focusK3,
                  //       minLines: null,
                  //       controller: controller.k3,
                  //       onEditingComplete: () => controller.addKhachHang(),
                  //       keyboardType: TextInputType.number,
                  //       inputFormatters: <TextInputFormatter>[
                  //         FilteringTextInputFormatter.digitsOnly
                  //       ],
                  //       onChanged: (s) {
                  //         controller.listKichThuoc[2] = s;
                  //       },
                  //       onSubmitted: (value) {
                  //         //THucw hien add khach hang voi kich thuoc cho truowc
                  //         controller.addKhachHang();
                  //       },
                  //       //rounded textfield
                  //     ),
                  //   ),
                  // ),
                  IconButton.filled(
                      onPressed: () {
                        controller.preparePrint();
                      },
                      icon: const Icon(Icons.print)),
                  Obx(
                    () => DropdownButton<String>(
                      value: controller.selectedState.value,
                      onChanged: (value) async {
                        controller.selectedState.value = value!;
                        if (value != "CC") {
                          await controller.getDiNgoaisTempFromFirebase();
                        }
                      },
                      items: const [
                        DropdownMenuItem(
                          value: "NTB",
                          child: Text('Nam Trung Bộ'),
                        ),
                        DropdownMenuItem(
                          value: "DN",
                          child: Text('Đà Nẵng'),
                        ),
                        DropdownMenuItem(
                          value: "CL",
                          child: Text('Còn Lại'),
                        ),
                        DropdownMenuItem(
                          value: "CC",
                          child: Text('Chưa Chọn'),
                        ),
                      ],
                    ),
                  ),
                  IconButton.filled(
                      onPressed: () {
                        controller.addKhachHang();
                      },
                      icon: const Icon(Icons.add)),
                  IconButton.filled(
                      onPressed: () {
                        // controller.addKhachHangAsQR();
                        // controller.addKhachHangAsQRV2();
                        // showModalBottomSheet(
                        //   context: context,
                        //   builder: (context) {
                        //     return MobileScanner(
                        //       onDetect: (barcodeCapture) {
                        //         controller.textHintController.text =
                        //             barcodeCapture.barcodes.first.rawValue ??
                        //                 "";

                        //         // Navigator.pop(
                        //         //     context); // Close the bottom sheet
                        //       },
                        //     );
                        //   },
                        // );
                        List<String> notMHs = [];
                        Get.dialog(
                          // barrierColor: Colors.transparent,
                          AlertDialog(
                            alignment: Alignment.topCenter,
                            content: SizedBox(
                              width: 350,
                              height: 300,
                              child: MobileScanner(
                                
                                onDetect: (barcodeCapture) {
                                  
                                  final barcode =
                                      barcodeCapture.barcodes.first.rawValue ??
                                          '';
                                  controller.addKhachHangAsQRV2(barcode,notMHs);
                                },
                              ),
                            ),
                          ),
                        );
                      },
                      icon: const Icon(Icons.barcode_reader)),
                ],
              ),
              Expanded(
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
                                  dx.checkSelected();
                                  dx.update();
                                },
                                color: WidgetStateProperty.resolveWith<Color?>(
                                    (Set<WidgetState> states) {
                                  if (states.contains(WidgetState.selected)) {
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
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: SizedBox(
                  width: 400,
                  height: 40,
                  child: ListView(
                    scrollDirection: Axis.horizontal,
                    children: [
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 1),
                        child: ElevatedButton(
                            child: const Text(
                              'Xóa',
                              style: TextStyle(color: Colors.red),
                            ),
                            onLongPress: () => controller.deleteAll(),
                            onPressed: () => controller.deleteSelected()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 1),
                        child: ElevatedButton(
                          onPressed: () {
                            controller.selectedState.value != "CC"
                                ? showDialog(
                                    context: context,
                                    builder: (BuildContext context) {
                                      return AlertDialog(
                                        title: const Text('Confirm Print'),
                                        content: const Text(
                                            'Bạn có muốn in BD1 và xoá thông tin đã In không?'),
                                        actions: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              controller.printAll();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text('Chỉ In'),
                                          ),
                                          ElevatedButton(
                                            onPressed: () async {
                                              await controller
                                                  .printAllAndDelete();
                                              Navigator.of(context).pop();
                                            },
                                            child: const Text(
                                              'In và Xoá',
                                              style:
                                                  TextStyle(color: Colors.red),
                                            ),
                                          ),
                                        ],
                                      );
                                    },
                                  )
                                : controller.printAll();
                          },
                          child: const Text('In BD1 New'),
                        ),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 1),
                        child: ElevatedButton(
                            child: const Text(
                              'Send',
                              style: TextStyle(color: Colors.blue),
                            ),
                            onPressed: () => controller.sendToPC()),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 1),
                        child: ElevatedButton(
                            onPressed: () {
                              controller.hoanTatTin();
                            },
                            child: const Text(
                              'Hoàn tất tin',
                            )),
                      ),
                      Padding(
                        padding: const EdgeInsets.symmetric(
                            vertical: 2, horizontal: 1),
                        child: ElevatedButton(
                            onPressed: () {
                              controller.dieuTin();
                            },
                            child: const Text(
                              'Điều tin',
                            )),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
