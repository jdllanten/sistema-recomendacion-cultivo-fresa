import 'dart:async';

import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../../../sensores/presentation/providers/sensor_suelo_provider.dart';
import '../../data/datasources/historial_local_datasource.dart';
import '../../data/datasources/historial_mock_datasource.dart';
import '../../data/repositories/historial_repository_impl.dart';
import '../../domain/entities/lectura_historial.dart';
import '../../domain/repositories/historial_repository.dart';
import '../../domain/usecases/guardar_lectura_historial.dart';
import '../../domain/usecases/limpiar_historial.dart';
import '../../domain/usecases/obtener_lecturas_historial.dart';

//Provider del datasource simulado.
final historialMockDatasourceProvider = Provider<HistorialMockDatasource>((ref) {
  return const HistorialMockDatasource();
});

//Provider del datasource local Hive.
final historialLocalDatasourceProvider = Provider<HistorialLocalDatasource>(
  (ref) {
    return HistorialLocalDatasource.fromHive();
  },
);

//Provider del repositorio de historial.
final historialRepositoryProvider = Provider<HistorialRepository>((ref) {
  final mockDatasource = ref.watch(historialMockDatasourceProvider);
  final localDatasource = ref.watch(historialLocalDatasourceProvider);

  return HistorialRepositoryImpl(
    mockDatasource: mockDatasource,
    localDatasource: localDatasource,
  );
});

//Caso de uso para obtener lecturas históricas.
final obtenerLecturasHistorialProvider =
    Provider<ObtenerLecturasHistorial>((ref) {
  final repository = ref.watch(historialRepositoryProvider);

  return ObtenerLecturasHistorial(
    repository: repository,
  );
});

//Caso de uso para guardar una lectura.
final guardarLecturaHistorialProvider =
    Provider<GuardarLecturaHistorial>((ref) {
  final repository = ref.watch(historialRepositoryProvider);

  return GuardarLecturaHistorial(
    repository: repository,
  );
});

//Caso de uso para limpiar historial.
final limpiarHistorialProvider = Provider<LimpiarHistorial>((ref) {
  final repository = ref.watch(historialRepositoryProvider);

  return LimpiarHistorial(
    repository: repository,
  );
});

class HistorialSesionNotifier extends StateNotifier<List<LecturaHistorial>> {
  HistorialSesionNotifier({
    required this.obtenerLecturas,
    required this.guardarLectura,
    required this.limpiarHistorial,
  }) : super(obtenerLecturas());

  final ObtenerLecturasHistorial obtenerLecturas;
  final GuardarLecturaHistorial guardarLectura;
  final LimpiarHistorial limpiarHistorial;

