import 'dart:async';
import 'dart:convert';

import 'package:flutter_test/flutter_test.dart';
import 'package:gestion_cafeteria/core/failure.dart';
import 'package:gestion_cafeteria/core/http_client.dart';
import 'package:http/http.dart' as http;
import 'package:http/testing.dart';

ApiClient apiClient(int status, [Object? body]) {
  return ApiClient(
    baseUrl: 'http://127.0.0.1',
    client: MockClient(
      (request) async => http.Response(
        body == null ? '' : jsonEncode(body),
        status,
        headers: {'Content-Type': 'application/json; charset=utf-8'},
      ),
    ),
  );
}

ApiClient throwingClient(Exception exception) {
  return ApiClient(
    baseUrl: 'http://127.0.0.1',
    client: MockClient((request) async => throw exception),
  );
}

void main() {
  group('Pruebas integrales de ApiClient', () {
    // -------------------------------------------------------------------------
    // Pruebas de transporte y respuestas vacías
    // -------------------------------------------------------------------------
    test('204 No Content retorna null', () async {
      final client = apiClient(204);
      final result = await client.get('/test');

      expect(result, isNull);
    });

    test('Error de transporte (ClientException) lanza NetworkFailure', () async {
      final client = throwingClient(http.ClientException('Connection failed'));

      expect(
        () => client.get('/test'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    test('Timeout de petición (TimeoutException) lanza NetworkFailure', () async {
      final client = throwingClient(TimeoutException('Request timed out'));

      expect(
        () => client.get('/test'),
        throwsA(isA<NetworkFailure>()),
      );
    });

    // -------------------------------------------------------------------------
    // Rango 200 - 300 (Éxito)
    // -------------------------------------------------------------------------
    test('1. Límite 200 inferior (199): fuera de rango 2xx lanza UnexpectedFailure', () async {
      final client = apiClient(199, {'detail': 'Informational response'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            199,
          ),
        ),
      );
    });

    test('2. Límite 200 superior inmediato (200 y 201): dentro de 2xx retornan éxito', () async {
      final client200 = apiClient(200, {'status': 'ok_200'});
      final client201 = apiClient(201, {'status': 'created_201'});

      expect(await client200.get('/test'), equals({'status': 'ok_200'}));
      expect(await client201.get('/test'), equals({'status': 'created_201'}));
    });

    test('3. Límite 300 inferior (299): dentro de rango 2xx retorna éxito', () async {
      final client = apiClient(299, {'status': 'ok_299'});
      expect(await client.get('/test'), equals({'status': 'ok_299'}));
    });

    test('4. Límite 300 (300): fuera de rango 2xx lanza UnexpectedFailure', () async {
      final client = apiClient(300, {'detail': 'Multiple Choices'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            300,
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // Punto 404 (NotFoundFailure)
    // -------------------------------------------------------------------------
    test('5. Límite 404 inferior (403): fuera de 404 lanza UnexpectedFailure', () async {
      final client = apiClient(403, {'detail': 'Forbidden'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            403,
          ),
        ),
      );
    });

    test('6. Punto exacto 404: lanza NotFoundFailure', () async {
      final client = apiClient(404, {'detail': 'Order not found'});
      expect(
        () => client.get('/test'),
        throwsA(isA<NotFoundFailure>()),
      );
    });

    test('7. Límite 404 superior (405): fuera de 404 lanza UnexpectedFailure', () async {
      final client = apiClient(405, {'detail': 'Method Not Allowed'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            405,
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // Punto 409 (ConflictFailure)
    // -------------------------------------------------------------------------
    test('8. Límite 409 inferior (408): fuera de 409 lanza UnexpectedFailure', () async {
      final client = apiClient(408, {'detail': 'Request Timeout'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            408,
          ),
        ),
      );
    });

    test('9. Punto exacto 409: lanza ConflictFailure con el mensaje de detail', () async {
      const message = 'Cannot change status from delivered to preparing';
      final client = apiClient(409, {'detail': message});
      expect(
        () => client.patch('/test', {'status': 'preparing'}),
        throwsA(
          isA<ConflictFailure>().having(
            (f) => f.message,
            'message',
            message,
          ),
        ),
      );
    });

    test('10. Límite 409 superior (410): fuera de 409 lanza UnexpectedFailure', () async {
      final client = apiClient(410, {'detail': 'Gone'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            410,
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // Punto 422 (UnprocessableEntityFailure)
    // -------------------------------------------------------------------------
    test('11. Límite 422 inferior (421): fuera de 422 lanza UnexpectedFailure', () async {
      final client = apiClient(421, {'detail': 'Misdirected Request'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            421,
          ),
        ),
      );
    });

    test('12. Punto exacto 422: lanza UnprocessableEntityFailure con mapa de errores', () async {
      final client = apiClient(422, {
        'detail': [
          {
            'loc': ['body', 'customer'],
            'msg': 'Must be 1-50 characters',
          },
        ],
      });
      expect(
        () => client.post('/test', {'customer': ''}),
        throwsA(
          isA<UnprocessableEntityFailure>().having(
            (f) => f.fields,
            'fields',
            equals({'customer': 'Must be 1-50 characters'}),
          ),
        ),
      );
    });

    test('13. Límite 422 superior (423): fuera de 422 lanza UnexpectedFailure', () async {
      final client = apiClient(423, {'detail': 'Locked'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            423,
          ),
        ),
      );
    });

    // -------------------------------------------------------------------------
    // Rango 500 - 600 (ServerFailure)
    // -------------------------------------------------------------------------
    test('14. Límite 500 inferior (499): fuera de 5xx lanza UnexpectedFailure', () async {
      final client = apiClient(499, {'detail': 'Client Closed Request'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            499,
          ),
        ),
      );
    });

    test('15. Límite 500 y 599: dentro del rango 5xx lanzan ServerFailure', () async {
      final client500 = apiClient(500, {'detail': 'Internal Server Error'});
      final client599 = apiClient(599, {'detail': 'Network Connect Timeout Error'});

      expect(
        () => client500.get('/test'),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            500,
          ),
        ),
      );
      expect(
        () => client599.get('/test'),
        throwsA(
          isA<ServerFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            599,
          ),
        ),
      );
    });

    test('16. Límite 600 (600): fuera de 5xx lanza UnexpectedFailure', () async {
      final client = apiClient(600, {'detail': 'Invalid HTTP status'});
      expect(
        () => client.get('/test'),
        throwsA(
          isA<UnexpectedFailure>().having(
            (f) => f.statusCode,
            'statusCode',
            600,
          ),
        ),
      );
    });
  });
}