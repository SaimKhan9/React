import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../../core/constants/app_constants.dart';
import '../models/models.dart';

// DevArena Live — Multi-language Code Execution Service via Judge0 / Server Proxy
class ExecutionService {
  static final ExecutionService _instance = ExecutionService._internal();
  factory ExecutionService() => _instance;
  ExecutionService._internal();

  /// Executes source code using the DevArena backend endpoint
  Future<ExecutionResult> execute({
    required String language,
    required String sourceCode,
    String stdin = '',
  }) async {
    final languageId = kJudge0LanguageIds[language];
    if (languageId == null) {
      return const ExecutionResult(
        stdout: '',
        stderr: 'Language not supported for execution',
        compileOutput: '',
        status: 'Error',
        isSuccess: false,
      );
    }

    // Try backend proxy first
    try {
      final res = await http
          .post(
            Uri.parse('$kServerUrl/api/execute'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'language_id': languageId,
              'source_code': sourceCode,
              'stdin': stdin,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode == 200) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return _parseJudge0Response(data);
      }
    } catch (e) {
      debugPrint('[ExecutionService] Backend error, falling back to Judge0 direct: $e');
    }

    // Fallback: Direct call to Judge0 CE Public API
    try {
      final base64Source = base64Encode(utf8.encode(sourceCode));
      final base64Stdin = stdin.isNotEmpty ? base64Encode(utf8.encode(stdin)) : '';

      final res = await http
          .post(
            Uri.parse('https://ce.judge0.com/submissions?base64_encoded=true&wait=true'),
            headers: {'Content-Type': 'application/json'},
            body: jsonEncode({
              'language_id': languageId,
              'source_code': base64Source,
              'stdin': base64Stdin,
              'redirect_stderr_to_stdout': false,
            }),
          )
          .timeout(const Duration(seconds: 25));

      if (res.statusCode >= 200 && res.statusCode < 300) {
        final data = jsonDecode(res.body) as Map<String, dynamic>;
        return _parseJudge0Response(data, isBase64: true);
      } else {
        return ExecutionResult(
          stdout: '',
          stderr: 'Execution server returned status: ${res.statusCode}',
          compileOutput: '',
          status: 'Server Error',
          isSuccess: false,
        );
      }
    } catch (e) {
      return ExecutionResult(
        stdout: '',
        stderr: 'Execution request timed out or failed: $e',
        compileOutput: '',
        status: 'Network Error',
        isSuccess: false,
      );
    }
  }

  ExecutionResult _parseJudge0Response(Map<String, dynamic> data, {bool isBase64 = false}) {
    String decodeField(dynamic val) {
      if (val == null) return '';
      final str = val.toString();
      if (!isBase64) return str;
      try {
        return utf8.decode(base64Decode(str));
      } catch (_) {
        return str;
      }
    }

    final stdout = decodeField(data['stdout']);
    final stderr = decodeField(data['stderr']);
    final compileOutput = decodeField(data['compile_output']);

    final statusObj = data['status'] as Map<String, dynamic>?;
    final statusId = statusObj?['id'] as int? ?? 0;
    final statusDesc = statusObj?['description'] as String? ?? 'Unknown';

    final isSuccess = statusId == 3; // 3 = Accepted
    final timeStr = data['time']?.toString();
    final time = timeStr != null ? double.tryParse(timeStr) : null;
    final memory = data['memory'] as int?;

    return ExecutionResult(
      stdout: stdout,
      stderr: stderr,
      compileOutput: compileOutput,
      status: statusDesc,
      time: time,
      memory: memory,
      isSuccess: isSuccess,
    );
  }
}
