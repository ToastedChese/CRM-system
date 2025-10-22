// lib/services/api_service.dart
import 'package:http/http.dart' as http;
import '../.env.dart'; // imports apiBaseUrl

class ApiService {
  final String _base = apiBaseUrl; // use your constant

  Uri _u(String path, [Map<String, dynamic>? q]) => Uri.parse(
    '$_base$path',
  ).replace(queryParameters: q?.map((k, v) => MapEntry(k, '$v')));

  Future<http.Response> ping() => http.get(_u('/api/health'));
}
