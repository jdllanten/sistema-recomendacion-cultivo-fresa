import '../widgets/tarjeta_sensor.dart';

//calcula el estado del sensor en función de su valor actual y los rangos definidos para cada estado
//Se utiliza para determinar si un sensor está en estado óptimo, advertencia o crítico,

EstadoSensor calcularEstadoSensor({
  required double valor,
  required double rangoIdealMinimo,
  required double rangoIdealMaximo,
  double margenAdvertencia = 0.15,
}) {
  if (valor >= rangoIdealMinimo && valor <= rangoIdealMaximo) {
    return EstadoSensor.optimo;
  } 
   final amplitudRango = rangoIdealMaximo - rangoIdealMinimo;
  final margen = amplitudRango * margenAdvertencia;

  final limiteAdvertenciaInferior = rangoIdealMinimo - margen;
  final limiteAdvertenciaSuperior = rangoIdealMaximo + margen;

  if (valor >= limiteAdvertenciaInferior && valor <= limiteAdvertenciaSuperior) {
    return EstadoSensor.advertencia;
  }

  return EstadoSensor.critico;
}
