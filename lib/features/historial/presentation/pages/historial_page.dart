import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tema/app_colores.dart';
import '../../domain/entities/alerta_critica_historial.dart';
import '../../domain/entities/lectura_historial.dart';
import '../providers/alertas_historial_provider.dart';
import '../providers/exportar_historial_provider.dart';
import '../providers/exportar_reporte_pdf_provider.dart';
import '../providers/historial_provider.dart';

enum FiltroHistorial { hoy, semana, mes, todo }

enum PeriodoReportePdf {
  hoy,
  ayer,
  ultimos7Dias,
  ultimos30Dias,
  todo,
}

class HistorialPage extends ConsumerStatefulWidget {
  const HistorialPage({super.key});

  @override
  ConsumerState<HistorialPage> createState() => _HistorialPageState();
}

class _HistorialPageState extends ConsumerState<HistorialPage> {
  FiltroHistorial _filtro = FiltroHistorial.semana;

  @override
  Widget build(BuildContext context) {
    final todasLecturas = ref.watch(historialLecturasProvider);
    final lecturas = _filtrarLecturas(todasLecturas);
    final alertasAsync = ref.watch(alertasCriticasHistorialProvider);

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
              child: Column(
                children: [
                  const _TituloHistorialHeader(),
                  const SizedBox(height: 14),
                  _AccionesExportacionHistorialCard(
                    deshabilitado: todasLecturas.isEmpty,
                    onExportarPdf: () async {
                      await _exportarReportePdf(
                        context: context,
                        ref: ref,
                        todasLecturas: todasLecturas,
                        alertasAsync: alertasAsync,
                      );
                    },
                    onExportarCsv: () async {
                      await _exportarCsv(
                        context: context,
                        ref: ref,
                        todasLecturas: todasLecturas,
                      );
                    },
                  ),
                  const SizedBox(height: 12),
                  _SelectorPeriodo(
                    filtroActual: _filtro,
                    onFiltroChanged: (filtro) {
                      setState(() {
                        _filtro = filtro;
                      });
                    },
                  ),
                ],
              ),
            ),
            Expanded(
              child: todasLecturas.isEmpty
                  ? const _HistorialVacio(
                      mensaje:
                          'Todavía no hay lecturas guardadas. Cuando lleguen datos por MQTT se almacenarán aquí.',
                    )
                  : lecturas.isEmpty
                      ? _HistorialVacio(
                          mensaje:
                              'No hay lecturas para ${_etiquetaPeriodo()}. Prueba seleccionando otro período.',
                        )
                      : _ContenidoHistorial(
                          lecturas: lecturas,
                          etiquetaPeriodo: _etiquetaPeriodo(),
                        ),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _exportarCsv({
    required BuildContext context,
    required WidgetRef ref,
    required List<LecturaHistorial> todasLecturas,
  }) async {
    final exportador = ref.read(exportarHistorialCsvServiceProvider);

    try {
      await exportador.compartirCsv(todasLecturas);

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'CSV generado con ${todasLecturas.length} lecturas.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo exportar el historial: $e',
            ),
          ),
        );
      }
    }
  }

  List<LecturaHistorial> _filtrarLecturas(List<LecturaHistorial> todas) {
    final ahora = DateTime.now();

    switch (_filtro) {
      case FiltroHistorial.hoy:
        final lecturas = todas.where((lectura) {
          return _esMismoDia(lectura.fechaLectura, ahora);
        }).toList();

        lecturas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return lecturas;

      case FiltroHistorial.semana:
        final limite = ahora.subtract(const Duration(days: 7));

        final lecturas = todas.where((lectura) {
          return lectura.fechaLectura.isAfter(limite) ||
              _esMismoDia(lectura.fechaLectura, limite);
        }).toList();

        lecturas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return lecturas;

      case FiltroHistorial.mes:
        final limite = ahora.subtract(const Duration(days: 30));

        final lecturas = todas.where((lectura) {
          return lectura.fechaLectura.isAfter(limite) ||
              _esMismoDia(lectura.fechaLectura, limite);
        }).toList();

        lecturas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return lecturas;

      case FiltroHistorial.todo:
        final lecturas = [...todas];

        lecturas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return lecturas;
    }
  }

  String _etiquetaPeriodo() {
    switch (_filtro) {
      case FiltroHistorial.hoy:
        return 'hoy';
      case FiltroHistorial.semana:
        return 'los últimos 7 días';
      case FiltroHistorial.mes:
        return 'los últimos 30 días';
      case FiltroHistorial.todo:
        return 'todo el historial';
    }
  }

  Future<void> _exportarReportePdf({
    required BuildContext context,
    required WidgetRef ref,
    required List<LecturaHistorial> todasLecturas,
    required AsyncValue<List<AlertaCriticaHistorial>> alertasAsync,
  }) async {
    final periodo = _periodoReporteDesdeFiltro(_filtro);
    final etiquetaPeriodo = _etiquetaPeriodoReporte(periodo);
    final tipoReporte = _tipoReportePdf(periodo);

    final lecturasFiltradas = _filtrarLecturasParaReporte(
      todasLecturas,
      periodo,
    );

    if (lecturasFiltradas.isEmpty) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No hay lecturas disponibles para $etiquetaPeriodo.',
            ),
          ),
        );
      }

      return;
    }

    final alertas = alertasAsync.maybeWhen(
      data: (value) => value,
      orElse: () => const <AlertaCriticaHistorial>[],
    );

    final alertasFiltradas = _filtrarAlertasParaReporte(
      alertas,
      periodo,
    );

    final exportador = ref.read(exportarReportePdfServiceProvider);

    try {
      await exportador.compartirReporte(
        lecturas: lecturasFiltradas,
        alertas: alertasFiltradas,
        periodoEtiqueta: etiquetaPeriodo,
        tipoReporte: tipoReporte,
      );

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Reporte PDF generado con ${lecturasFiltradas.length} lecturas.',
            ),
          ),
        );
      }
    } catch (e) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'No se pudo generar el reporte PDF: $e',
            ),
          ),
        );
      }
    }
  }

  Future<PeriodoReportePdf?> _seleccionarPeriodoReportePdf(
    BuildContext context,
  ) {
    return showDialog<PeriodoReportePdf>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Periodo del reporte'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  leading: const Icon(Icons.today_outlined),
                  title: const Text('Hoy'),
                  subtitle: const Text('Reporte diario parcial del día actual'),
                  onTap: () {
                    Navigator.of(context).pop(PeriodoReportePdf.hoy);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.history_outlined),
                  title: const Text('Ayer'),
                  subtitle: const Text('Reporte diario cerrado del día anterior'),
                  onTap: () {
                    Navigator.of(context).pop(PeriodoReportePdf.ayer);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.date_range_outlined),
                  title: const Text('Últimos 7 días'),
                  subtitle: const Text('Reporte semanal del cultivo'),
                  onTap: () {
                    Navigator.of(context).pop(PeriodoReportePdf.ultimos7Dias);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.calendar_month_outlined),
                  title: const Text('Últimos 30 días'),
                  subtitle: const Text('Reporte mensual del cultivo'),
                  onTap: () {
                    Navigator.of(context).pop(PeriodoReportePdf.ultimos30Dias);
                  },
                ),
                ListTile(
                  leading: const Icon(Icons.all_inbox_outlined),
                  title: const Text('Todo el historial'),
                  subtitle: const Text('Incluye todas las lecturas guardadas'),
                  onTap: () {
                    Navigator.of(context).pop(PeriodoReportePdf.todo);
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  List<LecturaHistorial> _filtrarLecturasParaReporte(
    List<LecturaHistorial> lecturas,
    PeriodoReportePdf periodo,
  ) {
    final ahora = DateTime.now();

    switch (periodo) {
      case PeriodoReportePdf.hoy:
        final filtradas = lecturas.where((lectura) {
          return _esMismoDia(lectura.fechaLectura, ahora);
        }).toList();

        filtradas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return filtradas;

      case PeriodoReportePdf.ayer:
        final ayer = ahora.subtract(const Duration(days: 1));

        final filtradas = lecturas.where((lectura) {
          return _esMismoDia(lectura.fechaLectura, ayer);
        }).toList();

        filtradas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return filtradas;

      case PeriodoReportePdf.ultimos7Dias:
        final desde = ahora.subtract(const Duration(days: 7));

        final filtradas = lecturas.where((lectura) {
          return lectura.fechaLectura.isAfter(desde) ||
              _esMismoDia(lectura.fechaLectura, desde);
        }).toList();

        filtradas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return filtradas;

      case PeriodoReportePdf.ultimos30Dias:
        final desde = ahora.subtract(const Duration(days: 30));

        final filtradas = lecturas.where((lectura) {
          return lectura.fechaLectura.isAfter(desde) ||
              _esMismoDia(lectura.fechaLectura, desde);
        }).toList();

        filtradas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return filtradas;

      case PeriodoReportePdf.todo:
        final filtradas = [...lecturas];

        filtradas.sort(
          (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
        );

        return filtradas;
    }
  }

  List<AlertaCriticaHistorial> _filtrarAlertasParaReporte(
    List<AlertaCriticaHistorial> alertas,
    PeriodoReportePdf periodo,
  ) {
    final ahora = DateTime.now();

    switch (periodo) {
      case PeriodoReportePdf.hoy:
        final filtradas = alertas.where((alerta) {
          return _esMismoDia(alerta.creadaEn, ahora);
        }).toList();

        filtradas.sort(
          (a, b) => b.creadaEn.compareTo(a.creadaEn),
        );

        return filtradas;

      case PeriodoReportePdf.ayer:
        final ayer = ahora.subtract(const Duration(days: 1));

        final filtradas = alertas.where((alerta) {
          return _esMismoDia(alerta.creadaEn, ayer);
        }).toList();

        filtradas.sort(
          (a, b) => b.creadaEn.compareTo(a.creadaEn),
        );

        return filtradas;

      case PeriodoReportePdf.ultimos7Dias:
        final desde = ahora.subtract(const Duration(days: 7));

        final filtradas = alertas.where((alerta) {
          return alerta.creadaEn.isAfter(desde) ||
              _esMismoDia(alerta.creadaEn, desde);
        }).toList();

        filtradas.sort(
          (a, b) => b.creadaEn.compareTo(a.creadaEn),
        );

        return filtradas;

      case PeriodoReportePdf.ultimos30Dias:
        final desde = ahora.subtract(const Duration(days: 30));

        final filtradas = alertas.where((alerta) {
          return alerta.creadaEn.isAfter(desde) ||
              _esMismoDia(alerta.creadaEn, desde);
        }).toList();

        filtradas.sort(
          (a, b) => b.creadaEn.compareTo(a.creadaEn),
        );

        return filtradas;

      case PeriodoReportePdf.todo:
        final filtradas = [...alertas];

        filtradas.sort(
          (a, b) => b.creadaEn.compareTo(a.creadaEn),
        );

        return filtradas;
    }
  }

  String _etiquetaPeriodoReporte(PeriodoReportePdf periodo) {
    switch (periodo) {
      case PeriodoReportePdf.hoy:
        return 'hoy';
      case PeriodoReportePdf.ayer:
        return 'ayer';
      case PeriodoReportePdf.ultimos7Dias:
        return 'los últimos 7 días';
      case PeriodoReportePdf.ultimos30Dias:
        return 'los últimos 30 días';
      case PeriodoReportePdf.todo:
        return 'todo el historial';
    }
  }

  PeriodoReportePdf _periodoReporteDesdeFiltro(FiltroHistorial filtro) {
    switch (filtro) {
      case FiltroHistorial.hoy:
        return PeriodoReportePdf.hoy;
      case FiltroHistorial.semana:
        return PeriodoReportePdf.ultimos7Dias;
      case FiltroHistorial.mes:
        return PeriodoReportePdf.ultimos30Dias;
      case FiltroHistorial.todo:
        return PeriodoReportePdf.todo;
    }
  }

  String _tipoReportePdf(PeriodoReportePdf periodo) {
    switch (periodo) {
      case PeriodoReportePdf.hoy:
        return 'Reporte diario';
      case PeriodoReportePdf.ayer:
        return 'Reporte diario';
      case PeriodoReportePdf.ultimos7Dias:
        return 'Reporte semanal';
      case PeriodoReportePdf.ultimos30Dias:
        return 'Reporte mensual';
      case PeriodoReportePdf.todo:
        return 'Reporte general';
    }
  }

  bool _esMismoDia(DateTime a, DateTime b) {
    return a.year == b.year && a.month == b.month && a.day == b.day;
  }
}


class _TituloHistorialHeader extends StatelessWidget {
  const _TituloHistorialHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColores.primario.withOpacity(0.14),
            ),
          ),
          child: const Icon(
            Icons.timeline_rounded,
            color: AppColores.primario,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Historial de mediciones',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: AppColores.textoPrincipal,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Seguimiento gráfico de las variables del suelo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _AccionesExportacionHistorialCard extends StatelessWidget {
  const _AccionesExportacionHistorialCard({
    required this.deshabilitado,
    required this.onExportarPdf,
    required this.onExportarCsv,
  });

  final bool deshabilitado;
  final VoidCallback onExportarPdf;
  final VoidCallback onExportarCsv;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: FilledButton.icon(
            onPressed: deshabilitado ? null : onExportarPdf,
            icon: const Icon(Icons.picture_as_pdf_outlined, size: 19),
            label: const Text(
              'Reporte PDF',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: FilledButton.styleFrom(
              backgroundColor: AppColores.primario,
              foregroundColor: Colors.white,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: OutlinedButton.icon(
            onPressed: deshabilitado ? null : onExportarCsv,
            icon: const Icon(Icons.file_download_outlined, size: 19),
            label: const Text(
              'Descargar CSV',
              style: TextStyle(fontWeight: FontWeight.w900),
            ),
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(15),
              ),
            ),
          ),
        ),
      ],
    );
  }
}


