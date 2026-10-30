import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';
import 'package:semestapay_api_client/semestapay_api_client.dart';

void main() {
  group('SemestaPayApiClient', () {
    test('login success parses token and user', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/auth/login');
        return http.Response(
          jsonEncode({
            'token': 'mock-token-123',
            'user': {
              'id': 2,
              'name': 'Kasir Kantin',
              'email': 'kasir@cashless.dev',
              'roles': ['cashier'],
            },
          }),
          200,
        );
      });

      final client = SemestaPayApiClient(
        baseUrl: 'https://test.api/api/v1',
        client: mockClient,
      );

      final auth = await client.login(
        email: 'kasir@cashless.dev',
        password: 'password',
      );

      expect(auth.token, 'mock-token-123');
      expect(auth.user.name, 'Kasir Kantin');
      expect(auth.user.isCashier, isTrue);
      expect(client.token, 'mock-token-123');
    });

    test('readCard parses card and balance correctly', () async {
      final mockClient = MockClient((request) async {
        expect(request.url.path, '/api/v1/card/read/DEMO-UID-0001');
        return http.Response(
          jsonEncode({
            'card': {'uid': 'DEMO-UID-0001', 'status': 'active'},
            'student': {
              'id': 1,
              'name': 'Ahmad Fauzi',
              'nis': '2026-001',
              'status': 'active',
              'class': 'Kelas 7A',
            },
            'wallet': {'balance': 114000, 'status': 'active'},
            'daily_used': 10000,
            'daily_limit': 50000,
          }),
          200,
        );
      });

      final client = SemestaPayApiClient(
        baseUrl: 'https://test.api/api/v1',
        client: mockClient,
        token: 'mock-token',
      );

      final result = await client.readCard('DEMO-UID-0001');

      expect(result.student.name, 'Ahmad Fauzi');
      expect(result.wallet.balance, 114000.0);
      expect(result.remainingDailyLimit, 40000.0);
      expect(result.isUsable, isTrue);
    });

    test('throws ApiException on error response', () async {
      final mockClient = MockClient((request) async {
        return http.Response(
          jsonEncode({'message': 'Saldo tidak mencukupi.'}),
          422,
        );
      });

      final client = SemestaPayApiClient(
        baseUrl: 'https://test.api/api/v1',
        client: mockClient,
      );

      expect(
        () => client.readCard('INVALID'),
        throwsA(
          isA<ApiException>().having(
            (e) => e.message,
            'message',
            'Saldo tidak mencukupi.',
          ),
        ),
      );
    });
  });
}
