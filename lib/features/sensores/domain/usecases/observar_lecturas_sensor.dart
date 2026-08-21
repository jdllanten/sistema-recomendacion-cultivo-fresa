import '../entities/datos_sensor_suelo.dart';
import '../repositories/sensor_suelo_repository.dart';

//Caso de uso para observar lecturas del sensor en tiempo real.
class ObservarLecturasSensor {
  const ObservarLecturasSensor({
    required this.repository,
  });

  final SensorSueloRepository repository;

  Stream<DatosSensorSuelo> call() {
    return repository.observarLecturas();
  }
}