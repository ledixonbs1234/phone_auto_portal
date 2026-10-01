package com.example.phone_auto_portal

import android.accessibilityservice.AccessibilityService
import android.accessibilityservice.GestureDescription
import android.content.Context
import android.content.Intent
import android.content.pm.PackageManager
import android.graphics.Path
import android.graphics.Rect
import android.os.Build
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.util.Log
import android.view.accessibility.AccessibilityEvent
import android.view.accessibility.AccessibilityNodeInfo
import android.widget.Toast

class TmsAccessibilityService : AccessibilityService() {

    enum class AutomationStep {
        IDLE,
        STEP_1_ACCEPT_ORDER,       // Bấm NHẬN LỆNH
        STEP_2_VIEW_DETAIL,        // Bấm CHI TIẾT
        STEP_3_START_TRIP,          // Bấm BẮT ĐẦU (nút cam)
        STEP_4_SELECT_FIRST_POINT,  // Chọn điểm đầu tiên trong lộ trình
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

        var currentStep: AutomationStep = AutomationStep.IDLE
            private set

        var bd10CodeToInput: String = ""
        var targetAppName: String = "TMS"

        fun isServiceRunning(): Boolean {
            return instance != null
        }
    }

    private val mainHandler = Handler(Looper.getMainLooper())
    private var stepStartTime: Long = 0L
    private val stepTimeoutMs: Long = 15000L // 15s timeout cho mỗi bước
    private var isActionPending: Boolean = false

