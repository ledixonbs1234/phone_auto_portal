import 'package:flutter/material.dart';

import 'package:get/get.dart';

import '../controllers/print_page_controller.dart';

class PrintPageView extends GetView<PrintPageController> {
  const PrintPageView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('In Mã Hiệu'),
        centerTitle: true,
      ),
      body: Center(
        child: Obx(
          () => Column(
            children: [
              SizedBox(
                width: 150,
                child: TextField(
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 18),
                  controller: controller.editMHC,
                  keyboardType: TextInputType.text,
                  onChanged: (e) {
                    controller.onChangeMH(e);
                  },
                  onSubmitted: (value) {},
                ),
              ),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Text(
                  controller.buuGui.value,
                  style: const TextStyle(
                      fontSize: 17,
                      color: Colors.blue,
                      fontWeight: FontWeight.bold),
                ),
              ),
              ElevatedButton(
                onPressed: () {
                  controller.printMaHieu();
                },
                child: const Text("Print"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
