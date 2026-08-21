import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';


//Pantalla base para futura lecturas de sensores

class SensoresPage extends StatelessWidget {
  const SensoresPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Sensores')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Variables del suelo',
              style: Theme.of(context).textTheme.headlineSmall,
            ),
            const SizedBox(height: 12),
            const Card(
              child: Padding(
                padding: EdgeInsets.all(16),
                child: Text(
                  'En esta sección se integrarán las lecturas de los sensores de humedad, temperatura y pH del suelo, '
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
