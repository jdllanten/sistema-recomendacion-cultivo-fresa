import '../repositories/historial_repository.dart';

//Caso de uso para limpiar el historial local.
class LimpiarHistorial {
  const LimpiarHistorial({
    required this.repository,
  });

  final HistorialRepository repository;

  Future<void> call() {
    return repository.limpiarHistorial();
  }
}