class _SelectorPeriodo extends StatelessWidget {
  const _SelectorPeriodo({
    required this.filtroActual,
    required this.onFiltroChanged,
  });

  final FiltroHistorial filtroActual;
  final ValueChanged<FiltroHistorial> onFiltroChanged;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: double.infinity,
      child: SegmentedButton<FiltroHistorial>(
        style: SegmentedButton.styleFrom(
          textStyle: const TextStyle(
            fontSize: 12.5,
            fontWeight: FontWeight.w800,
          ),
        ),
        segments: const [
          ButtonSegment(
            value: FiltroHistorial.hoy,
            label: Text('Hoy'),
          ),
          ButtonSegment(
            value: FiltroHistorial.semana,
            label: Text('Semana'),
          ),
          ButtonSegment(
            value: FiltroHistorial.mes,
            label: Text('Mes'),
          ),
          ButtonSegment(
            value: FiltroHistorial.todo,
            label: Text('Todo'),
          ),
        ],
        selected: {filtroActual},
        onSelectionChanged: (Set<FiltroHistorial> seleccion) {
          onFiltroChanged(seleccion.first);
        },
      ),
    );
  }
}

class _ContenidoHistorial extends StatelessWidget {
  const _ContenidoHistorial({
    required this.lecturas,
    required this.etiquetaPeriodo,
  });

