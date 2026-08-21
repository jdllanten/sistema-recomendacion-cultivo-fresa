import '../entities/lectura_historial.dart';

abstract class HistorialRepository {
  List<LecturaHistorial> obtenerLecturasRecientes();

  Future<void> guardarLectura(LecturaHistorial lectura);

  Future<void> limpiarHistorial();
}