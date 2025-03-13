import 'package:get/get.dart';

class HostInfo {
  String hostName = "";
  final isOnline = false.obs;
  HostInfo(String host) {
    hostName = host;
    isOnline.value = false;
  }
  HostInfo.defaultConstructor() {
    hostName = "maychu";
    isOnline.value = false;
  }
  setOnline(bool online) {
    isOnline.value = online;
  }

  getOnline() {
    return isOnline;
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is HostInfo &&
          runtimeType == other.runtimeType &&
          hostName == other.hostName;

  @override
  int get hashCode => hostName.hashCode;
}
