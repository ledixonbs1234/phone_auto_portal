import 'package:data_table_2/data_table_2.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../controllers/createnew_controller.dart';

class OptionView extends GetView<CreatenewController> {
  const OptionView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Option'),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(8.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Obx(() => CheckboxListTile(
                    title: const Text('Sử dụng Option'),
                    value: controller.useOptions.value,
                    onChanged: (value) {
                      controller.useOptions.value = value!;
                    },
                  )),
              Obx(() => RadioListTile(
                    title: const Text('Thay đổi KL'),
                    value: 'changeKLFromTo',
                    groupValue: controller.selectedOption.value,
                    onChanged: controller.useOptions.value
                        ? (value) {
                            controller.selectedOption.value = value.toString();
                          }
                        : null,
                  )),
              Obx(() => RadioListTile(
                    title: const Text('Nội dung thay đổi'),
                    value: 'contentChange',
                    groupValue: controller.selectedOption.value,
                    onChanged: controller.useOptions.value
                        ? (value) {
                            controller.selectedOption.value = value.toString();
                          }
                        : null,
                  )),
              Obx(() => RadioListTile(
                    title: const Text('Thêm từ KL hiện tại'),
                    value: 'increaseKL',
                    groupValue: controller.selectedOption.value,
                    onChanged: controller.useOptions.value
                        ? (value) {
                            controller.selectedOption.value = value.toString();
                          }
                        : null,
                  )),
              Obx(() {
                if (controller.selectedOption.value == 'changeKLFromTo') {
                  return TextField(
                    decoration: const InputDecoration(labelText: 'Nhập KL'),
                    keyboardType: TextInputType.number,
                    controller: controller.changeKLFromToController,
                    onChanged: (value) {
                      controller.changeKLFromTo.value =
                          int.tryParse(value) ?? 0;
                    },
                  );
                } else if (controller.selectedOption.value == 'contentChange') {
                  return Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        decoration:
                            const InputDecoration(labelText: 'Nhập nội dung'),
                        controller: controller.contentChangeController,
                        onChanged: (value) {
                          controller.contentChange.value = value;
                        },
                      ),
                      TextField(
                        decoration: const InputDecoration(
                            labelText: 'Nhập KL khi tìm thấy nội dung'),
                        keyboardType: TextInputType.number,
                        controller: controller.contentChangeKLController,
                        onChanged: (value) {
                          controller.contentChangeKL.value =
                              int.tryParse(value) ?? 0;
                        },
                      ),
                      ElevatedButton(
                        onPressed: () {
                          controller.addContentChange();
                        },
                        child: const Text('Thêm nội dung và KL mới'),
                      ),
                      controller.contentChanges.isEmpty
                          ? const Text('Chưa có nội dung thay đổi')
                          : SizedBox(
                              height: MediaQuery.of(context).size.height * 0.3,
                              child: GetBuilder<CreatenewController>(
                                builder: (dx) => DataTable2(
                                  columns: const [
                                    DataColumn2(label: Text('Nội dung')),
                                    DataColumn2(label: Text('Khối lượng')),
                                  ],
                                  rows: dx.contentChanges
                                      .map((contentChange) => DataRow(
                                            cells: [
                                              DataCell(
                                                  Text(contentChange.content)),
                                              DataCell(Text(contentChange
                                                  .khoiLuong
                                                  .toString())),
                                            ],
                                            onLongPress: () {
                                              controller.contentChanges
                                                  .remove(contentChange);
                                            },
                                          ))
                                      .toList(),
                                ),
                              ),
                            )
                    ],
                  );
                } else if (controller.selectedOption.value == 'increaseKL') {
                  return TextField(
                    decoration:
                        const InputDecoration(labelText: 'Nhập KL tăng thêm'),
                    keyboardType: TextInputType.number,
                    controller: controller.increaseKLController,
                    onChanged: (value) {
                      controller.increaseKL.value = int.tryParse(value) ?? 0;
                    },
                  );
                }
                return Container();
              }),
              TextButton(
                onPressed: () {
                  controller.saveOptions();
                  Get.back();
                  printInfo(
                      info: "use options: ${controller.useOptions.value}");
                },
                child: const Text('Xác nhận'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
