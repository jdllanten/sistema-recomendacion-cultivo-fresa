import '../entities/lectura_historial.dart';
import '../repositories/historial_repository.dart';

//Caso de uso para obtener lecturas históricas

class ObtenerLecturasHistorial {
  const ObtenerLecturasHistorial({
    required this.repository,
  });

  final HistorialRepository repository;

  List<LecturaHistorial> call() {
    return repository.obtenerLecturasRecientes();
  }
}