import 'dart:convert';
import 'dart:io';
import 'package:http/http.dart' as http;
import '../constants/api.dart';
import '../models/chat_response.dart';

class ChatService {
  static Future<ChatApiResponse> send({
    required String sessionId,
    required String message,
    File? image,
    String language = 'ko',
  }) async {
    String? imageBase64;
    if (image != null) {
      final bytes = await image.readAsBytes();
      imageBase64 = base64Encode(bytes);
    }

    final bodyMap = <String, dynamic>{
      'session_id': sessionId,
      'message': message,
      'language': language,
    };
    if (imageBase64 != null) bodyMap['image_base64'] = imageBase64;
    final body = jsonEncode(bodyMap);

    final response = await http
        .post(
          Uri.parse('${ApiConstants.baseUrl}/chat'),
          headers: {'Content-Type': 'application/json; charset=utf-8'},
          body: body,
        )
        .timeout(ApiConstants.timeout);

    if (response.statusCode == 200) {
      final data = jsonDecode(utf8.decode(response.bodyBytes)) as Map<String, dynamic>;
      return ChatApiResponse.fromJson(data);
    } else {
      final error = jsonDecode(utf8.decode(response.bodyBytes));
      throw Exception(error['detail'] ?? '서버 오류 (${response.statusCode})');
    }
  }
}
