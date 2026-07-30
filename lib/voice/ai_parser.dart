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
  static const List<String> _freeModels = [
    'openrouter/free',
    'openai/gpt-oss-20b:free',
  ];
  static const String _systemPrompt =
      'You are an alarm setting assistant. Extract alarm details from the '
      "user's text. Respond ONLY with one valid JSON object, without markdown "
      'or explanation. Use exactly these keys: {"hour": int or null, '
      '"minute": int or null, "recurrence": "once" | "daily" | "weekdays" | '
      '"weekends" | "weekly", "days": string[], "label": string}. Hours use '
      '24-hour time (0-23), minutes use 0-59, day names are lowercase English, '
      'and label is Title Case. If no time is specified, set both hour and '
      'minute to null. For a named recurring day use recurrence "weekly" and '
      'include that day in days.';

  static String? _failureMessage;

  static String? get failureMessage => _failureMessage;

  const AiParser._();

  static Future<ParsedAlarm?> parse(String transcript) async {
    _failureMessage = null;
    final normalizedTranscript = transcript.trim();
    if (normalizedTranscript.isEmpty) {
      _failureMessage = 'No speech was detected. Please try again.';
      return null;
    }
    if (_apiKey.isEmpty) {
      _failureMessage =
          'The OpenRouter API key is not configured in this app build.';
      return null;
    }

    for (final model in _freeModels) {
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
                'model': model,
                'temperature': 0.1,
                'max_tokens': 200,
                'messages': [
                  {'role': 'system', 'content': _systemPrompt},
                  {'role': 'user', 'content': normalizedTranscript},
                ],
              }),
            )
            .timeout(const Duration(seconds: 15));

        if (response.statusCode == 401 || response.statusCode == 403) {
          _failureMessage =
              'The OpenRouter API key is invalid or does not have access.';
          return null;
        }
        if (response.statusCode == 429) {
          _failureMessage =
              'Free OpenRouter models are rate limited. Wait a moment and '
              'try again.';
          continue;
        }
        if (response.statusCode < 200 || response.statusCode >= 300) {
          _failureMessage =
              'OpenRouter could not process the request. Please try again.';
          continue;
        }

        final responseBody = jsonDecode(response.body) as Map<String, dynamic>;
        final choices = responseBody['choices'] as List<dynamic>;
        if (choices.isEmpty) {
          throw const FormatException('OpenRouter returned no choices.');
        }

        final firstChoice = choices.first as Map<String, dynamic>;
        final message = firstChoice['message'] as Map<String, dynamic>;
        final content = message['content'] as String;
        final alarmJson = jsonDecode(_extractJsonObject(content))
            as Map<String, dynamic>;
        return ParsedAlarm.fromJson(alarmJson);
      } on SocketException {
        _failureMessage =
            'No internet connection. Connect to the internet and try again.';
        return null;
      } on TimeoutException {
        _failureMessage =
            'The free AI model took too long to respond. Please try again.';
      } on http.ClientException {
        _failureMessage =
            'Could not connect to OpenRouter. Please check your connection.';
        return null;
      } on FormatException {
        _failureMessage =
            'The AI returned an invalid alarm. Please phrase it differently.';
      } on TypeError {
        _failureMessage =
            'OpenRouter returned an unexpected response. Please try again.';
      }
    }

    return null;
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
