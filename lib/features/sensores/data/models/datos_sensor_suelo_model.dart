import '../../domain/entities/datos_sensor_suelo.dart';

//Modelo de datos para convertir JSON proveniente de la ESP32
class DatosSensorSueloModel extends DatosSensorSuelo {
  const DatosSensorSueloModel({
    required super.humedadSuelo,
    required super.temperaturaSuelo,
    required super.conductividadElectrica,
    required super.phSuelo,
    required super.nitrogeno,
    required super.fosforo,
    required super.potasio,
    required super.fechaLectura,
  });

  factory DatosSensorSueloModel.fromJson(Map<String, dynamic> json) {
    return DatosSensorSueloModel(
      humedadSuelo: _toDouble(json['humedadSuelo']),
      temperaturaSuelo: _toDouble(json['temperaturaSuelo']),
      conductividadElectrica: _toDouble(json['conductividadElectrica']),
      phSuelo: _toDouble(json['phSuelo']),
      nitrogeno: _toDouble(json['nitrogeno']),
      fosforo: _toDouble(json['fosforo']),
      potasio: _toDouble(json['potasio']),
      fechaLectura: _parseFechaLectura(json['fechaLectura']),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'humedadSuelo': humedadSuelo,
      'temperaturaSuelo': temperaturaSuelo,
      'conductividadElectrica': conductividadElectrica,
      'phSuelo': phSuelo,
      'nitrogeno': nitrogeno,
      'fosforo': fosforo,
      'potasio': potasio,
      'fechaLectura': fechaLectura.toIso8601String(),
    };
  }
static DateTime _parseFechaLectura(dynamic value) {
  if (value == null) return DateTime.now();
  final str = value.toString().trim();
  if (str.isEmpty) return DateTime.now();
  try {
    return DateTime.parse(str);
  } catch (_) {
    return DateTime.now();
  }
}
  static double _toDouble(dynamic value) {
    if (value is int) return value.toDouble();
    if (value is double) return value;
    if (value is String) return double.tryParse(value) ?? 0;
    return 0;
  }
}