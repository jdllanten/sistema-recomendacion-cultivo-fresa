class Finca {
  const Finca({
    required this.nombre,
    required this.ubicacion,
    required this.areaHectareas,
    required this.variedadCultivo,
    required this.etapaCultivo,
    required this.tipoSensor,
    required this.metodoConexion,
    required this.ultimaSincronizacion,
  });

  final String nombre;
  final String ubicacion;
  final double areaHectareas;
  final String variedadCultivo;
  final String etapaCultivo;
  final String tipoSensor;
  final String metodoConexion;
  final DateTime ultimaSincronizacion;
}