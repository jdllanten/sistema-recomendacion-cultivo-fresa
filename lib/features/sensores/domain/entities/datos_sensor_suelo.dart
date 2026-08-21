//Lectura de datos del sensor de suelo
class DatosSensorSuelo {
  final double humedadSuelo;
  final double temperaturaSuelo;
  final double conductividadElectrica;
  final double phSuelo;
  final double nitrogeno;
  final double fosforo;
  final double potasio;
  final DateTime fechaLectura;

  const DatosSensorSuelo({
    required this.humedadSuelo,
    required this.temperaturaSuelo,
    required this.conductividadElectrica,
    required this.phSuelo,
    required this.nitrogeno,
    required this.fosforo,
    required this.potasio,
    required this.fechaLectura,
  });
}
