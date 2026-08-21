import '../../domain/entities/lectura_historial.dart';
import '../../domain/repositories/historial_repository.dart';
import '../datasources/historial_local_datasource.dart';
import '../datasources/historial_mock_datasource.dart';

// Implementación concreta del repositorio de historial.
// Prioriza datos locales guardados en Hive.
// Si todavía no hay lecturas locales, muestra datos simulados.
class HistorialRepositoryImpl implements HistorialRepository {
  const HistorialRepositoryImpl({
    required this.mockDatasource,
    required this.localDatasource,
  });

  final HistorialMockDatasource mockDatasource;
  final HistorialLocalDatasource localDatasource;

  @override
  List<LecturaHistorial> obtenerLecturasRecientes() {
    final lecturasLocales = localDatasource.obtenerLecturas();

    if (lecturasLocales.isNotEmpty) {
      return lecturasLocales;
    }

    return mockDatasource.obtenerLecturasRecientes();
  }

  @override
  Future<void> guardarLectura(LecturaHistorial lectura) {
    return localDatasource.guardarLectura(lectura);
  }

  @override
  Future<void> limpiarHistorial() {
    return localDatasource.limpiar();
  }
}