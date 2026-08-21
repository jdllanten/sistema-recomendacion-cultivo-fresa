import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../historial/presentation/providers/historial_provider.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../../../sensores/presentation/providers/sensor_suelo_provider.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';
import '../../domain/entities/recomendacion.dart';
import '../../domain/services/generador_recomendaciones.dart';
import '../../domain/usecases/generar_recomendaciones.dart';
import 'plan_nutricional_npk_provider.dart';

final generadorRecomendacionesProvider =
    Provider<GeneradorRecomendaciones>((ref) {
  return const GeneradorRecomendaciones();
});

final generarRecomendacionesProvider = Provider<GenerarRecomendaciones>((ref) {
  final generador = ref.watch(generadorRecomendacionesProvider);

  return GenerarRecomendaciones(
    generador: generador,
  );
});


final lecturaBaseRecomendacionesProvider =
    Provider<AsyncValue<DatosSensorSuelo?>>((ref) {
  final loteId = ref.watch(loteSeleccionadoIdProvider);
  final lecturaLoteAsync = ref.watch(lecturaUltimaPorLotePlanProvider);
  final lecturaAsync = ref.watch(lecturaSensorStreamProvider);
  final ultimaLecturaHive = ref.watch(ultimaLecturaHistorialProvider);

  final lecturaLote = lecturaLoteAsync.valueOrNull;
  if (lecturaLote != null) {
    return AsyncValue.data(lecturaLote);
  }

  if (lecturaLoteAsync.isLoading && loteId != 'lote_1') {
    return const AsyncValue.loading();
  }

  if (lecturaLoteAsync.hasError && loteId != 'lote_1') {
    return AsyncValue.error(
      lecturaLoteAsync.error!,
      lecturaLoteAsync.stackTrace ?? StackTrace.current,
    );
  }


  if (loteId != 'lote_1') {
    return const AsyncValue.data(null);
  }

  return lecturaAsync.when(
    data: (lectura) {
      return AsyncValue.data(lectura);
    },
    loading: () {
      if (ultimaLecturaHive != null) {
        return AsyncValue.data(
          _convertirHistorialADatosSensor(ultimaLecturaHive),
        );
      }

      return const AsyncValue.loading();
    },
    error: (error, stackTrace) {
      if (ultimaLecturaHive != null) {
        return AsyncValue.data(
          _convertirHistorialADatosSensor(ultimaLecturaHive),
        );
      }

      return AsyncValue.error(error, stackTrace);
    },
  );
});

final recomendacionesAsyncProvider =
    Provider<AsyncValue<List<Recomendacion>>>((ref) {
  final lecturaBaseAsync = ref.watch(lecturaBaseRecomendacionesProvider);
  final historial = ref.watch(historialLecturasProvider);
  final generarRecomendaciones = ref.watch(generarRecomendacionesProvider);

  return lecturaBaseAsync.when(
    data: (lectura) {
      if (lectura == null) {
        return const AsyncValue.data(<Recomendacion>[]);
      }

      final recomendaciones = generarRecomendaciones(
        lectura,
        historial: historial,
      );

      return AsyncValue.data(recomendaciones);
    },
    loading: () => const AsyncValue.loading(),
    error: (error, stackTrace) => AsyncValue.error(error, stackTrace),
  );
});

DatosSensorSuelo _convertirHistorialADatosSensor(
  LecturaHistorial lectura,
) {
  return DatosSensorSuelo(
    humedadSuelo: lectura.humedad,
    temperaturaSuelo: lectura.temperatura,
    conductividadElectrica: lectura.ec,
    phSuelo: lectura.ph,
    nitrogeno: lectura.nitrogeno,
    fosforo: lectura.fosforo,
    potasio: lectura.potasio,
    fechaLectura: lectura.fechaLectura,
  );
}
