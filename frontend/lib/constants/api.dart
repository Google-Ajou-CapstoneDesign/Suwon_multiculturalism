class ApiConstants {
  // 에뮬레이터에서 로컬 백엔드 접속 시 10.0.2.2 사용 (localhost 대체)
  static const String baseUrl = 'http://10.0.2.2:8000';
  static const Duration timeout = Duration(seconds: 60);
}
