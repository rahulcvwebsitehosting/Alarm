import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:clock_app/voice/parsed_alarm.dart';
import 'package:http/http.dart' as http;

class AiParser {
  static const String _apiKey =
      String.fromEnvironment('OPENROUTER_API_KEY');
  static const String _endpoint =
      'https://openrouter.ai/api/v1/chat/completions';
  static const String _systemPrompt =
      'You are an alarm setting assistant. Extract alarm details from the '
      "user's text. Respond ONLY with valid JSON. Schema: {hour: int (0-23), "
      "minute: int (0-59), recurrence: string "
      "('once','daily','weekdays','weekends','weekly'), days: array of "
      "strings (e.g. ['monday']), label: string (Title Case)}. If time is not "
      'specified, hour and minute are null.';

  const AiParser._();

  static Future<ParsedAlarm?> parse(String transcript) async {
    if (transcript.trim().isEmpty || _apiKey.isEmpty) {
      return null;
    }

    try {
      final response = await http
          .post(
            Uri.parse(_endpoint),
            headers: const {
              'Authorization': 'Bearer $_apiKey',
              'Content-Type': 'application/json',
              'HTTP-Referer':
                  'https://github.com/rahulcvwebsitehosting/Alarm',
              'X-Title': 'Alarm Voice Agent',
            },
            body: jsonEncode({
              'model': 'mistralai/mistral-7b-instruct:free',
              'temperature': 0.1,
              'response_format': {'type': 'json_object'},
              'messages': [
                {'role': 'system', 'content': _systemPrompt},
                {'role': 'user', 'content': transcript.trim()},
              ],
            }),
          )
          .timeout(const Duration(seconds: 10));

      if (response.statusCode < 200 || response.statusCode >= 300) {
        return null;
      }

      final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
      final choices = responseBody['choices'] as List<dynamic>;
      if (choices.isEmpty) return null;

      final firstChoice = choices.first as Map<String, dynamic>;
      final message = firstChoice['message'] as Map<String, dynamic>;
      final content = message['content'] as String;
      final alarmJson = jsonDecode(_extractJsonObject(content))
          as Map<String, dynamic>;
      return ParsedAlarm.fromJson(alarmJson);
    } on SocketException {
      return null;
    } on FormatException {
      return null;
    } on TimeoutException {
      return null;
    } on http.ClientException {
      return null;
    } on TypeError {
      return null;
    }
  }

  static String _extractJsonObject(String content) {
    final start = content.indexOf('{');
    final end = content.lastIndexOf('}');
    if (start == -1 || end < start) {
      throw const FormatException('The model response did not contain JSON.');
    }
    return content.substring(start, end + 1);
  }
}