    private val automationRunnable = object : Runnable {
        override fun run() {
            if (!isRunning) return
            try {
                processAutomationStep()
            } catch (e: Exception) {
                Log.e(TAG, "Lỗi trong processAutomationStep: ${e.message}", e)
            }
            if (isRunning) {
                mainHandler.postDelayed(this, 700)
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
        if (!isRunning || event == null) return

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
        Log.d(TAG, "TmsAccessibilityService destroyed")
    }

    // =========================================================================
    // QUẢN LÝ TIẾN TRÌNH TỰ ĐỘNG HÓA (AUTOMATION ENGINE)
    // =========================================================================

    fun startAutomation(code: String, appName: String = "TMS") {
        bd10CodeToInput = code.trim()
        targetAppName = appName
        isRunning = true
        currentStep = AutomationStep.STEP_1_ACCEPT_ORDER
        stepStartTime = System.currentTimeMillis()
        isActionPending = false

        Log.i(TAG, "Bắt đầu tự động hóa TMS với mã BD10: $bd10CodeToInput, targetApp: $targetAppName")
        Toast.makeText(this, "Bắt đầu tự động hóa TMS ($bd10CodeToInput)", Toast.LENGTH_SHORT).show()

        // 1. Mở App TMS
        launchApp(targetAppName)

        // 2. Chạy vòng lặp State Machine
        mainHandler.removeCallbacks(automationRunnable)
        mainHandler.postDelayed(automationRunnable, 1200)
    }

    fun stopAutomation() {
        isRunning = false
        currentStep = AutomationStep.IDLE
        isActionPending = false
        mainHandler.removeCallbacks(automationRunnable)
        Log.i(TAG, "Đã dừng tự động hóa TMS")
    }

    private fun nextStep(step: AutomationStep, delayMs: Long = 800) {
        currentStep = step
        stepStartTime = System.currentTimeMillis()
        isActionPending = true
        Log.i(TAG, ">>> CHUYỂN SANG BƯỚC TIẾP THEO: $currentStep")

        mainHandler.postDelayed({
            isActionPending = false
        }, delayMs)
    }

    private fun processAutomationStep() {
        if (isActionPending) return

        val rootNode = rootInActiveWindow ?: run {
            Log.d(TAG, "rootInActiveWindow is null, đang chờ...")
            return
        }

        // Kiểm tra timeout cho bước hiện tại
        if (System.currentTimeMillis() - stepStartTime > stepTimeoutMs) {
            Log.w(TAG, "Timeout tại bước: $currentStep. Đang kiểm tra để bỏ qua hoặc phục hồi...")
            handleStepTimeout(rootNode)
            return
        }

        when (currentStep) {
            // -------------------------------------------------------------
            // BƯỚC 1: Nhận lệnh tại tab "Lệnh mới"
            // -------------------------------------------------------------
            AutomationStep.STEP_1_ACCEPT_ORDER -> {
                // Kiểm tra xem có nút "NHẬN LỆNH" không
                val acceptBtn = findNodeByTexts(rootNode, listOf("NHẬN LỆNH", "Nhận lệnh", "NHAN LENH", "Nhận"))
                if (acceptBtn != null) {
                    Log.i(TAG, "Bước 1: Tìm thấy nút [NHẬN LỆNH], đang bấm...")
                    if (clickNode(acceptBtn)) {
                        nextStep(AutomationStep.STEP_2_VIEW_DETAIL, 1200)
                        return
                    }
                }

                // Nếu đã ở màn hình "Đã nhận lệnh" hoặc thấy nút "CHI TIẾT" -> Chuyển thẳng sang Bước 2
                val detailBtn = findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết", "CHI TIET"))
                if (detailBtn != null) {
                    Log.i(TAG, "Bước 1: Đã thấy nút [CHI TIẾT], bỏ qua nhận lệnh -> sang Bước 2")
                    nextStep(AutomationStep.STEP_2_VIEW_DETAIL, 500)
                    return
                }

                // Nếu đã ở màn hình Chi tiết chuyến (thấy nút "BẮT ĐẦU") -> sang Bước 3
                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Bước 1: Đã ở màn hình chi tiết chuyến -> sang Bước 3")
                    nextStep(AutomationStep.STEP_3_START_TRIP, 500)
                    return
                }

                // Nếu đã ở màn hình Chuyến đang chạy (thấy tab LỘ TRÌNH hoặc TRẠNG THÁI) -> sang Bước 4
                if (findNodeByTexts(rootNode, listOf("TRẠNG THÁI", "LỘ TRÌNH", "Chuyến đang chạy", "Chuyển đang chạy")) != null) {
                    Log.i(TAG, "Bước 1: Đã ở màn hình chuyến đang chạy -> sang Bước 4")
                    nextStep(AutomationStep.STEP_4_SELECT_FIRST_POINT, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 2: Bấm nút "CHI TIẾT" (Màn hình Đã nhận lệnh)
            // -------------------------------------------------------------
            AutomationStep.STEP_2_VIEW_DETAIL -> {
                val detailBtn = findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết", "CHI TIET"))
                if (detailBtn != null) {
                    Log.i(TAG, "Bước 2: Tìm thấy nút [CHI TIẾT], đang bấm...")
                    if (clickNode(detailBtn)) {
                        nextStep(AutomationStep.STEP_3_START_TRIP, 1200)
                        return
                    }
                }

                // Nếu đã ở màn hình Chi tiết chuyến (thấy nút "BẮT ĐẦU")
                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Bước 2: Đã thấy nút [BẮT ĐẦU] -> sang Bước 3")
                    nextStep(AutomationStep.STEP_3_START_TRIP, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 3: Bấm nút "BẮT ĐẦU" (Chi tiết chuyến)
            // -------------------------------------------------------------
            AutomationStep.STEP_3_START_TRIP -> {
                val startBtn = findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu", "BAT DAU"))
                if (startBtn != null) {
                    Log.i(TAG, "Bước 3: Tìm thấy nút [BẮT ĐẦU], đang bấm...")
                    if (clickNode(startBtn)) {
                        nextStep(AutomationStep.STEP_4_SELECT_FIRST_POINT, 1500)
                        return
                    }
                }

                // Nếu đã vào màn hình Chuyến đang chạy
                if (findNodeByTexts(rootNode, listOf("Chuyến đang chạy", "Chuyển đang chạy", "TRẠNG THÁI", "LỘ TRÌNH")) != null) {
                    Log.i(TAG, "Bước 3: Đã vào màn hình chuyến đang chạy -> sang Bước 4")
                    nextStep(AutomationStep.STEP_4_SELECT_FIRST_POINT, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 4: Chọn điểm đầu tiên trong lộ trình
            // -------------------------------------------------------------
            AutomationStep.STEP_4_SELECT_FIRST_POINT -> {
                // Nếu đã thấy nút VÀO và RA ở trên cùng -> đã chọn điểm rồi -> sang Bước 5
                val vaoBtn = findNodeByTexts(rootNode, listOf("VÀO", "Vào", "VAO"))
                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (vaoBtn != null && raBtn != null) {
                    Log.i(TAG, "Bước 4: Đã ở màn hình điểm (thấy VÀO & RA) -> sang Bước 5")
                    nextStep(AutomationStep.STEP_5_CLICK_VAO_POINT_1, 500)
                    return
                }

                // Tìm điểm đầu tiên trong danh sách (node chứa "Tam Quan" hoặc "Kho" hoặc "Chưa đến điểm" hoặc item đầu tiên)
                val firstPointNode = findFirstRoutePointNode(rootNode)
                if (firstPointNode != null) {
                    Log.i(TAG, "Bước 4: Tìm thấy điểm đầu tiên, đang click chọn...")
                    if (clickNode(firstPointNode)) {
                        nextStep(AutomationStep.STEP_5_CLICK_VAO_POINT_1, 1200)
                        return
                    }
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 5: Bấm nút/tab "VÀO" của điểm 1
            // -------------------------------------------------------------
            AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> {
                // Kiểm tra nếu đã thấy nút "SCAN BD10" -> sang Bước 6
                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Bước 5: Đã thấy nút [SCAN BD10] -> sang Bước 6")
                    nextStep(AutomationStep.STEP_6_CLICK_SCAN_BD10_1, 500)
                    return
                }

                val vaoBtn = findNodeByTexts(rootNode, listOf("VÀO", "Vào", "VAO"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Bước 5: Tìm thấy nút [VÀO], đang bấm...")
                    if (clickNode(vaoBtn)) {
                        nextStep(AutomationStep.STEP_6_CLICK_SCAN_BD10_1, 1200)
                        return
                    }
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 6: Bấm nút "SCAN BD10" tại điểm 1
            // -------------------------------------------------------------
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1 -> {
                // Nếu đã thấy popup "Danh sách BD10" hoặc ô nhập text -> sang Bước 7
                if (findNodeByTexts(rootNode, listOf("Danh sách BD10", "Danh sach BD10", "Nhập tay mã BD10")) != null ||
                    findEditTextNode(rootNode) != null) {
                    Log.i(TAG, "Bước 6: Đã thấy popup [Danh sách BD10] -> sang Bước 7")
                    nextStep(AutomationStep.STEP_7_INPUT_BD10_CODE, 500)
                    return
                }

                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Bước 6: Tìm thấy nút [SCAN BD10], đang bấm...")
                    if (clickNode(scanBtn)) {
                        nextStep(AutomationStep.STEP_7_INPUT_BD10_CODE, 1200)
                        return
                    }
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 7: Điền mã BD10 vào ô nhập và bấm nút "Thêm"
            // -------------------------------------------------------------
            AutomationStep.STEP_7_INPUT_BD10_CODE -> {
                val editText = findEditTextNode(rootNode)
                if (editText != null && bd10CodeToInput.isNotEmpty()) {
                    Log.i(TAG, "Bước 7: Tìm thấy ô EditText, đang điền mã BD10: $bd10CodeToInput")
                    if (setTextOnNode(editText, bd10CodeToInput)) {
                        // Tìm và click nút "Thêm" bên cạnh ô input
                        mainHandler.postDelayed({
                            val root = rootInActiveWindow ?: return@postDelayed
                            val addBtn = findNodeByTexts(root, listOf("Thêm", "THÊM", "Them"))
                            if (addBtn != null) {
                                Log.i(TAG, "Bước 7: Tìm thấy nút [Thêm], đang bấm...")
                                clickNode(addBtn)
                            }
                            nextStep(AutomationStep.STEP_8_CONFIRM_BD10_1, 1000)
                        }, 500)
                        return
                    }
                } else if (bd10CodeToInput.isEmpty()) {
                    Log.w(TAG, "Bước 7: Không có mã BD10 cần nhập -> sang Bước 8")
                    nextStep(AutomationStep.STEP_8_CONFIRM_BD10_1, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 8: Bấm nút "Xác nhận" (modal Danh sách BD10)
            // -------------------------------------------------------------
            AutomationStep.STEP_8_CONFIRM_BD10_1 -> {
                val confirmBtn = findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN", "Xac nhan", "XAC NHAN"))
                if (confirmBtn != null) {
                    Log.i(TAG, "Bước 8: Tìm thấy nút [Xác nhận], đang bấm...")
                    if (clickNode(confirmBtn)) {
                        nextStep(AutomationStep.STEP_9_CLICK_RA_POINT_1, 1200)
                        return
                    }
                }

                // Nếu modal đã đóng và thấy tab RA -> sang Bước 9
                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null && findNodeByTexts(rootNode, listOf("Danh sách BD10")) == null) {
                    Log.i(TAG, "Bước 8: Modal đã đóng, thấy nút [RA] -> sang Bước 9")
                    nextStep(AutomationStep.STEP_9_CLICK_RA_POINT_1, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 9: Bấm nút/tab "RA" của điểm 1
            // -------------------------------------------------------------
            AutomationStep.STEP_9_CLICK_RA_POINT_1 -> {
                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null) {
                    Log.i(TAG, "Bước 9: Tìm thấy nút [RA], đang bấm để xuất phát rời điểm 1...")
                    if (clickNode(raBtn)) {
                        nextStep(AutomationStep.STEP_10_SELECT_SECOND_POINT, 1500)
                        return
                    }
                }

                // Nếu đã quay lại danh sách lộ trình -> sang Bước 10
                if (findNodeByTexts(rootNode, listOf("BCP Quy Nhơn", "Giao hàng", "Chuyến đang chạy")) != null) {
                    nextStep(AutomationStep.STEP_10_SELECT_SECOND_POINT, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 10: Chọn điểm thứ 2 trong lộ trình (Điểm bưu cục giao/trả)
            // -------------------------------------------------------------
            AutomationStep.STEP_10_SELECT_SECOND_POINT -> {
                // Nếu đã ở màn hình chi tiết điểm (thấy VÀO & RA)
                val vaoBtn = findNodeByTexts(rootNode, listOf("VÀO", "Vào", "VAO"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Bước 10: Đã ở màn hình chi tiết điểm 2 -> sang Bước 11")
                    nextStep(AutomationStep.STEP_11_CLICK_VAO_POINT_2, 500)
                    return
                }

                val secondPointNode = findSecondRoutePointNode(rootNode)
                if (secondPointNode != null) {
                    Log.i(TAG, "Bước 10: Tìm thấy điểm thứ 2, đang click chọn...")
                    if (clickNode(secondPointNode)) {
                        nextStep(AutomationStep.STEP_11_CLICK_VAO_POINT_2, 1200)
                        return
                    }
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 11: Bấm nút/tab "VÀO" của điểm 2
            // -------------------------------------------------------------
            AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> {
                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Bước 11: Đã thấy nút [SCAN BD10] -> sang Bước 12")
                    nextStep(AutomationStep.STEP_12_CLICK_SCAN_BD10_2, 500)
                    return
                }

                val vaoBtn = findNodeByTexts(rootNode, listOf("VÀO", "Vào", "VAO"))
                if (vaoBtn != null) {
                    Log.i(TAG, "Bước 11: Tìm thấy nút [VÀO], đang bấm...")
                    if (clickNode(vaoBtn)) {
                        nextStep(AutomationStep.STEP_12_CLICK_SCAN_BD10_2, 1200)
                        return
                    }
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 12: Bấm nút "SCAN BD10" tại điểm 2
            // -------------------------------------------------------------
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2 -> {
                // Nếu đã thấy nút "DS BD10 lên" trong modal -> sang Bước 13
                val dsLenBtn = findNodeByTexts(rootNode, listOf("DS BD10 lên", "DS BD10 LEN", "DS BD10 len", "DS BD10 LÊN"))
                if (dsLenBtn != null) {
                    Log.i(TAG, "Bước 12: Đã thấy nút [DS BD10 lên] -> sang Bước 13")
                    nextStep(AutomationStep.STEP_13_CLICK_DS_BD10_LEN, 500)
                    return
                }

                val scanBtn = findNodeByTexts(rootNode, listOf("SCAN BD10", "Scan BD10", "SCAN BD 10"))
                if (scanBtn != null) {
                    Log.i(TAG, "Bước 12: Tìm thấy nút [SCAN BD10], đang bấm...")
                    if (clickNode(scanBtn)) {
                        nextStep(AutomationStep.STEP_13_CLICK_DS_BD10_LEN, 1200)
                        return
                    }
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 13: Bấm nút "DS BD10 lên" (màu xanh lá)
            // -------------------------------------------------------------
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> {
                val dsLenBtn = findNodeByTexts(rootNode, listOf("DS BD10 lên", "DS BD10 LEN", "DS BD10 len", "DS BD10 LÊN"))
                if (dsLenBtn != null) {
                    Log.i(TAG, "Bước 13: Tìm thấy nút [DS BD10 lên], đang bấm...")
                    if (clickNode(dsLenBtn)) {
                        nextStep(AutomationStep.STEP_14_SELECT_ALL_AND_ADD, 1200)
                        return
                    }
                }

                // Nếu đã mở popup "DS BD10 tại điểm lên" -> sang Bước 14
                if (findNodeByTexts(rootNode, listOf("DS BD10 tại điểm lên", "DS BD10 tai diem len")) != null) {
                    Log.i(TAG, "Bước 13: Đã ở popup [DS BD10 tại điểm lên] -> sang Bước 14")
                    nextStep(AutomationStep.STEP_14_SELECT_ALL_AND_ADD, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 14: Chọn tất cả các mã BD10 và bấm nút "Thêm"
            // -------------------------------------------------------------
            AutomationStep.STEP_14_SELECT_ALL_AND_ADD -> {
                // Click chọn tất cả các dòng mã BD10 có trong danh sách popup
                val items = findBd10ItemsInPopup(rootNode)
                for (item in items) {
                    clickNode(item)
                    Log.i(TAG, "Bước 14: Đã click chọn mã BD10 item: ${item.text}")
                }

                // Bấm nút "Thêm" (màu xanh lá to)
                mainHandler.postDelayed({
                    val root = rootInActiveWindow ?: return@postDelayed
                    val addBtn = findNodeByTexts(root, listOf("Thêm", "THÊM", "Them"))
                    if (addBtn != null) {
                        Log.i(TAG, "Bước 14: Tìm thấy nút [Thêm], đang bấm...")
                        clickNode(addBtn)
                        nextStep(AutomationStep.STEP_15_CONFIRM_BD10_2, 1200)
                    } else {
                        nextStep(AutomationStep.STEP_15_CONFIRM_BD10_2, 800)
                    }
                }, 600)
            }

            // -------------------------------------------------------------
            // BƯỚC 15: Bấm nút "Xác nhận" (modal Danh sách BD10 tại điểm 2)
            // -------------------------------------------------------------
            AutomationStep.STEP_15_CONFIRM_BD10_2 -> {
                val confirmBtn = findNodeByTexts(rootNode, listOf("Xác nhận", "XÁC NHẬN", "Xac nhan", "XAC NHAN"))
                if (confirmBtn != null) {
                    Log.i(TAG, "Bước 15: Tìm thấy nút [Xác nhận], đang bấm...")
                    if (clickNode(confirmBtn)) {
                        nextStep(AutomationStep.STEP_16_CLICK_RA_POINT_2, 1200)
                        return
                    }
                }

                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null && findNodeByTexts(rootNode, listOf("Danh sách BD10")) == null) {
                    Log.i(TAG, "Bước 15: Modal đã đóng, thấy nút [RA] -> sang Bước 16")
                    nextStep(AutomationStep.STEP_16_CLICK_RA_POINT_2, 500)
                    return
                }
            }

            // -------------------------------------------------------------
            // BƯỚC 16: Bấm nút/tab "RA" của điểm 2 (Kết thúc chuyến)
            // -------------------------------------------------------------
            AutomationStep.STEP_16_CLICK_RA_POINT_2 -> {
                val raBtn = findNodeByTexts(rootNode, listOf("RA", "Ra"))
                if (raBtn != null) {
                    Log.i(TAG, "Bước 16: Tìm thấy nút [RA], đang bấm để kết thúc chuyến...")
                    if (clickNode(raBtn)) {
                        nextStep(AutomationStep.STEP_DONE, 1000)
                        return
                    }
                }
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
            }

            AutomationStep.IDLE -> {
                // Không làm gì
            }
        }
    }

    private fun handleStepTimeout(rootNode: AccessibilityNodeInfo) {
        stepStartTime = System.currentTimeMillis() // Reset timer
        when (currentStep) {
            AutomationStep.STEP_1_ACCEPT_ORDER -> {
                if (findNodeByTexts(rootNode, listOf("CHI TIẾT", "Chi tiết")) != null) {
                    nextStep(AutomationStep.STEP_2_VIEW_DETAIL, 500)
                } else if (findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu")) != null) {
                    nextStep(AutomationStep.STEP_3_START_TRIP, 500)
                } else {
                    nextStep(AutomationStep.STEP_4_SELECT_FIRST_POINT, 500)
                }
            }
            AutomationStep.STEP_2_VIEW_DETAIL -> {
                if (findNodeByTexts(rootNode, listOf("BẮT ĐẦU", "Bắt đầu")) != null) {
                    nextStep(AutomationStep.STEP_3_START_TRIP, 500)
                } else {
                    nextStep(AutomationStep.STEP_4_SELECT_FIRST_POINT, 500)
                }
            }
            AutomationStep.STEP_3_START_TRIP -> {
                nextStep(AutomationStep.STEP_4_SELECT_FIRST_POINT, 500)
            }
            AutomationStep.STEP_4_SELECT_FIRST_POINT -> {
                nextStep(AutomationStep.STEP_5_CLICK_VAO_POINT_1, 500)
            }
            AutomationStep.STEP_5_CLICK_VAO_POINT_1 -> {
                nextStep(AutomationStep.STEP_6_CLICK_SCAN_BD10_1, 500)
            }
            AutomationStep.STEP_6_CLICK_SCAN_BD10_1 -> {
                nextStep(AutomationStep.STEP_7_INPUT_BD10_CODE, 500)
            }
            AutomationStep.STEP_7_INPUT_BD10_CODE -> {
                nextStep(AutomationStep.STEP_8_CONFIRM_BD10_1, 500)
            }
            AutomationStep.STEP_8_CONFIRM_BD10_1 -> {
                nextStep(AutomationStep.STEP_9_CLICK_RA_POINT_1, 500)
            }
            AutomationStep.STEP_9_CLICK_RA_POINT_1 -> {
                nextStep(AutomationStep.STEP_10_SELECT_SECOND_POINT, 500)
            }
            AutomationStep.STEP_10_SELECT_SECOND_POINT -> {
                nextStep(AutomationStep.STEP_11_CLICK_VAO_POINT_2, 500)
            }
            AutomationStep.STEP_11_CLICK_VAO_POINT_2 -> {
                nextStep(AutomationStep.STEP_12_CLICK_SCAN_BD10_2, 500)
            }
            AutomationStep.STEP_12_CLICK_SCAN_BD10_2 -> {
                nextStep(AutomationStep.STEP_13_CLICK_DS_BD10_LEN, 500)
            }
            AutomationStep.STEP_13_CLICK_DS_BD10_LEN -> {
                nextStep(AutomationStep.STEP_14_SELECT_ALL_AND_ADD, 500)
            }
            AutomationStep.STEP_14_SELECT_ALL_AND_ADD -> {
                nextStep(AutomationStep.STEP_15_CONFIRM_BD10_2, 500)
            }
            AutomationStep.STEP_15_CONFIRM_BD10_2 -> {
                nextStep(AutomationStep.STEP_16_CLICK_RA_POINT_2, 500)
            }
            AutomationStep.STEP_16_CLICK_RA_POINT_2 -> {
                nextStep(AutomationStep.STEP_DONE, 500)
            }
            else -> {}
        }
    }

    // =========================================================================
    // CÁC HÀM TÌM KIẾM NODE VÀ TƯƠNG TÁC (NODE SEARCH & DISPATCH)
    // =========================================================================

    private fun findNodeByTexts(root: AccessibilityNodeInfo, targetTexts: List<String>): AccessibilityNodeInfo? {
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
        // Thử tìm duyệt đệ quy (contains ignore case)
        return findNodeRecursive(root) { node ->
            val nodeText = node.text?.toString() ?: ""
            val nodeDesc = node.contentDescription?.toString() ?: ""
            targetTexts.any { target ->
                nodeText.contains(target, ignoreCase = true) ||
                nodeDesc.contains(target, ignoreCase = true)
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
        // Tìm node có chứa "Kho" hoặc "Tam Quan" hoặc "Chưa đến điểm"
        val specific = findNodeByTexts(root, listOf("Tam Quan", "Kho", "Nhận hàng", "Chưa đến điểm"))
        if (specific != null) {
            return findClickableParent(specific) ?: specific
        }
        return null
    }

    private fun findSecondRoutePointNode(root: AccessibilityNodeInfo): AccessibilityNodeInfo? {
        // Tìm node chứa "BCP" hoặc "Quy Nhơn" hoặc "Giao hàng"
        val specific = findNodeByTexts(root, listOf("BCP", "Quy Nhơn", "Giao hàng", "Trả hàng"))
        if (specific != null) {
            return findClickableParent(specific) ?: specific
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
        // Các mục mã BD10 thường bắt đầu bằng số STT hoặc dãy số dài > 10 ký tự (ví dụ "1. 593330591520605131")
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

    private fun clickNode(node: AccessibilityNodeInfo): Boolean {
        // Thử ACTION_CLICK trực tiếp
        if (node.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
            return true
        }

        // Thử tìm cha có clickable
        val clickableParent = findClickableParent(node)
        if (clickableParent != null && clickableParent.performAction(AccessibilityNodeInfo.ACTION_CLICK)) {
            return true
        }

        // Fallback: Sử dụng Gesture click theo tọa độ Bounds trong màn hình
        val bounds = Rect()
        node.getBoundsInScreen(bounds)
        if (bounds.width() > 0 && bounds.height() > 0) {
            return performGestureClick(bounds.centerX().toFloat(), bounds.centerY().toFloat())
        }

        return false
    }

    private fun setTextOnNode(node: AccessibilityNodeInfo, text: String): Boolean {
        val targetNode = if (node.isEditable) node else (findEditTextNode(node) ?: node)
        val arguments = Bundle()
        arguments.putCharSequence(AccessibilityNodeInfo.ACTION_ARGUMENT_SET_TEXT_CHARSEQUENCE, text)
        return targetNode.performAction(AccessibilityNodeInfo.ACTION_SET_TEXT, arguments)
    }

    private fun performGestureClick(x: Float, y: Float): Boolean {
        if (Build.VERSION.SDK_INT < Build.VERSION_CODES.N) return false
        val path = Path()
        path.moveTo(x, y)
        val builder = GestureDescription.Builder()
        builder.addStroke(GestureDescription.StrokeDescription(path, 0, 100))
        return dispatchGesture(builder.build(), null, null)
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
                intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                startActivity(intent)
                return true
            }

            // 2. Tìm app có nhãn (Label) hoặc Package bắt đầu bằng tiền tố (case insensitive)
            for (app in apps) {
                val label = pm.getApplicationLabel(app).toString()
                if (label.startsWith(prefixOrPackage, ignoreCase = true) ||
                    app.packageName.startsWith(prefixOrPackage, ignoreCase = true)) {
                    intent = pm.getLaunchIntentForPackage(app.packageName)
                    if (intent != null) {
                        intent.addFlags(Intent.FLAG_ACTIVITY_NEW_TASK)
                        startActivity(intent)
                        return true
                    }
                }
            }

            // 3. Tìm app có chứa "TMS", "STM", "VNPost" nếu không tìm thấy chính xác
            val fallbacks = listOf("TMS", "STM", "VNPost", "Post")
            for (fallback in fallbacks) {
                for (app in apps) {
                    val label = pm.getApplicationLabel(app).toString()
                    if (label.contains(fallback, ignoreCase = true) ||
                        app.packageName.contains(fallback, ignoreCase = true)) {
                        intent = pm.getLaunchIntentForPackage(app.packageName)
                        if (intent != null) {
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
