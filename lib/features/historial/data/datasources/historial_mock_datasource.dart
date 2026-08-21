import '../../domain/entities/lectura_historial.dart';

// Fuente de datos simulada para el historial.
// Se usa cuando todavía no hay lecturas guardadas localmente.
class HistorialMockDatasource {
  const HistorialMockDatasource();

  List<LecturaHistorial> obtenerLecturasRecientes() {
    final ahora = DateTime.now();

    return [
      LecturaHistorial(
        fechaLectura: ahora.subtract(const Duration(hours: 8)),
        humedad: 61,
        temperatura: 19,
        ph: 5.6,
        ec: 1.7,
        nitrogeno: 90,
        fosforo: 40,
        potasio: 115,
      ),
      LecturaHistorial(
        fechaLectura: ahora.subtract(const Duration(hours: 6)),
        humedad: 63,
        temperatura: 20,
        ph: 5.7,
        ec: 1.8,
        nitrogeno: 95,
        fosforo: 42,
        potasio: 118,
      ),
      LecturaHistorial(
        fechaLectura: ahora.subtract(const Duration(hours: 4)),
        humedad: 65,
        temperatura: 21,
        ph: 5.7,
        ec: 1.8,
        nitrogeno: 100,
        fosforo: 45,
        potasio: 120,
      ),
      LecturaHistorial(
        fechaLectura: ahora.subtract(const Duration(hours: 2)),
        humedad: 58,
        temperatura: 23,
        ph: 5.8,
        ec: 1.9,
        nitrogeno: 105,
        fosforo: 50,
        potasio: 130,
      ),
      LecturaHistorial(
        fechaLectura: ahora,
        humedad: 54,
        temperatura: 24,
        ph: 5.9,
        ec: 2.0,
        nitrogeno: 110,
        fosforo: 52,
        potasio: 140,
      ),
    ];
  }
}