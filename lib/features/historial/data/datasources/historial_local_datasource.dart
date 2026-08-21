import 'package:hive_ce/hive.dart';

import '../../../../core/constantes/cajas_hive.dart';
import '../../domain/entities/lectura_historial.dart';

// Fuente de datos local para el historial.
// Guarda las lecturas en Hive para que no se pierdan al cerrar la app.
/// Usa una clave compuesta para evitar que dos lecturas con la misma fecha

class HistorialLocalDatasource {
  HistorialLocalDatasource({
    required this.box,
  });

  final Box<dynamic> box;

  factory HistorialLocalDatasource.fromHive() {
    return HistorialLocalDatasource(
      box: Hive.box(CajasHive.lecturasHistorial),
    );
  }

  Future<void> guardarLectura(LecturaHistorial lectura) async {
    final key = _generarKeyLectura(lectura);

    final yaExiste = _existeLectura(lectura);

    if (yaExiste) {
      return;
    }

    await box.put(
      key,
      lectura.toMap(),
    );
  }

  List<LecturaHistorial> obtenerLecturas() {
    final lecturasPorKey = <String, LecturaHistorial>{};

    for (final item in box.values) {
      if (item is! Map) continue;

      try {
        final map = Map<String, dynamic>.from(item);
        final lectura = LecturaHistorial.fromMap(map);
        final key = _generarKeyLectura(lectura);

        lecturasPorKey[key] = lectura;
      } catch (_) {
        continue;
      }
    }

    final lecturas = lecturasPorKey.values.toList();

    lecturas.sort(
      (a, b) => a.fechaLectura.compareTo(b.fechaLectura),
    );

    return lecturas;
  }

  Future<void> limpiar() async {
    await box.clear();
  }

  bool _existeLectura(LecturaHistorial nuevaLectura) {
    for (final item in box.values) {
      if (item is! Map) continue;

      try {
        final map = Map<String, dynamic>.from(item);
        final lecturaExistente = LecturaHistorial.fromMap(map);

        if (_sonLaMismaLectura(lecturaExistente, nuevaLectura)) {
          return true;
        }
      } catch (_) {
        continue;
      }
    }

    return false;
  }

  bool _sonLaMismaLectura(
    LecturaHistorial a,
    LecturaHistorial b,
  ) {
    return a.fechaLectura.toIso8601String() ==
            b.fechaLectura.toIso8601String() &&
        _numeroIgual(a.humedad, b.humedad) &&
        _numeroIgual(a.temperatura, b.temperatura) &&
        _numeroIgual(a.ec, b.ec) &&
        _numeroIgual(a.ph, b.ph) &&
        _numeroIgual(a.nitrogeno, b.nitrogeno) &&
        _numeroIgual(a.fosforo, b.fosforo) &&
        _numeroIgual(a.potasio, b.potasio);
  }

  bool _numeroIgual(double a, double b) {
    return a.toStringAsFixed(3) == b.toStringAsFixed(3);
  }

  String _generarKeyLectura(LecturaHistorial lectura) {
    final fecha = lectura.fechaLectura.toIso8601String();

    final humedad = _normalizarNumero(lectura.humedad);
    final temperatura = _normalizarNumero(lectura.temperatura);
    final ec = _normalizarNumero(lectura.ec);
    final ph = _normalizarNumero(lectura.ph);
    final nitrogeno = _normalizarNumero(lectura.nitrogeno);
    final fosforo = _normalizarNumero(lectura.fosforo);
    final potasio = _normalizarNumero(lectura.potasio);

    final key =
        '${fecha}_h${humedad}_t${temperatura}_ec${ec}_ph${ph}_n${nitrogeno}_p${fosforo}_k${potasio}';

    return key
        .replaceAll(':', '-')
        .replaceAll('.', '-')
        .replaceAll(' ', '_');
  }

  String _normalizarNumero(double value) {
    return value.toStringAsFixed(3);
  }
}