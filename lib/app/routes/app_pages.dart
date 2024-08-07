import 'package:get/get.dart';

import '../modules/createnew/bindings/createnew_binding.dart';
import '../modules/createnew/views/createnew_view.dart';
import '../modules/detail/bindings/detail_binding.dart';
import '../modules/detail/views/detail_view.dart';
import '../modules/edit_page/bindings/edit_page_binding.dart';
import '../modules/edit_page/views/edit_page_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/portalinfo/bindings/portalinfo_binding.dart';
import '../modules/portalinfo/views/portalinfo_view.dart';
import '../modules/printPage/bindings/print_page_binding.dart';
import '../modules/printPage/views/print_page_view.dart';

part 'app_routes.dart';

class AppPages {
  AppPages._();

  static const INITIAL = Routes.HOME;

  static final routes = [
    GetPage(
      name: _Paths.HOME,
      page: () => const HomeView(),
      binding: HomeBinding(),
    ),
    GetPage(
      name: _Paths.DETAIL,
      page: () => const DetailView(),
      binding: DetailBinding(),
    ),
    GetPage(
      name: _Paths.CREATENEW,
      page: () => const CreatenewView(),
      binding: CreatenewBinding(),
    ),
    GetPage(
      name: _Paths.PORTALINFO,
      page: () => const PortalinfoView(),
      binding: PortalinfoBinding(),
    ),
    GetPage(
      name: _Paths.PRINT_PAGE,
      page: () => const PrintPageView(),
      binding: PrintPageBinding(),
    ),
    GetPage(
      name: _Paths.EDIT_PAGE,
      page: () => const EditPageView(),
      binding: EditPageBinding(),
    ),
  ];
}
