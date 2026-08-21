import '../entities/datos_sensor_suelo.dart';
import '../repositories/sensor_suelo_repository.dart';


class ObtenerUltimaLecturaSensor {
  const ObtenerUltimaLecturaSensor({
    required this.repository,
  });

  final SensorSueloRepository repository;

  DatosSensorSuelo call() {
    return repository.obtenerUltimaLectura();
  }
}