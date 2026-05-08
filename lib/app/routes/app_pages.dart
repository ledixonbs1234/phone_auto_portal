import 'package:get/get.dart';

import '../modules/createnew/bindings/createnew_binding.dart';
import '../modules/createnew/views/createnew_view.dart';
import '../modules/khoi_tao_moi/bindings/khoi_tao_moi_binding.dart';
import '../modules/khoi_tao_moi/views/khoi_tao_moi_view.dart';
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
import '../modules/capture_image/bindings/capture_image_binding.dart';
import '../modules/capture_image/views/capture_image_view.dart';
import '../modules/dingoai_rt/bindings/dingoai_rt_binding.dart';
import '../modules/dingoai_rt/views/dingoai_rt_view.dart';
import '../modules/danhsachbd/bindings/danhsachbd_binding.dart';
import '../modules/danhsachbd/views/danhsachbd_view.dart';
import '../modules/taodon/bindings/taodon_binding.dart';
import '../modules/taodon/views/taodon_view.dart';
import '../modules/nhaphang/bindings/nhaphang_binding.dart';
import '../modules/nhaphang/views/nhaphang_view.dart';

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
      name: _Paths.KHOITAOMOI,
      page: () => KhoiTaoMoiView(),
      binding: KhoiTaoMoiBinding(),
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
    GetPage(
      name: _Paths.CAPTURE_IMAGE,
      page: () => const CaptureImageView(),
      binding: CaptureImageBinding(),
    ),
    GetPage(
      name: _Paths.DINGOAI_RT,
      page: () => const DiNgoaiRtView(),
      binding: DiNgoaiRtBinding(),
    ),
    GetPage(
      name: _Paths.DANHSACHBD,
      page: () => const DanhSachBDView(),
      binding: DanhSachBDBinding(),
    ),
    GetPage(
      name: _Paths.TAODON,
      page: () => const TaodonView(),
      binding: TaodonBinding(),
    ),
    GetPage(
      name: _Paths.NHAPHANG,
      page: () => const NhapHangView(),
      binding: NhapHangBinding(),
    ),
  ];
}
