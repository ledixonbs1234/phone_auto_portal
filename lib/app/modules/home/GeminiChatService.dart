import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:phone_auto_portal/app/modules/home/ExtractedData.dart';

class GeminiChatService {
  final Uri _apiUrl;
  final http.Client _client;

  /// Lịch sử hội thoại, được lưu trữ để gửi cùng với các yêu cầu tiếp theo.
  List<Map<String, dynamic>> conversationHistory = [];

  GeminiChatService({required String apiUrl})
      : _apiUrl = Uri.parse(apiUrl),
        _client = http.Client();

  /// Xóa lịch sử để bắt đầu một cuộc hội thoại mới.
  void clearHistory() {
    conversationHistory.clear();
    debugPrint('Conversation history cleared.');
  }

  /// Phương thức cốt lõi để gửi yêu cầu đến API.
  /// Nó sẽ tự động đính kèm lịch sử hội thoại hiện tại.
  Future<String> _sendRequest(List<Map<String, dynamic>> newUserParts) async {
    final userMessage = {"role": "user", "parts": newUserParts};

    // Tạo body request với toàn bộ lịch sử + tin nhắn mới của người dùng
    final requestBody = {
      "contents": [
        ...conversationHistory,
        userMessage,
      ],
      "tools": [
        {"googleSearch": {}}
      ],
      // Thêm phần này để kích hoạt Thinking mode theo script của bạn
      "generationConfig": {
        "thinkingConfig": {
          "thinkingLevel": "HIGH", // Theo script mẫu
        },
      },
    };

    try {
      final response = await _client.post(
        _apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        // Xử lý và trích xuất văn bản từ phản hồi của model
        final String modelResponseText =
            _extractTextFromResponse(response.body);

        // <<<<<<<<<<<<<<<< CẬP NHẬT LỊCH SỬ HỘI THOẠI >>>>>>>>>>>>>>>>>
        // Thêm cả tin nhắn của người dùng và phản hồi của model vào lịch sử
        // để chuẩn bị cho lần gọi tiếp theo.
        // if (conversationHistory.length < 5) {
        //   conversationHistory.add(userMessage);
        //   conversationHistory.add({
        //     "role": "model",
        //     "parts": [
        //       {"text": modelResponseText}
        //     ]
        //   });
        // }

        debugPrint('Successfully received and processed model response.');
        return modelResponseText;
      } else {
        // Ném ra lỗi để bên gọi có thể xử lý
        final errorBody =
            'API request failed with status code: ${response.statusCode}. Body: ${response.body}';
        debugPrint(errorBody);
        throw Exception(errorBody);
      }
    } catch (e) {
      debugPrint('An error occurred during API request: $e');
      throw Exception('An error occurred during API request: $e');
    }
  }

  
  // Hàm hỗ trợ gửi request riêng (để tránh phụ thuộc vào logic history của hàm cũ nếu muốn)
  Future<String> _sendRequestInternal(List<Map<String, dynamic>> newUserParts) async {
    final requestBody = {
      "contents": [
        {"role": "user", "parts": newUserParts}
      ],
      // Tắt safety settings nếu cần thiết để tránh chặn nội dung
      "safetySettings": [
        {"category": "HARM_CATEGORY_HARASSMENT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_HATE_SPEECH", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_SEXUALLY_EXPLICIT", "threshold": "BLOCK_NONE"},
        {"category": "HARM_CATEGORY_DANGEROUS_CONTENT", "threshold": "BLOCK_NONE"}
      ],
    };

    try {
      final response = await _client.post(
        _apiUrl,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode(requestBody),
      );

      if (response.statusCode == 200) {
        return _extractTextFromResponse(response.body);
      } else {
        throw Exception('API request failed: ${response.statusCode} - ${response.body}');
      }
    } catch (e) {
      throw Exception('Error sending request: $e');
    }
  }
Future<List<ExtractedData>> extractInfoFromImages(List<File> imageFiles) async {
    List<Map<String, dynamic>> parts = [];

    // 1. Thêm tất cả hình ảnh vào parts
    for (var file in imageFiles) {
      final List<int> imageBytes = await file.readAsBytes();
      final String base64Image = base64Encode(imageBytes);
      parts.add({
        "inlineData": {
          "mimeType": "image/jpeg", // Giả định là jpeg/png
          "data": base64Image,
        }
      });
    }

    // 2. Thêm Prompt yêu cầu
    parts.add({
      "text":
          "Từ danh sách hình ảnh lấy mã hiệu (không dấu cách), tên người nhận, số điện thoại (không dấu cách), và địa chỉ chi tiết ( sai thì chỉnh lại cho đúng ) một cách lần lượt. Kết quả nhận được là json array có cấu trúc như sau : MaHieu,TenNguoiNhan,DiaChi,SoDienThoai. Quan trọng là không giải thích"
    });

    try {
      final String rawResponse = await _sendRequestInternal(parts);

      // 3. Clean JSON String
      String cleanedJsonString = rawResponse;
      final jsonBlockRegex = RegExp(r'```(?:json)?\s*(\[.*?\])\s*```', dotAll: true);
      final match = jsonBlockRegex.firstMatch(rawResponse);

      if (match != null) {
        cleanedJsonString = match.group(1)!.trim();
      } else {
        cleanedJsonString = rawResponse.replaceAll(RegExp(r'```json|```'), '').trim();
      }
      
      // Xử lý trường hợp AI trả về text thừa ngoài JSON
      int startIndex = cleanedJsonString.indexOf('[');
      int endIndex = cleanedJsonString.lastIndexOf(']');
      if (startIndex != -1 && endIndex != -1) {
        cleanedJsonString = cleanedJsonString.substring(startIndex, endIndex + 1);
      }

      debugPrint('Cleaned JSON Array: $cleanedJsonString');

      // 4. Parse JSON List
      final List<dynamic> jsonList = jsonDecode(cleanedJsonString);
      
      return jsonList.map((item) {
        // Map từ PascalCase (AI trả về) sang CamelCase (Model ExtractedData)
        return ExtractedData(
          maHieu: item['MaHieu'],
          tenNguoiNhan: item['TenNguoiNhan'],
          diaChi: item['DiaChi'],
          soDienThoai: item['SoDienThoai'],
        );
      }).toList();

    } catch (e) {
      debugPrint('Error extracting info from multiple images: $e');
      return [];
    }
  }
  /// Gửi yêu cầu ban đầu với hình ảnh để trích xuất thông tin.
  /// Đây là điểm khởi đầu của cuộc hội thoại.
  Future<ExtractedData?> extractInfoFromImage(File imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    // Prompt ban đầu của bạn, bao gồm cả hình ảnh và chỉ dẫn
    final List<Map<String, dynamic>> initialParts = [
      {
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": base64Image,
        }
      },
      {
        "text":
            "Lấy mã hiệu, tên người nhận, địa chỉ nhận, số điện thoại từ hình ảnh được cung cấp, mã hiệu và số điện thoại không có khoảng trống, địa chỉ không xuống hàng. Phản hồi phải là danh sách đối tượng lần lượt JSON. Ví dụ: ```json{\"maHieu\": \"...\", \"tenNguoiNhan\": \"...\", \"diaChi\": \"...\", \"soDienThoai\": \"...\"}```"
      },
    ];

    try {
      final String rawResponse = await _sendRequest(initialParts);

      // Làm sạch chuỗi JSON (Thinking models đôi khi xuất ra cả suy nghĩ)
      // Regex này sẽ chỉ lấy phần nằm trong ```json ... ``` hoặc ``` ... ```
      String cleanedJsonString = rawResponse;

      // Tìm khối code JSON nếu có
      final jsonBlockRegex =
          RegExp(r'```(?:json)?\s*(\{.*?\})\s*```', dotAll: true);
      final match = jsonBlockRegex.firstMatch(rawResponse);

      if (match != null) {
        cleanedJsonString = match.group(1)!.trim();
      } else {
        // Fallback: Xóa markdown code block nếu regex trên không bắt được
        cleanedJsonString =
            rawResponse.replaceAll(RegExp(r'```json|```'), '').trim();
      }

      debugPrint('Cleaned JSON String for decoding: $cleanedJsonString');

      final Map<String, dynamic> jsonData = jsonDecode(cleanedJsonString);
      return ExtractedData.fromJson(jsonData);
    } on FormatException catch (e) {
      debugPrint('Error decoding JSON from model response: $e');
      return null;
    } catch (e) {
      debugPrint('An unexpected error occurred: $e');
      return null;
    }
  }

