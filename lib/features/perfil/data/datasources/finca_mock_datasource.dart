import '../../domain/entities/finca.dart';

// llega los datos de la finca o el perfil
class FincaMockDatasource {
  const FincaMockDatasource();

  Finca obtenerFinca() {
    return Finca(
      nombre: 'Finca',
      ubicacion: 'Cauca, Colombia',
      areaHectareas: 1,
      variedadCultivo: 'Fresa Albión',
      etapaCultivo: 'Fructificación',
      tipoSensor: 'Sensor de suelo RS485 Modbus 7 en 1',
      metodoConexion: 'ESP32 + RS485/TTL',
      ultimaSincronizacion: DateTime.now(),
    );
  }
}