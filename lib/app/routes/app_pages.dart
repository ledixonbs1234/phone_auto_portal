import 'package:get/get.dart';

import '../modules/createnew/bindings/createnew_binding.dart';
import '../modules/createnew/views/createnew_view.dart';
import '../modules/detail/bindings/detail_binding.dart';
import '../modules/detail/views/detail_view.dart';
import '../modules/direction_scanning/bindings/direction_scanning_binding.dart';
import '../modules/direction_scanning/views/direction_scanning_view.dart';
import '../modules/edit_page/bindings/edit_page_binding.dart';
import '../modules/edit_page/views/edit_page_view.dart';
import '../modules/home/bindings/home_binding.dart';
import '../modules/home/views/home_view.dart';
import '../modules/myview/bindings/myview_binding.dart';
import '../modules/myview/views/myview_view.dart';
import '../modules/portalinfo/bindings/portalinfo_binding.dart';
import '../modules/portalinfo/views/portalinfo_view.dart';
import '../modules/printPage/bindings/print_page_binding.dart';
import '../modules/printPage/views/print_page_view.dart';
import '../modules/quetthu/bindings/quetthu_binding.dart';
import '../modules/quetthu/views/quetthu_view.dart';
import '../modules/quetmh/bindings/quetmh_binding.dart';
import '../modules/quetmh/views/quetmh_view.dart';
import '../modules/import_images/views/import_images_view.dart';
import '../modules/import_images/controllers/image_import_controller.dart';

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
    GetPage(
      name: _Paths.MYVIEW,
      page: () => const MyviewView(),
      binding: MyviewBinding(),
    ),
    GetPage(
      name: _Paths.QUETTHU,
      page: () => const QuetThuView(),
      binding: QuetThuBinding(),
    ),
    GetPage(
      name: _Paths.QUETMH,
      page: () => const QuetmhView(),
      binding: QuetmhBinding(),
    ),
    GetPage(
      name: _Paths.IMPORT_IMAGES,
      page: () => ImportImagesView(),
      binding: BindingsBuilder(() {
        Get.lazyPut<ImageImportController>(() => ImageImportController());
      }),
    ),
    GetPage(
      name: _Paths.DIRECTION_SCANNING,
      page: () => const DirectionScanningView(),
      binding: DirectionScanningBinding(),
    ),
  ];
}
