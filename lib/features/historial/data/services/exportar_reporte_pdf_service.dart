import 'dart:typed_data';

import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../../domain/entities/alerta_critica_historial.dart';
import '../../domain/entities/lectura_historial.dart';

class ExportarReportePdfService {
  Future<void> compartirReporte({
    required List<LecturaHistorial> lecturas,
    required List<AlertaCriticaHistorial> alertas,
    required String periodoEtiqueta,
    required String tipoReporte,
  }) async {
    final pdfBytes = await generarReporte(
      lecturas: lecturas,
      alertas: alertas,
      periodoEtiqueta: periodoEtiqueta,
      tipoReporte: tipoReporte,
    );

    await Printing.sharePdf(
      bytes: pdfBytes,
      filename: _nombreArchivo(tipoReporte),
    );
  }

  Future<Uint8List> generarReporte({
    required List<LecturaHistorial> lecturas,
    required List<AlertaCriticaHistorial> alertas,
    required String periodoEtiqueta,
    required String tipoReporte,
  }) async {
    final pdf = pw.Document();

    final ahora = DateTime.now();
    final lecturasPeriodo = [...lecturas]
      ..sort((a, b) => a.fechaLectura.compareTo(b.fechaLectura));
    final alertasPeriodo = [...alertas]
      ..sort((a, b) => b.creadaEn.compareTo(a.creadaEn));

    final desde = lecturasPeriodo.isEmpty ? ahora : lecturasPeriodo.first.fechaLectura;
    final hasta = lecturasPeriodo.isEmpty ? ahora : lecturasPeriodo.last.fechaLectura;
    final ultimaLectura = lecturasPeriodo.isEmpty ? null : lecturasPeriodo.last;

    final resumenesLote = _crearResumenesLote(lecturasPeriodo);
    final variables = lecturasPeriodo.isEmpty
        ? <_VariableReporte>[]
        : _crearVariablesReporte(lecturasPeriodo);
    final recomendaciones = _generarRecomendaciones(variables);

    pdf.addPage(
      pw.MultiPage(
        maxPages: 20,
        pageTheme: _pageTheme(),
        header: (_) => _header(),
        footer: (context) => _footer(context),
        build: (_) {
          if (lecturasPeriodo.isEmpty) {
            return [
              _hero(
                tipoReporte: tipoReporte,
                periodoEtiqueta: periodoEtiqueta,
                desde: desde,
                hasta: hasta,
                totalLecturas: 0,
                totalLotes: 0,
              ),
              pw.SizedBox(height: 16),
              _section(
                'Sin lecturas para el reporte',
                pw.Text(
                  'No hay lecturas disponibles para el periodo seleccionado. Cuando se registren mediciones, el reporte incluira resumen por lote, variables, tendencias y lecturas recientes.',
                  style: _bodyStyle,
                ),
              ),
            ];
          }

          return [
            _hero(
              tipoReporte: tipoReporte,
              periodoEtiqueta: periodoEtiqueta,
              desde: desde,
              hasta: hasta,
              totalLecturas: lecturasPeriodo.length,
              totalLotes: resumenesLote.length,
            ),
            pw.SizedBox(height: 14),
            _executiveSummary(
              variables: variables,
              totalLecturas: lecturasPeriodo.length,
              totalLotes: resumenesLote.length,
              totalAlertas: alertasPeriodo.length,
              ultimaLectura: ultimaLectura!,
            ),
            pw.SizedBox(height: 12),
            _lotSummary(resumenesLote),
            pw.SizedBox(height: 12),
            _lastReading(ultimaLectura),
            pw.SizedBox(height: 12),
            _variableLotAverages(variables),
            pw.SizedBox(height: 12),
            _trendCharts(variables),
            pw.SizedBox(height: 12),
            _recommendations(recomendaciones),
            pw.SizedBox(height: 12),
            _alerts(alertasPeriodo),
            pw.SizedBox(height: 12),
            _recentReadings(lecturasPeriodo),
            pw.SizedBox(height: 12),
            _referenceRanges(),
          ];
        },
      ),
    );

    return pdf.save();
  }

  pw.PageTheme _pageTheme() {
    return pw.PageTheme(
      pageFormat: PdfPageFormat.a4,
      margin: const pw.EdgeInsets.fromLTRB(34, 30, 34, 38),
      theme: pw.ThemeData.withFont(
        base: pw.Font.helvetica(),
        bold: pw.Font.helveticaBold(),
      ),
    );
  }

