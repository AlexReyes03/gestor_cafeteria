import 'package:flutter/material.dart';
import 'core/http_client.dart';

void main() {
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late final Future<dynamic> _respuesta;

  @override
  void initState() {
    super.initState();
    final clientePrueba = ApiClient(
      baseUrl: 'http://0.0.0.0:8000',
    );
    _respuesta = clientePrueba.get('/orders');
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: Scaffold(
        body: Center(
          child: FutureBuilder<dynamic>(
            future: _respuesta,
            builder: (context, snapshot) {
              if (snapshot.connectionState != ConnectionState.done) {
                return const CircularProgressIndicator();
              }
              if (snapshot.hasError) {
                return Text('Error: ${snapshot.error}');
              }
              return Text('${snapshot.data}');
            },
          ),
        ),
      ),
    );
  }
}
