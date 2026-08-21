//Representa una lectura histórica de sensores del cultivo.
///Esta entidad guarda las variables principales del sensor de suelo.
//Se usa para gráficas, historial local y sincronización con Firebase.
class LecturaHistorial {
  const LecturaHistorial({
    required this.fechaLectura,
    required this.humedad,
    required this.temperatura,
    required this.ph,
    required this.ec,
    required this.nitrogeno,
    required this.fosforo,
    required this.potasio,
    this.id = '',
    this.loteId = 'lote_1',
    this.loteNombre = 'Lote 1',
    this.origen = 'sensor',
    this.pendienteSync = false,
    this.sincronizado = true,
  });

  final String id;
  final String loteId;
  final String loteNombre;
  final String origen;
  final DateTime fechaLectura;
  final double humedad;
  final double temperatura;
  final double ph;
  final double ec;
  final double nitrogeno;
  final double fosforo;
  final double potasio;
  final bool pendienteSync;
  final bool sincronizado;

  String get hora {
    return '${fechaLectura.hour}:${fechaLectura.minute.toString().padLeft(2, '0')}';
  }

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'loteId': loteId,
      'loteNombre': loteNombre,
      'origen': origen,
      'fechaLectura': fechaLectura.toIso8601String(),
      'humedad': humedad,
      'temperatura': temperatura,
      'ph': ph,
      'ec': ec,
      'nitrogeno': nitrogeno,
      'fosforo': fosforo,
      'potasio': potasio,
      'pendienteSync': pendienteSync,
      'sincronizado': sincronizado,
    };
  }

  factory LecturaHistorial.fromMap(Map<String, dynamic> map) {
    final fecha = DateTime.tryParse(map['fechaLectura']?.toString() ?? '') ??
        DateTime.now();
    final id = (map['id'] ?? fecha.toIso8601String()).toString();
    final loteId = (map['loteId'] ?? 'lote_1').toString();

    return LecturaHistorial(
      id: id,
      loteId: loteId,
      loteNombre: (map['loteNombre'] ?? _nombreLote(loteId)).toString(),
      origen: (map['origen'] ?? 'sensor').toString(),
      fechaLectura: fecha,
      humedad: _toDouble(map['humedad']),
      temperatura: _toDouble(map['temperatura']),
      ph: _toDouble(map['ph']),
      ec: _toDouble(map['ec']),
      nitrogeno: _toDouble(map['nitrogeno']),
      fosforo: _toDouble(map['fosforo']),
      potasio: _toDouble(map['potasio']),
      pendienteSync: map['pendienteSync'] is bool
          ? map['pendienteSync'] as bool
          : false,
      sincronizado: map['sincronizado'] is bool
          ? map['sincronizado'] as bool
          : true,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static String _nombreLote(String loteId) {
    if (loteId == 'lote_2') return 'Lote 2';
    if (loteId == 'lote_3') return 'Lote 3';
    return 'Lote 1';
  }
}
