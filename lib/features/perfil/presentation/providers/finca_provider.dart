import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/finca_mock_datasource.dart';
import '../../data/repositories/finca_repository_impl.dart';
import '../../domain/entities/finca.dart';
import '../../domain/repositories/finca_repository.dart';
import '../../domain/usecases/obtener_finca.dart';

final fincaMockDatasourceProvider = Provider<FincaMockDatasource>((ref) {
  return const FincaMockDatasource();
});

//Provider del repositorio 
final fincaRepositoryProvider = Provider<FincaRepository>((ref) {
  final datasource = ref.watch(fincaMockDatasourceProvider);

  return FincaRepositoryImpl(
    datasource: datasource,
  );
});

//Provider del caso de uso.
final obtenerFincaProvider = Provider<ObtenerFinca>((ref) {
  final repository = ref.watch(fincaRepositoryProvider);

  return ObtenerFinca(
    repository: repository,
  );
});

// Provider consumido por la pantalla de perfil.
final fincaProvider = Provider<Finca>((ref) {
  final obtenerFinca = ref.watch(obtenerFincaProvider);

  return obtenerFinca();
});