  final List<LecturaHistorial> lecturas;
  final String etiquetaPeriodo;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 6, 16, 24),
      children: [
        _ResumenHistorialCard(
          totalLecturas: lecturas.length,
          ultimaLectura: lecturas.last,
          etiquetaPeriodo: etiquetaPeriodo,
        ),
        const SizedBox(height: 18),
        _seccionTitulo(
          'Variables del suelo',
          'Promedio por lote y gráfica desplegable por variable.',
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'Humedad del suelo',
          descripcion: 'Disponibilidad de agua en el suelo.',
          unidad: '%',
          color: AppColores.primario,
          minY: 0,
          maxY: 100,
          lecturas: lecturas,
          obtenerValor: (l) => l.humedad,
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'Temperatura del suelo',
          descripcion: 'Temperatura registrada por el sensor.',
          unidad: '°C',
          color: Colors.orange,
          minY: 0,
          maxY: 40,
          lecturas: lecturas,
          obtenerValor: (l) => l.temperatura,
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'pH del suelo',
          descripcion: 'Acidez o alcalinidad del suelo.',
          unidad: '',
          color: Colors.purple,
          minY: 0,
          maxY: 14,
          lecturas: lecturas,
          obtenerValor: (l) => l.ph,
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'Conductividad eléctrica',
          descripcion: 'Nivel de sales disueltas en el suelo.',
          unidad: 'dS/m',
          color: Colors.blue,
          minY: 0,
          maxY: 5,
          lecturas: lecturas,
          obtenerValor: (l) => l.ec,
        ),
        const SizedBox(height: 18),
        _seccionTitulo(
          'Nutrientes NPK',
          'Promedio de nitrógeno, fósforo y potasio por lote.',
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'Nitrógeno (N)',
          descripcion: 'Nutriente asociado al crecimiento vegetativo.',
          unidad: 'mg/kg',
          color: const Color(0xFF20B486),
          minY: 0,
          maxY: 180,
          lecturas: lecturas,
          obtenerValor: (l) => l.nitrogeno,
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'Fósforo (P)',
          descripcion: 'Nutriente asociado a raíz, floración y energía.',
          unidad: 'mg/kg',
          color: const Color(0xFFE0A11B),
          minY: 0,
          maxY: 100,
          lecturas: lecturas,
          obtenerValor: (l) => l.fosforo,
        ),
        const SizedBox(height: 12),
        _VariableHistorialResumenCard(
          titulo: 'Potasio (K)',
          descripcion: 'Nutriente asociado a calidad y llenado del fruto.',
          unidad: 'mg/kg',
          color: const Color(0xFFD64545),
          minY: 0,
          maxY: 220,
          lecturas: lecturas,
          obtenerValor: (l) => l.potasio,
        ),
      ],
    );
  }

  Widget _seccionTitulo(String titulo, String descripcion) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          titulo,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),
        const SizedBox(height: 3),
        Text(
          descripcion,
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontSize: 13,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}

