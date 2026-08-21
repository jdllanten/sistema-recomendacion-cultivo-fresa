enum TipoRecomendacion {
  riego,
  fertilizacion,
  ph,
  temperatura,
  salinidad,
  general,
}

class Recomendacion {
  const Recomendacion({
    required this.titulo,
    required this.descripcion,
    required this.prioridad,
    required this.tipo,
    this.variable,
    this.valorActual,
    this.rangoIdeal,
    this.accionSugerida,
    this.explicacion,
  });


  final String titulo;

  final String descripcion;

  final int prioridad;

  final TipoRecomendacion tipo;

  final String? variable;

  final String? valorActual;

  final String? rangoIdeal;

  final String? accionSugerida;

  final String? explicacion;
}