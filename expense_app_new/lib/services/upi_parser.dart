class UpiParser {
  static Map<String, dynamic> parseResponse(String? response) {
    if (response == null || response.isEmpty) return {};

    final parts = response.split('&');
    final Map<String, dynamic> data = {};

    for (var p in parts) {
      final t = p.split('=');
      if (t.length == 2) data[t[0]] = t[1];
    }

    return data;
  }
}
