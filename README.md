# gestion_cafeteria

Cliente Flutter de ejemplo para los pedidos de una cafetería. `ApiClient` llama al API, distingue un fallo de red de un error HTTP y traduce 404, 409, 422 y 5xx a clases de `Failure`.

El paquete de Dart se llama `gestion_cafeteria`.

## Requisitos

- Flutter con Dart 3.13.3 o superior.
- Node.js 22.13 o superior, solo para el servidor.

## mini_backend

El servidor no vive en este repositorio. Se clona aparte:

https://github.com/DMI-2026/mini_backend

La corrida de referencia usó el commit local `94d2533` (8 de octubre de 2026, `feat: enable CORS for Flutter web clients`). Ese commit está uno adelante de `master` público, que está en `118adde` (7 de octubre de 2026).

## Levantar el servidor

Dentro de la carpeta clonada de mini_backend:

```bat
node server.js
```

Escucha en `http://127.0.0.1:8000`. No hace falta `npm install`.

## Ejecutar la app

`ApiClient` lee `API_URL` cuando se construye sin `baseUrl`. El valor por defecto es `http://10.0.2.2:8000` (emulador de Android). En la máquina anfitriona:

```bat
flutter run --dart-define=API_URL=http://127.0.0.1:8000
```

Ese define solo aplica si no se pasa `baseUrl`. `lib/main.dart` hoy sí lo pasa, con `http://0.0.0.0:8000`. Ese host no está permitido (`localhost`, `127.0.0.1`, `10.0.2.2`, `10.0.3.2`), así que el arranque actual lanza `ArgumentError` antes de la petición.

## Pruebas

```bat
flutter test test/core/http_client_test.dart
```

Usan `MockClient`. No necesitan el servidor encendido.

## Estructura

- `lib/main.dart`: pantalla de prueba que pide `/orders`.
- `lib/core/http_client.dart`: cliente HTTP.
- `lib/core/failure.dart`: errores tipados.
- `lib/core/token_storage.dart`: token en almacenamiento seguro.
- `test/core/http_client_test.dart`: pruebas del cliente.
