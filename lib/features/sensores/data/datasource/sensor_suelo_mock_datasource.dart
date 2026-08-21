import '../../domain/entities/datos_sensor_suelo.dart';

class SensorSueloMockDatasource {
  const SensorSueloMockDatasource();

  DatosSensorSuelo obtenerUltimaLectura() {
    return DatosSensorSuelo(
      humedadSuelo: 65,
      temperaturaSuelo: 20,
      conductividadElectrica: 1.8,
      phSuelo: 5.7,
      nitrogeno: 32,
      fosforo: 21,
      potasio: 28,
      fechaLectura: DateTime.now(),
    );
  }
}
