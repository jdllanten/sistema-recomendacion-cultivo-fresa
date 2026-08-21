import 'package:flutter/material.dart';

import '../../data/datasources/historial_remoto_datasource.dart';
import '../entities/lectura_historial.dart';
import '../repositories/historial_repository.dart';

class SincronizarHistorialDesdeFirestore {
  const SincronizarHistorialDesdeFirestore({
    required this.remotoDatasource,
    required this.historialRepository,
  });

  final HistorialRemotoDatasource remotoDatasource;
  final HistorialRepository historialRepository;

  Future<int> call() async {
    debugPrint('Sincronizando historial completo desde Firebase...');

    final lecturasLocales = historialRepository.obtenerLecturasRecientes();

    debugPrint('Lecturas locales en Hive: ${lecturasLocales.length}');

    final lecturasRemotas = await remotoDatasource.obtenerLecturasRecientes(
      limite: 1000,
    );

    debugPrint(
      'Lecturas descargadas desde Firebase: ${lecturasRemotas.length}',
    );

    return _guardarLecturasEnHive(lecturasRemotas);
  }

  Future<int> _guardarLecturasEnHive(
    List<LecturaHistorial> lecturas,
  ) async {
    var totalSincronizadas = 0;

    for (final lectura in lecturas) {
      await historialRepository.guardarLectura(lectura);
      totalSincronizadas++;
    }

    debugPrint('Lecturas guardadas en Hive: $totalSincronizadas');

    return totalSincronizadas;
  }
}