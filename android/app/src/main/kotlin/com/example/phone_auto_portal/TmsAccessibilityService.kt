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
import android.widget.Button
import android.widget.LinearLayout
import android.widget.TextView
import android.widget.Toast

class TmsAccessibilityService : AccessibilityService() {

    enum class AutomationStep {
        IDLE,
        STEP_1_ACCEPT_ORDER,       // Bấm NHẬN LỆNH
        STEP_2_VIEW_DETAIL,        // Bấm CHI TIẾT
        STEP_3_START_TRIP,          // Bấm BẮT ĐẦU (nút cam)
        STEP_3B_CLICK_POINT_593200, // Bấm nút "593200" (Chọn điểm 593200 trên lộ trình)
       
        STEP_5_CLICK_VAO_POINT_1,   // Bấm VÀO điểm 1
        STEP_6_CLICK_SCAN_BD10_1,   // Bấm SCAN BD10
        STEP_7_INPUT_BD10_CODE,     // Điền mã BD10 và bấm Thêm
        STEP_8_CONFIRM_BD10_1,      // Bấm Xác nhận (modal Danh sách BD10)
        STEP_9_CLICK_RA_POINT_1,    // Bấm RA điểm 1
        STEP_10_SELECT_SECOND_POINT,// Chọn điểm thứ 2 trong lộ trình
        STEP_11_CLICK_VAO_POINT_2,  // Bấm VÀO điểm 2
        STEP_12_CLICK_SCAN_BD10_2,  // Bấm SCAN BD10 điểm 2
        STEP_13_CLICK_DS_BD10_LEN,  // Bấm DS BD10 lên (xanh lá)
        STEP_14_SELECT_ALL_AND_ADD, // Chọn tất cả mã BD10 và bấm Thêm
        STEP_15_CONFIRM_BD10_2,     // Bấm Xác nhận (modal Danh sách BD10)
        STEP_16_CLICK_RA_POINT_2,   // Bấm RA điểm 2 (kết thúc)
        STEP_DONE                   // Hoàn thành
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