class _VariableHistorialResumenCard extends StatelessWidget {
  const _VariableHistorialResumenCard({
    required this.titulo,
    required this.descripcion,
    required this.unidad,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.lecturas,
    required this.obtenerValor,
  });

  final String titulo;
  final String descripcion;
  final String unidad;
  final Color color;
  final double minY;
  final double maxY;
  final List<LecturaHistorial> lecturas;
  final double Function(LecturaHistorial) obtenerValor;

  @override
  Widget build(BuildContext context) {
    final resumenes = _resumenesPorLote();
    final promedioGeneral = _promedio(lecturas.map(obtenerValor).toList());

    return Container(
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.fromLTRB(14, 12, 12, 12),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: color,
          collapsedIconColor: AppColores.textoSecundario,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(13),
            ),
            child: Icon(
              _iconoVariable(titulo),
              color: color,
              size: 21,
            ),
          ),
          title: Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              _PromedioGeneralPill(
                valor: promedioGeneral,
                unidad: unidad,
                color: color,
              ),
            ],
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 7),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PromediosPorLoteList(
                  resumenes: resumenes,
                  unidad: unidad,
                  color: color,
                ),
                const SizedBox(height: 6),
                Text(
                  'Toca para ver la gráfica de $titulo',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.4,
                    height: 1.15,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          children: [
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                descripcion,
                style: const TextStyle(
                  fontSize: 12.2,
                  height: 1.30,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoSecundario,
                ),
              ),
            ),
            const SizedBox(height: 12),
            _GraficaPorLoteSelector(
              titulo: titulo,
              unidad: unidad,
              color: color,
              minY: minY,
              maxY: maxY,
              lecturas: lecturas,
              obtenerValor: obtenerValor,
            ),
          ],
        ),
      ),
    );
  }

  List<_ResumenLoteHistorial> _resumenesPorLote() {
    final agrupadas = <String, List<LecturaHistorial>>{};

    for (final lectura in lecturas) {
      final nombre = _nombreLoteLectura(lectura);
      agrupadas.putIfAbsent(nombre, () => <LecturaHistorial>[]).add(lectura);
    }

    final resumenes = agrupadas.entries.map((entry) {
      final valores = entry.value.map(obtenerValor).toList();
      return _ResumenLoteHistorial(
        loteNombre: entry.key,
        promedio: _promedio(valores),
        cantidad: entry.value.length,
        ultimaLectura: entry.value.last.fechaLectura,
      );
    }).toList();

    resumenes.sort(
      (a, b) => a.loteNombre.toLowerCase().compareTo(b.loteNombre.toLowerCase()),
    );

    return resumenes;
  }
}


class _PromediosPorLoteCompactWrap extends StatelessWidget {
  const _PromediosPorLoteCompactWrap({
    required this.resumenes,
    required this.unidad,
    required this.color,
  });

