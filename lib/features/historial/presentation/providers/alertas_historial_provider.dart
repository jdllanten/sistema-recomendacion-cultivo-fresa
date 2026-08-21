import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/datasources/alertas_remoto_datasource.dart';
import '../../domain/entities/alerta_critica_historial.dart';

final alertasRemotoDatasourceProvider =
    Provider<AlertasRemotoDatasource>((ref) {
  return AlertasRemotoDatasource();
});

final alertasCriticasHistorialProvider =
    FutureProvider<List<AlertaCriticaHistorial>>((ref) async {
  final datasource = ref.watch(alertasRemotoDatasourceProvider);

  return datasource.obtenerAlertasRecientes(limite: 50);
});