        fun isServiceRunning(): Boolean {
            return instance != null
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var stepStartTime: Long = 0L
    private val stepTimeoutMs: Long = 20000L // 20s timeout tối đa cho mỗi bước
    private var totalInactiveCount: Int = 0
    private var isActionPending: Boolean = false
 private var step13RetryCount: Int = 0
    private var lastStep13ClickTime: Long = 0L
    // Window Manager cho nút dừng nổi (Floating Stop Overlay)
    private var windowManager: WindowManager? = null
    private var stopOverlayView: View? = null

    private val automationRunnable = object : Runnable {
        override fun run() {
            if (!isRunning || !isContinuousMode) return
            try {
                processAutomationStep()
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi trong processAutomationStep: ${e.message}", e)
            }
            if (isRunning && isContinuousMode) {
                mainHandler.postDelayed(this, 800)
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
        // Chỉ tự động xử lý khi ở chế độ chạy liên hoàn (Continuous Auto Mode)
        if (!isRunning || !isContinuousMode || event == null) return

        val pkg = event.packageName?.toString() ?: ""
        // Chỉ xử lý event nếu là từ App TMS hoặc App của chúng ta
        if (pkg.isNotEmpty() && !isTmsPackage(pkg) && !pkg.contains("phone_auto_portal")) {
            return
        }

        // Khi có thay đổi cửa sổ hoặc nội dung, kích hoạt kiểm tra ngay nếu không bận
        if (event.eventType == AccessibilityEvent.TYPE_WINDOW_STATE_CHANGED ||
            event.eventType == AccessibilityEvent.TYPE_WINDOW_CONTENT_CHANGED) {
            if (!isActionPending) {
                mainHandler.removeCallbacks(automationRunnable)
                mainHandler.post(automationRunnable)
            }
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
        isContinuousMode = true // Khởi động ở chế độ chạy tự động liên hoàn

        val parsedStep = try {
            AutomationStep.valueOf(startStepName)
        } catch (e: Exception) {
            AutomationStep.STEP_1_ACCEPT_ORDER
        }
        currentStep = parsedStep
        stepStartTime = System.currentTimeMillis()
        totalInactiveCount = 0
        isActionPending = false

        Log.i(TAG, "Bắt đầu tự động hóa TMS từ bước: $currentStep (${getStepShortName(currentStep)}) với mã BD10: $bd10CodeToInput, targetApp: $targetAppName")
        Toast.makeText(this, "Bắt đầu tự động hóa: ${getStepShortName(currentStep)}", Toast.LENGTH_SHORT).show()

        // 1. Hiển thị nút DỪNG thủ công nổi trên màn hình
        showStopOverlayButton()
        updateOverlayStepText(currentStep.name)

        // 2. Mở App TMS
        launchApp(targetAppName)

        // 3. Chạy vòng lặp State Machine
        mainHandler.removeCallbacks(automationRunnable)
        mainHandler.postDelayed(automationRunnable, 1500)
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
        isActionPending = false
        mainHandler.removeCallbacks(automationRunnable)
        removeStopOverlayButton()
        Log.i(TAG, "Đã dừng tự động hóa TMS")
    }

    private fun nextStep(step: AutomationStep, delayMs: Long = 800) {
        currentStep = step
        stepStartTime = System.currentTimeMillis()
        totalInactiveCount = 0
        isActionPending = true
        Log.i(TAG, ">>> CHUYỂN SANG BƯỚC TIẾP THEO: $currentStep")
step13RetryCount = 0
        lastStep13ClickTime = 0L
        updateOverlayStepText(step.name)

        mainHandler.postDelayed({
            isActionPending = false
        }, delayMs)
    }

    private fun isTmsPackage(pkgName: String): Boolean {
        if (targetPackageName.isNotEmpty() && pkgName.equals(targetPackageName, ignoreCase = true)) {
            return true
        }
        val lower = pkgName.lowercase()
        return lower.contains("tms") || lower.contains("stm") || lower.contains("vnpost") || lower.contains("mypost")
    }

        private fun processAutomationStep() {
        if (isActionPending || !isRunning || !isContinuousMode) return

        val rootNode = rootInActiveWindow ?: run {
            Log.d(TAG, "rootInActiveWindow is null, đang chờ...")
            return
        }

        val currentPkg = rootNode.packageName?.toString() ?: ""

        // =====================================================================
        // KIỂM TRA ỨNG DỤNG TMS CÓ ĐANG ACTIVE KHÔNG
        // =====================================================================
        if (currentPkg.isNotEmpty() && !isTmsPackage(currentPkg)) {
            if (currentPkg.contains("phone_auto_portal")) {
                Log.d(TAG, "Đang ở màn hình app phone_auto_portal, đang chờ chuyển sang TMS...")
                return
            }

            totalInactiveCount++
            if (totalInactiveCount % 5 == 0) {
                Log.d(TAG, "App TMS không active (cửa sổ hiện tại: $currentPkg). Tạm dừng chờ TMS active...")
            }
            return
        }

        if (currentPkg.isNotEmpty() && isTmsPackage(currentPkg) && targetPackageName.isEmpty()) {
            targetPackageName = currentPkg
            Log.i(TAG, "Đã nhận diện package TMS active: $targetPackageName")
        }

        // Kiểm tra timeout cho bước hiện tại (chỉ áp dụng trong Continuous Auto Mode)
        if (System.currentTimeMillis() - stepStartTime > stepTimeoutMs) {
            Log.w(TAG, "Đang chờ phần tử của bước: $currentStep trên màn hình TMS...")
            handleStepTimeout(rootNode)
            return
        }

        // Thực thi bước hiện tại trong chế độ tự động liên hoàn
        val success = executeStepAction(currentStep, rootNode)
        if (success) {
            val idx = RUNNABLE_STEPS.indexOf(currentStep)
            val nextStepEnum = if (idx >= 0 && idx < RUNNABLE_STEPS.size - 1) {
                RUNNABLE_STEPS[idx + 1]
            } else {
                AutomationStep.STEP_DONE
            }
            val delay = when (currentStep) {
                AutomationStep.STEP_1_ACCEPT_ORDER, 
                AutomationStep.STEP_3_START_TRIP, 
                AutomationStep.STEP_3B_CLICK_POINT_593200,
                AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> 6000L // 👈 THÊM DÒNG NÀY ĐỂ CHỜ POPUP ĐÓNG HẲN (1.5s)
                AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> 8000L
                AutomationStep.STEP_10_SELECT_SECOND_POINT -> 2000L
                AutomationStep.STEP_7_INPUT_BD10_CODE, 
                AutomationStep.STEP_14_SELECT_ALL_AND_ADD -> 1200L
                AutomationStep.STEP_8_CONFIRM_BD10_1, AutomationStep.STEP_15_CONFIRM_BD10_2 -> 1200L
                AutomationStep.STEP_9_CLICK_RA_POINT_1 -> 8500L 
                else -> 800L
            }
            nextStep(nextStepEnum, delay)
        }
    }

    /**
     * Thực thi một bước cụ thể trên cây giao diện (UI Tree) hiện tại.
     * Trả về true nếu đã tìm thấy và thực hiện thành công thao tác (hoặc màn hình đã ở bước tiếp theo), false nếu không tìm thấy.
     */
    private fun executeStepAction(step: AutomationStep, rootNode: AccessibilityNodeInfo): Boolean {
        return when (step) {
            // -------------------------------------------------------------
            // BƯỚC 1: Nhận lệnh tại tab "Lệnh mới"
            // -------------------------------------------------------------
            AutomationStep.STEP_1_ACCEPT_ORDER -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Đồng Ý", "Dong y", "DONG Y", "Chấp nhận", "CHẤP NHẬN", "OK", "Ok"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Bạn muốn nhận lệnh này?", "Hủy", "HUY")) != null) {
                    Log.i(TAG, "Bước 1: Phát hiện popup [Bạn muốn nhận lệnh này?], đang bấm nút [Đồng ý]...")
                    return clickNode(popupAgreeBtn, "Nút Đồng ý")
                }

                val acceptBtn = findNodeByTexts(rootNode, listOf("NHẬN LỆNH", "Nhận lệnh", "NHAN LENH"))
                if (acceptBtn != null) {
                    Log.i(TAG, "Bước 1: Tìm thấy nút [NHẬN LỆNH], đang bấm...")
                    return clickNode(acceptBtn, "Nút NHẬN LỆNH")
                }

                val detailBtn = findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết", "CHI TIET", "Chi Tiết"))
                if (detailBtn != null) {
                    Log.i(TAG, "Bước 1: Đã ở màn hình có nút [CHI TIẾT]")
                    return true
                }

                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Bước 1: Đã ở màn hình chi tiết chuyến")
                    return true
                }

                if (findNodeByTexts(rootNode, listOf("TRẠNG THÁI", "LỘ TRÌNH", "Chuyến đang chạy", "Chuyển đang chạy")) != null) {
                    Log.i(TAG, "Bước 1: Đã ở màn hình chuyến đang chạy")
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 2: Bấm nút "CHI TIẾT" (Màn hình Đã nhận lệnh)
            // -------------------------------------------------------------
            AutomationStep.STEP_2_VIEW_DETAIL -> {
                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Đồng Ý", "Dong y", "DONG Y", "Chấp nhận", "CHẤP NHẬN", "OK", "Ok"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Bạn muốn nhận lệnh này?", "Hủy", "HUY")) != null) {
                    Log.i(TAG, "Bước 2: Phát hiện popup [Bạn muốn nhận lệnh này?], đang bấm nút [Đồng ý]...")
                    return clickNode(popupAgreeBtn, "Nút Đồng ý")
                }

                val detailBtn = findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết", "CHI TIET", "Chi Tiết"))
                if (detailBtn != null) {
                    Log.i(TAG, "Bước 2: Tìm thấy nút [CHI TIẾT], đang bấm...")
                    return clickNode(detailBtn, "Nút CHI TIẾT")
                }

                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Bước 2: Đã thấy nút [BẮT ĐẦU]")
                    return true
                }