  final List<_ResumenLoteHistorial> resumenes;
  final String unidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    if (resumenes.isEmpty) {
      return const Text(
        'Sin datos por lote en este periodo.',
        style: TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w700,
          color: AppColores.textoSecundario,
        ),
      );
    }

    return Wrap(
      spacing: 6,
      runSpacing: 6,
      children: resumenes.map((resumen) {
        return Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
          decoration: BoxDecoration(
            color: color.withOpacity(0.07),
            borderRadius: BorderRadius.circular(999),
            border: Border.all(color: color.withOpacity(0.13)),
          ),
          child: RichText(
            text: TextSpan(
              style: const TextStyle(
                fontSize: 10.8,
                height: 1,
                color: AppColores.textoSecundario,
                fontWeight: FontWeight.w800,
              ),
              children: [
                TextSpan(text: '${resumen.loteNombre}: '),
                TextSpan(
                  text:
                      '${_formatearNumero(resumen.promedio)}${unidad.isEmpty ? '' : ' $unidad'}',
                  style: TextStyle(
                    color: color,
                    fontWeight: FontWeight.w900,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }
}

class _PromedioGeneralPill extends StatelessWidget {
  const _PromedioGeneralPill({
    required this.valor,
    required this.unidad,
    required this.color,
  });

  final double valor;
  final String unidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Text(
        'Prom. ${_formatearNumero(valor)}${unidad.isEmpty ? '' : ' $unidad'}',
        style: TextStyle(
          fontSize: 10.8,
          height: 1,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _PromediosPorLoteList extends StatelessWidget {
  const _PromediosPorLoteList({
    required this.resumenes,
    required this.unidad,
    required this.color,
  });

  final List<_ResumenLoteHistorial> resumenes;
  final String unidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        children: [
          for (var i = 0; i < resumenes.length; i++) ...[
            _PromedioLoteRow(
              resumen: resumenes[i],
              unidad: unidad,
              color: color,
            ),
            if (i != resumenes.length - 1)
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Divider(
                  height: 1,
                  color: AppColores.borde.withOpacity(0.8),
                ),
              ),
          ],
        ],
      ),
    );
  }
}

class _PromedioLoteRow extends StatelessWidget {
  const _PromedioLoteRow({
    required this.resumen,
    required this.unidad,
    required this.color,
  });

  final _ResumenLoteHistorial resumen;
  final String unidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: color.withOpacity(0.10),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Icon(
            Icons.grass_rounded,
            size: 16,
            color: color,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                resumen.loteNombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12.6,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                '${resumen.cantidad} lectura${resumen.cantidad == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 10.8,
                  fontWeight: FontWeight.w700,
                  color: AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(width: 8),
        Text(
          '${_formatearNumero(resumen.promedio)}${unidad.isEmpty ? '' : ' $unidad'}',
          style: TextStyle(
            fontSize: 13.2,
            fontWeight: FontWeight.w900,
            color: color,
          ),
        ),
      ],
    );
  }
}

class _GraficaPorLoteSelector extends StatefulWidget {
  const _GraficaPorLoteSelector({
    required this.titulo,
    required this.unidad,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.lecturas,
    required this.obtenerValor,
  });

  final String titulo;
  final String unidad;
  final Color color;
  final double minY;
  final double maxY;
  final List<LecturaHistorial> lecturas;
  final double Function(LecturaHistorial) obtenerValor;

  @override
  State<_GraficaPorLoteSelector> createState() => _GraficaPorLoteSelectorState();
}

class _GraficaPorLoteSelectorState extends State<_GraficaPorLoteSelector> {
  String _loteSeleccionado = 'Todos';

  @override
  Widget build(BuildContext context) {
    final lotes = _lotesDisponibles(widget.lecturas);

    if (!lotes.contains(_loteSeleccionado)) {
      _loteSeleccionado = 'Todos';
    }

    final lecturasFiltradas = _loteSeleccionado == 'Todos'
        ? widget.lecturas
        : widget.lecturas
            .where((lectura) => _nombreLoteLectura(lectura) == _loteSeleccionado)
            .toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mostrar gráfica',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),
        const SizedBox(height: 9),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: [
              for (final lote in lotes) ...[
                _LoteFiltroChip(
                  texto: lote,
                  seleccionado: _loteSeleccionado == lote,
                  color: widget.color,
                  onTap: () {
                    setState(() {
                      _loteSeleccionado = lote;
                    });
                  },
                ),
                const SizedBox(width: 8),
              ],
            ],
          ),
        ),
        const SizedBox(height: 12),
        if (_loteSeleccionado == 'Todos')
          _GraficaTodosLotesCard(
            titulo: widget.titulo,
            unidad: widget.unidad,
            minY: widget.minY,
            maxY: widget.maxY,
            lecturas: widget.lecturas,
            obtenerValor: widget.obtenerValor,
          )
        else if (lecturasFiltradas.length < 2)
          _SinDatosGraficaVariable(color: widget.color)
        else
          _GraficaHistorialCard(
            titulo: '${widget.titulo} · $_loteSeleccionado',
            unidad: widget.unidad,
            color: widget.color,
            minY: widget.minY,
            maxY: widget.maxY,
            lecturas: lecturasFiltradas,
            obtenerValor: widget.obtenerValor,
          ),
      ],
    );
  }
}

class _LoteFiltroChip extends StatelessWidget {
  const _LoteFiltroChip({
    required this.texto,
    required this.seleccionado,
    required this.color,
    required this.onTap,
  });

  final String texto;
  final bool seleccionado;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(999),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.13) : AppColores.superficie,
          borderRadius: BorderRadius.circular(999),
          border: Border.all(
            color: seleccionado ? color.withOpacity(0.55) : AppColores.borde,
            width: seleccionado ? 1.3 : 1,
          ),
        ),
        child: Text(
          texto,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w900,
            color: seleccionado ? color : AppColores.textoSecundario,
          ),
        ),
      ),
    );
  }
}

class _SinDatosGraficaVariable extends StatelessWidget {
  const _SinDatosGraficaVariable({required this.color});

  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.045),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: const Text(
        'Se necesitan al menos 2 lecturas para graficar esta variable.',
        style: TextStyle(
          fontSize: 12.2,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }
}

class _ResumenLoteHistorial {
  const _ResumenLoteHistorial({
    required this.loteNombre,
    required this.promedio,
    required this.cantidad,
    required this.ultimaLectura,
  });

  final String loteNombre;
  final double promedio;
  final int cantidad;
  final DateTime ultimaLectura;
}

IconData _iconoVariable(String titulo) {
  final texto = titulo.toLowerCase();

  if (texto.contains('humedad')) return Icons.water_drop_rounded;
  if (texto.contains('temperatura')) return Icons.thermostat_rounded;
  if (texto.contains('ph')) return Icons.science_rounded;
  if (texto.contains('conductividad')) return Icons.bolt_rounded;
  if (texto.contains('nitrógeno') || texto.contains('nitrogeno')) {
    return Icons.eco_rounded;
  }
  if (texto.contains('fósforo') || texto.contains('fosforo')) {
    return Icons.spa_rounded;
  }
  if (texto.contains('potasio')) return Icons.local_florist_rounded;

  return Icons.analytics_rounded;
}

String _nombreLoteLectura(LecturaHistorial lectura) {
  final nombre = lectura.loteNombre.trim();

  if (nombre.isNotEmpty) return nombre;

  final loteId = lectura.loteId.trim();
  if (loteId.isEmpty) return 'Lote sin definir';

  return loteId
      .replaceAll('_', ' ')
      .split(' ')
      .where((parte) => parte.trim().isNotEmpty)
      .map((parte) => '${parte[0].toUpperCase()}${parte.substring(1)}')
      .join(' ');
}

List<String> _lotesDisponibles(List<LecturaHistorial> lecturas) {
  final nombres = lecturas.map(_nombreLoteLectura).toSet().toList()
    ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

  return <String>['Todos', ...nombres];
}

double _promedio(List<double> valores) {
  if (valores.isEmpty) return 0;
  final suma = valores.reduce((a, b) => a + b);
  return suma / valores.length;
}

