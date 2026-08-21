import '../../domain/entities/finca.dart';
import '../../domain/repositories/finca_repository.dart';
import '../datasources/finca_mock_datasource.dart';

class FincaRepositoryImpl implements FincaRepository {
  const FincaRepositoryImpl({
    required this.datasource,
  });

  final FincaMockDatasource datasource;

  @override
  Finca obtenerFinca() {
    return datasource.obtenerFinca();
  }
}