import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/services/exportar_reporte_pdf_service.dart';

final exportarReportePdfServiceProvider =
    Provider<ExportarReportePdfService>((ref) {
  return ExportarReportePdfService();
});