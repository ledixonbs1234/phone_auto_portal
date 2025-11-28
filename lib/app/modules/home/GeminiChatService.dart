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
        ...conversationHistory, // <-- Quan trọng: Gửi toàn bộ lịch sử trước đó
        userMessage,
      ],
      "tools": [
        {"googleSearch": {}}
      ],
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
        if (conversationHistory.length < 5) {
          conversationHistory.add(userMessage);
          conversationHistory.add({
            "role": "model",
            "parts": [
              {"text": modelResponseText}
            ]
          });
        }

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
      // Gửi yêu cầu và nhận về chuỗi phản hồi thô từ model
      final String rawResponse = await _sendRequest(initialParts);

      // Làm sạch và phân tích chuỗi JSON
      String cleanedJsonString =
          rawResponse.replaceAll(RegExp(r'```json|```'), '').trim();
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
    final List<dynamic> responseChunks = jsonDecode(responseBody);
    String combinedText = "";

    for (var chunk in responseChunks) {
      if (chunk is Map<String, dynamic> && chunk.containsKey('candidates')) {
        final List<dynamic> candidates = chunk['candidates'];
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
    }
    return combinedText;
  }
}
