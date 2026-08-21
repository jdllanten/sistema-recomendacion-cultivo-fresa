import 'dart:async';

import '../../../../core/constantes/configuracion_mqtt.dart';
import '../../domain/entities/datos_sensor_suelo.dart';
import '../../domain/repositories/sensor_suelo_repository.dart';
import '../datasource/sensor_suelo_mock_datasource.dart';
import '../datasource/sensor_suelo_mqtt_datasource.dart';


class SensorSueloRepositoryImpl implements SensorSueloRepository {
  const SensorSueloRepositoryImpl({
    required this.mockDatasource,
    required this.mqttDatasource,
  });

  final SensorSueloMockDatasource mockDatasource;
  final SensorSueloMqttDatasource mqttDatasource;

  @override
  DatosSensorSuelo obtenerUltimaLectura() {
    return mockDatasource.obtenerUltimaLectura();
  }

  @override
  Stream<DatosSensorSuelo> observarLecturas() async* {

    if (ConfiguracionMqtt.usarDatosMock) {
      yield mockDatasource.obtenerUltimaLectura();
      return;
    }


    unawaited(mqttDatasource.conectar());

    yield* mqttDatasource.lecturasStream;
  }
}