                val hasPopup = findNodeByTexts(rootNode, listOf("Bạn muốn nhận lệnh này?", "Hủy")) != null
                if (!hasPopup) {
                    val acceptBtn = findNodeByTexts(rootNode, listOf("NHẬN LỆNH", "Nhận lệnh", "NHAN LENH"))
                    if (acceptBtn != null) {
                        return clickNode(acceptBtn, "Nút NHẬN LỆNH (Retry từ Bước 2)")
                    }
                    val daNhanTab = findNodeByTexts(rootNode, listOf("Đã nhận", "ĐÃ NHẬN", "Da nhan"))
                    if (daNhanTab != null && findNodeByTexts(rootNode, listOf("Lệnh mới", "Chuyến mới")) != null) {
                        return clickNode(daNhanTab, "Tab Đã nhận")
                    }
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 3: Bấm nút "BẮT ĐẦU" (Chi tiết chuyến)
            // -------------------------------------------------------------
            AutomationStep.STEP_3_START_TRIP -> {
                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu"))
                if (startBtn != null) {
                    Log.i(TAG, "Bước 3: Tìm thấy nút [BẮT ĐẦU], đang bấm...")
                    return clickNode(startBtn, "Nút BẮT ĐẦU")
                }
                if (findNodeByTexts(rootNode, listOf("Chuyến đang chạy", "TRẠNG THÁI", "LỘ TRÌNH","HÌNH ẢNH")) != null) {
                    Log.i(TAG, "Bước 3: Đã vào màn hình chuyến đang chạy")
                    return true
                }
                false
            }

                        // -------------------------------------------------------------
            // BƯỚC 3B: Bấm nút "593200" (Chọn điểm 593200 trên lộ trình)
            // -------------------------------------------------------------
            AutomationStep.STEP_3B_CLICK_POINT_593200 -> {
                if (handleArrivalNotificationPopup(rootNode, "Bước 3B")) return true

                // Nếu đã ở màn hình chi tiết điểm 1 (thấy Đến điểm hoặc Nhận hàng tại:) -> Đã chọn điểm thành công
                if (findNodeByTexts(rootNode, listOf("đi khỏi điểm")) != null) {
                    Log.i(TAG, "Bước 3B: Đã ở màn hình chi tiết điểm 1 (593200)")
                    return true
                }

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
            // BƯỚC 5: Bấm nút/tab "Đến điểm" (VÀO) của điểm 1 & Xác nhận popup
            // -------------------------------------------------------------
           AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> {
                // 1. Nếu popup [Thông báo / Xác nhận đến điểm] đã hiện sẵn từ trước -> Bấm [Đồng ý] ngay
                if (handleArrivalNotificationPopup(rootNode, "Bước 5")) return true

                // 2. Kiểm tra nếu ĐÃ ĐẾN ĐIỂM THÀNH CÔNG (Trạng thái: Đã đến, Thực tế đến)
                val isArrived = findNodeByTexts(rootNode, listOf("Trạng thái: Đã đến", "Đã đến", "Thực tế đến")) != null
                if (isArrived) {
                    Log.i(TAG, "Bước 5: Đã xác nhận đến điểm 1 thành công (Trạng thái: Đã đến)")
                    return true
                }

                // 3. Nếu chưa đến điểm -> Tìm nút [Đến điểm] để bấm
                val vaoBtn = findNodeByTexts(rootNode, listOf("đến điểm", "ĐẾN ĐIỂM", "Đến Điểm"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Bước 5: Tìm thấy nút [Đến điểm], đang bấm...")
                    clickNode(vaoBtn, "Nút Đến điểm 1")

                    // 👉 CHỜ 600ms CHO POPUP HIỆN LÊN RỒI TỰ ĐỘNG BẤM [ĐỒNG Ý]
                    mainHandler.postDelayed({
                        val currentRoot = rootInActiveWindow ?: return@postDelayed
                        
                        // Cách 1: Dùng hàm kiểm tra popup chuẩn
                        if (!handleArrivalNotificationPopup(currentRoot, "Bước 5 (Tự động bấm popup)")) {
                            // Cách 2: Quét tìm trực tiếp nút [Đồng ý] / [Xác nhận] / [OK] phòng khi tiêu đề popup khác chữ "Thông báo"
                            val agreeBtn = findNodeByTexts(currentRoot, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "Chấp nhận", "Xác nhận", "OK", "Ok"))
                            if (agreeBtn != null) {
                                Log.i(TAG, "Bước 5: Đang bấm nút Đồng ý trên popup...")
                                clickNode(agreeBtn, "Nút Đồng ý Popup Đến Điểm")
                            }
                        }
                    }, 600)

                    return true
                }

                false
            }

            // -------------------------------------------------------------
            // BƯỚC 6: Bấm nút "SCAN BD10" tại điểm 1
            // -------------------------------------------------------------
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1 -> {
                if (findNodeByTexts(rootNode, listOf("Danh sách BD10", "Danh sach BD10", "Nhập tay mã BD10")) != null ||
                    findEditTextNode(rootNode) != null) {
                    Log.i(TAG, "Bước 6: Đã thấy popup [Danh sách BD10]")
                    return true
                }

                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10", "SCAN MÃ BD10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Bước 6: Tìm thấy nút [SCAN BD10], đang bấm...")
                    return clickNode(scanBtn, "Nút SCAN BD10")
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 7: Điền mã BD10 vào ô nhập và bấm nút "Thêm"
            // -------------------------------------------------------------
            AutomationStep.STEP_7_INPUT_BD10_CODE -> {
                val editText = findEditTextNode(rootNode)
                if (editText != null && bd10CodeToInput.isNotEmpty()) {
                    Log.i(TAG, "Bước 7: Tìm thấy ô EditText, đang điền mã BD10: $bd10CodeToInput")
                    if (setTextOnNode(editText, bd10CodeToInput)) {
                        mainHandler.postDelayed({
                            val root = rootInActiveWindow ?: return@postDelayed
                            val addBtn = findNodeByTexts(root, listOf("Thêm", "THÊM", "Them"))
                            if (addBtn != null) {
                                Log.i(TAG, "Bước 7: Tìm thấy nút [Thêm], đang bấm...")
                                clickNode(addBtn, "Nút Thêm mã BD10")
                            }
                        }, 500)
                        return true
                    }
                } else if (bd10CodeToInput.isEmpty()) {
                    Log.w(TAG, "Bước 7: Không có mã BD10 cần nhập -> hoàn thành")
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 8: Bấm nút "Xác nhận" (modal Danh sách BD10)
            // -------------------------------------------------------------
            AutomationStep.STEP_8_CONFIRM_BD10_1 -> {
                val confirmBtn = findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN", "Xac nhan", "XAC NHAN"))
                if (confirmBtn != null) {
                    Log.i(TAG, "Bước 8: Tìm thấy nút [Xác nhận], đang bấm...")
                    return clickNode(confirmBtn, "Nút Xác nhận Modal BD10")
                }

                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null && findNodeByTexts(rootNode, listOf("Danh sách BD10")) == null) {
                    Log.i(TAG, "Bước 8: Modal đã đóng, thấy nút [RA]")
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 9: Bấm nút/tab "RA" của điểm 1
            // -------------------------------------------------------------
           AutomationStep.STEP_9_CLICK_RA_POINT_1 -> {
                // 1. Nếu popup thông báo rời điểm đã hiện sẵn -> Bấm [Đồng ý] ngay
                if (handleArrivalNotificationPopup(rootNode, "Bước 9")) return true

                // 2. Tìm nút "Đi khỏi điểm" để bấm
                val raBtn = findNodeByTexts(rootNode, listOf("Đi khỏi điểm", "ĐI KHỎI ĐIỂM", "Đi Khỏi Điểm", "RA", "Ra"))
                if (raBtn != null) {
                    Log.i(TAG, "Bước 9: Tìm thấy nút [Đi khỏi điểm], đang bấm...")
                    clickNode(raBtn, "Nút Đi khỏi điểm 1")

                    // 👉 CHỜ 600ms CHO POPUP XUẤT HIỆN RỒI TỰ ĐỘNG BẤM [ĐỒNG Ý]
                    mainHandler.postDelayed({
                        val currentRoot = rootInActiveWindow ?: return@postDelayed
                        if (!handleArrivalNotificationPopup(currentRoot, "Bước 9 (Popup rời điểm)")) {
                            val agreeBtn = findNodeByTexts(currentRoot, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "Xác nhận", "OK", "Ok"))
                            if (agreeBtn != null) {
                                Log.i(TAG, "Bước 9: Đang bấm nút Đồng ý popup rời điểm...")
                                clickNode(agreeBtn, "Nút Đồng ý Rời Điểm")
                            }
                        }
                    }, 600)

                    // Hiển thị thông báo để biết đang chờ 8 giây
                    Toast.makeText(this, "⏳ Đã xác nhận rời điểm 1. Đang chờ 8 giây...", Toast.LENGTH_SHORT).show()
                    return true
                }

                // 3. Nếu màn hình đã quay lại lộ trình chuyến
                if (findNodeByTexts(rootNode, listOf("BCP", "Giao hàng", "Chuyến đang chạy", "LỘ TRÌNH")) != null) {
                    Log.i(TAG, "Bước 9: Đã ở màn hình lộ trình chuyến")
                    return true
                }

                false
            }

            // -------------------------------------------------------------
            // BƯỚC 10: Chọn điểm thứ 2 trong lộ trình (Điểm bưu cục giao/trả)
            // -------------------------------------------------------------
            AutomationStep.STEP_10_SELECT_SECOND_POINT -> {
               
                val vaoBtn = findNodeByTexts(rootNode, listOf("593280"))
                if (vaoBtn != null) {
                    clickNode(vaoBtn,"Điểm thứ 2")
                    return true
                }

                false
            }

            // -------------------------------------------------------------
            // BƯỚC 11: Bấm nút/tab "VÀO" của điểm 2
            // -------------------------------------------------------------
            AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> {
               

                val vaoBtn = findNodeByTexts(rootNode, listOf("Đến điểm"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Bước 11: Tìm thấy nút [VÀO / Đến điểm], đang bấm...")
                    clickNode(vaoBtn, "Nút VÀO Điểm 2")
                    mainHandler.postDelayed({
                        val currentRoot = rootInActiveWindow ?: return@postDelayed
                        if (!handleArrivalNotificationPopup(currentRoot, "Bước 11 (Popup đến điểm 2)")) {
                            val agreeBtn = findNodeByTexts(currentRoot, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "Chấp nhận", "Xác nhận", "OK", "Ok"))
                            if (agreeBtn != null) {
                                Log.i(TAG, "Bước 11: Đang bấm nút Đồng ý popup đến điểm 2...")
                                clickNode(agreeBtn, "Nút Đồng ý Điểm 2")
                            }
                        }
                    }, 600)
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 12: Bấm nút "SCAN BD10" tại điểm 2
            // -------------------------------------------------------------
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2 -> {
                val dsLenBtn = findNodeByTexts(rootNode, listOf("DS BD10 lên", "DS BD10 LEN", "DS BD10 len", "DS BD10 LÊN"))
                if (dsLenBtn != null) return true

                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10", "SCAN MÃ BD10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Bước 12: Tìm thấy nút [SCAN BD10], đang bấm...")
                    return clickNode(scanBtn, "Nút SCAN BD10 Điểm 2")
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 13: Bấm nút "DS BD10 lên" (màu xanh lá)
            // -------------------------------------------------------------
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> {
                // 🎯 1. ĐIỀU KIỆN TIÊN QUYẾT: Nếu ĐÃ THẤY popup "DS BD10 tại điểm lên" -> XONG BƯỚC 13!
                val popupModal = findNodeByTexts(rootNode, listOf("DS BD10 tại điểm lên", "tai diem len", "điểm lên"))
                if (popupModal != null) {
                    Log.i(TAG, "Bước 13: ✅ ĐÃ MỞ THÀNH CÔNG popup [DS BD10 tại điểm lên] -> Chuyển sang Bước 14!")
                    step13RetryCount = 0
                    return true
                }

                // 2. Nếu đã thử bấm đủ 5 lần mà popup vẫn không mở -> Dừng cảnh báo
                if (step13RetryCount >= 5) {
                    Log.e(TAG, "Bước 13: ❌ Đã thử bấm 5 lần nhưng popup không mở!")
                    mainHandler.post {
                        Toast.makeText(this, "⚠️ Không thể mở DS BD10 sau 5 lần thử!", Toast.LENGTH_LONG).show()
                    }
                    stopAutomation()
                    return false
                }

                // 3. Giãn cách: Mỗi lần bấm cách nhau ít nhất 1.5 giây để tránh chớp nút liên tục
                val now = System.currentTimeMillis()
                if (now - lastStep13ClickTime < 1500L) {
                    // Đang trong thời gian 1.5s chờ popup tải, kiên nhẫn đợi không click spam
                    return false
                }

                // 4. Tìm nút xanh lá "DS BD10 lên"
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

                // 5. Thực hiện bấm nút và tăng biến đếm
                if (dsLenBtn != null) {
                    step13RetryCount++
                    lastStep13ClickTime = now

                    val target = findClickableParent(dsLenBtn) ?: dsLenBtn
                    val bounds = Rect()
                    target.getBoundsInScreen(bounds)
                    val cx = bounds.centerX().toFloat()
                    val cy = bounds.centerY().toFloat()

                    Log.i(TAG, "Bước 13: Đang bấm [DS BD10 lên] lần $step13RetryCount/5...")
                    mainHandler.post {
                        Toast.makeText(this, "👉 Bấm DS BD10 lên (lần $step13RetryCount/5)...", Toast.LENGTH_SHORT).show()
                    }

                    if (bounds.width() > 0 && bounds.height() > 0) {
                        performGestureClick(cx, cy)
                    } else {
                        clickNode(target, "Nút DS BD10 lên")
                    }

                    // 👉 Nếu đang chạy tự động: Trả về FALSE để CHƯA CHUYỂN BƯỚC NGAY,
                    // mà chờ vòng lặp 800ms kế tiếp kiểm tra xem popup đã mở chưa.
                    // Chỉ khi popup ĐÃ MỞ (ở mục 1) thì mới trả về TRUE!
                    return !isContinuousMode
                }

                false
            }

            // -------------------------------------------------------------
            // BƯỚC 14: Bấm nút "Thêm" trong popup "DS BD10 tại điểm lên"
            // -------------------------------------------------------------
            AutomationStep.STEP_14_SELECT_ALL_AND_ADD -> {
                // 1. Tìm chính xác nút [Thêm] màu xanh lá của popup "DS BD10 tại điểm lên" (tránh nút Thêm xanh dương của ô nhập tay)
                val addBtn = findAddButtonInDsLenPopup(rootNode)
                if (addBtn != null) {
                    Log.i(TAG, "Bước 14: Tìm thấy nút [Thêm] popup DS BD10 tại điểm lên, đang bấm...")
                    return clickNode(addBtn, "Nút Thêm popup DS BD10 Điểm 2")
                }

                // 2. Nếu popup DS BD10 tại điểm lên đã đóng và đã thấy nút Xác nhận -> coi như xong bước 14
                if (findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN")) != null) {
                    Log.i(TAG, "Bước 14: Đã ở màn hình có nút [Xác nhận]")
                    return true
                }

                // 3. Nếu thấy nút RA và không còn popup -> coi như đã xong
                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null && findNodeByTexts(rootNode, listOf("DS BD10", "Danh sách BD10")) == null) {
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 15: Bấm nút "Xác nhận" (modal Danh sách BD10 tại điểm 2)
            // -------------------------------------------------------------
            AutomationStep.STEP_15_CONFIRM_BD10_2 -> {
                // Self-healing: Nếu màn hình vẫn còn popup "DS BD10 tại điểm lên" (thấy nút Thêm) -> bấm nút Thêm giúp người dùng
                val addBtn = findAddButtonInDsLenPopup(rootNode)
                if (addBtn != null && findNodeByTexts(rootNode, listOf("DS BD10 tại điểm lên", "DS BD10 tai diem len", "điểm lên")) != null) {
                    Log.i(TAG, "Bước 15: Phát hiện vẫn còn popup [DS BD10 tại điểm lên], tự động bấm nút [Thêm]...")
                    return clickNode(addBtn, "Nút Thêm (Self-healing từ Bước 15)")
                }

                 val items = findBd10ItemsInPopup(rootNode)
                for (item in items) {
                    clickNode(item)
                    Log.i(TAG, "Bước 14: Đã click chọn mã BD10 item: ${item.text}")
                }

                val confirmBtn = findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN", "Xac nhan", "XAC NHAN"))
                if (confirmBtn != null) {
                    Log.i(TAG, "Bước 15: Tìm thấy nút [Xác nhận], đang bấm...")
                    return clickNode(confirmBtn, "Nút Xác nhận Modal Điểm 2")
                }

                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null && findNodeByTexts(rootNode, listOf("Danh sách BD10")) == null) {
                    Log.i(TAG, "Bước 15: Modal đã đóng, thấy nút [RA]")
                    return true
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC 16: Bấm nút/tab "RA" của điểm 2 (Kết thúc chuyến)
            // -------------------------------------------------------------
            AutomationStep.STEP_16_CLICK_RA_POINT_2 -> {
                if (handleArrivalNotificationPopup(rootNode, "Bước 16")) return true

                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra", "Đi khỏi điểm", "Kết thúc chuyến"))
                if (raBtn != null) {
                    Log.i(TAG, "Bước 16: Tìm thấy nút [RA / Kết thúc chuyến], đang bấm...")
                    return clickNode(raBtn, "Nút RA Điểm 2")
                }
                false
            }

            // -------------------------------------------------------------
            // BƯỚC CUỐI: Hoàn thành tự động hóa
            // -------------------------------------------------------------
            AutomationStep.STEP_DONE -> {
                Log.i(TAG, "==============================================")
                Log.i(TAG, " ĐÃ HOÀN THÀNH TOÀN BỘ TIẾN TRÌNH TỰ ĐỘNG HÓA TMS!")
                Log.i(TAG, "==============================================")
                Toast.makeText(this, "Hoàn tất tự động hóa quét BD10 TMS!", Toast.LENGTH_LONG).show()
                stopAutomation()
                true
            }

            AutomationStep.IDLE -> {
                false
            }
        }
    }

    /**
     * Kiểm tra và bấm nút [Đồng ý] của popup Thông báo (Xác nhận đến điểm / rời điểm / nhận lệnh)
     */
    private fun handleArrivalNotificationPopup(rootNode: AccessibilityNodeInfo, currentStepName: String): Boolean {
        val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Dong y", "DONG Y", "Chấp nhận", "OK", "Ok"))
        val isArrivalPopup = findNodeByTexts(rootNode, listOf("Thông báo", "Xác nhận đến điểm?", "Xác nhận rời điểm?", "Xác nhận đến điểm", "Xác nhận rời điểm", "Bạn muốn nhận lệnh này?")) != null
        if (popupAgreeBtn != null && isArrivalPopup) {
            Log.i(TAG, "[$currentStepName] Phát hiện popup Thông báo, đang bấm [Đồng ý]...")
            clickNode(popupAgreeBtn, "Nút Đồng ý Popup ($currentStepName)")
            return true
        }
        return false
    }

    /**
     * Xử lý timeout an toàn: Dump UI để debug và tự động phục hồi nếu kẹt
     */
    private fun handleStepTimeout(rootNode: AccessibilityNodeInfo) {
        stepStartTime = System.currentTimeMillis() // Reset timer để chờ tiếp
        Log.w(TAG, "⏳ TIMEOUT bước $currentStep sau ${stepTimeoutMs}ms. Đang dump cây UI và tự động khôi phục...")
        logNodeHierarchy(rootNode)

        // 1. Kiểm tra nếu có popup Thông báo / Xác nhận đến điểm đang che màn hình
        if (handleArrivalNotificationPopup(rootNode, "Timeout $currentStep")) {
            return
        }

        // Tự động kiểm tra và chuyển bước hoặc retry nếu màn hình có phần tử tương ứng
        when (currentStep) {
            AutomationStep.STEP_1_ACCEPT_ORDER, AutomationStep.STEP_2_VIEW_DETAIL -> {
                val acceptBtn = findNodeByTexts(rootNode, listOf("NHẬN LỆNH", "Nhận lệnh", "NHAN LENH"))
                if (acceptBtn != null) {
                    Log.w(TAG, "Timeout: Phát hiện vẫn còn nút [NHẬN LỆNH], bấm lại...")
                    clickNode(acceptBtn, "Nút NHẬN LỆNH (Timeout Retry)")
                    return
                }

                val popupAgreeBtn = findNodeByTexts(rootNode, listOf("Đồng ý", "ĐỒNG Ý", "Đồng Ý", "Dong y", "DONG Y", "Chấp nhận", "OK"))
                if (popupAgreeBtn != null && findNodeByTexts(rootNode, listOf("Bạn muốn nhận lệnh này?", "Hủy", "HUY")) != null) {
                    Log.i(TAG, "Timeout: Phát hiện popup xác nhận nhận lệnh chưa đóng, bấm [Đồng ý]...")
                    clickNode(popupAgreeBtn, "Nút Đồng ý (Timeout)")
                    return
                }

                val detailBtn = findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết", "CHI TIET", "Chi Tiết"))
                if (detailBtn != null) {
                    Log.i(TAG, "Timeout: Đã thấy nút [CHI TIẾT], bấm chi tiết...")
                    if (clickNode(detailBtn, "Nút CHI TIẾT (Timeout)")) {
                        nextStep(AutomationStep.STEP_3_START_TRIP, 1000)
                        return
                    }
                }

                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Timeout: Đã thấy nút [BẮT ĐẦU] -> sang Bước 3")
                    nextStep(AutomationStep.STEP_3_START_TRIP, 500)
                    return
                }

                val daNhanTab = findNodeByTexts(rootNode, listOf("Đã nhận", "ĐÃ NHẬN", "Da nhan"))
                if (daNhanTab != null) {
                    Log.i(TAG, "Timeout: Thử bấm chuyển sang tab [Đã nhận]...")
                    clickNode(daNhanTab, "Tab Đã nhận (Timeout)")
                }
            }
            AutomationStep.STEP_3_START_TRIP -> {
                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    clickNode(startBtn, "Nút BẮT ĐẦU (Timeout Retry)")
                } else if (findNodeByTexts(rootNode, listOf("TRẠNG THÁI", "LỘ TRÌNH")) != null) {
                    nextStep(AutomationStep.STEP_3B_CLICK_POINT_593200, 500)
                }
            }
            AutomationStep.STEP_3B_CLICK_POINT_593200 -> {
                if (findNodeByTexts(rootNode, listOf("Đến điểm", "ĐẾN ĐIỂM", "Nhận hàng tại", "Trạng thái: Chưa đến điểm", "Trạng thái: Đã đến", "Thực tế đến")) != null) {
                    nextStep(AutomationStep.STEP_5_CLICK_VAO_POINT_1, 500)
                } else {
                    val btn593200 = findNodeByTexts(rootNode, listOf("593200", "Hoài Nhơn", "Hòai Nhơn"))
                    if (btn593200 != null) {
                        val target = findClickableParent(btn593200) ?: btn593200
                        clickNode(target, "Nút 593200 (Timeout Retry)")
                    } else {
                        val firstPoint = findFirstRoutePointNode(rootNode)
                        if (firstPoint != null) {
                            clickNode(firstPoint, "Điểm 1 (Timeout Retry)")
                        }
                    }
                }
            }
            AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> {
                if (findNodeByTexts(rootNode, listOf("Trạng thái: Đã đến", "Đã đến", "Thực tế đến")) != null) {
                    nextStep(AutomationStep.STEP_6_CLICK_SCAN_BD10_1, 500)
                } else {
                    val vaoBtn = findNodeByTexts(rootNode, listOf("Đến điểm", "ĐẾN ĐIỂM", "VÀO", "Vào", "VAO"))
                    if (vaoBtn != null) {
                        clickNode(vaoBtn, "Nút Đến điểm 1 (Timeout Retry)")
                    }
                }
            }
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1 -> {
                if (findNodeByTexts(rootNode, listOf("Danh sách BD10", "Nhập tay mã BD10")) != null) {
                    nextStep(AutomationStep.STEP_7_INPUT_BD10_CODE, 500)
                } else {
                    val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10"))
                    if (scanBtn != null) {
                        clickNode(scanBtn, "Nút SCAN BD10 (Timeout Retry)")
                    }
                }
            }
            AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> {
                if (findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10")) != null) {
                    nextStep(AutomationStep.STEP_12_CLICK_SCAN_BD10_2, 500)
                }
            }
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2 -> {
                if (findNodeByTexts(rootNode, listOf("DS BD10 lên", "DS BD10 LEN")) != null) {
                    nextStep(AutomationStep.STEP_13_CLICK_DS_BD10_LEN, 500)
                }
            }
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> {
                if (findNodeByTexts(rootNode, listOf("DS BD10 tại điểm lên")) != null) {
                    nextStep(AutomationStep.STEP_14_SELECT_ALL_AND_ADD, 500)
                }
            }
            else -> {
                Log.d(TAG, "Vẫn đang chờ bước: $currentStep...")
            }
        }
    }

    // =========================================================================
    // THANH ĐIỀU KHIỂN NỔI ĐA NĂNG TRÊN MÀN HÌNH (FLOATING CONTROL BAR)
    // =========================================================================

    /**
     * Bấm nút TIẾN (⏭): CHỈ chuyển con trỏ sang bước tiếp theo để chọn, TUYỆT ĐỐI KHÔNG tự động chạy!
     */
    fun stepForward() {
        isContinuousMode = false
        mainHandler.removeCallbacks(automationRunnable)

        val idx = RUNNABLE_STEPS.indexOf(currentStep)
        val nextIdx = if (idx >= 0 && idx < RUNNABLE_STEPS.size - 1) idx + 1 else 0
        currentStep = RUNNABLE_STEPS[nextIdx]

        stepStartTime = System.currentTimeMillis()
        totalInactiveCount = 0
        isActionPending = false

        Log.i(TAG, "⏭ [Thủ công] Đã chọn bước: $currentStep (${getStepShortName(currentStep)})")
        Toast.makeText(this, "⏭ Đã chọn: ${getStepShortName(currentStep)}", Toast.LENGTH_SHORT).show()
        updateOverlayStepText(currentStep.name)
    }

    /**
     * Bấm nút LÙI (⏮): CHỈ chuyển con trỏ sang bước trước đó để chọn, TUYỆT ĐỐI KHÔNG tự động chạy!
     */
    fun stepBackward() {
        isContinuousMode = false
        mainHandler.removeCallbacks(automationRunnable)

        val idx = RUNNABLE_STEPS.indexOf(currentStep)
        val prevIdx = if (idx > 0) idx - 1 else RUNNABLE_STEPS.size - 1
        currentStep = RUNNABLE_STEPS[prevIdx]

        stepStartTime = System.currentTimeMillis()
        totalInactiveCount = 0
        isActionPending = false

        Log.i(TAG, "⏮ [Thủ công] Đã chọn bước: $currentStep (${getStepShortName(currentStep)})")
        Toast.makeText(this, "⏮ Đã chọn: ${getStepShortName(currentStep)}", Toast.LENGTH_SHORT).show()
        updateOverlayStepText(currentStep.name)
    }

    /**
     * Bấm nút CHẠY (⚡ Chạy): CHỈ chạy duy nhất bước đang được chọn (Single-Step Execution).
     * Sau khi chạy xong bước đó:
     * - Cập nhật bước tiếp theo lên thanh nổi để sẵn sàng cho lần bấm tiếp theo.
     * - DỪNG LẠI tại đó (KHÔNG tự động chạy lan man sang các bước kế tiếp).
     */
    fun runCurrentStepManually() {
        isContinuousMode = false
        mainHandler.removeCallbacks(automationRunnable)

        if (!isRunning) {
            isRunning = true
        }
        if (currentStep == AutomationStep.IDLE || currentStep == AutomationStep.STEP_DONE) {
            currentStep = RUNNABLE_STEPS.first()
            updateOverlayStepText(currentStep.name)
        }

        // Tự động lấy mã BD10 từ Clipboard hệ thống nếu biến trong bộ nhớ đang rỗng
        if (bd10CodeToInput.isEmpty()) {
            try {
                val clipboard = getSystemService(Context.CLIPBOARD_SERVICE) as? ClipboardManager
                val clipText = clipboard?.primaryClip?.getItemAt(0)?.text?.toString()?.trim() ?: ""
                if (clipText.isNotEmpty()) {
                    bd10CodeToInput = clipText
                    Log.i(TAG, "Lấy mã BD10 từ Clipboard: $bd10CodeToInput")
                }
            } catch (e: Exception) {
                Log.w(TAG, "Không thể đọc Clipboard: ${e.message}")
            }
        }

        isActionPending = false
        stepStartTime = System.currentTimeMillis()
        val stepToRun = currentStep

        Log.i(TAG, "⚡ [Thủ công] Bắt đầu chạy duy nhất bước: $stepToRun (${getStepShortName(stepToRun)})")
        Toast.makeText(this, "⚡ Đang chạy: ${getStepShortName(stepToRun)}...", Toast.LENGTH_SHORT).show()

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

                val success = executeStepAction(stepToRun, rootNode)
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
                    Log.w(TAG, "⚠️ [Thủ công] Không tìm thấy nút cho: ${getStepShortName(stepToRun)}")
                    Toast.makeText(this, "⚠️ Không thấy nút cho: ${getStepShortName(stepToRun)}\nHãy kiểm tra màn hình hoặc dùng ⏮/⏭ chọn lại!", Toast.LENGTH_LONG).show()
                }
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi thực thi thủ công bước $stepToRun: ${e.message}", e)
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

                // Hỗ trợ kéo thả thanh công cụ
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
                            false // Trả về false để các nút con vẫn nhận click
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

    private fun findFirstRoutePointNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val specific = findNodeByTexts(root, listOf("593200", "Hoài Nhơn", "Tam Quan", "Kho", "Nhận hàng", "Chưa đến điểm"))
        if (specific != null) {
            return findClickableParent(specific) ?: specific
        }
        return null
    }

    private fun findSecondRoutePointNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        val specific = findNodeByTexts(root, listOf("BCP", "Quy Nhơn", "Giao hàng", "Trả hàng"))
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
     * Đồng thời in LOG CHI TIẾT & HIỂN THỊ TOAST để người dùng nhận diện rõ ràng.
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

        // 4. Lựa chọn Target chính xác
        var target: DetectedAddButton? = detectedList.firstOrNull { it.modalType.contains("Modal 2") }

        if (target == null && detectedList.isNotEmpty()) {
            target = detectedList.lastOrNull { it.isClickable || it.className.contains("Button") } ?: detectedList.last()
        }

        for (btn in detectedList) {
            if (btn == target) {
                btn.isTarget = true
                btn.reason = "NÚT MỤC TIÊU CẦN BẤM (Cửa sổ nổi Modal 2 bên trên)"
            } else {
                btn.isTarget = false
                btn.reason = "Nằm ở Modal 1 bên dưới (bị che khuất, bỏ qua)"
            }
        }

        // 5. In LOG BLOCK CHI TIẾT ĐỂ NGƯỜI DÙNG DỄ DÀNG QUAN SÁT VÀ PHÂN BIỆT
        Log.i(TAG, "╔═══════════════════════════════════════════════════════════════════════════════╗")
        Log.i(TAG, "║ 🔍 [TMS BUTTON DETECT] PHÂN TÍCH TOÀN BỘ BUTTON 'THÊM' TRÊN MÀN HÌNH          ║")
        Log.i(TAG, "╠═══════════════════════════════════════════════════════════════════════════════╣")
        Log.i(TAG, "║ Tổng số nút 'Thêm' phát hiện: ${detectedList.size}")
        for ((idx, btn) in detectedList.withIndex()) {
            val mark = if (btn.isTarget) "🎯 [ĐƯỢC CHỌN]" else "⏭️ [BỎ QUA]"
            Log.i(TAG, "║")
            Log.i(TAG, "║ $mark Nút #${idx + 1}: ${btn.modalType}")
            Log.i(TAG, "║   ├─ Class: ${btn.className}, Text: '${btn.text}', Clickable: ${btn.isClickable}")
            Log.i(TAG, "║   ├─ Bounds: ${btn.bounds} (Rộng: ${btn.bounds.width()}px, Cao: ${btn.bounds.height()}px)")
            Log.i(TAG, "║   ├─ Tọa độ tâm: (${btn.centerX.toInt()}, ${btn.centerY.toInt()})")
            Log.i(TAG, "║   └─ Đánh giá: ${btn.reason}")
        }
        Log.i(TAG, "╠═══════════════════════════════════════════════════════════════════════════════╣")
        if (target != null) {
            Log.i(TAG, "║ 👉 KẾT QUẢ: ĐÃ CHỌN NÚT #${detectedList.indexOf(target) + 1} (${target.modalType})")
            Log.i(TAG, "║    Tâm click: (${target.centerX.toInt()}, ${target.centerY.toInt()})")
        } else {
            Log.w(TAG, "║ ⚠️ CẢNH BÁO: Không phát hiện được nút 'Thêm' nào!")
        }
        Log.i(TAG, "╚═══════════════════════════════════════════════════════════════════════════════╝")

        // 6. Hiển thị Toast thông báo trực quan trên màn hình điện thoại
        if (target != null) {
            mainHandler.post {
                val shortName = if (target.modalType.contains("Modal 2")) "Modal 2 (Xanh lá)" else "Modal 1 (Xanh dương)"
                Toast.makeText(this, "🎯 Bấm [Thêm] của $shortName\nTọa độ: (${target.centerX.toInt()}, ${target.centerY.toInt()})", Toast.LENGTH_SHORT).show()
            }
            return target.node
        }

        // 7. PHƯƠNG ÁN DỰ PHÒNG CUỐI CÙNG (FALLBACK THEO NÚT 'ĐÓNG' CỦA MODAL 2)
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
                                Log.i(TAG, "🎯 [Fallback theo nút Đóng] Đã tìm thấy nút Thêm bên phải nút Đóng: bounds=$sibBounds")
                                mainHandler.post {
                                    Toast.makeText(this, "🎯 Bấm [Thêm] bên phải nút Đóng: (${sibBounds.centerX()}, ${sibBounds.centerY()})", Toast.LENGTH_SHORT).show()
                                }
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

        // 1. Thử gửi Accessibility ACTION_CLICK trực tiếp trên node
        if (node.isClickable) {
            val res = node.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            Log.d(TAG, "-> performAction(ACTION_CLICK) trên node: $res")
            if (res) success = true
        }

        // 2. Thử gửi ACTION_CLICK lên Parent nếu node không clickable
        val clickableParent = findClickableParent(node)
        if (clickableParent != null && clickableParent != node) {
            val parentClass = clickableParent.className?.toString()?.substringAfterLast(".") ?: "Parent"
            val resParent = clickableParent.performAction(AccessibilityNodeInfo.ACTION_CLICK)
            Log.d(TAG, "-> performAction(ACTION_CLICK) trên $parentClass: $resParent")
            if (resParent) success = true
        }

        // 3. LUÔN LUÔN kích hoạt Gesture Tap vật lý vào tâm tọa độ của View
        // Đảm bảo hoạt động 100% kể cả khi app dùng Flutter / React Native / Custom TouchListener
        if (hasValidBounds) {
            val gestureRes = performGestureClick(centerX, centerY)
            Log.d(TAG, "-> performGestureClick($centerX, $centerY): $gestureRes")
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

        // 👉 Dùng Path với 1 điểm chạm duy nhất (Click chuẩn xác, không kéo rê dù chỉ 1 pixel)
        val path = Path().apply {
            moveTo(x, y)
        }
        val builder = GestureDescription.Builder()
        builder.addStroke(GestureDescription.StrokeDescription(path, 0L, 100L)) // 100ms chuẩn độ giữ của ngón tay
        return try {
            dispatchGesture(builder.build(), null, null)
        } catch (e: Exception) {
            Log.e(TAG, "Lỗi khi dispatchGesture: ${e.message}", e)
            false
        }
    
    }

    /**
     * In ra toàn bộ cây giao diện hiện tại của màn hình để người dùng quan sát và debug
     */
    private fun logNodeHierarchy(node: AccessibilityNodeInfo?, depth: Int = 0) {
        if (node == null || depth > 8) return
        val indent = "  ".repeat(depth)
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        val text = node.text?.toString() ?: ""
        val desc = node.contentDescription?.toString() ?: ""
        val cls = node.className?.toString()?.substringAfterLast(".") ?: "Node"
        val info = buildString {
            append("$indent├─ [$cls] ")
            if (text.isNotEmpty()) append("text='$text' ")
            if (desc.isNotEmpty()) append("desc='$desc' ")
            if (node.isClickable) append("(CLICKABLE) ")
            if (node.isEditable) append("(EDITABLE) ")
            append("bounds=[${bounds.left},${bounds.top} - ${bounds.right},${bounds.bottom}]")
        }
        Log.d(TAG, info)
        for (i in 0 until node.childCount) {
            logNodeHierarchy(node.getChild(i), depth + 1)
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

            // 2. Tìm app có nhãn (Label) hoặc Package bắt đầu bằng tiền tố
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
            val fallbacks = listOf("TMS", "STM", "VNPost", "Post")
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