  /// Gửi một câu hỏi văn bản tiếp theo, dựa trên ngữ cảnh đã có.
  Future<ExtractedData> askFollowUp(File imageFile) async {
    final List<int> imageBytes = await imageFile.readAsBytes();
    final String base64Image = base64Encode(imageBytes);

    // Prompt ban đầu của bạn, bao gồm cả hình ảnh và chỉ dẫn
    final List<Map<String, dynamic>> initialParts = [
      {
        "inlineData": {
          "mimeType": "image/jpeg",
          "data": base64Image,
        }
      },
      {"text": ""},
    ];

    try {
      // Gửi câu hỏi và trả về câu trả lời dạng văn bản của model
      final String responseText = await _sendRequest(initialParts);
      // Làm sạch và phân tích chuỗi JSON
      String cleanedJsonString =
          responseText.replaceAll(RegExp(r'```json|```'), '').trim();
      debugPrint('Cleaned JSON String for decoding: $cleanedJsonString');

      final Map<String, dynamic> jsonData = jsonDecode(cleanedJsonString);
      return ExtractedData.fromJson(jsonData);
    } catch (e) {
      debugPrint('Error asking follow-up: $e');
      throw Exception('Error asking follow-up: $e');
    }
  }

  /// Hàm trợ giúp để phân tích phản hồi từ API.
  /// (Tương tự như logic trong code gốc của bạn)
  String _extractTextFromResponse(String responseBody) {
    final dynamic decoded = jsonDecode(responseBody);
    String combinedText = "";

    // Helper function để lấy text từ candidate
    void extractFromCandidates(List<dynamic> candidates) {
      if (candidates.isNotEmpty) {
        final Map<String, dynamic> firstCandidate = candidates[0];
        if (firstCandidate.containsKey('content') &&
            firstCandidate['content']['parts'] is List) {
          final List<dynamic> parts = firstCandidate['content']['parts'];
          for (var part in parts) {
            if (part is Map<String, dynamic> && part.containsKey('text')) {
              combinedText += part['text'].toString();
            }
          }
        }
      }
    }

    // Trường hợp 1: JSON Object (Non-streaming) -> Đây là cái bạn đang gặp
    if (decoded is Map<String, dynamic>) {
      if (decoded.containsKey('candidates')) {
        extractFromCandidates(decoded['candidates']);
      }
    } 
    // Trường hợp 2: JSON List (Streaming) -> Hỗ trợ code cũ
    else if (decoded is List) {
      for (var chunk in decoded) {
        if (chunk is Map<String, dynamic> && chunk.containsKey('candidates')) {
          extractFromCandidates(chunk['candidates']);
        }
      }
    }

    return combinedText;
  }
}
