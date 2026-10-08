package com.example.phone_auto_portal

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.ClipboardManager
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Color
import android.graphics.Path
import android.graphics.PixelFormat
import android.graphics.Rect
import android.graphics.drawable.GradientDrawable
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.Gravity
import android.view.MotionEvent
import android.view.View
import android.view.WindowManager
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class TmsAccessibilityService : AccessibilityService() {

    enum class AutomationStep {
        IDLE,
        STEP_1_ACCEPT_ORDER,       // Scene 1: Nhận lệnh / Bấm [NHẬN LỆNH] & popup [Đồng ý]
        STEP_2_VIEW_DETAIL,        // Scene 2: Mở Chi tiết chuyến (tab Đã nhận -> bấm [CHI TIẾT])
        STEP_3_START_TRIP,          // Scene 3: Bắt đầu chuyến đi (Bấm cam [BẮT ĐẦU])
        STEP_3B_CLICK_POINT_593200, // Scene 4: Lộ trình -> Chọn Điểm 1 (593200)
        STEP_5_CLICK_VAO_POINT_1,   // Scene 5: Chi tiết Điểm 1 -> Bấm [Đến điểm] & popup [Đồng ý]
        STEP_6_CLICK_SCAN_BD10_1,   // Scene 6: Điểm 1 đã đến -> Bấm nút [SCAN BD10]
        STEP_7_INPUT_BD10_CODE,     // Scene 7: Popup BD10 Điểm 1 -> Điền mã BD10 & bấm [Thêm]
        STEP_8_CONFIRM_BD10_1,      // Scene 8: Popup BD10 Điểm 1 -> Bấm [Xác nhận]
        STEP_9_CLICK_RA_POINT_1,    // Scene 9: Chi tiết Điểm 1 -> Bấm [Đi khỏi điểm] & popup [Đồng ý]
        STEP_10_SELECT_SECOND_POINT,// Scene 10: Lộ trình -> Chọn Điểm 2 (593280)
        STEP_11_CLICK_VAO_POINT_2,  // Scene 11: Chi tiết Điểm 2 -> Bấm [Đến điểm] & popup [Đồng ý]
        STEP_12_CLICK_SCAN_BD10_2,  // Scene 12: Điểm 2 đã đến -> Bấm nút [SCAN BD10]
        STEP_13_CLICK_DS_BD10_LEN,  // Scene 13: Popup BD10 Điểm 2 -> Bấm [DS BD10 lên] (xanh lá)
        STEP_14_SELECT_ALL_AND_ADD, // Scene 14: Popup con -> Chọn mã & bấm [Thêm] (xanh lá)
        STEP_15_CONFIRM_BD10_2,     // Scene 15: Popup BD10 Điểm 2 -> Bấm [Xác nhận]
        STEP_16_CLICK_RA_POINT_2,   // Scene 16: Chi tiết Điểm 2 -> Bấm [Đi khỏi điểm] & popup [Đồng ý]
        STEP_DONE                   // Hoàn thành toàn bộ
    }

    companion object {
        private const val TAG = "TmsAccessibilityService"
        var instance: TmsAccessibilityService? = null
            private set

        var isRunning: Boolean = false
            private set

        var isContinuousMode: Boolean = false
            private set

        var currentStep: AutomationStep = AutomationStep.IDLE
            private set

        var bd10CodeToInput: String = ""
        var targetAppName: String = "TMS"
        var targetPackageName: String = ""

        val RUNNABLE_STEPS = listOf(
            AutomationStep.STEP_1_ACCEPT_ORDER,
            AutomationStep.STEP_2_VIEW_DETAIL,
            AutomationStep.STEP_3_START_TRIP,
            AutomationStep.STEP_3B_CLICK_POINT_593200,
            AutomationStep.STEP_5_CLICK_VAO_POINT_1,
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1,
            AutomationStep.STEP_7_INPUT_BD10_CODE,
            AutomationStep.STEP_8_CONFIRM_BD10_1,
            AutomationStep.STEP_9_CLICK_RA_POINT_1,
            AutomationStep.STEP_10_SELECT_SECOND_POINT,
            AutomationStep.STEP_11_CLICK_VAO_POINT_2,
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2,
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN,
            AutomationStep.STEP_14_SELECT_ALL_AND_ADD,
            AutomationStep.STEP_15_CONFIRM_BD10_2,
            AutomationStep.STEP_16_CLICK_RA_POINT_2
        )

        // Cấu hình khoảng thời gian giãn cách giữa các lần bấm lại (Debounce / Rate-limit)
        private const val DEFAULT_ACTION_INTERVAL_MS = 1400L // 1.4 giây đối với click thường
        private const val NETWORK_ACTION_INTERVAL_MS = 2200L // 2.2 giây đối với thao tác có gọi mạng/popup
        private const val MAX_RETRY_PER_SCENE = 15 // Tối đa 15 lần retry (~20-30s) trước khi dừng an toàn

        fun isServiceRunning(): Boolean {
            return instance != null
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    
    // Quản lý Reactive State Machine
    private var activeScene: AutomationStep = AutomationStep.IDLE
    private var lastActionTimestamp: Long = 0L
    private var sceneRetryCount: Int = 0
    private var totalInactiveCount: Int = 0

    // Ghi nhớ trạng thái đã hoàn thành xử lý popup BD10 tại từng điểm
    private var isPoint1Bd10Done: Boolean = false
    private var isPoint2Bd10Done: Boolean = false
    private var isClickBD10OneTime: Boolean = false

    // Window Manager cho thanh điều khiển nổi
    private var windowManager: WindowManager? = null
    private var stopOverlayView: View? = null

    // Vòng lặp quan sát và phản ứng tự thích ứng (State-Driven Reactive Loop)
    private val automationRunnable = object : Runnable {
        override fun run() {
            if (!isRunning || !isContinuousMode) return
            try {
                processAutomationCycle()
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi trong processAutomationCycle: ${e.message}", e)
            }
            if (isRunning && isContinuousMode) {
                mainHandler.postDelayed(this, 500) // Chu kỳ quét 500ms cực kỳ mượt mà
            }
        }
    }

    override fun onServiceConnected() {
        super.onServiceConnected()
        instance = this
        Log.d(TAG, "TmsAccessibilityService connected successfully")
        Toast.makeText(this, "TMS Automation Service đã kết nối", Toast.LENGTH_SHORT).show()
    }

    override fun onAccessibilityEvent(event: AccessibilityEvent?) {
        if (!isRunning || !isContinuousMode || event == null) return

        val pkg = event.packageName?.toString() ?: ""
        if (pkg.isNotEmpty() && !isTmsPackage(pkg) && !pkg.contains("phone_auto_portal")) {
            return
        }

        // Khi cửa sổ hoặc nội dung thay đổi, kích hoạt ngay chu kỳ kiểm tra
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            mainHandler.removeCallbacks(automationRunnable)
            mainHandler.post(automationRunnable)
        }
    }

    override fun onInterrupt() {
        Log.w(TAG, "TmsAccessibilityService interrupted")
        stopAutomation()
    }

    override fun onDestroy() {
        super.onDestroy()
        instance = null
        stopAutomation()
        removeStopOverlayButton()
        Log.d(TAG, "TmsAccessibilityService destroyed")
    }

    // =========================================================================
    // QUẢN LÝ TIẾN TRÌNH TỰ ĐỘNG HÓA (AUTOMATION ENGINE)
    // =========================================================================

    fun startAutomation(code: String, appName: String = "TMS", startStepName: String = "STEP_1_ACCEPT_ORDER") {
        bd10CodeToInput = code.trim()
        targetAppName = appName
        isRunning = true
        isContinuousMode = true

        val parsedStep = try {
            AutomationStep.valueOf(startStepName)
        } catch (e: Exception) {
            AutomationStep.STEP_1_ACCEPT_ORDER
        }
        currentStep = parsedStep
        activeScene = AutomationStep.IDLE
        lastActionTimestamp = 0L
        sceneRetryCount = 0
        totalInactiveCount = 0
        isPoint1Bd10Done = false
        isPoint2Bd10Done = false

        Log.i(TAG, "🚀 BẮT ĐẦU TỰ ĐỘNG HÓA TMS (State-Driven Engine) | Bước đầu: $currentStep | Mã BD10: $bd10CodeToInput")
        Toast.makeText(this, "Bắt đầu tự động hóa: ${getStepShortName(currentStep)}", Toast.LENGTH_SHORT).show()

        // 1. Hiển thị thanh điều khiển nổi
        showStopOverlayButton()
        updateOverlayStepText(currentStep.name)

        // 2. Mở App TMS
        launchApp(targetAppName)

        // 3. Chạy vòng lặp tự động hóa
        mainHandler.removeCallbacks(automationRunnable)
        mainHandler.postDelayed(automationRunnable, 1200)
    }

    private fun getStepShortName(step: AutomationStep): String {
        return when (step) {
            AutomationStep.STEP_1_ACCEPT_ORDER -> "1. Nhận Lệnh"
            AutomationStep.STEP_2_VIEW_DETAIL -> "2. Chi Tiết"
            AutomationStep.STEP_3_START_TRIP -> "3. Bắt Đầu"
            AutomationStep.STEP_3B_CLICK_POINT_593200 -> "3B. Bấm 593200"
            AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> "5. Vào Điểm 1"
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1 -> "6. Scan Điểm 1"
            AutomationStep.STEP_7_INPUT_BD10_CODE -> "7. Nhập Mã BD10"
            AutomationStep.STEP_8_CONFIRM_BD10_1 -> "8. Xác Nhận Điểm 1"
            AutomationStep.STEP_9_CLICK_RA_POINT_1 -> "9. Ra Điểm 1"
            AutomationStep.STEP_10_SELECT_SECOND_POINT -> "10. Chọn Điểm 2"
            AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> "11. Vào Điểm 2"
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2 -> "12. Scan Điểm 2"
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> "13. DS BD10 Lên"
            AutomationStep.STEP_14_SELECT_ALL_AND_ADD -> "14. Chọn & Thêm"
            AutomationStep.STEP_15_CONFIRM_BD10_2 -> "15. Xác Nhận Điểm 2"
            AutomationStep.STEP_16_CLICK_RA_POINT_2 -> "16. Ra Điểm 2 (Xong)"
            AutomationStep.STEP_DONE -> "Hoàn Thành"
            AutomationStep.IDLE -> "Chờ lệnh"
        }
    }

    fun stopAutomation() {
        if (!isRunning && currentStep == AutomationStep.IDLE) return
        isRunning = false
        isContinuousMode = false
        currentStep = AutomationStep.IDLE
        activeScene = AutomationStep.IDLE
        isPoint1Bd10Done = false
        isPoint2Bd10Done = false
        mainHandler.removeCallbacks(automationRunnable)
        removeStopOverlayButton()
        Log.i(TAG, "🛑 Đã dừng tự động hóa TMS")
    }

    private fun isTmsPackage(pkgName: String): Boolean {
        if (targetPackageName.isNotEmpty() && pkgName.equals(targetPackageName, ignoreCase = true)) {
            return true
        }
        val lower = pkgName.lowercase()
        return lower.contains("stm")
    }

    // =========================================================================
    // TRÁI TIM ĐIỀU PHỐI TỰ THÍCH ỨNG (STATE-DRIVEN AUTONOMOUS ENGINE)
    // =========================================================================

    /**
     * Vòng lặp điều phối chính:
     * 1. Quét nhận diện chính xác Scene hiện tại trên màn hình TMS.
     * 2. Nếu phát hiện Scene MỚI (Scene tiếp theo đã tới) -> Chuyển trạng thái & Thực thi ngay.
     * 3. Nếu vẫn ở Scene CŨ (Scene tiếp theo CHƯA TỚI) -> Chờ đúng chu kỳ và BẤM LẠI BUTTON CŨ (Retry)!
     */
    private fun processAutomationCycle() {
        if (!isRunning || !isContinuousMode) return

        val rootNode = rootInActiveWindow ?: run {
            Log.d(TAG, "rootInActiveWindow is null, đang chờ...")
            return
        }

        val currentPkg = rootNode.packageName?.toString() ?: ""

        if (currentPkg.isNotEmpty() && !isTmsPackage(currentPkg)) {
            if (currentPkg.contains("phone_auto_portal")) {
                Log.d(TAG, "Đang ở app portal, đang chờ chuyển sang TMS...")
                return
            }
            totalInactiveCount++
            if (totalInactiveCount % 6 == 0) {
                Log.d(TAG, "App TMS không active ($currentPkg), đang chờ...")
            }
            return
        }

        if (currentPkg.isNotEmpty() && isTmsPackage(currentPkg) && targetPackageName.isEmpty()) {
            targetPackageName = currentPkg
            Log.i(TAG, "Đã nhận diện package TMS active: $targetPackageName")
        }

        // 1. NHẬN DIỆN MÀN HÌNH HIỆN TẠI (Detect Current Active Scene)
        val detectedScene = detectCurrentScene(rootNode)

        if (detectedScene == AutomationStep.IDLE) {
            // Màn hình đang load hoặc ở trạng thái chưa định danh, kiên nhẫn chờ chu kỳ tiếp
            return
        }

        if (detectedScene == AutomationStep.STEP_DONE) {
            Log.i(TAG, "==============================================")
            Log.i(TAG, "🎉 ĐÃ HOÀN THÀNH TOÀN BỘ TIẾN TRÌNH TỰ ĐỘNG HÓA TMS!")
            Log.i(TAG, "==============================================")
            Toast.makeText(this, "🎉 Hoàn tất tự động hóa TMS!", Toast.LENGTH_LONG).show()
            stopAutomation()
            return
        }

        val now = System.currentTimeMillis()

        // 2. NẾU PHÁT HIỆN SCENE MỚI (Màn hình đã chuyển sang Scene tiếp theo thành công)
        if (detectedScene != activeScene) {
            Log.i(TAG, "🔄 [SCENE CHUYỂN ĐỔI] $activeScene ──> $detectedScene (${getStepShortName(detectedScene)})")
            activeScene = detectedScene
            currentStep = detectedScene
            sceneRetryCount = 0
            updateOverlayStepText(detectedScene.name)

            // Thực thi ngay hành động của Scene mới
            val executed = executeSceneAction(detectedScene, rootNode)
            if (executed) {
                lastActionTimestamp = now
            }
            return
        }

        // 3. NẾU VẪN ĐANG Ở SCENE CŨ (Scene tiếp theo CHƯA TỚI):
        val requiredInterval = getRequiredIntervalForScene(detectedScene)

        // Kiểm tra xem đã trôi qua đủ thời gian giãn cách chưa
        if (now - lastActionTimestamp >= requiredInterval) {
            sceneRetryCount++

            if (sceneRetryCount > MAX_RETRY_PER_SCENE) {
                Log.w(TAG, "⚠️ Scene $detectedScene đã thử lại $sceneRetryCount lần quá giới hạn. Đang reset thử lại...")
                sceneRetryCount = 1
            }

            Log.w(TAG, "🔁 [RETRY #$sceneRetryCount] Scene tiếp theo chưa tới, đang bấm lại nút của: ${getStepShortName(detectedScene)}...")
            mainHandler.post {
                Toast.makeText(this, "👉 Nhấn lại: ${getStepShortName(detectedScene)} (#$sceneRetryCount)", Toast.LENGTH_SHORT).show()
            }

            val executed = executeSceneAction(detectedScene, rootNode)
            if (executed) {
                lastActionTimestamp = now
            }
        }
    }

    private fun getRequiredIntervalForScene(scene: AutomationStep): Long {
        return when (scene) {
            AutomationStep.STEP_1_ACCEPT_ORDER,
            AutomationStep.STEP_5_CLICK_VAO_POINT_1,
            AutomationStep.STEP_9_CLICK_RA_POINT_1,
            AutomationStep.STEP_11_CLICK_VAO_POINT_2,
            AutomationStep.STEP_16_CLICK_RA_POINT_2 -> NETWORK_ACTION_INTERVAL_MS // Thao tác mạng/popup cần 2.2s
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> 1600L
            else -> DEFAULT_ACTION_INTERVAL_MS // 1.4s cho các nút bình thường
        }
    }

    // =========================================================================
    // BỘ NHẬN DIỆN MÀN HÌNH ĐẶC TRƯNG (DISTINCTIVE SCENE RECOGNITION DETECTIVE)
    // =========================================================================

    /**
     * Phân tích cây UI để xác định DUY NHẤT 1 Scene đang hoạt động.
     * Quy tắc: Kiểm tra từ các Modal con bên trong nhất -> Modal cha -> Chi tiết Điểm -> Lộ trình -> Menu ngoài.
     * TUYỆT ĐỐI KHÔNG sử dụng các từ khóa chung chung gây nhầm lẫn giữa các màn hình.
     */
    private fun detectCurrentScene(root: AccessibilityNodeInfo): AutomationStep {
        // -------------------------------------------------------------
        // A. CÁC MODAL VÀ POPUP NỔI (Ưu tiên cao nhất)
        // -------------------------------------------------------------

        // 1. Modal con bên trong nhất: "DS BD10 tại điểm lên" (Ảnh 13 & 14)
        if (isAtDsLenSubModal(root)) {
            return AutomationStep.STEP_14_SELECT_ALL_AND_ADD
        }

         val screen1find = hasAllExactTexts(root,listOf("NHẬN LỆNH","Lệnh mới"))
         if(screen1find){
            Log.i(TAG, "🚀 Đang ở màn hình 1: Nhận lệnh (10:00 - 17:50)")
             return AutomationStep.STEP_1_ACCEPT_ORDER
         }
         val screen2find = hasAllExactTexts(root,listOf("CHI TIẾT","Đã nhận lệnh"))
         if(screen2find){
            Log.i(TAG, "🚀 Đang ở màn hình 2: Chi tiết lệnh")
            return AutomationStep.STEP_2_VIEW_DETAIL
         }

         val screen3find = hasAllExactTexts(root,listOf("Chi tiết chuyến","BẮT ĐẦU"))
         if(screen3find){
            Log.i(TAG, "🚀 Đang ở màn hình 3: Chi tiết chuyến (Bắt đầu)")
            return AutomationStep.STEP_3_START_TRIP
         }

                 // 2. Modal "Danh sách BD10" (Điểm 1 & Điểm 2)
        if (isAtBd10MainModal(root) || hasAllExactTexts(root, listOf("Danh sách BD10", "Thêm", "Xác nhận"))) {
            val hasDsLenBtn = findNodeByTexts(root, listOf("DS BD10 lên", "DS BD10 LEN", "DS BD10 len", "DS BD10 LÊN")) != null
            val hasItemsInList = hasBd10ItemInTable(root)

            if (hasDsLenBtn) {
                // Điểm 2 (có nút DS BD10 lên):
                return if (hasItemsInList) {
                    Log.i(TAG, "🚀 Popup BD10 Điểm 2 - Có mã trong bảng -> Bấm Xác nhận")
                    isPoint1Bd10Done = true
                    AutomationStep.STEP_15_CONFIRM_BD10_2
                } else {
                    Log.i(TAG, "🚀 Popup BD10 Điểm 2 - Bảng rỗng -> Bấm DS BD10 lên")
                    AutomationStep.STEP_13_CLICK_DS_BD10_LEN
                }
            } else {
                // Popup nhập tay mã BD10 (Điểm 1 hoặc Điểm 2):
                val isPoint2Screen = findNodeByTexts(root, listOf("- 593280")) != null
                return if (hasItemsInList) {
                    Log.i(TAG, "🚀 Popup BD10 - Có mã trong bảng -> Bấm Xác nhận")
                    if (isPoint2Screen) AutomationStep.STEP_15_CONFIRM_BD10_2 else AutomationStep.STEP_8_CONFIRM_BD10_1
                } else {
                    Log.i(TAG, "🚀 Popup BD10 - Bảng rỗng -> Nhập mã BD10 & Thêm")
                    AutomationStep.STEP_7_INPUT_BD10_CODE
                }
            }
        }

        // 4. Popup "Xác nhận đến điểm?" (Ảnh 6, 10)
        if (findNodeByTexts(root, listOf("Xác nhận đến điểm?", "Xác nhận đến điểm")) != null) {
            val isPoint2 = findNodeByTexts(root, listOf("593280", "BCP Hoài Nhơn", "Giao hàng")) != null
            return if (isPoint2) AutomationStep.STEP_11_CLICK_VAO_POINT_2 else AutomationStep.STEP_5_CLICK_VAO_POINT_1
        }

        // 5. Popup "Xác nhận rời điểm?" (Ảnh 8, 16)
        if (findNodeByTexts(root, listOf("Xác nhận rời điểm?", "Xác nhận rời điểm")) != null) {
            val isPoint2 = findNodeByTexts(root, listOf("593280", "BCP Hoài Nhơn", "Giao hàng")) != null
            return if (isPoint2) AutomationStep.STEP_16_CLICK_RA_POINT_2 else AutomationStep.STEP_9_CLICK_RA_POINT_1
        }

        // -------------------------------------------------------------
        // B. MÀN HÌNH CHI TIẾT ĐIỂM (Có 3 block: Đến điểm, Đi khỏi điểm, Cập nhật vị trí)
        // -------------------------------------------------------------
        if (isAtPointDetailScreen(root)) {
            val isPoint2 = findNodeByTexts(root, listOf("593280")) != null

            if (isPoint2) {
                // === ĐIỂM 2 (593280) ===
                val isArrived2 = isPointArrived(root)
                if (!isArrived2) {
                    return AutomationStep.STEP_11_CLICK_VAO_POINT_2 // Chưa đến -> Bấm Đến điểm
                }

                // Đã đến điểm 2:
                // Nếu vừa xử lý popup BD10 xong (vừa từ popup con quay ra ngoài màn hình chính):
                val justCameFromBd10Popup = activeScene in listOf(
                    AutomationStep.STEP_7_INPUT_BD10_CODE,
                    AutomationStep.STEP_8_CONFIRM_BD10_1,
                    AutomationStep.STEP_13_CLICK_DS_BD10_LEN,
                    AutomationStep.STEP_14_SELECT_ALL_AND_ADD,
                    AutomationStep.STEP_15_CONFIRM_BD10_2
                )
                if (justCameFromBd10Popup) {
                    isPoint2Bd10Done = true
                }

                val shouldLeavePoint = isPoint2Bd10Done || currentStep == AutomationStep.STEP_16_CLICK_RA_POINT_2

                return if (shouldLeavePoint) {
                    Log.i(TAG, "🚀 Đang ở chi tiết Điểm 2 (593280) - Đã xử lý xong BD10 -> Bấm [Đi khỏi điểm]")
                    AutomationStep.STEP_16_CLICK_RA_POINT_2 // Đã scan xong -> Bấm Đi khỏi điểm!
                } else {
                    Log.i(TAG, "🚀 Đang ở chi tiết Điểm 2 (593280) - Chưa scan BD10 -> Bấm [SCAN BD10]")
                    AutomationStep.STEP_12_CLICK_SCAN_BD10_2 // Có nút SCAN BD10 -> Bấm Scan BD10
                }
            } else {
                // === ĐIỂM 1 (593200) ===
                val isArrived1 = isPointArrived(root)
                if (!isArrived1) {
                    return AutomationStep.STEP_5_CLICK_VAO_POINT_1 // Chưa đến -> Bấm Đến điểm
                }

                // Đã đến điểm 1:
                val justCameFromBd10Popup = activeScene in listOf(
                    AutomationStep.STEP_7_INPUT_BD10_CODE,
                    AutomationStep.STEP_8_CONFIRM_BD10_1
                )
                if (justCameFromBd10Popup) {
                    isPoint1Bd10Done = true
                }

                val shouldLeavePoint = isPoint1Bd10Done 

                return if (shouldLeavePoint) {
                    Log.i(TAG, "🚀 Đang ở chi tiết Điểm 1 (593200) - Đã xử lý xong BD10 -> Bấm [Đi khỏi điểm]")
                    AutomationStep.STEP_9_CLICK_RA_POINT_1 // Đã scan xong -> Bấm Đi khỏi điểm!
                } else {
                    Log.i(TAG, "🚀 Đang ở chi tiết Điểm 1 (593200) - Chưa scan BD10 -> Bấm [SCAN BD10]")
                    AutomationStep.STEP_6_CLICK_SCAN_BD10_1 // Có nút SCAN BD10 -> Bấm Scan
                }
            }
        }

        // -------------------------------------------------------------
        // C. MÀN HÌNH LỘ TRÌNH TỔNG QUAN ("Chuyến đang chạy" / tab TRẠNG THÁI & LỘ TRÌNH)
        // -------------------------------------------------------------
        if (isAtRouteOverviewScreen(root)) {
            // Kiểm tra trạng thái Điểm 1 (593200)
            val point1Completed = isPoint1CompletedOnRoute(root)

            return if (!point1Completed) {
                AutomationStep.STEP_3B_CLICK_POINT_593200 // Điểm 1 chưa xong -> Chọn Điểm 1
            } else {
                // Điểm 1 đã xong -> Kiểm tra Điểm 2
                val point2Completed = isPoint2CompletedOnRoute(root)
                if (!point2Completed) {
                    AutomationStep.STEP_10_SELECT_SECOND_POINT // Điểm 2 chưa xong -> Chọn Điểm 2
                } else {
                    AutomationStep.STEP_DONE // Cả 2 điểm đã xong -> Hoàn thành!
                }
            }
        }

        // -------------------------------------------------------------
        // D. CÁC MÀN HÌNH TRƯỚC KHI BẮT ĐẦU CHUYẾN
        // -------------------------------------------------------------




        return AutomationStep.IDLE
    }

    // Các hàm kiểm tra phân biệt Screen Signature chuyên sâu:

    private fun isAtDsLenSubModal(root: AccessibilityNodeInfo): Boolean {
        return findNodeByTexts(root, listOf("DS BD10 tại điểm lên", "tai diem len", "Nhập mã BD10")) != null
    }

    private fun isAtBd10MainModal(root: AccessibilityNodeInfo): Boolean {
        if (isAtDsLenSubModal(root)) return false
        return findNodeByTexts(root, listOf("Danh sách BD10", "SCAN MÃ BD10", "SCAN QR BD10", "Nhập tay mã BD10")) != null
    }

    private fun isAtPointDetailScreen(root: AccessibilityNodeInfo): Boolean {
        // Màn hình chi tiết điểm luôn có các ô block header đặc trưng
        val hasVaoBtn = findNodeByTexts(root, listOf("Đến điểm", "ĐẾN ĐIỂM", "Đến Điểm")) != null
        val hasRaBtn = findNodeByTexts(root, listOf("Đi khỏi điểm", "ĐI KHỎI ĐIỂM", "Đi Khỏi Điểm")) != null
        val hasLocationBtn = findNodeByTexts(root, listOf("Cập nhật vị trí", "Cap nhat vi tri")) != null
        val hasNhantatOrGiaotat = findNodeByTexts(root, listOf("Nhận hàng tại:", "Giao hàng tại:", "Nhận hàng tại", "Giao hàng tại")) != null

        return (hasVaoBtn || hasRaBtn || hasLocationBtn) && hasNhantatOrGiaotat
    }

    private fun isPointArrived(root: AccessibilityNodeInfo): Boolean {
        return findNodeByTexts(root, listOf("Trạng thái: Đã đến", "Thực tế đến", "Đã đến")) != null
    }

    private fun isAtRouteOverviewScreen(root: AccessibilityNodeInfo): Boolean {
        // Màn hình Lộ trình tổng quan có tab TRẠNG THÁI / LỘ TRÌNH / HÌNH ẢNH nhưng KHÔNG có các block Đến điểm / Đi khỏi điểm
        if (isAtPointDetailScreen(root)) return false
        val hasRouteTabs = findNodeByTexts(root, listOf("TRẠNG THÁI", "LỘ TRÌNH", "HÌNH ẢNH", "Tên điểm", "BỘ LỌC")) != null
        val hasTripTitle = findNodeByTexts(root, listOf("Chuyến đang chạy", "Chuyển đang chạy")) != null
        return hasRouteTabs || hasTripTitle
    }

    /**
     * Tìm ViewGroup/CardView bao bọc riêng 1 Card điểm trên Lộ trình (không leo ra RecyclerView/ScrollView chung)
     */
    private fun findItemCardContainer(node: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        var current: AccessibilityNodeInfo? = node
        while (current != null) {
            val parent = current.parent ?: break
            val parentClass = parent.className?.toString() ?: ""

            // Nếu parent là container danh sách cuộn -> current chính là item card hoàn chỉnh
            if (parentClass.contains("RecyclerView", ignoreCase = true) ||
                parentClass.contains("ListView", ignoreCase = true) ||
                parentClass.contains("ScrollView", ignoreCase = true) ||
                parentClass.contains("ViewPager", ignoreCase = true)) {
                return current
            }

            current = parent
        }
        return node.parent?.parent ?: node.parent
    }

    private fun isPoint1CompletedOnRoute(root: AccessibilityNodeInfo): Boolean {
        // Điểm 1 (593200) hoàn thành khi có chữ "Đã đi" hoặc "Thực tế rời" và KHÔNG có "Chưa đến điểm"
        val point1Node = findNodeByTexts(root, listOf("593200"))
        if (point1Node != null) {
            val cardContainer = findItemCardContainer(point1Node)
            if (cardContainer != null) {
                val hasChuaDen = findNodeByTexts(cardContainer, listOf("Chưa đến điểm", "Chua den diem", "CHƯA ĐẾN ĐIỂM")) != null
                if (hasChuaDen) return false

                val hasDaDi = findNodeByTexts(cardContainer, listOf("Trạng thái: Đã đi", "Đã đi", "Thực tế rời")) != null
                if (hasDaDi) return true
            }
        }
        return false
    }

    private fun isPoint2CompletedOnRoute(root: AccessibilityNodeInfo): Boolean {
        // Điểm 2 (593280) hoàn thành khi có chữ "Đã đi" hoặc "Thực tế rời" và KHÔNG có "Chưa đến điểm"
        val point2Node = findNodeByTexts(root, listOf("593280"))
        if (point2Node != null) {
            val cardContainer = findItemCardContainer(point2Node)
            if (cardContainer != null) {
                // 1. Nếu card có chữ "Chưa đến điểm" -> Chắc chắn chưa hoàn thành!
                val isNotArrived = findNodeByTexts(cardContainer, listOf("Chưa đến điểm", "Chua den diem", "CHƯA ĐẾN ĐIỂM")) != null
                if (isNotArrived) return false

                // 2. Chỉ hoàn thành khi có "Đã đi" hoặc "Thực tế rời" trong CHÍNH CARD NÀY
                val hasDaDi = findNodeByTexts(cardContainer, listOf("Trạng thái: Đã đi", "Đã đi", "Thực tế rời")) != null
                if (hasDaDi) return true
            }
        }
        return false
    }

    private fun hasBd10ItemInTable(root: AccessibilityNodeInfo): Boolean {
        // Kiểm tra xem trong bảng Danh sách BD10 đã có dòng mã BD10 nào chưa (dãy số >= 10 ký tự)
        val items = findBd10ItemsInPopup(root)
        return items.isNotEmpty()
    }

    // =========================================================================
    // THỰC THI HÀNH ĐỘNG THEO SCENE (SCENE ACTION EXECUTOR)
    // =========================================================================

    /**
     * Thực thi đúng hành động của Scene được truyền vào.
     * Trả về true nếu đã gửi lệnh tương tác (click / nhập liệu) thành công.
     */
    private fun executeSceneAction(scene: AutomationStep, rootNode: AccessibilityNodeInfo): Boolean {
        return when (scene) {
            // -------------------------------------------------------------
            // SCENE 1: Nhận lệnh tại tab "Lệnh mới" (Ảnh 1 & 2)
            // -------------------------------------------------------------
            AutomationStep.STEP_1_ACCEPT_ORDER -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Chấp nhận", "OK"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Bạn muốn nhận lệnh này?", "Hủy")) != null) {
                    Log.i(TAG, "Scene 1: Phát hiện popup [Bạn muốn nhận lệnh này?], đang bấm [Đồng ý]...")
                    return clickNode(popupAgreeBtn, "Nút Đồng ý Popup Nhận Lệnh")
                }

                val acceptBtn = findNodeByTexts(rootNode, listOf("NHẬN LỆNH", "Nhận lệnh", "NHAN LENH"))
                if (acceptBtn != null) {
                    Log.i(TAG, "Scene 1: Tìm thấy nút [NHẬN LỆNH], đang bấm...")
                    return clickNode(acceptBtn, "Nút NHẬN LỆNH")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 2: Bấm nút "CHI TIẾT" tại tab "Đã nhận" (Ảnh 3)
            // -------------------------------------------------------------
            AutomationStep.STEP_2_VIEW_DETAIL -> {
                val detailBtn = findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết", "CHI TIET"))
                if (detailBtn != null) {
                    Log.i(TAG, "Scene 2: Tìm thấy nút [CHI TIẾT], đang bấm...")
                    return clickNode(detailBtn, "Nút CHI TIẾT")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 3: Bấm nút cam "BẮT ĐẦU" tại Chi tiết chuyến (Ảnh 4)
            // -------------------------------------------------------------
            AutomationStep.STEP_3_START_TRIP -> {
                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Scene 3: Tìm thấy nút [BẮT ĐẦU], đang bấm...")
                    return clickNode(startBtn, "Nút BẮT ĐẦU")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 4: Chọn Điểm 1 (593200) trên Lộ trình (Ảnh 5)
            // -------------------------------------------------------------
            AutomationStep.STEP_3B_CLICK_POINT_593200 -> {
               val btn593200 = findNodeByTexts(rootNode, listOf("593200"))
                if (btn593200 != null) {
                    Log.i(TAG, "Bước 3B: Tìm thấy nút [593200], đang bấm...")
                    val target = findClickableParent(btn593200) ?: btn593200
                    return clickNode(target, "Nút 593200")
                }

                val firstPointNode = findFirstRoutePointNode(rootNode)
                if (firstPointNode != null) {
                    Log.i(TAG, "Bước 3B: Tìm thấy điểm đầu tiên qua fallback, đang click chọn...")
                    return clickNode(firstPointNode, "Điểm 593200 (Fallback)")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 5: Chi tiết Điểm 1 -> Bấm [Đến điểm] & popup [Đồng ý] (Ảnh 6)
            // -------------------------------------------------------------
            AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "OK"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Xác nhận đến điểm?", "Xác nhận đến điểm", "Thông báo")) != null) {
                    Log.i(TAG, "Scene 5: Phát hiện popup [Xác nhận đến điểm?], đang bấm [Đồng ý]...")
                    return clickNode(popupAgreeBtn, "Nút Đồng ý Đến Điểm 1")
                }

                val vaoBtn = findNodeByTexts(rootNode, listOf("Đến điểm", "ĐẾN ĐIỂM", "Đến Điểm"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Scene 5: Tìm thấy ô [Đến điểm 1], đang bấm...")
                    return clickNode(vaoBtn, "Ô Đến điểm 1")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 6: Điểm 1 đã đến -> Bấm nút [SCAN BD10] (Ảnh 6 & 7)
            // -------------------------------------------------------------
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1 -> {
                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Scene 6: Tìm thấy nút [SCAN BD10 Điểm 1], đang bấm...")
                    return clickNode(scanBtn, "Nút SCAN BD10 Điểm 1")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 7: Popup BD10 Điểm 1 -> Nhập mã BD10 & Bấm [Thêm] (Ảnh 7)
            // -------------------------------------------------------------
            AutomationStep.STEP_7_INPUT_BD10_CODE -> {
                // Lấy mã từ Clipboard nếu bộ nhớ rỗng
                ensureBd10CodeLoaded()

                val editText = findEditTextNode(rootNode)
                if (editText != null && bd10CodeToInput.isNotEmpty()) {
                    Log.i(TAG, "Scene 7: Đang điền mã BD10: $bd10CodeToInput vào ô nhập...")
                    val textSet = setTextOnNode(editText, bd10CodeToInput)
                    if (textSet) {
                        mainHandler.postDelayed({
                            val root = rootInActiveWindow ?: return@postDelayed
                            val addBtn = findNodeByTexts(root, listOf("Thêm", "THÊM", "Them"))
                            if (addBtn != null) {
                                Log.i(TAG, "Scene 7: Đang bấm nút [Thêm] mã BD10...")
                                clickNode(addBtn, "Nút Thêm mã BD10 Điểm 1")
                            }
                        }, 400)
                        return true
                    }
                } else if (bd10CodeToInput.isEmpty()) {
                    Log.w(TAG, "Scene 7: bd10CodeToInput đang trống!")
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 8: Popup BD10 Điểm 1 -> Bấm [Xác nhận] (Ảnh 7)
            // -------------------------------------------------------------
            AutomationStep.STEP_8_CONFIRM_BD10_1 -> {
                val confirmBtn = findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN", "Xac nhan"))
                if (confirmBtn != null) {
                    Log.i(TAG, "Scene 8: Tìm thấy nút [Xác nhận] Modal Điểm 1, đang bấm...")
                    val clicked = clickNode(confirmBtn, "Nút Xác nhận Modal Điểm 1")
                    if (clicked) {
                        isPoint1Bd10Done = true
                    }
                    return clicked
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 9: Chi tiết Điểm 1 -> Bấm [Đi khỏi điểm] & popup [Đồng ý] (Ảnh 8)
            // -------------------------------------------------------------
            AutomationStep.STEP_9_CLICK_RA_POINT_1 -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "OK"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Xác nhận rời điểm?", "Xác nhận rời điểm", "Thông báo")) != null) {
                    Log.i(TAG, "Scene 9: Phát hiện popup [Xác nhận rời điểm?], đang bấm [Đồng ý]...")
                    val clicked = clickNode(popupAgreeBtn, "Nút Đồng ý Rời Điểm 1")
                    if (clicked) {
                        isPoint1Bd10Done = false
                    }
                    return clicked
                }

                val raBtn = findNodeByTexts(rootNode, listOf("Đi khỏi điểm"))
                if (raBtn != null) {
                    Log.i(TAG, "Scene 9: Tìm thấy ô [Đi khỏi điểm 1], đang bấm...")
                    return clickNode(raBtn, "Ô Đi khỏi điểm 1")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 10: Chọn Điểm 2 (593280) trên Lộ trình (Ảnh 9)
            // -------------------------------------------------------------
            AutomationStep.STEP_10_SELECT_SECOND_POINT -> {
                val btn593280 = findNodeByTexts(rootNode, listOf("593280"))
                if (btn593280 != null) {
                    Log.i(TAG, "Scene 10: Tìm thấy Card [593280], đang bấm...")
                    val target = findClickableParent(btn593280) ?: btn593280
                    return clickNode(target, "Card Điểm 593280")
                }
                val secondPointNode = findSecondRoutePointNode(rootNode)
                if (secondPointNode != null) {
                    Log.i(TAG, "Scene 10: Tìm thấy Điểm 2 qua fallback, đang bấm...")
                    return clickNode(secondPointNode, "Điểm 2 (Fallback)")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 11: Chi tiết Điểm 2 -> Bấm [Đến điểm] & popup [Đồng ý] (Ảnh 10 & 11)
            // -------------------------------------------------------------
            AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "OK"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Xác nhận đến điểm?", "Xác nhận đến điểm", "Thông báo")) != null) {
                    Log.i(TAG, "Scene 11: Phát hiện popup [Xác nhận đến điểm?], đang bấm [Đồng ý]...")
                    return clickNode(popupAgreeBtn, "Nút Đồng ý Đến Điểm 2")
                }

                val vaoBtn = findNodeByTexts(rootNode, listOf("Đến điểm", "ĐẾN ĐIỂM", "Đến Điểm"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Scene 11: Tìm thấy ô [Đến điểm 2], đang bấm...")
                    return clickNode(vaoBtn, "Ô Đến điểm 2")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 12: Điểm 2 đã đến -> Bấm nút [SCAN BD10] (Ảnh 11)
            // -------------------------------------------------------------
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2 -> {
                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Scene 12: Tìm thấy nút [SCAN BD10 Điểm 2], đang bấm...")
                    return clickNode(scanBtn, "Nút SCAN BD10 Điểm 2")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 13: Popup BD10 Điểm 2 -> Bấm nút xanh lá [DS BD10 lên] (Ảnh 12)
            // -------------------------------------------------------------
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> {
                var dsLenBtn = findNodeByTexts(rootNode, listOf(
                    "DS BD10\nlên", "DS BD10\nLên", "DS BD10\nLEN",
                    "DS BD10 lên", "DS BD10 len", "DS BD10"
                ))

                if (dsLenBtn == null) {
                    dsLenBtn = findNodeRecursive(rootNode) { node ->
                        val txt = (node.text?.toString() ?: "").replace("\n", " ").trim().lowercase()
                        val desc = (node.contentDescription?.toString() ?: "").replace("\n", " ").trim().lowercase()
                        (txt.contains("ds bd10") || desc.contains("ds bd10")) &&
                        !txt.contains("danh sách") && !desc.contains("danh sách")
                    }
                }

                if (dsLenBtn != null) {
                    Log.i(TAG, "Scene 13: Tìm thấy nút xanh lá [DS BD10 lên], đang bấm...")
                    val target = findClickableParent(dsLenBtn) ?: dsLenBtn
                    val bounds = Rect()
                    target.getBoundsInScreen(bounds)
                    if (bounds.width() > 0 && bounds.height() > 0) {
                        performGestureClick(bounds.centerX().toFloat(), bounds.centerY().toFloat())
                    }
                    return clickNode(target, "Nút DS BD10 lên")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 14: Popup con -> Chọn item mã BD10 & Bấm [Thêm] (xanh lá) (Ảnh 13 & 14)
            // -------------------------------------------------------------
            AutomationStep.STEP_14_SELECT_ALL_AND_ADD -> {
                if(!isClickBD10OneTime){
                        isClickBD10OneTime = true
                // 1. Click chọn các item mã BD10 trong popup con nếu chưa chọn
                val items = findBd10ItemsInPopup(rootNode)
                for (item in items) {
                    val clickableItem = findClickableParent(item) ?: item
                    clickNode(clickableItem, "Item BD10 (${item.text})")
                }
            }

                // 2. Tìm chính xác nút [Thêm] màu xanh lá của popup con này
               val addBtn = findThem(rootNode, 2) // Truyền 1 hoặc 2 tại đây
                if (addBtn != null) {
                    return clickNode(addBtn, "Nút Thêm số ")
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 15: Popup BD10 Điểm 2 -> Bấm [Xác nhận] (Ảnh 15)
            // -------------------------------------------------------------
            AutomationStep.STEP_15_CONFIRM_BD10_2 -> {
                val confirmBtn = findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN", "Xac nhan"))
                if (confirmBtn != null) {
                    Log.i(TAG, "Scene 15: Tìm thấy nút [Xác nhận] Modal Điểm 2, đang bấm...")
                    val clicked = clickNode(confirmBtn, "Nút Xác nhận Modal Điểm 2")
                    if (clicked) {
                        isPoint2Bd10Done = true
                    }
                    return clicked
                }
                false
            }

            // -------------------------------------------------------------
            // SCENE 16: Chi tiết Điểm 2 -> Bấm [Đi khỏi điểm] & popup [Đồng ý] (Ảnh 16)
            // -------------------------------------------------------------
            AutomationStep.STEP_16_CLICK_RA_POINT_2 -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "OK"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Xác nhận rời điểm?", "Xác nhận rời điểm", "Thông báo")) != null) {
                    Log.i(TAG, "Scene 16: Phát hiện popup [Xác nhận rời điểm?], đang bấm [Đồng ý]...")
                    val clicked = clickNode(popupAgreeBtn, "Nút Đồng ý Rời Điểm 2")
                    if (clicked) {
                        isPoint2Bd10Done = false
                    }
                    return clicked
                }

                val raBtn = findNodeByTexts(rootNode, listOf("Đi khỏi điểm"))
                if (raBtn != null) {
                    Log.i(TAG, "Scene 16: Tìm thấy ô [Đi khỏi điểm 2 / Kết thúc], đang bấm...")
                    return clickNode(raBtn, "Ô Đi khỏi điểm 2")
                }
                false
            }

            AutomationStep.STEP_DONE -> {
                Log.i(TAG, "Đã hoàn thành toàn bộ tiến trình.")
                stopAutomation()
                true
            }

            AutomationStep.IDLE -> false
        }
    }

    private fun ensureBd10CodeLoaded() {
        if (bd10CodeToInput.isEmpty()) {
            try {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                val clipText = clipboard?.primaryClip?.getItemAt(0)?.text?.toString()?.trim() ?: ""
                if (clipText.isNotEmpty()) {
                    bd10CodeToInput = clipText
                    Log.i(TAG, "Tự động nạp mã BD10 từ Clipboard: $bd10CodeToInput")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Không thể đọc Clipboard: ${e.message}")
            }
        }
    }

    // =========================================================================
    // THANH ĐIỀU KHIỂN NỔI ĐA NĂNG TRÊN MÀN HÌNH (FLOATING CONTROL BAR)
    // =========================================================================

    /**
     * Bấm nút TIẾN (⏭): Chuyển con trỏ sang bước tiếp theo để chọn
     */
    fun stepForward() {
        isContinuousMode = false
        mainHandler.removeCallbacks(automationRunnable)

        val idx = RUNNABLE_STEPS.indexOf(currentStep)
        val nextIdx = if (idx >= 0 && idx < RUNNABLE_STEPS.size - 1) idx + 1 else 0
        currentStep = RUNNABLE_STEPS[nextIdx]
        activeScene = currentStep

        Log.i(TAG, "⏭ [Thủ công] Đã chọn bước: $currentStep (${getStepShortName(currentStep)})")
        Toast.makeText(this, "⏭ Đã chọn: ${getStepShortName(currentStep)}", Toast.LENGTH_SHORT).show()
        updateOverlayStepText(currentStep.name)
    }

    /**
     * Bấm nút LÙI (⏮): Chuyển con trỏ sang bước trước đó để chọn
     */
    fun stepBackward() {
        isContinuousMode = false
        mainHandler.removeCallbacks(automationRunnable)

        val idx = RUNNABLE_STEPS.indexOf(currentStep)
        val prevIdx = if (idx > 0) idx - 1 else RUNNABLE_STEPS.size - 1
        currentStep = RUNNABLE_STEPS[prevIdx]
        activeScene = currentStep

        Log.i(TAG, "⏮ [Thủ công] Đã chọn bước: $currentStep (${getStepShortName(currentStep)})")
        Toast.makeText(this, "⏮ Đã chọn: ${getStepShortName(currentStep)}", Toast.LENGTH_SHORT).show()
        updateOverlayStepText(currentStep.name)
    }

    /**
     * Bấm nút CHẠY (⚡ Chạy):
     * - Tự động phát hiện Scene thực tế đang hiển thị trên màn hình và thực thi đúng hành động.
     * - Nếu không tự phát hiện được, chạy bước người dùng đang chọn trên thanh nổi.
     */
    fun runCurrentStepManually() {
        isContinuousMode = false
        mainHandler.removeCallbacks(automationRunnable)

        if (!isRunning) {
            isRunning = true
        }

        ensureBd10CodeLoaded()

        mainHandler.post {
            try {
                val rootNode = rootInActiveWindow
                if (rootNode == null) {
                    Toast.makeText(this, "⚠️ Không thể đọc màn hình TMS (root null)", Toast.LENGTH_SHORT).show()
                    return@post
                }

                val currentPkg = rootNode.packageName?.toString() ?: ""
                if (currentPkg.isNotEmpty() && !isTmsPackage(currentPkg) && !currentPkg.contains("phone_auto_portal")) {
                    Toast.makeText(this, "⚠️ TMS chưa active (đang ở: $currentPkg)", Toast.LENGTH_SHORT).show()
                    return@post
                }

                // 1. Ưu tiên: Nếu người dùng đã dùng nút ⏮/⏭ chọn thủ công bước rời điểm (STEP_9 hoặc STEP_16)
                val detectedScene = detectCurrentScene(rootNode)
                val stepToRun = if (currentStep == AutomationStep.STEP_16_CLICK_RA_POINT_2 || currentStep == AutomationStep.STEP_9_CLICK_RA_POINT_1) {
                    currentStep
                } else if (detectedScene != AutomationStep.IDLE && detectedScene != AutomationStep.STEP_DONE) {
                    detectedScene
                } else if (currentStep != AutomationStep.IDLE && currentStep != AutomationStep.STEP_DONE) {
                    currentStep
                } else {
                    RUNNABLE_STEPS.first()
                }

                Log.i(TAG, "⚡ [Thủ công] Bắt đầu thực thi: $stepToRun (${getStepShortName(stepToRun)})")
                Toast.makeText(this, "⚡ Đang chạy: ${getStepShortName(stepToRun)}...", Toast.LENGTH_SHORT).show()

                val success = executeSceneAction(stepToRun, rootNode)
                if (success) {
                    val idx = RUNNABLE_STEPS.indexOf(stepToRun)
                    val nextStep = if (idx >= 0 && idx < RUNNABLE_STEPS.size - 1) {
                        RUNNABLE_STEPS[idx + 1]
                    } else {
                        RUNNABLE_STEPS.first()
                    }
                    currentStep = nextStep
                    updateOverlayStepText(nextStep.name)
                    Log.i(TAG, "✅ [Thủ công] Đã chạy xong: ${getStepShortName(stepToRun)} -> Sẵn sàng: ${getStepShortName(nextStep)}")
                    Toast.makeText(this, "✅ Xong: ${getStepShortName(stepToRun)}\n👉 Tiếp theo: ${getStepShortName(nextStep)}", Toast.LENGTH_SHORT).show()
                } else {
                    Log.w(TAG, "⚠️ [Thủ công] Không tìm thấy phần tử cho: ${getStepShortName(stepToRun)}")
                    Toast.makeText(this, "⚠️ Không thấy nút cho: ${getStepShortName(stepToRun)}\nHãy kiểm tra màn hình hoặc dùng ⏮/⏭ chọn lại!", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi thực thi thủ công: ${e.message}", e)
                Toast.makeText(this, "❌ Lỗi: ${e.message}", Toast.LENGTH_SHORT).show()
            }
        }
    }

    private fun showStopOverlayButton() {
        mainHandler.post {
            try {
                if (stopOverlayView != null) return@post
                windowManager = getSystemService(Context.WINDOW_SERVICE) as WindowManager

                val layoutParams = WindowManager.LayoutParams(
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    WindowManager.LayoutParams.WRAP_CONTENT,
                    if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.O)
                        WindowManager.LayoutParams.TYPE_ACCESSIBILITY_OVERLAY
                    else
                        WindowManager.LayoutParams.TYPE_PHONE,
                    WindowManager.LayoutParams.FLAG_NOT_FOCUSABLE or WindowManager.LayoutParams.FLAG_LAYOUT_NO_LIMITS,
                    PixelFormat.TRANSLUCENT
                ).apply {
                    gravity = Gravity.TOP or Gravity.START
                    x = 24
                    y = 120
                }

                val mainBar = LinearLayout(this).apply {
                    orientation = LinearLayout.HORIZONTAL
                    gravity = Gravity.CENTER_VERTICAL
                    val bg = GradientDrawable().apply {
                        setColor(Color.parseColor("#0F172A"))
                        cornerRadius = 36f
                        setStroke(2, Color.parseColor("#475569"))
                    }
                    background = bg
                    setPadding(12, 10, 12, 10)
                    elevation = 20f
                }

                // 1. Nút DỪNG (🛑 Dừng)
                val btnStop = TextView(this).apply {
                    text = "🛑 Dừng"
                    setTextColor(Color.WHITE)
                    textSize = 12f
                    paint.isFakeBoldText = true
                    val bg = GradientDrawable().apply {
                        setColor(Color.parseColor("#DC2626"))
                        cornerRadius = 24f
                    }
                    background = bg
                    setPadding(20, 12, 20, 12)
                    setOnClickListener {
                        Toast.makeText(this@TmsAccessibilityService, "Đã dừng tự động hóa TMS!", Toast.LENGTH_SHORT).show()
                        stopAutomation()
                    }
                }

                // 2. Nút LÙI BƯỚC (⏮)
                val btnPrev = TextView(this).apply {
                    text = "⏮"
                    setTextColor(Color.WHITE)
                    textSize = 14f
                    paint.isFakeBoldText = true
                    val bg = GradientDrawable().apply {
                        setColor(Color.parseColor("#334155"))
                        cornerRadius = 24f
                    }
                    background = bg
                    setPadding(16, 12, 16, 12)
                    setOnClickListener {
                        stepBackward()
                    }
                }

                // 3. Nhãn hiển thị bước hiện tại (Bấm vào để chạy lại bước này)
                val stepTextView = TextView(this).apply {
                    id = View.generateViewId()
                    text = getStepShortName(currentStep)
                    setTextColor(Color.parseColor("#FBBF24"))
                    textSize = 12f
                    paint.isFakeBoldText = true
                    val bg = GradientDrawable().apply {
                        setColor(Color.parseColor("#1E293B"))
                        cornerRadius = 24f
                        setStroke(1, Color.parseColor("#F59E0B"))
                    }
                    background = bg
                    setPadding(18, 12, 18, 12)
                    setOnClickListener {
                        runCurrentStepManually()
                    }
                }

                // 4. Nút TIẾN BƯỚC (⏭)
                val btnNext = TextView(this).apply {
                    text = "⏭"
                    setTextColor(Color.WHITE)
                    textSize = 14f
                    paint.isFakeBoldText = true
                    val bg = GradientDrawable().apply {
                        setColor(Color.parseColor("#334155"))
                        cornerRadius = 24f
                    }
                    background = bg
                    setPadding(16, 12, 16, 12)
                    setOnClickListener {
                        stepForward()
                    }
                }

                // 5. Nút THỰC THI NGAY (⚡ Chạy)
                val btnRun = TextView(this).apply {
                    text = "⚡ Chạy"
                    setTextColor(Color.WHITE)
                    textSize = 12f
                    paint.isFakeBoldText = true
                    val bg = GradientDrawable().apply {
                        setColor(Color.parseColor("#059669"))
                        cornerRadius = 24f
                    }
                    background = bg
                    setPadding(20, 12, 20, 12)
                    setOnClickListener {
                        runCurrentStepManually()
                    }
                }

                fun space(): View {
                    val v = View(this)
                    v.layoutParams = LinearLayout.LayoutParams(8, 1)
                    return v
                }

                mainBar.addView(btnStop)
                mainBar.addView(space())
                mainBar.addView(btnPrev)
                mainBar.addView(space())
                mainBar.addView(stepTextView)
                mainBar.addView(space())
                mainBar.addView(btnNext)
                mainBar.addView(space())
                mainBar.addView(btnRun)

                var initialX = 0
                var initialY = 0
                var initialTouchX = 0f
                var initialTouchY = 0f

                mainBar.setOnTouchListener { _, event ->
                    when (event.action) {
                        MotionEvent.ACTION_DOWN -> {
                            initialX = layoutParams.x
                            initialY = layoutParams.y
                            initialTouchX = event.rawX
                            initialTouchY = event.rawY
                            false
                        }
                        MotionEvent.ACTION_MOVE -> {
                            val diffX = Math.abs(event.rawX - initialTouchX)
                            val diffY = Math.abs(event.rawY - initialTouchY)
                            if (diffX > 15 || diffY > 15) {
                                layoutParams.x = initialX + (event.rawX - initialTouchX).toInt()
                                layoutParams.y = initialY + (event.rawY - initialTouchY).toInt()
                                windowManager?.updateViewLayout(stopOverlayView, layoutParams)
                                true
                            } else {
                                false
                            }
                        }
                        else -> false
                    }
                }

                stopOverlayView = mainBar
                windowManager?.addView(stopOverlayView, layoutParams)
                Log.d(TAG, "Đã hiển thị Thanh điều khiển nổi TMS trên màn hình")
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi tạo thanh điều khiển nổi: ${e.message}", e)
            }
        }
    }

    private fun updateOverlayStepText(stepName: String) {
        mainHandler.post {
            try {
                val container = stopOverlayView as? LinearLayout ?: return@post
                if (container.childCount >= 5) {
                    val textView = container.getChildAt(4) as? TextView
                    val stepEnum = try {
                        AutomationStep.valueOf(stepName)
                    } catch (e: Exception) {
                        null
                    }
                    val shortName = if (stepEnum != null) getStepShortName(stepEnum) else stepName
                    textView?.text = shortName
                }
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi cập nhật overlay text: ${e.message}")
            }
        }
    }

    private fun removeStopOverlayButton() {
        mainHandler.post {
            try {
                if (stopOverlayView != null && windowManager != null) {
                    windowManager?.removeView(stopOverlayView)
                    stopOverlayView = null
                    Log.d(TAG, "Đã gỡ bỏ nút Dừng nổi khỏi màn hình")
                }
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi xóa overlay: ${e.message}")
            }
        }
    }

    // =========================================================================
    // CÁC HÀM TÌM KIẾM NODE VÀ TƯƠNG TÁC (NODE SEARCH & DISPATCH)
    // =========================================================================

    private fun normalize(text: String): String {
        return java.text.Normalizer.normalize(text, java.text.Normalizer.Form.NFC).lowercase().trim()
    }

    /**
     * Kiểm tra xem trên màn hình CÓ ĐẦY ĐỦ TẤT CẢ các chuỗi trong [targetTexts] hay không (Phép toán AND).
     * Phục vụ đắc lực cho việc nhận diện chính xác màn hình (Scene Signature) khi debug.
     *
     * Ví dụ: hasAllTexts(root, listOf("Đã nhận lệnh", "CHI TIẾT"), exactMatch = true)
     * -> Yêu cầu trên màn hình phải đồng thời xuất hiện cả 2 cụm từ này.
     *
     * @param root Node gốc của cửa sổ đang kiểm tra (rootInActiveWindow)
     * @param targetTexts Danh sách các chuỗi bắt buộc phải cùng xuất hiện
     * @param exactMatch Nếu true: so khớp trùng khớp 100% nội dung (bỏ qua hoa thường, khoảng trắng và chuẩn hóa Unicode).
     *                   Nếu false: chỉ cần text của phần tử chứa (contains) từ khóa.
     * @return true nếu TẤT CẢ các chuỗi trong list đều xuất hiện trên màn hình, ngược lại false.
     */
    fun hasAllTexts(
        root: AccessibilityNodeInfo?,
        targetTexts: List<String>,
        exactMatch: Boolean = false
    ): Boolean {
        if (root == null || targetTexts.isEmpty()) return false

        val screenTexts = mutableListOf<String>()
        collectVisibleTexts(root, screenTexts)

        val normalizedTargets = targetTexts.map { normalize(it) }

        // Mọi target trong danh sách đều phải có ít nhất 1 node trên màn hình khớp
        return normalizedTargets.all { target ->
            screenTexts.any { screenText ->
                if (exactMatch) {
                    screenText == target
                } else {
                    screenText.contains(target)
                }
            }
        }
    }

    /**
     * Phiên bản tiện ích kiểm tra TRÙNG KHỚP CHÍNH XÁC 100% toàn bộ các chuỗi trong [targetTexts].
     * (Bỏ qua hoa thường, khoảng trắng thừa và chuẩn hóa Unicode NFC).
     */
    fun hasAllExactTexts(root: AccessibilityNodeInfo?, targetTexts: List<String>): Boolean {
        return hasAllTexts(root, targetTexts, exactMatch = true)
    }

    /**
     * Kiểm tra điều kiện AND giữa các nhóm, trong mỗi nhóm là quan hệ OR (Từ đồng nghĩa / Biến thể).
     * Ví dụ: listOf(listOf("Đã nhận lệnh", "Đã nhận"), listOf("CHI TIẾT", "Chi tiết"))
     * -> Bắt buộc phải có (Đã nhận lệnh HOẶC Đã nhận) VÀ phải có (CHI TIẾT HOẶC Chi tiết).
     */
    fun hasAllTextGroups(
        root: AccessibilityNodeInfo?,
        targetGroups: List<List<String>>,
        exactMatch: Boolean = false
    ): Boolean {
        if (root == null || targetGroups.isEmpty()) return false

        val screenTexts = mutableListOf<String>()
        collectVisibleTexts(root, screenTexts)

        return targetGroups.all { group ->
            val normalizedGroup = group.map { normalize(it) }
            normalizedGroup.any { target ->
                screenTexts.any { screenText ->
                    if (exactMatch) screenText == target else screenText.contains(target)
                }
            }
        }
    }

    /**
     * Tìm và trả về danh sách các Node tương ứng với TẤT CẢ các chuỗi trong [targetTexts] (Phép toán AND).
     * Nếu thiếu dù chỉ 1 từ khóa trong danh sách -> trả về null.
     * Thuận tiện để vừa xác nhận có đủ cả 2 text, vừa lấy luôn node để click ngay.
     */
    fun findNodesMatchingAllTexts(
        root: AccessibilityNodeInfo?,
        targetTexts: List<String>,
        exactMatch: Boolean = false
    ): Map<String, AccessibilityNodeInfo>? {
        if (root == null || targetTexts.isEmpty()) return null

        val allNodes = mutableListOf<AccessibilityNodeInfo>()
        collectVisibleNodes(root, allNodes)

        val resultMap = mutableMapOf<String, AccessibilityNodeInfo>()

        for (target in targetTexts) {
            val normTarget = normalize(target)
            val matchedNode = allNodes.firstOrNull { node ->
                val t = normalize(node.text?.toString() ?: "")
                val d = normalize(node.contentDescription?.toString() ?: "")
                if (exactMatch) {
                    t == normTarget || d == normTarget
                } else {
                    t.contains(normTarget) || d.contains(normTarget)
                }
            }

            if (matchedNode != null) {
                resultMap[target] = matchedNode
            } else {
                return null // Thiếu 1 từ -> không thỏa mãn
            }
        }

        return resultMap
    }

    private fun collectVisibleTexts(node: AccessibilityNodeInfo?, result: MutableList<String>) {
        if (node == null || !node.isVisibleToUser) return
        val t = node.text?.toString()
        if (!t.isNullOrBlank()) result.add(normalize(t))
        val d = node.contentDescription?.toString()
        if (!d.isNullOrBlank()) result.add(normalize(d))
        for (i in 0 until node.childCount) {
            collectVisibleTexts(node.getChild(i), result)
        }
    }

    private fun collectVisibleNodes(node: AccessibilityNodeInfo?, result: MutableList<AccessibilityNodeInfo>) {
        if (node == null || !node.isVisibleToUser) return
        result.add(node)
        for (i in 0 until node.childCount) {
            collectVisibleNodes(node.getChild(i), result)
        }
    }

    private fun findNodeByTexts(root: AccessibilityNodeInfo, targetTexts: List<String>): AccessibilityNodeInfo? {
        // 1. Ưu tiên tìm các node có khả năng click (isClickable hoặc Button)
        for (text in targetTexts) {
            val list = root.findAccessibilityNodeInfosByText(text)
            if (!list.isNullOrEmpty()) {
                for (node in list) {
                    if (node.isVisibleToUser && (node.isClickable || node.className?.toString()?.contains("Button", ignoreCase = true) == true)) {
                        return node
                    }
                }
            }
        }
        // 2. Tìm các node hiển thị thông thường
        for (text in targetTexts) {
            val list = root.findAccessibilityNodeInfosByText(text)
            if (!list.isNullOrEmpty()) {
                for (node in list) {
                    if (node.isVisibleToUser) {
                        return node
                    }
                }
            }
        }
        // 3. Quét đệ quy toàn bộ cây với chuẩn hóa Unicode NFC
        val normalizedTargets = targetTexts.map { normalize(it) }
        return findNodeRecursive(root) { node ->
            val nodeText = normalize(node.text?.toString() ?: "")
            val nodeDesc = normalize(node.contentDescription?.toString() ?: "")
            normalizedTargets.any { target ->
                nodeText.contains(target) || nodeDesc.contains(target)
            }
        }
    }

    private fun findEditTextNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        return findNodeRecursive(root) { node ->
            node.className?.toString()?.contains("EditText", ignoreCase = true) == true ||
            node.isEditable
        }
    }

     private fun findThem(root: AccessibilityNodeInfo, index: Int = 2): AccessibilityNodeInfo? {
        val allNodes = mutableListOf<AccessibilityNodeInfo>()

        // 1. Gom tất cả node trên màn hình (quét cả các cửa sổ popup nếu có)
        fun collect(node: AccessibilityNodeInfo?) {
            if (node == null || !node.isVisibleToUser) return
            allNodes.add(node)
            for (i in 0 until node.childCount) {
                collect(node.getChild(i))
            }
        }

        try {
            windows?.forEach { w -> w.root?.let { collect(it) } }
        } catch (e: Exception) { }
        if (allNodes.isEmpty()) collect(root)

        // 2. Lọc các phần tử có chữ "Thêm"
        val matchedNodes = allNodes.filter { node ->
            val txt = normalize(node.text?.toString() ?: "")
            val desc = normalize(node.contentDescription?.toString() ?: "")
            txt.contains("thêm") || desc.contains("thêm") || txt.contains("them")
        }

        // 3. Lọc trùng lặp tọa độ (tránh 1 nút bị đếm 2 lần do cả TextView và Button cha đều có)
        val distinctButtons = mutableListOf<AccessibilityNodeInfo>()
        for (node in matchedNodes) {
            val r = Rect()
            node.getBoundsInScreen(r)
            if (r.width() > 0 && r.height() > 0) {
                val isDuplicate = distinctButtons.any { existing ->
                    val er = Rect()
                    existing.getBoundsInScreen(er)
                    Math.abs(er.centerX() - r.centerX()) < 30 && Math.abs(er.centerY() - r.centerY()) < 30
                }
                if (!isDuplicate) {
                    distinctButtons.add(findClickableParent(node) ?: node)
                }
            }
        }

        // 4. Sắp xếp các nút từ trên xuống dưới theo tọa độ Y
        distinctButtons.sortBy {
            val r = Rect()
            it.getBoundsInScreen(r)
            r.top
        }

        // In log danh sách nút tìm được để bạn nhìn thấy ngay trong Logcat
        Log.i(TAG, "🔎 Quét thấy tổng cộng ${distinctButtons.size} nút [Thêm]:")
        distinctButtons.forEachIndexed { i, btn ->
            val r = Rect()
            btn.getBoundsInScreen(r)
            Log.i(TAG, "   👉 Nút Thêm [${i + 1}]: bounds=$r, clickable=${btn.isClickable}")
        }

        val targetIdx = index - 1
        return if (targetIdx in distinctButtons.indices) {
            Log.i(TAG, "🎯 Đang chọn nút Thêm [$index]")
            distinctButtons[targetIdx]
        } else {
            Log.e(TAG, "❌ Không tìm thấy nút Thêm [$index] (Chỉ tìm thấy ${distinctButtons.size} nút)")
            null
        }
    }

    /**
     * Helper duyệt đệ quy toàn bộ cây để gom node thỏa mãn điều kiện
     */
    private fun collectNodesRecursive(node: AccessibilityNodeInfo?, predicate: (AccessibilityNodeInfo) -> Boolean) {
        if (node == null || !node.isVisibleToUser) return
        if (predicate(node)) {
            // Callback hoặc thêm vào collection
        }
        for (i in 0 until node.childCount) {
            collectNodesRecursive(node.getChild(i), predicate)
        }
    }

    private fun findFirstRoutePointNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val specific = findNodeByTexts(root, listOf("593200", "Hoài Nhơn", "Tam Quan", "Kho", "Nhận hàng", "Chưa đến điểm"))
        if (specific != null) {
            return findClickableParent(specific) ?: specific
        }
        return null
    }

    private fun findSecondRoutePointNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val specific = findNodeByTexts(root, listOf("593280", "BCP", "Quy Nhơn", "Giao hàng", "Trả hàng"))
        if (specific != null) {
            return findClickableParent(specific) ?: specific
        }
        return null
    }

    data class DetectedAddButton(
        val node: AccessibilityNodeInfo,
        val text: String,
        val className: String,
        val bounds: Rect,
        val centerX: Float,
        val centerY: Float,
        val isClickable: Boolean,
        var modalType: String,
        var isTarget: Boolean = false,
        var reason: String = ""
    )

    /**
     * Tìm chính xác nút [Thêm] (màu xanh lá) bên trong Modal 2 "DS BD10 tại điểm lên"
     * Tránh nhầm lẫn 100% với nút [Thêm] (màu xanh dương) của ô "Nhập tay mã BD10" ở Modal 1 bên dưới
     */
    private fun findAddButtonInDsLenPopup(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val detectedList = mutableListOf<DetectedAddButton>()

        // 1. Quét từ tất cả các roots (các Window theo layer Z-index giảm dần + rootInActiveWindow)
        val rootsToScan = mutableListOf<AccessibilityNodeInfo>()
        try {
            if (Build.VERSION.SDK_INT >= Build.VERSION_CODES.LOLLIPOP) {
                val currentWindows = windows
                if (!currentWindows.isNullOrEmpty()) {
                    for (w in currentWindows.sortedByDescending { it.layer }) {
                        val r = w.root
                        if (r != null && r.isVisibleToUser) {
                            rootsToScan.add(r)
                        }
                    }
                }
            }
        } catch (e: Exception) {
            Log.w(TAG, "Không thể lấy danh sách windows: ${e.message}")
        }
        if (!rootsToScan.contains(root)) {
            rootsToScan.add(root)
        }

        // 2. Thu thập tất cả các node có text là "Thêm" hoặc "THEM"
        for (r in rootsToScan) {
            val list = r.findAccessibilityNodeInfosByText("Thêm")
            if (!list.isNullOrEmpty()) {
                for (node in list) {
                    if (node.isVisibleToUser) {
                        val b = Rect()
                        node.getBoundsInScreen(b)
                        if (detectedList.none { it.bounds == b }) {
                            val nodeClass = node.className?.toString()?.substringAfterLast(".") ?: "View"
                            val cx = b.centerX().toFloat()
                            val cy = b.centerY().toFloat()
                            val btnInfo = DetectedAddButton(
                                node = node,
                                text = node.text?.toString() ?: "Thêm",
                                className = nodeClass,
                                bounds = b,
                                centerX = cx,
                                centerY = cy,
                                isClickable = node.isClickable,
                                modalType = "Chưa xác định"
                            )
                            detectedList.add(btnInfo)
                        }
                    }
                }
            }
        }

        // 3. Phân loại từng nút theo Modal 1 (Cửa sổ dưới) hay Modal 2 (Cửa sổ trên)
        for (btn in detectedList) {
            var isModal2 = false
            var isModal1 = false

            var parent = btn.node.parent
            for (level in 0..4) {
                if (parent == null) break

                if (parent.findAccessibilityNodeInfosByText("DS BD10 tại điểm lên").isNotEmpty() ||
                    parent.findAccessibilityNodeInfosByText("Nhập mã BD10").isNotEmpty() ||
                    parent.findAccessibilityNodeInfosByText("điểm lên").isNotEmpty()) {
                    isModal2 = true
                    break
                }

                if (parent.findAccessibilityNodeInfosByText("Nhập tay mã BD10").isNotEmpty() ||
                    parent.findAccessibilityNodeInfosByText("Danh sách BD10").isNotEmpty()) {
                    isModal1 = true
                }
                parent = parent.parent
            }

            if (isModal2) {
                btn.modalType = "Modal 2 (DS BD10 tại điểm lên - Xanh lá)"
            } else if (isModal1) {
                btn.modalType = "Modal 1 (Danh sách BD10 - Ô nhập tay xanh dương)"
            } else {
                btn.modalType = if (btn.bounds.width() < 350) {
                    "Modal 1 (Ô nhập tay - Width: ${btn.bounds.width()}px)"
                } else {
                    "Modal 2 (Nút popup - Width: ${btn.bounds.width()}px)"
                }
            }
        }

        // 4. Lựa chọn Target chính xác (Modal 2 bên trên)
        var target: DetectedAddButton? = detectedList.firstOrNull { it.modalType.contains("Modal 2") }

        if (target == null && detectedList.isNotEmpty()) {
            target = detectedList.lastOrNull { it.isClickable || it.className.contains("Button") } ?: detectedList.last()
        }

        if (target != null) {
            Log.i(TAG, "🎯 [CHỌN NÚT THÊM] ${target.modalType} tại (${target.centerX.toInt()}, ${target.centerY.toInt()})")
            return target.node
        }

        // 5. Fallback theo nút 'Đóng' của Modal 2
        val closeNodes = root.findAccessibilityNodeInfosByText("Đóng")
        if (!closeNodes.isNullOrEmpty()) {
            for (closeNode in closeNodes.reversed()) {
                val closeBounds = Rect()
                closeNode.getBoundsInScreen(closeBounds)
                val closeParent = closeNode.parent
                if (closeParent != null) {
                    for (i in 0 until closeParent.childCount) {
                        val sibling = closeParent.getChild(i) ?: continue
                        if (sibling != closeNode && sibling.isVisibleToUser) {
                            val sibBounds = Rect()
                            sibling.getBoundsInScreen(sibBounds)
                            if (sibBounds.left >= closeBounds.right - 20 && Math.abs(sibBounds.centerY() - closeBounds.centerY()) < 50) {
                                Log.i(TAG, "🎯 [Fallback theo nút Đóng] Tìm thấy nút Thêm: bounds=$sibBounds")
                                return sibling
                            }
                        }
                    }
                }
            }
        }

        return null
    }

    private fun findBd10ItemsInPopup(root: AccessibilityNodeInfo): List<AccessibilityNodeInfo> {
        val results = mutableListOf<AccessibilityNodeInfo>()
        collectBd10Items(root, results)
        return results
    }

    private fun collectBd10Items(node: AccessibilityNodeInfo?, list: MutableList<AccessibilityNodeInfo>) {
        if (node == null || !node.isVisibleToUser) return
        val text = node.text?.toString() ?: ""
        if (text.matches(Regex(".*\\d{10,}.*")) || text.matches(Regex("^\\d+\\..*"))) {
            list.add(node)
        }
        for (i in 0 until node.childCount) {
            collectBd10Items(node.getChild(i), list)
        }
    }

    private fun findNodeRecursive(node: AccessibilityNodeInfo?, predicate: (AccessibilityNodeInfo) -> Boolean): AccessibilityNodeInfo? {
        if (node == null || !node.isVisibleToUser) return null
        if (predicate(node)) return node
        for (i in 0 until node.childCount) {
            val childResult = findNodeRecursive(node.getChild(i), predicate)
            if (childResult != null) return childResult
        }
        return null
    }

    private fun findClickableParent(node: AccessibilityNodeInfo?): AccessibilityNodeInfo? {
        var current = node
        while (current != null) {
            if (current.isClickable) return current
            current = current.parent
        }
        return null
    }

    private fun clickNode(node: AccessibilityNodeInfo, label: String = ""): Boolean {
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        val centerX = bounds.centerX().toFloat()
        val centerY = bounds.centerY().toFloat()
        val hasValidBounds = bounds.width() > 0 && bounds.height() > 0 && centerX > 0 && centerY > 0

        val nodeText = node.text?.toString() ?: ""
        val nodeDesc = node.contentDescription?.toString() ?: ""
        val nodeClass = node.className?.toString()?.substringAfterLast(".") ?: "View"
        val descInfo = if (label.isNotEmpty()) "[$label] " else ""
        Log.i(TAG, "🎯 Click ${descInfo}[$nodeClass, text='$nodeText', desc='$nodeDesc', clickable=${node.isClickable}, bounds=$bounds]")

        var success = false

        // 1. Accessibility ACTION_CLICK trên node
        if (node.isClickable) {
            val res = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (res) success = true
        }

        // 2. ACTION_CLICK lên Parent nếu node không clickable
        val clickableParent = findClickableParent(node)
        if (clickableParent != null && clickableParent != node) {
            val resParent = clickableParent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            if (resParent) success = true
        }

        // 3. Kích hoạt Gesture Tap vật lý vào tâm tọa độ (đảm bảo click trúng 100% trên mọi framework)
        if (hasValidBounds) {
            val gestureRes = performGestureClick(centerX, centerY)
            if (gestureRes) success = true
        }

        return success
    }

    private fun setTextOnNode(node: AccessibilityNodeInfo, text: String): Boolean {
        val targetNode = if (node.isEditable) node else (findEditTextNode(node) ?: node)
        val arguments = Bundle()
        arguments.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        return targetNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    private fun performGestureClick(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        if (x <= 0f || y <= 0f) return false

        val path = Path().apply {
            moveTo(x, y)
        }
        val builder = GestureDescription.Builder()
        builder.addStroke(GestureDescription.StrokeDescription(path, 0L, 80L))
        return try {
            dispatchGesture(builder.build(), null, null)
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi khi dispatchGesture: ${e.message}", e)
            false
        }
    }

    // =========================================================================
    // KHỞI CHẠY APP TMS (LAUNCH APP HELPER)
    // =========================================================================

    private fun launchApp(prefixOrPackage: String): Boolean {
        try {
            val pm = packageManager
            val apps = pm.getInstalledApplications(PackageManager.GET_META_DATA)

            // 1. Khớp chính xác package name
            var intent = pm.getLaunchIntentForPackage(prefixOrPackage)
            if (intent != null) {
                targetPackageName = prefixOrPackage
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            }

            // 2. Tìm app có nhãn hoặc Package bắt đầu bằng tiền tố
            for (app in apps) {
                val label = pm.getApplicationLabel(app).toString()
                if (label.startsWith(prefixOrPackage, ignoreCase = true) ||
                    app.packageName.startsWith(prefixOrPackage, ignoreCase = true)) {
                    intent = pm.getLaunchIntentForPackage(app.packageName)
                    if (intent != null) {
                        targetPackageName = app.packageName
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        return true
                    }
                }
            }

            // 3. Tìm app có chứa "TMS", "STM", "VNPost"
            val fallbacks = listOf("STM")
            for (fallback in fallbacks) {
                for (app in apps) {
                    val label = pm.getApplicationLabel(app).toString()
                    if (label.contains(fallback, ignoreCase = true) ||
                        app.packageName.contains(fallback, ignoreCase = true)) {
                        intent = pm.getLaunchIntentForPackage(app.packageName)
                        if (intent != null) {
                            targetPackageName = app.packageName
                            intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                            startActivity(intent)
                            return true
                        }
                    }
                }
            }

            return false
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi khi mở app $prefixOrPackage: ${e.message}", e)
            return false
        }
    }
}
