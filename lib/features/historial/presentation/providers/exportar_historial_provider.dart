import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/exportar_historial_csv_service.dart';

final exportarHistorialCsvServiceProvider =
    Provider<ExportarHistorialCsvService>((ref) {
  return ExportarHistorialCsvService();
});