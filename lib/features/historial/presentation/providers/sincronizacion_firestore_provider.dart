import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sensores/presentation/providers/sensor_suelo_provider.dart';
import '../../data/datasources/historial_remoto_datasource.dart';
import '../../domain/entities/lectura_historial.dart';
import '../../domain/usecases/sincronizar_historial_desde_firestore.dart';
import 'historial_provider.dart';


enum EstadoSincronizacionFirestore {
  inicial,
  sincronizando,
  sincronizado,
  error,
}

class EstadoFirestoreInfo {
  const EstadoFirestoreInfo({
    required this.estado,
    this.ultimaSincronizacion,
    this.mensajeError,
  });

  final EstadoSincronizacionFirestore estado;
  final DateTime? ultimaSincronizacion;
  final String? mensajeError;

  EstadoFirestoreInfo copyWith({
    EstadoSincronizacionFirestore? estado,
    DateTime? ultimaSincronizacion,
    String? mensajeError,
  }) {
    return EstadoFirestoreInfo(
      estado: estado ?? this.estado,
      ultimaSincronizacion:
          ultimaSincronizacion ?? this.ultimaSincronizacion,
      mensajeError: mensajeError,
    );
  }

  static const inicial = EstadoFirestoreInfo(
    estado: EstadoSincronizacionFirestore.inicial,
  );
}



final historialRemotoDatasourceProvider =
    Provider<HistorialRemotoDatasource>((ref) {
  return HistorialRemotoDatasource();
});



final estadoFirestoreProvider = StateProvider<EstadoFirestoreInfo>((ref) {
  return EstadoFirestoreInfo.inicial;
});



final sincronizarLecturasFirestoreProvider = Provider<void>((ref) {
  final datasource = ref.watch(historialRemotoDatasourceProvider);

  ref.listen(lecturaSensorStreamProvider, (previous, next) {
    next.whenData((lectura) async {
      final lecturaHistorial = LecturaHistorial(
        fechaLectura: lectura.fechaLectura,
        humedad: lectura.humedadSuelo,
        temperatura: lectura.temperaturaSuelo,
        ph: lectura.phSuelo,
        ec: lectura.conductividadElectrica,
        nitrogeno: lectura.nitrogeno,
        fosforo: lectura.fosforo,
        potasio: lectura.potasio,
      );

      try {
        ref.read(estadoFirestoreProvider.notifier).state =
            const EstadoFirestoreInfo(
          estado: EstadoSincronizacionFirestore.sincronizando,
        );

        await datasource.guardarLectura(lecturaHistorial);

final ahora = DateTime.now();

ref.read(estadoFirestoreProvider.notifier).state =
    EstadoFirestoreInfo(
  estado: EstadoSincronizacionFirestore.sincronizado,
  ultimaSincronizacion: ahora,
);

// También actualiza la tarjeta de historial remoto,
// porque Hive y Firebase ya quedaron sincronizados con la nueva lectura.
ref.read(ultimaDescargaFirestoreProvider.notifier).state = ahora;

debugPrint('Lectura subida a Firestore');
      } catch (e) {
        ref.read(estadoFirestoreProvider.notifier).state =
            EstadoFirestoreInfo(
          estado: EstadoSincronizacionFirestore.error,
          mensajeError: e.toString(),
        );

        debugPrint('Error subiendo lectura a Firestore: $e');
      }
    });
  });
});


final sincronizarHistorialDesdeFirestoreUsecaseProvider =
    Provider<SincronizarHistorialDesdeFirestore>((ref) {
  final remotoDatasource = ref.watch(historialRemotoDatasourceProvider);
  final historialRepository = ref.watch(historialRepositoryProvider);

  return SincronizarHistorialDesdeFirestore(
    remotoDatasource: remotoDatasource,
    historialRepository: historialRepository,
  );
});


final sincronizandoDesdeFirestoreProvider = StateProvider<bool>((ref) {
  return false;
});

final ultimaDescargaFirestoreProvider = StateProvider<DateTime?>((ref) {
  return null;
});

final errorDescargaFirestoreProvider = StateProvider<String?>((ref) {
  return null;
});


final sincronizarDesdeFirestoreAutomaticoProvider =
    FutureProvider<int>((ref) async {
  final sincronizar =
      ref.watch(sincronizarHistorialDesdeFirestoreUsecaseProvider);

  ref.read(sincronizandoDesdeFirestoreProvider.notifier).state = true;
  ref.read(errorDescargaFirestoreProvider.notifier).state = null;

  try {
    final total = await sincronizar();

    ref.read(ultimaDescargaFirestoreProvider.notifier).state = DateTime.now();

    debugPrint('Historial descargado desde Firestore: $total lecturas');

    return total;
  } catch (e) {
    ref.read(errorDescargaFirestoreProvider.notifier).state = e.toString();

    debugPrint('Error descargando historial desde Firestore: $e');

    return 0;
  } finally {
    ref.read(sincronizandoDesdeFirestoreProvider.notifier).state = false;
  }
});