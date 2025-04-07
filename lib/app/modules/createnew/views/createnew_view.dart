  import 'package:autocomplete_textfield/autocomplete_textfield.dart';
  import 'package:data_table_2/data_table_2.dart';
  import 'package:flutter/material.dart';
  import 'package:flutter/services.dart';

  import 'package:get/get.dart';
  import 'package:group_button/group_button.dart';

  import '../controllers/createnew_controller.dart';
  import 'option_view.dart';

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
                      ElevatedButton.icon(
                        // Thêm icon nếu muốn
                        icon: const Icon(Icons.cloud_upload_outlined),
                        onPressed: controller.selectedState.value == "CC"
                            ? () => controller.khoiTaoPortal()
                            : null,
                        label: const Text('Khởi tạo'),
                      ),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.settings_outlined),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: controller.useOptions.value
                              ? Colors.blue
                              : Colors.white, // Màu nền khi active
                          // : theme.colorScheme.surface, // Màu nền mặc định
                          foregroundColor: controller.useOptions.value
                              ? Colors.white // Màu chữ khi active
                              : Colors.purple, // Màu chữ mặc định
                          side: !controller
                                  .useOptions.value // Thêm viền khi không active
                              ? BorderSide(color: Colors.purple.withOpacity(0.5))
                              : null,
                        ),
                        onPressed: () {
                          controller.loadOptions();
                          Get.to(() => const OptionView());
                        },
                        label: const Text('Option'),
                      ),
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
                          height: 30,
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
                      padding: const EdgeInsets.all(5.0),
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
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    Card(
                      child: SizedBox(
                        child: Row(
                          children: [
                            Checkbox(
                                value: controller.is1KG.value,
                                onChanged: (e) {
                                  controller.is1KG.value = e!;
                                }),
                            const Text("1KG"),
                            DropdownButton<String>(
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
                            ElevatedButton(
                              child: const Text("Hiện Hết"),
                              onPressed: () {
                                controller.showAll();
                              },
                            )
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    IconButton.filled(
                        onPressed: () {
                          controller.preparePrint();
                        },
                        icon: const Icon(Icons.print)),
                    IconButton.filled(
                        onPressed: () {
                          controller.addKhachHang();
                        },
                        icon: const Icon(Icons.add)),
                    IconButton.filled(
                        onPressed: () {
                          controller.addKhachHangAsQR();
                        },
                        icon: const Icon(Icons.barcode_reader)),
                    Obx(
                      () => Checkbox(
                          value: controller.isAutoWork.value,
                          onChanged: (s) => {
                                controller.isAutoWork.value = s!,
                                if (s) {controller.autoWork()}
                              }),
                    ),
                    IconButton.filled(
                        onPressed: () {
                          controller.sendEndAndPrint();
                        },
                        icon: const Icon(Icons.send_and_archive_rounded)),
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
                          label: Text(''), // Không cần tiêu đề nếu muốn cực nhỏ
                          tooltip: 'Trạng thái', // Tooltip nếu cần
                          fixedWidth: 30, // Cố định chiều rộng rất nhỏ
                        ),
                        DataColumn2(
                            label: Text('Code'), fixedWidth: 120, numeric: false),
                        DataColumn2(
                            label: Text('KL'), fixedWidth: 40, numeric: true),
                        DataColumn2(label: Text('COD'), numeric: true),
                        DataColumn2(label: Text('State'), fixedWidth: 50),
                      ],
                      rows: _rowsBuild(dx, context),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
                  child: SizedBox(
                    width: 400,
                    height: 60,
                    child: ListView(
                      scrollDirection: Axis.horizontal,
                      children: [
                        Row(
                          children: [
                            _buildActionButton(
                              icon: Icons.delete_outline,
                              label: 'Xóa',
                              color: Colors.red,
                              onPressed: () => controller.deleteSelected(),
                              onLongPress: () => controller.deleteAll(),
                            ),
                            const SizedBox(width: 10),
                            _buildActionButton(
                              icon: Icons.send_outlined,
                              label: 'Send',
                              color: Colors.blue,
                              onPressed: () => controller.sendToPC(),
                            ),
                            const SizedBox(width: 10),
                            _buildActionButton(
                              icon: Icons.print_outlined,
                              label: 'In BD1 New',
                              color: Colors.orange,
                              onPressed: () {
                                if (controller.selectedState.value != "CC") {
                                  showDialog(
                                    context: context,
                                    builder: (context) => AlertDialog(
                                      title: const Text('Xác nhận In'),
                                      content: const Text(
                                          'In BD1 và tùy chọn xóa thông tin đã In?'),
                                      actions: [
                                        TextButton(
                                          onPressed: () {
                                            controller.printAll();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('Chỉ In'),
                                        ),
                                        ElevatedButton(
                                          style: ElevatedButton.styleFrom(
                                              backgroundColor:
                                                  Colors.orange[700]),
                                          onPressed: () async {
                                            await controller.printAllAndDelete();
                                            Navigator.pop(context);
                                          },
                                          child: const Text('In và Xoá',
                                              style:
                                                  TextStyle(color: Colors.white)),
                                        ),
                                      ],
                                    ),
                                  );
                                } else {
                                  controller.printAll();
                                }
                              },
                            ),
                            const SizedBox(width: 10),
                            _buildActionButton(
                              icon: Icons.check,
                              label: 'Hoàn tất tin',
                              color: Colors.green,
                              onPressed: () => controller.hoanTatTin(),
                            ),
                            const SizedBox(width: 10),
                            _buildActionButton(
                              icon: Icons.info_outline,
                              label: 'Điều tin',
                              color: Colors.indigo,
                              onPressed: () => controller.dieuTin(),
                            ),
                          ],
                        )
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

    Color _getStatusColor(String? status) {
      switch (status?.toLowerCase()) {
        // Chuyển sang chữ thường để so sánh dễ hơn
        case 'đã chấp nhận':
          return Colors.red;
        case 'đã phân hướng':
          return Colors.blue;
        case 'đang đi thu gom':
          return Colors.yellow;
        case 'nhận hàng thành công':
          return Colors.orange;
        default:
          return Colors.grey; // Màu mặc định nếu trạng thái không khớp
      }
    }

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

    List<DataRow> _rowsBuild(CreatenewController dx, BuildContext context) {
      return List<DataRow>.generate(
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
                          color: Color.fromARGB(255, 102, 102, 96),
                          fontWeight: FontWeight.bold),
                    )),
                    DataCell(
                      Center(
                        // Căn giữa hình tròn trong ô
                        child: Tooltip(
                          // Thêm tooltip để hiển thị trạng thái khi hover
                          message:
                              dx.buuGuis[index].trangThai ?? 'Không xác định',
                          child: Container(
                            width: 12, // Kích thước nhỏ
                            height: 12,
                            decoration: BoxDecoration(
                              color: _getStatusColor(
                                  dx.buuGuis[index].trangThai), // Lấy màu động
                              shape: BoxShape.circle,
                            ),
                          ),
                        ),
                      ),
                    ),
                    DataCell(Text(
                      dx.buuGuis[index].maBuuGui!,
                      style: const TextStyle(
                          fontWeight: FontWeight.w400,
                          fontStyle: FontStyle.italic),
                    )),
                    DataCell(Text(
                      dx.buuGuis[index].khoiLuong == null
                          ? ""
                          : dx.buuGuis[index].khoiLuong!.toString(),
                    )),
                    DataCell(Text(
                      dx.buuGuis[index].money == null
                          ? ""
                          : dx.buuGuis[index].money!.toString(),
                    )),
                    DataCell(Text(
                      dx.buuGuis[index].trangThaiRequest == null
                          ? ""
                          : dx.buuGuis[index].trangThaiRequest!.toString(),
                      style: const TextStyle(color: Colors.teal),
                    )),
                  ]));
    }
  }
