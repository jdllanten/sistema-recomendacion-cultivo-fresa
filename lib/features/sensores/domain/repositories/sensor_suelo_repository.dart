import '../entities/datos_sensor_suelo.dart';

abstract class SensorSueloRepository {
  DatosSensorSuelo obtenerUltimaLectura();

  Stream<DatosSensorSuelo> observarLecturas();
}