String _formatearNumero(double valor) {
  if (valor % 1 == 0) return valor.toInt().toString();
  return valor.toStringAsFixed(1);
}


class _HistorialVacio extends StatelessWidget {
  const _HistorialVacio({
    required this.mensaje,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.history_rounded,
              size: 56,
              color: AppColores.primario.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              mensaje,
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: AppColores.textoSecundario,
                height: 1.5,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ResumenHistorialCard extends StatelessWidget {
  const _ResumenHistorialCard({
    required this.totalLecturas,
    required this.ultimaLectura,
    required this.etiquetaPeriodo,
  });

  final int totalLecturas;
  final LecturaHistorial ultimaLectura;
  final String etiquetaPeriodo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 46,
              height: 46,
              decoration: BoxDecoration(
                color: AppColores.primariosuave,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.analytics_rounded,
                color: AppColores.primario,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$totalLecturas lecturas · $etiquetaPeriodo',
                    style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Última lectura a las ${ultimaLectura.hora}',
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GraficaTodosLotesCard extends StatelessWidget {
  const _GraficaTodosLotesCard({
    required this.titulo,
    required this.unidad,
    required this.minY,
    required this.maxY,
    required this.lecturas,
    required this.obtenerValor,
  });

  final String titulo;
  final String unidad;
  final double minY;
  final double maxY;
  final List<LecturaHistorial> lecturas;
  final double Function(LecturaHistorial) obtenerValor;

  static const List<Color> _paletaLotes = <Color>[
    Color(0xFF2E7D32),
    Color(0xFF1565C0),
    Color(0xFFEF6C00),
    Color(0xFF7B1FA2),
    Color(0xFFC62828),
    Color(0xFF00838F),
    Color(0xFF6D4C41),
    Color(0xFF455A64),
  ];

  @override
  Widget build(BuildContext context) {
    final series = _crearSeries();

    final seriesGraficables =
        series.where((serie) => serie.lecturas.length >= 2).toList();

    if (seriesGraficables.isEmpty) {
      return const _SinDatosGraficaVariable(
        color: AppColores.primario,
      );
    }

    final todasGraficables = seriesGraficables
        .expand((serie) => serie.lecturas)
        .toList()
      ..sort((a, b) => a.fechaLectura.compareTo(b.fechaLectura));

    final fechaInicial = todasGraficables.first.fechaLectura;
    final fechaFinal = todasGraficables.last.fechaLectura;

    final rangoHoras = fechaFinal
        .difference(fechaInicial)
        .inMinutes
        .abs() /
        60.0;

    final maxX = rangoHoras <= 0 ? 1.0 : rangoHoras;
    final intervaloX = _intervaloEjeX(maxX);

    final lineBars = <LineChartBarData>[
      for (final serie in seriesGraficables)
        LineChartBarData(
          spots: [
            for (final lectura in _muestrearSerie(serie.lecturas))
              FlSpot(
                _xDesdeFecha(
                  lectura.fechaLectura,
                  fechaInicial,
                ),
                obtenerValor(lectura),
              ),
          ],
          isCurved: true,
          curveSmoothness: 0.25,
          color: serie.color,
          barWidth: 2.4,
          isStrokeCapRound: true,
          dotData: FlDotData(
            show: serie.lecturas.length <= 16,
            getDotPainter: (_, __, ___, ____) {
              return FlDotCirclePainter(
                radius: 2.8,
                color: serie.color,
                strokeWidth: 1.2,
                strokeColor: Colors.white,
              );
            },
          ),
          belowBarData: BarAreaData(show: false),
        ),
    ];

    final valores = todasGraficables.map(obtenerValor).toList();
    final promedioGeneral = _promedio(valores);

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColores.borde.withOpacity(0.95),
          width: 1.1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.multiline_chart_rounded,
                  color: AppColores.textoPrincipal,
                  size: 19,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '$titulo · Todos los lotes',
                    style: const TextStyle(
                      color: AppColores.textoPrincipal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: AppColores.fondo,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: AppColores.borde),
                  ),
                  child: Text(
                    'Prom. ${_numero(promedioGeneral)}${unidad.isNotEmpty ? ' $unidad' : ''}',
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      fontWeight: FontWeight.w900,
                      fontSize: 11.5,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 11),

            Wrap(
              spacing: 10,
              runSpacing: 8,
              children: [
                for (final serie in series)
                  _LeyendaLoteGrafica(
                    nombre: serie.nombre,
                    color: serie.color,
                    cantidad: serie.lecturas.length,
                    disponible: serie.lecturas.length >= 2,
                  ),
              ],
            ),

            const SizedBox(height: 14),

            SizedBox(
              height: 180,
              child: LineChart(
                LineChartData(
                  minX: 0,
                  maxX: maxX,
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColores.borde.withOpacity(0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) =>
                          AppColores.textoPrincipal.withOpacity(0.90),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          final indiceSerie = spot.barIndex;
                          final nombre =
                              indiceSerie >= 0 &&
                                      indiceSerie < seriesGraficables.length
                                  ? seriesGraficables[indiceSerie].nombre
                                  : 'Lote';

                          return LineTooltipItem(
                            '$nombre\n${_numero(spot.y)}${unidad.isNotEmpty ? ' $unidad' : ''}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 11.5,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (value, _) => Text(
                          _numero(value),
                          style: const TextStyle(
                            color: AppColores.textoSecundario,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 28,
                        interval: intervaloX,
                        getTitlesWidget: (value, meta) {
                          if (value < 0 || value > maxX + 0.001) {
                            return const SizedBox.shrink();
                          }

                          final fecha = fechaInicial.add(
                            Duration(
                              minutes: (value * 60).round(),
                            ),
                          );

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _etiquetaFechaEje(
                                fecha,
                                fechaInicial,
                                fechaFinal,
                              ),
                              style: const TextStyle(
                                color: AppColores.textoSecundario,
                                fontSize: 9.5,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: lineBars,
                ),
              ),
            ),

            const SizedBox(height: 10),

            Text(
              'Cada línea corresponde a un lote diferente. '
              'El promedio mostrado arriba resume todas las lecturas visibles, '
              'pero las curvas se mantienen separadas para comparar el comportamiento de cada lote.',
              style: TextStyle(
                fontSize: 10.8,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario.withOpacity(0.88),
              ),
            ),
          ],
        ),
      ),
    );
  }

  List<_SerieLoteGrafica> _crearSeries() {
    final agrupadas = <String, List<LecturaHistorial>>{};

    for (final lectura in lecturas) {
      final nombre = _nombreLoteLectura(lectura);

      agrupadas
          .putIfAbsent(nombre, () => <LecturaHistorial>[])
          .add(lectura);
    }

    final nombres = agrupadas.keys.toList()
      ..sort((a, b) => a.toLowerCase().compareTo(b.toLowerCase()));

    return [
      for (var i = 0; i < nombres.length; i++)
        _SerieLoteGrafica(
          nombre: nombres[i],
          color: _paletaLotes[i % _paletaLotes.length],
          lecturas: (agrupadas[nombres[i]]!..sort(
            (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
          )),
        ),
    ];
  }

  List<LecturaHistorial> _muestrearSerie(
    List<LecturaHistorial> originales,
  ) {
    const maxPuntosPorLote = 45;

    if (originales.length <= maxPuntosPorLote) {
      return originales;
    }

    final paso = originales.length / maxPuntosPorLote;
    final resultado = <LecturaHistorial>[];

    for (double i = 0; i < originales.length - 1; i += paso) {
      resultado.add(originales[i.floor()]);
    }

    if (resultado.isEmpty || resultado.last != originales.last) {
      resultado.add(originales.last);
    }

    return resultado;
  }

  double _xDesdeFecha(
    DateTime fecha,
    DateTime inicio,
  ) {
    return fecha.difference(inicio).inMinutes / 60.0;
  }

  double _intervaloEjeX(double rangoHoras) {
    if (rangoHoras <= 6) return 1;
    if (rangoHoras <= 24) return 4;
    if (rangoHoras <= 72) return 12;
    if (rangoHoras <= 168) return 24;

    final calculado = rangoHoras / 5;
    return calculado < 1 ? 1 : calculado;
  }

  String _etiquetaFechaEje(
    DateTime fecha,
    DateTime inicio,
    DateTime fin,
  ) {
    final rango = fin.difference(inicio);

    if (rango.inHours < 24) {
      return '${fecha.hour.toString().padLeft(2, '0')}:'
          '${fecha.minute.toString().padLeft(2, '0')}';
    }

    return '${fecha.day}/${fecha.month}';
  }

  String _numero(double valor) {
    if (valor % 1 == 0) {
      return valor.toInt().toString();
    }

    return valor.toStringAsFixed(1);
  }
}

class _SerieLoteGrafica {
  const _SerieLoteGrafica({
    required this.nombre,
    required this.color,
    required this.lecturas,
  });

  final String nombre;
  final Color color;
  final List<LecturaHistorial> lecturas;
}

class _LeyendaLoteGrafica extends StatelessWidget {
  const _LeyendaLoteGrafica({
    required this.nombre,
    required this.color,
    required this.cantidad,
    required this.disponible,
  });

  final String nombre;
  final Color color;
  final int cantidad;
  final bool disponible;

  @override
  Widget build(BuildContext context) {
    return Opacity(
      opacity: disponible ? 1 : 0.48,
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(
              color: color,
              shape: BoxShape.circle,
            ),
          ),
          const SizedBox(width: 5),
          Text(
            disponible ? nombre : '$nombre · sin gráfica',
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w800,
              color: AppColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _GraficaHistorialCard extends StatelessWidget {
  const _GraficaHistorialCard({
    required this.titulo,
    required this.unidad,
    required this.color,
    required this.minY,
    required this.maxY,
    required this.lecturas,
    required this.obtenerValor,
  });

  final String titulo;
  final String unidad;
  final Color color;
  final double minY;
  final double maxY;
  final List<LecturaHistorial> lecturas;
  final double Function(LecturaHistorial) obtenerValor;

  List<LecturaHistorial> _muestrear() {
    const maxPuntos = 60;

    if (lecturas.length <= maxPuntos) {
      return lecturas;
    }

    final paso = lecturas.length / maxPuntos;
    final resultado = <LecturaHistorial>[];

    for (double i = 0; i < lecturas.length - 1; i += paso) {
      resultado.add(lecturas[i.floor()]);
    }

    if (resultado.isEmpty || resultado.last != lecturas.last) {
      resultado.add(lecturas.last);
    }

    return resultado;
  }

  String _etiquetaX(
    LecturaHistorial lectura,
    List<LecturaHistorial> muestras,
  ) {
    if (muestras.length < 2) {
      return lectura.hora;
    }

    final rango = muestras.last.fechaLectura.difference(
      muestras.first.fechaLectura,
    );

    if (rango.inHours < 24) {
      return lectura.hora;
    }

    final fecha = lectura.fechaLectura;

    return '${fecha.day}/${fecha.month}';
  }

  @override
  Widget build(BuildContext context) {
    final muestras = _muestrear();
    final valores = lecturas.map(obtenerValor).toList();
    final ultimoValor = valores.last;
    final mostrarPuntos = muestras.length <= 30;
    final estadisticas = _EstadisticasGrafica.fromValores(
      valores: valores,
      rangoGrafica: maxY - minY,
    );

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: color.withOpacity(0.18),
          width: 1.2,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 10,
                  height: 10,
                  decoration: BoxDecoration(
                    color: color,
                    shape: BoxShape.circle,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      color: AppColores.textoPrincipal,
                      fontSize: 15,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.12),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    '${_numero(ultimoValor)}${unidad.isNotEmpty ? ' $unidad' : ''}',
                    style: TextStyle(
                      color: color,
                      fontWeight: FontWeight.w900,
                      fontSize: 13,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              height: 160,
              child: LineChart(
                LineChartData(
                  minY: minY,
                  maxY: maxY,
                  clipData: const FlClipData.all(),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    horizontalInterval: (maxY - minY) / 4,
                    getDrawingHorizontalLine: (_) => FlLine(
                      color: AppColores.borde.withOpacity(0.6),
                      strokeWidth: 1,
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineTouchData: LineTouchData(
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipColor: (_) => color.withOpacity(0.85),
                      getTooltipItems: (spots) {
                        return spots.map((spot) {
                          return LineTooltipItem(
                            '${_numero(spot.y)}${unidad.isNotEmpty ? ' $unidad' : ''}',
                            const TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                          );
                        }).toList();
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    leftTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 38,
                        interval: (maxY - minY) / 4,
                        getTitlesWidget: (value, _) => Text(
                          _numero(value),
                          style: const TextStyle(
                            color: AppColores.textoSecundario,
                            fontSize: 10,
                          ),
                        ),
                      ),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        reservedSize: 24,
                        interval: (muestras.length / 5).ceilToDouble(),
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();

                          if (index < 0 || index >= muestras.length) {
                            return const SizedBox.shrink();
                          }

                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              _etiquetaX(muestras[index], muestras),
                              style: const TextStyle(
                                color: AppColores.textoSecundario,
                                fontSize: 10,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  lineBarsData: [
                    LineChartBarData(
                      spots: [
                        for (int i = 0; i < muestras.length; i++)
                          FlSpot(
                            i.toDouble(),
                            obtenerValor(muestras[i]),
                          ),
                      ],
                      isCurved: true,
                      curveSmoothness: 0.3,
                      color: color,
                      barWidth: 2.5,
                      isStrokeCapRound: true,
                      dotData: FlDotData(
                        show: mostrarPuntos,
                        getDotPainter: (_, __, ___, ____) {
                          return FlDotCirclePainter(
                            radius: 3,
                            color: color,
                            strokeWidth: 1.5,
                            strokeColor: Colors.white,
                          );
                        },
                      ),
                      belowBarData: BarAreaData(
                        show: true,
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            color.withOpacity(0.18),
                            color.withOpacity(0.01),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            _ResumenTendenciaGrafica(
              estadisticas: estadisticas,
              unidad: unidad,
              color: color,
            ),
            if (lecturas.length > 60) ...[
              const SizedBox(height: 8),
              Text(
                'Mostrando ${muestras.length} de ${lecturas.length} lecturas',
                style: TextStyle(
                  fontSize: 10,
                  color: AppColores.textoSecundario.withOpacity(0.7),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _numero(double valor) {
    if (valor % 1 == 0) {
      return valor.toInt().toString();
    }

    return valor.toStringAsFixed(1);
  }
}

class _ResumenTendenciaGrafica extends StatelessWidget {
  const _ResumenTendenciaGrafica({
    required this.estadisticas,
    required this.unidad,
    required this.color,
  });

  final _EstadisticasGrafica estadisticas;
  final String unidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColores.borde),
      ),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: [
          _ChipEstadistica(
            titulo: 'Promedio',
            valor: _formatear(estadisticas.promedio),
            unidad: unidad,
            color: color,
          ),
          _ChipEstadistica(
            titulo: 'Tendencia',
            valor: estadisticas.tendencia,
            unidad: '',
            color: color,
          ),
          _ChipEstadistica(
            titulo: 'Mínimo',
            valor: _formatear(estadisticas.minimo),
            unidad: unidad,
            color: color,
          ),
          _ChipEstadistica(
            titulo: 'Máximo',
            valor: _formatear(estadisticas.maximo),
            unidad: unidad,
            color: color,
          ),
        ],
      ),
    );
  }

  String _formatear(double valor) {
    if (valor % 1 == 0) {
      return valor.toInt().toString();
    }

    return valor.toStringAsFixed(1);
  }
}

class _ChipEstadistica extends StatelessWidget {
  const _ChipEstadistica({
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.color,
  });

  final String titulo;
  final String valor;
  final String unidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final textoUnidad = unidad.isEmpty ? '' : ' $unidad';

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 11.2,
            color: AppColores.textoSecundario,
          ),
          children: [
            TextSpan(
              text: '$titulo: ',
              style: const TextStyle(fontWeight: FontWeight.w800),
            ),
            TextSpan(
              text: '$valor$textoUnidad',
              style: TextStyle(
                color: color,
                fontWeight: FontWeight.w900,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EstadisticasGrafica {
  const _EstadisticasGrafica({
    required this.promedio,
    required this.minimo,
    required this.maximo,
    required this.tendencia,
  });

  final double promedio;
  final double minimo;
  final double maximo;
  final String tendencia;

  factory _EstadisticasGrafica.fromValores({
    required List<double> valores,
    required double rangoGrafica,
  }) {
    if (valores.isEmpty) {
      return const _EstadisticasGrafica(
        promedio: 0,
        minimo: 0,
        maximo: 0,
        tendencia: 'Sin datos',
      );
    }

    final suma = valores.reduce((a, b) => a + b);
    final promedio = suma / valores.length;

    double minimo = valores.first;
    double maximo = valores.first;

    for (final valor in valores) {
      if (valor < minimo) minimo = valor;
      if (valor > maximo) maximo = valor;
    }

    final diferencia = valores.last - valores.first;
    final umbral = rangoGrafica <= 0 ? 0.5 : rangoGrafica * 0.02;

    final tendencia = diferencia.abs() <= umbral
        ? 'Estable'
        : diferencia > 0
            ? 'En aumento'
            : 'En disminución';

    return _EstadisticasGrafica(
      promedio: promedio,
      minimo: minimo,
      maximo: maximo,
      tendencia: tendencia,
    );
  }
}
