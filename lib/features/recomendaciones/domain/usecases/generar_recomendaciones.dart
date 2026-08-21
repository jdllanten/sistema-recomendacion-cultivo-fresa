import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../entities/recomendacion.dart';
import '../services/generador_recomendaciones.dart';

class GenerarRecomendaciones {
  const GenerarRecomendaciones({
    required this.generador,
  });

  final GeneradorRecomendaciones generador;

  List<Recomendacion> call(
    DatosSensorSuelo lectura, {
    List<LecturaHistorial> historial = const [],
  }) {
    return generador.generar(
      lectura,
      historial: historial,
    );
  }
}