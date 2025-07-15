import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/controllers/home_controller.dart';
import 'package:phone_auto_portal/app/modules/home/host_info.dart';

class HostSelectionWidget extends StatelessWidget {
  const HostSelectionWidget({super.key});

  @override
  Widget build(BuildContext context) {
    final HomeController controller = Get.find<HomeController>();
    final screenWidth = MediaQuery.of(context).size.width;
    final isNarrowScreen = screenWidth < 450;

    return LayoutBuilder(
      builder: (context, constraints) {
        if (isNarrowScreen || constraints.maxWidth < 450) {
          // Compact layout for narrow screens
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 2.0, horizontal: 10.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.outlined(
                  onPressed: () {
                    controller.sendPing();
                  },
                  icon: const Icon(
                    Icons.refresh_outlined,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 20,
                    minHeight: 20,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Obx(() => DropdownButton<HostInfo>(
                        value: controller.selectedMayChu.value,
                        onChanged: (value) {
                          controller.selectedMayChu.value = value!;
                          controller.saveKey(value.hostName);
                        },
                        onTap: () {
                          controller.sendPing();
                        },
                        isExpanded: true,
                        isDense: false,
                        items: controller.maychus.map((HostInfo e) {
                          return DropdownMenuItem<HostInfo>(
                            value: e,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    e.hostName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Obx(() => Padding(
                                      padding: const EdgeInsets.only(left: 6),
                                      child: Icon(
                                        Icons.circle,
                                        color: e.isOnline.value
                                            ? Colors.green
                                            : Colors.red,
                                        size: 8,
                                      ),
                                    ))
                              ],
                            ),
                          );
                        }).toList(),
                      )),
                ),
                const SizedBox(width: 8),
                const Text('cách', style: TextStyle(fontSize: 13)),
                const SizedBox(width: 6),
                SizedBox(
                  width: 35,
                  child: TextField(
                    controller: controller.dayLastController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      isDense: true,
                    ),
                  ),
                ),
              ],
            ),
          );
        } else {
          // Normal layout for wider screens
          return Padding(
            padding:
                const EdgeInsets.symmetric(vertical: 2.0, horizontal: 16.0),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                IconButton.outlined(
                  onPressed: () {
                    controller.sendPing();
                  },
                  icon: const Icon(
                    Icons.refresh_outlined,
                    size: 20,
                  ),
                  padding: const EdgeInsets.all(8),
                  constraints: const BoxConstraints(
                    minWidth: 40,
                    minHeight: 40,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Obx(() => DropdownButton<HostInfo>(
                        value: controller.selectedMayChu.value,
                        onChanged: (value) {
                          controller.selectedMayChu.value = value!;
                          controller.saveKey(value.hostName);
                        },
                        onTap: () {
                          controller.sendPing();
                        },
                        isExpanded: true,
                        isDense: false,
                        items: controller.maychus.map((HostInfo e) {
                          return DropdownMenuItem<HostInfo>(
                            value: e,
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                Flexible(
                                  child: Text(
                                    e.hostName,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Obx(() => Padding(
                                      padding: const EdgeInsets.only(left: 8),
                                      child: Icon(
                                        Icons.circle,
                                        color: e.isOnline.value
                                            ? Colors.green
                                            : Colors.red,
                                        size: 10,
                                      ),
                                    ))
                              ],
                            ),
                          );
                        }).toList(),
                      )),
                ),
                const SizedBox(width: 16),
                const Text('cách'),
                const SizedBox(width: 8),
                SizedBox(
                  width: 50,
                  child: TextField(
                    controller: controller.dayLastController,
                    textAlign: TextAlign.center,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      contentPadding:
                          EdgeInsets.symmetric(vertical: 8, horizontal: 4),
                      isDense: true,
                    ),
                  ),
                )
              ],
            ),
          );
        }
      },
    );
  }
}