  pw.Widget _header() {
    return pw.Container(
      padding: const pw.EdgeInsets.only(bottom: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        crossAxisAlignment: pw.CrossAxisAlignment.center,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 9, height: 9, color: _green),
              pw.SizedBox(width: 7),
              pw.Text(
                'Fresa App',
                style: pw.TextStyle(
                  fontSize: 12,
                  fontWeight: pw.FontWeight.bold,
                  color: _text,
                ),
              ),
            ],
          ),
          pw.Text(
            'Reporte de historial',
            style: const pw.TextStyle(
              fontSize: 8.5,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _footer(pw.Context context) {
    return pw.Container(
      padding: const pw.EdgeInsets.only(top: 8),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          top: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Row(
        mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
        children: [
          pw.Text(
            'Generado por Fresa App',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
          pw.Text(
            'Pagina ${context.pageNumber} de ${context.pagesCount}',
            style: const pw.TextStyle(fontSize: 8, color: _muted),
          ),
        ],
      ),
    );
  }

  pw.Widget _hero({
    required String tipoReporte,
    required String periodoEtiqueta,
    required DateTime desde,
    required DateTime hasta,
    required int totalLecturas,
    required int totalLotes,
  }) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(18),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          left: pw.BorderSide(color: _green, width: 4),
          top: pw.BorderSide(color: _line, width: 0.8),
          right: pw.BorderSide(color: _line, width: 0.8),
          bottom: pw.BorderSide(color: _line, width: 0.8),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            tipoReporte.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 8.5,
              fontWeight: pw.FontWeight.bold,
              color: _green,
              letterSpacing: 0.8,
            ),
          ),
          pw.SizedBox(height: 7),
          pw.Text(
            'Reporte de historial de mediciones',
            style: pw.TextStyle(
              fontSize: 24,
              fontWeight: pw.FontWeight.bold,
              color: _text,
              height: 1.05,
            ),
          ),
          pw.SizedBox(height: 5),
          pw.Text(
            'Resumen del periodo seleccionado, separado por lotes y variables del suelo.',
            style: const pw.TextStyle(
              fontSize: 10,
              color: _muted,
            ),
          ),
          pw.SizedBox(height: 14),
          _metaGrid([
            _MetaItem('Periodo', periodoEtiqueta),
            _MetaItem('Lecturas', totalLecturas.toString()),
            _MetaItem('Lotes', totalLotes.toString()),
            _MetaItem('Fechas', '${_fechaCorta(desde)} - ${_fechaCorta(hasta)}'),
            _MetaItem('Generado', _formatearFechaHora(DateTime.now())),
            const _MetaItem('Variables', 'Suelo y NPK'),
          ]),
        ],
      ),
    );
  }

  pw.Widget _metaGrid(List<_MetaItem> items) {
    return pw.Table(
      columnWidths: const {
        0: pw.FlexColumnWidth(1),
        1: pw.FlexColumnWidth(1),
        2: pw.FlexColumnWidth(1),
      },
      children: [
        pw.TableRow(
          children: items.take(3).map(_metaCell).toList(),
        ),
        pw.TableRow(
          children: items.skip(3).take(3).map(_metaCell).toList(),
        ),
      ],
    );
  }

  pw.Widget _metaCell(_MetaItem item) {
    return pw.Container(
      padding: const pw.EdgeInsets.fromLTRB(10, 8, 10, 8),
      decoration: const pw.BoxDecoration(
        color: _soft,
        border: pw.Border(
          right: pw.BorderSide(color: _line, width: 0.5),
          bottom: pw.BorderSide(color: _line, width: 0.5),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            item.label.toUpperCase(),
            style: pw.TextStyle(
              fontSize: 6.8,
              fontWeight: pw.FontWeight.bold,
              color: _muted,
              letterSpacing: 0.4,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            item.value,
            maxLines: 2,
            overflow: pw.TextOverflow.clip,
            style: pw.TextStyle(
              fontSize: 9.2,
              fontWeight: pw.FontWeight.bold,
              color: _text,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _section(String title, pw.Widget child) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(13),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: _line, width: 0.8),
          right: pw.BorderSide(color: _line, width: 0.8),
          bottom: pw.BorderSide(color: _line, width: 0.8),
          left: pw.BorderSide(color: _line, width: 0.8),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            title,
            style: pw.TextStyle(
              fontSize: 13.2,
              fontWeight: pw.FontWeight.bold,
              color: _text,
            ),
          ),
          pw.SizedBox(height: 9),
          child,
        ],
      ),
    );
  }

  pw.Widget _sectionTitle(String title) {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.symmetric(vertical: 7),
      decoration: const pw.BoxDecoration(
        border: pw.Border(
          bottom: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Text(
        title,
        style: pw.TextStyle(
          fontSize: 13.2,
          fontWeight: pw.FontWeight.bold,
          color: _text,
        ),
      ),
    );
  }

  pw.Widget _executiveSummary({
    required List<_VariableReporte> variables,
    required int totalLecturas,
    required int totalLotes,
    required int totalAlertas,
    required LecturaHistorial ultimaLectura,
  }) {
    final criticas = variables.where((v) => v.estado == _EstadoReporte.critico).length;
    final revisar = variables.where((v) => v.estado == _EstadoReporte.revisar).length;

    final estado = criticas > 0
        ? 'Atencion prioritaria'
        : revisar > 0
            ? 'Revision recomendada'
            : 'Condicion estable';

    final color = criticas > 0
        ? _red
        : revisar > 0
            ? _orange
            : _green;

    return _section(
      '1. Resumen ejecutivo',
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(child: _kpi('Estado general', estado, color, compact: true)),
              pw.SizedBox(width: 7),
              pw.Expanded(child: _kpi('Lecturas', totalLecturas.toString(), _green)),
              pw.SizedBox(width: 7),
              pw.Expanded(child: _kpi('Lotes', totalLotes.toString(), _green)),
              pw.SizedBox(width: 7),
              pw.Expanded(child: _kpi('Alertas', totalAlertas.toString(), totalAlertas > 0 ? _red : _green)),
            ],
          ),
          pw.SizedBox(height: 9),
          pw.Text(
            'Ultima lectura: ${ultimaLectura.loteNombre} - ${_formatearFechaHora(ultimaLectura.fechaLectura)}. Variables a revisar: $revisar. Variables criticas: $criticas.',
            style: _bodyStyle,
          ),
        ],
      ),
    );
  }

  pw.Widget _kpi(String label, String value, PdfColor color, {bool compact = false}) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: const pw.BoxDecoration(
        color: _soft,
        border: pw.Border(
          left: pw.BorderSide(color: _line, width: 0.7),
          top: pw.BorderSide(color: _line, width: 0.7),
          right: pw.BorderSide(color: _line, width: 0.7),
          bottom: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(label, style: const pw.TextStyle(fontSize: 7.8, color: _muted)),
          pw.SizedBox(height: 4),
          pw.Text(
            value,
            maxLines: 2,
            style: pw.TextStyle(
              fontSize: compact ? 9.4 : 15,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _lotSummary(List<_ResumenLoteReporte> lotes) {
    return _section(
      '2. Resumen por lote',
      _simpleTable(
        headers: const ['Lote', 'Lect.', 'Hum.', 'Temp.', 'pH', 'EC', 'N', 'P', 'K'],
        rows: lotes.map((l) {
          return [
            l.nombre,
            l.totalLecturas.toString(),
            '${_numero(l.humedad)}%',
            _numero(l.temperatura),
            _numero(l.ph),
            _numero(l.ec),
            _numero(l.nitrogeno),
            _numero(l.fosforo),
            _numero(l.potasio),
          ];
        }).toList(),
        widths: const {
          0: pw.FlexColumnWidth(1.25),
          1: pw.FlexColumnWidth(0.65),
          2: pw.FlexColumnWidth(0.72),
          3: pw.FlexColumnWidth(0.72),
          4: pw.FlexColumnWidth(0.62),
          5: pw.FlexColumnWidth(0.62),
          6: pw.FlexColumnWidth(0.62),
          7: pw.FlexColumnWidth(0.62),
          8: pw.FlexColumnWidth(0.62),
        },
      ),
    );
  }

  pw.Widget _lastReading(LecturaHistorial lectura) {
    final values = [
      _ValueBox('Humedad', '${lectura.humedad.toStringAsFixed(1)} %', _estadoHumedad(lectura.humedad)),
      _ValueBox('Temperatura', '${lectura.temperatura.toStringAsFixed(1)} C', _estadoTemperatura(lectura.temperatura)),
      _ValueBox('pH', lectura.ph.toStringAsFixed(1), _estadoPh(lectura.ph)),
      _ValueBox('Conductividad', '${lectura.ec.toStringAsFixed(2)} dS/m', _estadoEc(lectura.ec)),
      _ValueBox('N', '${lectura.nitrogeno.toStringAsFixed(0)} ppm', _estadoN(lectura.nitrogeno)),
      _ValueBox('P', '${lectura.fosforo.toStringAsFixed(0)} ppm', _estadoP(lectura.fosforo)),
      _ValueBox('K', '${lectura.potasio.toStringAsFixed(0)} ppm', _estadoK(lectura.potasio)),
    ];

    return _section(
      '3. Ultima lectura registrada',
      pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            '${lectura.loteNombre} - ${_formatearFechaHora(lectura.fechaLectura)}',
            style: pw.TextStyle(
              fontSize: 9.4,
              fontWeight: pw.FontWeight.bold,
              color: _green,
            ),
          ),
          pw.SizedBox(height: 9),
          pw.Wrap(
            spacing: 7,
            runSpacing: 7,
            children: values.map(_valueCard).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _valueCard(_ValueBox value) {
    final color = _colorEstado(value.estado);

    return pw.Container(
      width: 110,
      padding: const pw.EdgeInsets.all(8),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: color, width: 0.8),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(value.label, style: const pw.TextStyle(fontSize: 7.7, color: _muted)),
          pw.SizedBox(height: 3),
          pw.Text(
            value.value,
            style: pw.TextStyle(
              fontSize: 10.3,
              fontWeight: pw.FontWeight.bold,
              color: _text,
            ),
          ),
          pw.SizedBox(height: 3),
          pw.Text(
            _textoEstado(value.estado),
            style: pw.TextStyle(
              fontSize: 7.7,
              fontWeight: pw.FontWeight.bold,
              color: color,
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _variableLotAverages(List<_VariableReporte> variables) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('4. Promedios por variable y lote'),
        pw.SizedBox(height: 8),
        ...variables.map((v) {
          return pw.Padding(
            padding: const pw.EdgeInsets.only(bottom: 8),
            child: _variableAverageCard(v),
          );
        }),
      ],
    );
  }

  pw.Widget _variableAverageCard(_VariableReporte variable) {
    final color = _colorEstado(variable.estado);
    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: _soft,
        border: pw.Border(
          top: pw.BorderSide(color: _line, width: 0.7),
          right: pw.BorderSide(color: _line, width: 0.7),
          bottom: pw.BorderSide(color: _line, width: 0.7),
          left: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Container(width: 4, height: 14, color: color),
              pw.SizedBox(width: 7),
              pw.Expanded(
                child: pw.Text(
                  variable.nombre,
                  style: pw.TextStyle(
                    fontSize: 10,
                    fontWeight: pw.FontWeight.bold,
                    color: _text,
                  ),
                ),
              ),
              pw.Text(
                'Prom. general: ${_numero(variable.promedio)} ${variable.unidad}',
                style: pw.TextStyle(
                  fontSize: 8.2,
                  fontWeight: pw.FontWeight.bold,
                  color: color,
                ),
              ),
            ],
          ),
          pw.SizedBox(height: 7),
          pw.Wrap(
            spacing: 6,
            runSpacing: 6,
            children: variable.promediosPorLote.map((l) {
              return pw.Container(
                padding: const pw.EdgeInsets.symmetric(horizontal: 7, vertical: 4),
                decoration: pw.BoxDecoration(
                  color: PdfColors.white,
                  border: pw.Border.all(color: _line, width: 0.6),
                ),
                child: pw.Text(
                  '${l.nombre}: ${_numero(l.promedio)} ${variable.unidad}',
                  style: const pw.TextStyle(fontSize: 7.8, color: _body),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  pw.Widget _trendCharts(List<_VariableReporte> variables) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        _sectionTitle('5. Graficas compactas de tendencia'),
        pw.SizedBox(height: 8),
        for (var i = 0; i < variables.length; i += 2) ...[
          pw.Row(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Expanded(child: _miniChart(variables[i])),
              if (i + 1 < variables.length) ...[
                pw.SizedBox(width: 8),
                pw.Expanded(child: _miniChart(variables[i + 1])),
              ] else
                pw.Expanded(child: pw.SizedBox()),
            ],
          ),
          if (i + 2 < variables.length) pw.SizedBox(height: 8),
        ],
      ],
    );
  }

  pw.Widget _miniChart(_VariableReporte variable) {
    final points = _muestrearValores(variable.valores, 16);
    final min = variable.minimo;
    final max = variable.maximo;
    final range = (max - min).abs() < 0.0001 ? 1.0 : max - min;
    final color = _colorEstado(variable.estado);

    return pw.Container(
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border(
          top: pw.BorderSide(color: _line, width: 0.7),
          right: pw.BorderSide(color: _line, width: 0.7),
          bottom: pw.BorderSide(color: _line, width: 0.7),
          left: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Row(
            children: [
              pw.Expanded(
                child: pw.Text(
                  variable.nombre,
                  style: pw.TextStyle(
                    fontSize: 9.5,
                    fontWeight: pw.FontWeight.bold,
                    color: _text,
                  ),
                ),
              ),
              pw.Text(
                '${_numero(variable.ultimo)} ${variable.unidad}',
                style: pw.TextStyle(fontSize: 8.3, fontWeight: pw.FontWeight.bold, color: color),
              ),
            ],
          ),
          pw.SizedBox(height: 8),
          pw.Container(
            height: 50,
            alignment: pw.Alignment.bottomCenter,
            child: pw.Row(
              crossAxisAlignment: pw.CrossAxisAlignment.end,
              children: points.map((value) {
                final p = ((value - min) / range).clamp(0.0, 1.0);
                final h = 6 + (p * 38);
                return pw.Expanded(
                  child: pw.Padding(
                    padding: const pw.EdgeInsets.symmetric(horizontal: 1),
                    child: pw.Container(height: h, color: color),
                  ),
                );
              }).toList(),
            ),
          ),
          pw.SizedBox(height: 6),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text('Prom: ${_numero(variable.promedio)}', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
              pw.Text(variable.tendencia, style: pw.TextStyle(fontSize: 7.5, fontWeight: pw.FontWeight.bold, color: color)),
            ],
          ),
        ],
      ),
    );
  }

  pw.Widget _recommendations(List<_RecomendacionPdf> recomendaciones) {
    return _section(
      '6. Recomendaciones principales',
      recomendaciones.isEmpty
          ? pw.Text(
              'Las variables analizadas se mantienen dentro de rangos aceptables. Mantenga el seguimiento periodico del cultivo.',
              style: _bodyStyle,
            )
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: recomendaciones.map((r) {
                return pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 7),
                  child: _recommendationRow(r),
                );
              }).toList(),
            ),
    );
  }

  pw.Widget _recommendationRow(_RecomendacionPdf r) {
    final color = r.prioridad == 'Alta' ? _red : r.prioridad == 'Media' ? _orange : _green;

    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: pw.BoxDecoration(
        color: PdfColors.white,
        border: pw.Border.all(color: _line, width: 0.7),
      ),
      child: pw.Row(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Container(width: 4, height: 38, color: color),
          pw.SizedBox(width: 8),
          pw.Expanded(
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Row(
                  children: [
                    pw.Expanded(
                      child: pw.Text(
                        r.titulo,
                        style: pw.TextStyle(fontSize: 9.2, fontWeight: pw.FontWeight.bold, color: _text),
                      ),
                    ),
                    pw.Text(r.prioridad, style: pw.TextStyle(fontSize: 7.6, fontWeight: pw.FontWeight.bold, color: color)),
                  ],
                ),
                pw.SizedBox(height: 4),
                pw.Text(r.descripcion, style: const pw.TextStyle(fontSize: 8.2, color: _body, lineSpacing: 2)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  pw.Widget _alerts(List<AlertaCriticaHistorial> alertas) {
    final visibles = alertas.take(4).toList();

    return _section(
      '7. Alertas del periodo',
      visibles.isEmpty
          ? pw.Text(
              'No se registran alertas criticas en el periodo seleccionado.',
              style: _bodyStyle,
            )
          : pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                ...visibles.map((a) {
                  return pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 7),
                    child: _alertRow(a),
                  );
                }),
                if (alertas.length > visibles.length)
                  pw.Text(
                    'Se muestran ${visibles.length} de ${alertas.length} alertas.',
                    style: const pw.TextStyle(fontSize: 8, color: _muted),
                  ),
              ],
            ),
    );
  }

  pw.Widget _alertRow(AlertaCriticaHistorial alerta) {
    return pw.Container(
      padding: const pw.EdgeInsets.all(9),
      decoration: const pw.BoxDecoration(
        color: _soft,
        border: pw.Border(
          left: pw.BorderSide(color: _orange, width: 3),
          top: pw.BorderSide(color: _line, width: 0.7),
          right: pw.BorderSide(color: _line, width: 0.7),
          bottom: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Column(
        crossAxisAlignment: pw.CrossAxisAlignment.start,
        children: [
          pw.Text(
            alerta.tituloVisible,
            style: pw.TextStyle(fontSize: 9.2, fontWeight: pw.FontWeight.bold, color: _text),
          ),
          pw.SizedBox(height: 3),
          pw.Text(_recortarTexto(alerta.subtituloVisible, 150), style: const pw.TextStyle(fontSize: 8.2, color: _body, lineSpacing: 2)),
          pw.SizedBox(height: 3),
          pw.Text('${_formatearFechaHora(alerta.creadaEn)} - ${alerta.enviada ? 'Notificada' : 'Pendiente'}', style: const pw.TextStyle(fontSize: 7.5, color: _muted)),
        ],
      ),
    );
  }

  pw.Widget _recentReadings(List<LecturaHistorial> lecturas) {
    final recientes = lecturas.reversed.take(10).toList();

    return _section(
      '8. Ultimas lecturas registradas',
      _simpleTable(
        headers: const ['Lote', 'Fecha', 'Hum.', 'Temp.', 'pH', 'EC', 'N', 'P', 'K'],
        rows: recientes.map((l) {
          return [
            l.loteNombre,
            _formatearFechaHora(l.fechaLectura),
            '${l.humedad.toStringAsFixed(0)}%',
            l.temperatura.toStringAsFixed(1),
            l.ph.toStringAsFixed(1),
            l.ec.toStringAsFixed(2),
            l.nitrogeno.toStringAsFixed(0),
            l.fosforo.toStringAsFixed(0),
            l.potasio.toStringAsFixed(0),
          ];
        }).toList(),
        widths: const {
          0: pw.FlexColumnWidth(1.0),
          1: pw.FlexColumnWidth(1.55),
          2: pw.FlexColumnWidth(0.65),
          3: pw.FlexColumnWidth(0.75),
          4: pw.FlexColumnWidth(0.55),
          5: pw.FlexColumnWidth(0.65),
          6: pw.FlexColumnWidth(0.55),
          7: pw.FlexColumnWidth(0.55),
          8: pw.FlexColumnWidth(0.55),
        },
      ),
    );
  }

  pw.Widget _simpleTable({
    required List<String> headers,
    required List<List<String>> rows,
    required Map<int, pw.TableColumnWidth> widths,
  }) {
    return pw.Table(
      columnWidths: widths,
      border: const pw.TableBorder(
        horizontalInside: pw.BorderSide(color: _line, width: 0.5),
      ),
      children: [
        pw.TableRow(
          decoration: const pw.BoxDecoration(color: _green),
          children: headers.map((h) => _tableCell(h, header: true)).toList(),
        ),
        ...rows.map((row) {
          return pw.TableRow(
            children: row.map((v) => _tableCell(v)).toList(),
          );
        }),
      ],
    );
  }

  pw.Widget _tableCell(String text, {bool header = false}) {
    return pw.Padding(
      padding: const pw.EdgeInsets.symmetric(horizontal: 5, vertical: 6),
      child: pw.Text(
        text,
        maxLines: 2,
        style: pw.TextStyle(
          fontSize: header ? 7.7 : 7.3,
          fontWeight: header ? pw.FontWeight.bold : pw.FontWeight.normal,
          color: header ? PdfColors.white : _text,
        ),
      ),
    );
  }

  pw.Widget _referenceRanges() {
    return pw.Container(
      width: double.infinity,
      padding: const pw.EdgeInsets.all(10),
      decoration: const pw.BoxDecoration(
        color: _soft,
        border: pw.Border(
          left: pw.BorderSide(color: _line, width: 0.7),
          top: pw.BorderSide(color: _line, width: 0.7),
          right: pw.BorderSide(color: _line, width: 0.7),
          bottom: pw.BorderSide(color: _line, width: 0.7),
        ),
      ),
      child: pw.Text(
        'Rangos usados: humedad 45-65 %, temperatura 15-25 C, pH 5.7-6.5, EC 1.2-2.0 dS/m, N 72-129 ppm, P 20-40 ppm, K 82-160 ppm. Este informe es orientativo y apoya la toma de decisiones; las acciones agronomicas deben validarse con el asesor tecnico.',
        style: const pw.TextStyle(fontSize: 8.1, color: _body, lineSpacing: 2.3),
      ),
    );
  }

  List<_ResumenLoteReporte> _crearResumenesLote(List<LecturaHistorial> lecturas) {
    final porLote = <String, List<LecturaHistorial>>{};

    for (final lectura in lecturas) {
      porLote.putIfAbsent(lectura.loteId, () => <LecturaHistorial>[]).add(lectura);
    }

    final resumenes = porLote.entries.map((entry) {
      final lista = entry.value;
      final nombre = lista.isEmpty ? entry.key : lista.first.loteNombre;

      return _ResumenLoteReporte(
        id: entry.key,
        nombre: nombre,
        totalLecturas: lista.length,
        humedad: _promedio(lista.map((l) => l.humedad).toList()),
        temperatura: _promedio(lista.map((l) => l.temperatura).toList()),
        ph: _promedio(lista.map((l) => l.ph).toList()),
        ec: _promedio(lista.map((l) => l.ec).toList()),
        nitrogeno: _promedio(lista.map((l) => l.nitrogeno).toList()),
        fosforo: _promedio(lista.map((l) => l.fosforo).toList()),
        potasio: _promedio(lista.map((l) => l.potasio).toList()),
      );
    }).toList();

    resumenes.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return resumenes;
  }

  List<_VariableReporte> _crearVariablesReporte(List<LecturaHistorial> lecturas) {
    return [
      _variable(
        nombre: 'Humedad',
        unidad: '%',
        lecturas: lecturas,
        obtenerValor: (l) => l.humedad,
        evaluar: _estadoHumedad,
      ),
      _variable(
        nombre: 'Temperatura',
        unidad: 'C',
        lecturas: lecturas,
        obtenerValor: (l) => l.temperatura,
        evaluar: _estadoTemperatura,
      ),
      _variable(
        nombre: 'pH',
        unidad: '',
        lecturas: lecturas,
        obtenerValor: (l) => l.ph,
        evaluar: _estadoPh,
      ),
      _variable(
        nombre: 'Conductividad electrica',
        unidad: 'dS/m',
        lecturas: lecturas,
        obtenerValor: (l) => l.ec,
        evaluar: _estadoEc,
      ),
      _variable(
        nombre: 'Nitrogeno',
        unidad: 'ppm',
        lecturas: lecturas,
        obtenerValor: (l) => l.nitrogeno,
        evaluar: _estadoN,
      ),
      _variable(
        nombre: 'Fosforo',
        unidad: 'ppm',
        lecturas: lecturas,
        obtenerValor: (l) => l.fosforo,
        evaluar: _estadoP,
      ),
      _variable(
        nombre: 'Potasio',
        unidad: 'ppm',
        lecturas: lecturas,
        obtenerValor: (l) => l.potasio,
        evaluar: _estadoK,
      ),
    ];
  }

  _VariableReporte _variable({
    required String nombre,
    required String unidad,
    required List<LecturaHistorial> lecturas,
    required double Function(LecturaHistorial lectura) obtenerValor,
    required _EstadoReporte Function(double valor) evaluar,
  }) {
    final valores = lecturas.map(obtenerValor).toList();
    final promediosPorLote = _promediosPorLote(
      lecturas: lecturas,
      obtenerValor: obtenerValor,
    );

    final promedio = _promedio(valores);
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final ultimo = valores.last;

    return _VariableReporte(
      nombre: nombre,
      unidad: unidad,
      valores: valores,
      promedio: promedio,
      minimo: minimo,
      maximo: maximo,
      ultimo: ultimo,
      tendencia: _tendencia(valores),
      estado: evaluar(ultimo),
      promediosPorLote: promediosPorLote,
    );
  }

  List<_PromedioLoteVariable> _promediosPorLote({
    required List<LecturaHistorial> lecturas,
    required double Function(LecturaHistorial lectura) obtenerValor,
  }) {
    final porLote = <String, List<LecturaHistorial>>{};

    for (final lectura in lecturas) {
      porLote.putIfAbsent(lectura.loteId, () => <LecturaHistorial>[]).add(lectura);
    }

    final promedios = porLote.entries.map((entry) {
      final lista = entry.value;
      return _PromedioLoteVariable(
        id: entry.key,
        nombre: lista.isEmpty ? entry.key : lista.first.loteNombre,
        promedio: _promedio(lista.map(obtenerValor).toList()),
      );
    }).toList();

    promedios.sort((a, b) => a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase()));
    return promedios;
  }

  double _promedio(List<double> valores) {
    if (valores.isEmpty) return 0;
    return valores.reduce((a, b) => a + b) / valores.length;
  }

  String _tendencia(List<double> valores) {
    if (valores.length < 2) return 'Sin tendencia';

    final diferencia = valores.last - valores.first;
    final tolerancia = _toleranciaTendencia(valores);

    if (diferencia.abs() <= tolerancia) return 'Estable';
    if (diferencia > 0) return 'En aumento';
    return 'En disminucion';
  }

  double _toleranciaTendencia(List<double> valores) {
    final maximo = valores.reduce((a, b) => a > b ? a : b);
    final minimo = valores.reduce((a, b) => a < b ? a : b);
    final rango = (maximo - minimo).abs();
    if (rango < 1) return 0.2;
    return rango * 0.08;
  }

  List<double> _muestrearValores(List<double> valores, int maxPuntos) {
    if (valores.length <= maxPuntos) return valores;

    final paso = valores.length / maxPuntos;
    final salida = <double>[];

    for (double i = 0; i < valores.length; i += paso) {
      salida.add(valores[i.floor()]);
    }

    if (salida.isEmpty || salida.last != valores.last) {
      salida.add(valores.last);
    }

    return salida.take(maxPuntos).toList();
  }

  List<_RecomendacionPdf> _generarRecomendaciones(List<_VariableReporte> variables) {
    final recomendaciones = <_RecomendacionPdf>[];

    for (final variable in variables) {
      if (variable.estado == _EstadoReporte.optimo) continue;

      final prioridad = variable.estado == _EstadoReporte.critico ? 'Alta' : 'Media';
      final valor = '${_numero(variable.ultimo)} ${variable.unidad}'.trim();

      recomendaciones.add(
        _RecomendacionPdf(
          titulo: '${variable.nombre}: ${_textoEstado(variable.estado).toLowerCase()}',
          descripcion: 'Ultimo valor $valor. Tendencia: ${variable.tendencia}. Revise el manejo del lote y compare con los rangos usados.',
          prioridad: prioridad,
        ),
      );
    }

    recomendaciones.sort((a, b) {
      final ap = a.prioridad == 'Alta' ? 0 : 1;
      final bp = b.prioridad == 'Alta' ? 0 : 1;
      return ap.compareTo(bp);
    });

    return recomendaciones.take(6).toList();
  }

  _EstadoReporte _estadoHumedad(double v) {
    if (v >= 45 && v <= 65) return _EstadoReporte.optimo;
    if (v >= 35 && v <= 75) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  _EstadoReporte _estadoTemperatura(double v) {
    if (v >= 15 && v <= 25) return _EstadoReporte.optimo;
    if (v >= 10 && v <= 30) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  _EstadoReporte _estadoPh(double v) {
    if (v >= 5.7 && v <= 6.5) return _EstadoReporte.optimo;
    if (v >= 5.2 && v <= 7.0) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  _EstadoReporte _estadoEc(double v) {
    if (v >= 1.2 && v <= 2.0) return _EstadoReporte.optimo;
    if (v > 0 && v <= 2.5) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  _EstadoReporte _estadoN(double v) {
    if (v >= 72 && v <= 129) return _EstadoReporte.optimo;
    if (v >= 50 && v <= 160) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  _EstadoReporte _estadoP(double v) {
    if (v >= 20 && v <= 40) return _EstadoReporte.optimo;
    if (v >= 10 && v <= 60) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  _EstadoReporte _estadoK(double v) {
    if (v >= 82 && v <= 160) return _EstadoReporte.optimo;
    if (v >= 50 && v <= 220) return _EstadoReporte.revisar;
    return _EstadoReporte.critico;
  }

  PdfColor _colorEstado(_EstadoReporte estado) {
    switch (estado) {
      case _EstadoReporte.optimo:
        return _green;
      case _EstadoReporte.revisar:
        return _orange;
      case _EstadoReporte.critico:
        return _red;
    }
  }

  String _textoEstado(_EstadoReporte estado) {
    switch (estado) {
      case _EstadoReporte.optimo:
        return 'Optimo';
      case _EstadoReporte.revisar:
        return 'Revisar';
      case _EstadoReporte.critico:
        return 'Critico';
    }
  }

  String _recortarTexto(String texto, int maximo) {
    if (texto.length <= maximo) return texto;
    return '${texto.substring(0, maximo)}...';
  }

  String _nombreArchivo(String tipoReporte) {
    final fecha = DateTime.now();
    final year = fecha.year.toString();
    final month = fecha.month.toString().padLeft(2, '0');
    final day = fecha.day.toString().padLeft(2, '0');
    final tipo = tipoReporte.toLowerCase().replaceAll(' ', '_');
    return 'reporte_${tipo}_fresa_$year-$month-$day.pdf';
  }

  String _fechaCorta(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    return '$day/$month';
  }

  String _formatearFechaHora(DateTime fecha) {
    final day = fecha.day.toString().padLeft(2, '0');
    final month = fecha.month.toString().padLeft(2, '0');
    final year = fecha.year.toString();
    final hour = fecha.hour.toString().padLeft(2, '0');
    final minute = fecha.minute.toString().padLeft(2, '0');
    return '$day/$month/$year $hour:$minute';
  }

  String _numero(double valor) {
    if (valor.abs() >= 100) return valor.toStringAsFixed(0);
    if (valor.abs() >= 10) return valor.toStringAsFixed(1);
    return valor.toStringAsFixed(2);
  }

  static const PdfColor _green = PdfColor.fromInt(0xFF2E7D32);
  static const PdfColor _orange = PdfColor.fromInt(0xFFF57C00);
  static const PdfColor _red = PdfColor.fromInt(0xFFD32F2F);
  static const PdfColor _text = PdfColor.fromInt(0xFF1F2937);
  static const PdfColor _body = PdfColor.fromInt(0xFF4B5563);
  static const PdfColor _muted = PdfColor.fromInt(0xFF6B7280);
  static const PdfColor _line = PdfColor.fromInt(0xFFE5E7EB);
  static const PdfColor _soft = PdfColor.fromInt(0xFFF8FAF8);

  static const pw.TextStyle _bodyStyle = pw.TextStyle(
    fontSize: 9.2,
    color: _body,
    lineSpacing: 2.4,
  );
}

class _MetaItem {
  const _MetaItem(this.label, this.value);

  final String label;
  final String value;
}

class _ValueBox {
  const _ValueBox(this.label, this.value, this.estado);

  final String label;
  final String value;
  final _EstadoReporte estado;
}

class _ResumenLoteReporte {
  const _ResumenLoteReporte({
    required this.id,
    required this.nombre,
    required this.totalLecturas,
    required this.humedad,
    required this.temperatura,
    required this.ph,
    required this.ec,
    required this.nitrogeno,
    required this.fosforo,
    required this.potasio,
  });

  final String id;
  final String nombre;
  final int totalLecturas;
  final double humedad;
  final double temperatura;
  final double ph;
  final double ec;
  final double nitrogeno;
  final double fosforo;
  final double potasio;
}

class _PromedioLoteVariable {
  const _PromedioLoteVariable({
    required this.id,
    required this.nombre,
    required this.promedio,
  });

  final String id;
  final String nombre;
  final double promedio;
}

class _VariableReporte {
  const _VariableReporte({
    required this.nombre,
    required this.unidad,
    required this.valores,
    required this.promedio,
    required this.minimo,
    required this.maximo,
    required this.ultimo,
    required this.tendencia,
    required this.estado,
    required this.promediosPorLote,
  });

  final String nombre;
  final String unidad;
  final List<double> valores;
  final double promedio;
  final double minimo;
  final double maximo;
  final double ultimo;
  final String tendencia;
  final _EstadoReporte estado;
  final List<_PromedioLoteVariable> promediosPorLote;
}

enum _EstadoReporte {
  optimo,
  revisar,
  critico,
}

class _RecomendacionPdf {
  const _RecomendacionPdf({
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
  });

  final String titulo;
  final String descripcion;
  final String prioridad;
}