  Future<void> agregarLecturaHistorial(
    LecturaHistorial nuevaLectura,
  ) async {
    final loteNuevo = nuevaLectura.loteId.trim();

    final yaExiste = state.any((item) {
      final mismoLote = item.loteId.trim() == loteNuevo;
      final mismaFecha =
          item.fechaLectura.toUtc().toIso8601String() ==
          nuevaLectura.fechaLectura.toUtc().toIso8601String();

      return mismoLote && mismaFecha;
    });

    if (yaExiste) return;

    await guardarLectura(nuevaLectura);

    // Actualizamos el estado directamente para no perder una lectura de otro
    // lote si ambas tienen exactamente la misma fecha/hora.
    final lecturasActualizadas = <LecturaHistorial>[
      ...state,
      nuevaLectura,
    ]..sort(
        (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
      );

    if (lecturasActualizadas.length > 200) {
      state = lecturasActualizadas.sublist(
        lecturasActualizadas.length - 200,
      );
    } else {
      state = lecturasActualizadas;
    }
  }


  Future<void> agregarDesdeSensor(
    DatosSensorSuelo lectura, {
    String loteId = 'lote_1',
    String loteNombre = 'Lote 1',
  }) async {
    final nuevaLectura = LecturaHistorial(
      fechaLectura: lectura.fechaLectura,
      humedad: lectura.humedadSuelo,
      temperatura: lectura.temperaturaSuelo,
      ph: lectura.phSuelo,
      ec: lectura.conductividadElectrica,
      nitrogeno: lectura.nitrogeno,
      fosforo: lectura.fosforo,
      potasio: lectura.potasio,
      loteId: loteId,
      loteNombre: loteNombre,
    );

    await agregarLecturaHistorial(nuevaLectura);
  }

  Future<void> limpiar() async {
    await limpiarHistorial();
    state = const [];
  }

  void recargar() {
    state = obtenerLecturas();
  }
}

//Provider del historial mostrado en la UI.
final historialSesionProvider =
    StateNotifierProvider<HistorialSesionNotifier, List<LecturaHistorial>>(
  (ref) {
    final obtenerLecturas = ref.watch(obtenerLecturasHistorialProvider);
    final guardarLectura = ref.watch(guardarLecturaHistorialProvider);
    final limpiarHistorial = ref.watch(limpiarHistorialProvider);

    return HistorialSesionNotifier(
      obtenerLecturas: obtenerLecturas,
      guardarLectura: guardarLectura,
      limpiarHistorial: limpiarHistorial,
    );
  },
);


final sincronizarHistorialConSensorProvider = Provider<void>((ref) {
  const usuarioId = 'jdh2010';
  const fincaId = 'finca_esperanza';


  ref.listen<AsyncValue<DatosSensorSuelo>>(
    lecturaSensorStreamProvider,
    (previous, next) {
      
    },
  );

  final query = FirebaseFirestore.instance
      .collectionGroup('lecturas')
      .where('usuarioId', isEqualTo: usuarioId);

  final subscription = query.snapshots().listen(
    (snapshot) {
      unawaited(
        _procesarCambiosFirestore(
          ref: ref,
          cambios: snapshot.docChanges,
          fincaIdEsperada: fincaId,
        ),
      );
    },
    onError: (_) {
      // Si no hay conexión o Firestore falla temporalmente, no borramos nada.
      // El historial local de Hive continúa disponible.
    },
  );

  ref.onDispose(() {
    subscription.cancel();
  });
});

Future<void> _procesarCambiosFirestore({
  required Ref ref,
  required List<
          DocumentChange<Map<String, dynamic>>>
      cambios,
  required String fincaIdEsperada,
}) async {
  for (final cambio in cambios) {
    if (cambio.type == DocumentChangeType.removed) {
      continue;
    }

    final data = cambio.doc.data();

    if (data == null) {
      continue;
    }

    final fincaId = (data['fincaId'] ?? '').toString().trim();

    if (fincaId != fincaIdEsperada) {
      continue;
    }

    final lectura = _lecturaHistorialDesdeFirestore(data);

    if (lectura == null) {
      continue;
    }

    await ref
        .read(historialSesionProvider.notifier)
        .agregarLecturaHistorial(lectura);
  }
}

//Convierte un documento de Firestore a LecturaHistorial manteniendo
//la identidad del lote.
LecturaHistorial? _lecturaHistorialDesdeFirestore(
  Map<String, dynamic> data,
) {
  final loteId = (data['loteId'] ?? '').toString().trim();

  if (loteId.isEmpty) {
    return null;
  }

  final fecha = _fechaFirestore(data['fechaLectura']);

  if (fecha == null) {
    return null;
  }

  final nombreFirestore = (data['nombreLote'] ?? '').toString().trim();

  final loteNombre = nombreFirestore.isNotEmpty
      ? nombreFirestore
      : _nombreLoteDesdeId(loteId);

  return LecturaHistorial(
    fechaLectura: fecha,
    humedad: _doubleFirestore(data['humedadSuelo']),
    temperatura: _doubleFirestore(data['temperaturaSuelo']),
    ph: _doubleFirestore(data['phSuelo']),
    ec: _doubleFirestore(data['conductividadElectrica']),
    nitrogeno: _doubleFirestore(data['nitrogeno']),
    fosforo: _doubleFirestore(data['fosforo']),
    potasio: _doubleFirestore(data['potasio']),
    loteId: loteId,
    loteNombre: loteNombre,
  );
}

DateTime? _fechaFirestore(dynamic value) {
  if (value is Timestamp) {
    return value.toDate();
  }

  if (value is DateTime) {
    return value;
  }

  if (value is String) {
    return DateTime.tryParse(value);
  }

  return null;
}

double _doubleFirestore(dynamic value) {
  if (value is num) {
    return value.toDouble();
  }

  if (value is String) {
    return double.tryParse(
          value.trim().replaceAll(',', '.'),
        ) ??
        0;
  }

  return 0;
}


String _nombreLoteDesdeId(String loteId) {
  final match = RegExp(
    r'^lote_(\d+)',
    caseSensitive: false,
  ).firstMatch(loteId.trim());

  if (match != null) {
    return 'Lote ${match.group(1)}';
  }

  return loteId
      .replaceAll('_', ' ')
      .split(' ')
      .where((parte) => parte.trim().isNotEmpty)
      .map(
        (parte) =>
            '${parte[0].toUpperCase()}${parte.substring(1)}',
      )
      .join(' ');
}

//Provider consumido por HistorialPage.
final historialLecturasProvider = Provider<List<LecturaHistorial>>((ref) {
  return ref.watch(historialSesionProvider);
});

//Última lectura disponible en Hive.
final ultimaLecturaHistorialProvider = Provider<LecturaHistorial?>((ref) {
  final lecturas = ref.watch(historialLecturasProvider);

  if (lecturas.isEmpty) {
    return null;
  }

  final lecturasOrdenadas = [...lecturas]
    ..sort(
      (a, b) => b.fechaLectura.compareTo(a.fechaLectura),
    );

  return lecturasOrdenadas.first;
});
