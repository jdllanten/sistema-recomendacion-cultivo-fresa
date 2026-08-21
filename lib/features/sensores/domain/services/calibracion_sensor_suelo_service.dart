
class CalibracionSensorSueloService {
  const CalibracionSensorSueloService();

  static const double _pendientePh = 0.909;
  static const double _interceptoPh = 0.01;

  //Aplica la corrección provisional al pH leído por el sensor.
  double calibrarPh(double phSensor) {
    final phCorregido = (_pendientePh * phSensor) + _interceptoPh;
    return _limitar(phCorregido, minimo: 0, maximo: 14);
  }

  double calibrarHumedad(double humedadSensor) {
    return _limitar(humedadSensor, minimo: 0, maximo: 100);
  }

  double calibrarTemperatura(double temperaturaSensor) {
    return temperaturaSensor;
  }

  double calibrarEc(double ecSensor) {
    return ecSensor < 0 ? 0 : ecSensor;
  }

  double calibrarNitrogeno(double nSensor) {
    return nSensor < 0 ? 0 : nSensor;
  }

  double calibrarFosforo(double pSensor) {
    return pSensor < 0 ? 0 : pSensor;
  }

  double calibrarPotasio(double kSensor) {
    return kSensor < 0 ? 0 : kSensor;
  }

  double _limitar(
    double valor, {
    required double minimo,
    required double maximo,
  }) {
    if (valor < minimo) return minimo;
    if (valor > maximo) return maximo;
    return valor;
  }
}
