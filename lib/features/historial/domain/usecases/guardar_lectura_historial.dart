import '../entities/lectura_historial.dart';
import '../repositories/historial_repository.dart';

//Caso de uso para guardar una lectura histórica.
class GuardarLecturaHistorial {
  const GuardarLecturaHistorial({
    required this.repository,
  });

  final HistorialRepository repository;

  Future<void> call(LecturaHistorial lectura) {
    return repository.guardarLectura(lectura);
  }
}