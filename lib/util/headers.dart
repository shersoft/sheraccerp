Future<Map<String, String>> getHeaders() async {
  Map<String, String> headers = {
    'Content-Type': 'application/json',
    // 'token-type': 'Bearer',
    // 'ng-api': 'true',
    'auth-token': '',
    'Guest-Order-Token': ''
  };
  return headers;
}
