import 'dart:io';

import 'package:csv/csv.dart';
import 'package:path_provider/path_provider.dart';
import 'package:share_plus/share_plus.dart';

import '../../domain/entities/lectura_historial.dart';

class ExportarHistorialCsvService {
  Future<File> generarCsv(List<LecturaHistorial> lecturas) async {
    final filas = <List<dynamic>>[
      [
        'fechaLectura',
        'humedadSuelo',
        'temperaturaSuelo',
        'conductividadElectrica',
        'phSuelo',
        'nitrogeno',
        'fosforo',
        'potasio',
      ],
      ...lecturas.map(
        (lectura) => [
          lectura.fechaLectura.toIso8601String(),
          lectura.humedad,
          lectura.temperatura,
          lectura.ec,
          lectura.ph,
          lectura.nitrogeno,
          lectura.fosforo,
          lectura.potasio,
        ],
      ),
    ];

    final csv = const ListToCsvConverter().convert(filas);

    final directory = await getApplicationDocumentsDirectory();

    final fecha = DateTime.now();
    final nombreArchivo =
        'historial_fresa_${fecha.year}_${fecha.month.toString().padLeft(2, '0')}_${fecha.day.toString().padLeft(2, '0')}.csv';

    final archivo = File('${directory.path}/$nombreArchivo');

    await archivo.writeAsString(csv);

    return archivo;
  }

  Future<void> compartirCsv(List<LecturaHistorial> lecturas) async {
    final archivo = await generarCsv(lecturas);

    await Share.shareXFiles(
      [XFile(archivo.path)],
      text: 'Historial de lecturas del cultivo de fresa',
    );
  }
}