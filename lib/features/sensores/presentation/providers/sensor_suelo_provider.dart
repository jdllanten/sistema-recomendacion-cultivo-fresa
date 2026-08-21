import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'dart:async';
import '../../data/datasource/sensor_suelo_mock_datasource.dart';
import '../../data/datasource/sensor_suelo_mqtt_datasource.dart';
import '../../data/repositories/sensor_suelo_repository_impl.dart';
import '../../domain/entities/datos_sensor_suelo.dart';
import '../../domain/repositories/sensor_suelo_repository.dart';
import '../../domain/usecases/observar_lecturas_sensor.dart';
import '../../domain/usecases/obtener_ultima_lectura_sensor.dart';

//Provider del datasource simulado.
final sensorSueloMockDatasourceProvider =
    Provider<SensorSueloMockDatasource>((ref) {
  return const SensorSueloMockDatasource();
});


final sensorSueloMqttDatasourceProvider =
    Provider<SensorSueloMqttDatasource>((ref) {
  final datasource = SensorSueloMqttDatasource();

  ref.onDispose(() {
    datasource.desconectar();
  });

  return datasource;
});

//Provider del repositorio.
final sensorSueloRepositoryProvider = Provider<SensorSueloRepository>((ref) {
  final mockDatasource = ref.watch(sensorSueloMockDatasourceProvider);
  final mqttDatasource = ref.watch(sensorSueloMqttDatasourceProvider);

  return SensorSueloRepositoryImpl(
    mockDatasource: mockDatasource,
    mqttDatasource: mqttDatasource,
  );
});

//Caso de uso para obtener lectura inmediata.
final obtenerUltimaLecturaSensorProvider =
    Provider<ObtenerUltimaLecturaSensor>((ref) {
  final repository = ref.watch(sensorSueloRepositoryProvider);

  return ObtenerUltimaLecturaSensor(
    repository: repository,
  );
});

//Caso de uso para observar lecturas en tiempo real.
final observarLecturasSensorProvider = Provider<ObservarLecturasSensor>((ref) {
  final repository = ref.watch(sensorSueloRepositoryProvider);

  return ObservarLecturasSensor(
    repository: repository,
  );
});

//Provider síncrono usado por pantallas o procesos que todavía necesitan
//una lectura inmediata.
final ultimaLecturaSensorProvider = Provider<DatosSensorSuelo>((ref) {
  final obtenerUltimaLectura = ref.watch(obtenerUltimaLecturaSensorProvider);

  return obtenerUltimaLectura();
});


final lecturaSensorStreamProvider = StreamProvider<DatosSensorSuelo>((ref) {
  final observarLecturas = ref.watch(observarLecturasSensorProvider);

  return observarLecturas();
});


enum EstadoConexionMqtt {
  conectando,
  activo,
  sinDatosRecientes,
  sinConexion,
}



final estadoConexionMqttProvider =
    Provider<(EstadoConexionMqtt, DateTime?)>((ref) {
  // Recalcular cada minuto aunque no lleguen datos nuevos.
  // Así el umbral de 15 min y el "hace X min" se actualizan solos.
  final timer = Timer.periodic(const Duration(minutes: 1), (_) {
    ref.invalidateSelf();
  });
  ref.onDispose(() => timer.cancel());

  final stream = ref.watch(lecturaSensorStreamProvider);

  return stream.when(
    data: (lectura) {
  final diferencia = DateTime.now().difference(lectura.fechaLectura);

  const tiempoMaximoActivo = Duration(minutes: 1);

  if (diferencia <= tiempoMaximoActivo) {
    return (EstadoConexionMqtt.activo, lectura.fechaLectura);
  }

  return (EstadoConexionMqtt.sinDatosRecientes, lectura.fechaLectura);
},
    loading: () => (EstadoConexionMqtt.conectando, null),
    error: (_, __) => (EstadoConexionMqtt.sinConexion, null),
  );
});