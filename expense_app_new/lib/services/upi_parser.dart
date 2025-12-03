class UpiParser {
  static Map<String, dynamic> parseResponse(String? response) {
    if (response == null || response.isEmpty) return {};

    final Map<String, dynamic> data = {};
    final parts = response.split('&');

    for (var part in parts) {
      if (part.isEmpty) continue;
      final idx = part.indexOf('=');
      if (idx > 0) {
        final key = part.substring(0, idx);
        final value = part.substring(idx + 1);
        data[key] = value;
      }
    }

    return data;
  }
}
