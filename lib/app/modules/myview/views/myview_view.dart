import 'package:flutter/material.dart';

import 'package:get/get.dart';
import 'package:phone_auto_portal/app/modules/home/khach_hangs_model.dart';

import '../controllers/myview_controller.dart';

class MyviewView extends GetView<MyviewController> {
  const MyviewView({super.key});
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('MyviewView'),
        centerTitle: true,
      ),
      body: Center(
        child: Column(
          children: [
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
          ],
        ),
      ),
    );
  }
}
