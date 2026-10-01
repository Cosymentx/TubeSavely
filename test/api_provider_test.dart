import 'package:flutter_test/flutter_test.dart';
import 'package:tubesavely/app/utils/constants.dart';

void main() {
  test('Constants initialization', () {
    expect(Constants.API_BASE_URL, 'https://api.tubesavely.cosyment.com');
    expect(Constants.API_TIMEOUT, 30000);
  });

  group('API Endpoints', () {
    test('API Base URL should be correct', () {
      expect(Constants.API_BASE_URL, 'https://api.tubesavely.cosyment.com');
      expect(Constants.PARSE_API_BASE_URL, 'https://tube-savely-server.vercel.app');
    });

    test('API Timeout should be 30 seconds', () {
      expect(Constants.API_TIMEOUT, 30000);
    });
  });
}
