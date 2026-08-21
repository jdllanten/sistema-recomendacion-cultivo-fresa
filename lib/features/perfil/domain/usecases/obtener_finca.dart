import '../entities/finca.dart';
import '../repositories/finca_repository.dart';

class ObtenerFinca {
  const ObtenerFinca({
    required this.repository,
  });

  final FincaRepository repository;

  Finca call() {
    return repository.obtenerFinca();
  }
}