import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../entities/plan_nutricional.dart';

class CalculadoraPlanNutricionalNpk {
  const CalculadoraPlanNutricionalNpk();

  static const double _factorPAP2O5 = 2.29;
  static const double _factorKAK2O = 1.21;

  static const double _requerimientoTotalN = 104.4;
  static const double _requerimientoTotalP = 15;
  static const double _requerimientoTotalK = 229.5;

  static const List<FertilizanteDisponible> fertilizantesBase = <FertilizanteDisponible>[];

  PlanNutricionalNpk calcular({
    required DatosSensorSuelo lectura,
    required ParametrosPlanNutricionalNpk parametros,
    List<FertilizanteDisponible>? fertilizantesDisponibles,
  }) {
    final nitrogeno = _calcularNutriente(
      nombre: 'Nitrógeno',
      simbolo: 'N',
      valorSensorMgKg: lectura.nitrogeno,
      requerimientoKgHa: parametros.requerimientoNKgHa,
      eficienciaExploracion: parametros.eficienciaExploracionN,
      eficienciaAplicacion: parametros.eficienciaAplicacionN,
      factorFormaComercial: 1,
      nombreFormaComercial: 'N',
      parametros: parametros,
    );

    final fosforo = _calcularNutriente(
      nombre: 'Fósforo',
      simbolo: 'P',
      valorSensorMgKg: lectura.fosforo,
      requerimientoKgHa: parametros.requerimientoPKgHa,
      eficienciaExploracion: parametros.eficienciaExploracionP,
      eficienciaAplicacion: parametros.eficienciaAplicacionP,
      factorFormaComercial: _factorPAP2O5,
      nombreFormaComercial: 'P₂O₅',
      parametros: parametros,
    );

    final potasio = _calcularNutriente(
      nombre: 'Potasio',
      simbolo: 'K',
      valorSensorMgKg: lectura.potasio,
      requerimientoKgHa: parametros.requerimientoKKgHa,
      eficienciaExploracion: parametros.eficienciaExploracionK,
      eficienciaAplicacion: parametros.eficienciaAplicacionK,
      factorFormaComercial: _factorKAK2O,
      nombreFormaComercial: 'K₂O',
      parametros: parametros,
    );

    final listaFertilizantes =
        _prepararListaFertilizantes(fertilizantesDisponibles);

    final resultadoFertilizantes = _calcularFertilizantesCompuestos(
      necesidadN: nitrogeno.faltanteFormaComercialSemanaKg,
      necesidadP2O5: fosforo.faltanteFormaComercialSemanaKg,
      necesidadK2O: potasio.faltanteFormaComercialSemanaKg,
      fertilizantesDisponibles: listaFertilizantes,
    );

    return PlanNutricionalNpk(
      parametros: parametros,
      nitrogeno: nitrogeno,
      fosforo: fosforo,
      potasio: potasio,
      fertilizantes: resultadoFertilizantes.fertilizantes,
      resumenCobertura: resultadoFertilizantes.resumen,
      notaTecnica:
          'Este cálculo es orientativo y sigue la base Manzanillo: convierte las lecturas NPK del sensor a kg/ha, compara la disponibilidad con el requerimiento elemental de referencia, divide el déficit por la eficiencia del nutriente, transforma P a P₂O₅ y K a K₂O, ajusta a las hectáreas reales del lote, aplica el porcentaje de la etapa fenológica y distribuye la necesidad por semanas. La dosis final debe validarse con el asesor agronómico.',
    );
  }

List<FertilizanteDisponible> _prepararListaFertilizantes(
  List<FertilizanteDisponible>? fertilizantesDisponibles,
) {
  final lista = fertilizantesDisponibles ?? <FertilizanteDisponible>[];

  final filtrados = lista.where((fertilizante) {
    if (!fertilizante.disponible) return false;

    final tieneNpk = fertilizante.concentracionN > 0 ||
        fertilizante.concentracionP2O5 > 0 ||
        fertilizante.concentracionK2O > 0;

    return tieneNpk;
  }).toList();

  return filtrados;
}

  NutrientePlanNpk _calcularNutriente({
    required String nombre,
    required String simbolo,
    required double valorSensorMgKg,
    required double requerimientoKgHa,
    required double eficienciaExploracion,
    required double eficienciaAplicacion,
    required double factorFormaComercial,
    required String nombreFormaComercial,
    required ParametrosPlanNutricionalNpk parametros,
  }) {
    final requerimientoTotalKgHa = _requerimientoTotalCicloKgHa(
      simbolo: simbolo,
      valorConfiguradoKgHa: requerimientoKgHa,
    );

    final kgHaEnSuelo = _sensorMgKgAKgHa(
      valorSensorMgKg: valorSensorMgKg,
      pesoSueloKgHa: parametros.pesoSueloKgHa,
    );

    final kgHaDisponibleReal = kgHaEnSuelo * eficienciaExploracion;

    final faltanteKgHa = requerimientoTotalKgHa - kgHaDisponibleReal;

    final faltantePositivoKgHa = faltanteKgHa > 0 ? faltanteKgHa : 0.0;

    final faltanteAjustadoKgHa = _ajustarPorEficienciaAplicacion(
      faltantePositivoKgHa: faltantePositivoKgHa,
      eficienciaAplicacion: eficienciaAplicacion,
    );

    final faltanteFormaComercialKgHa =
        faltanteAjustadoKgHa * factorFormaComercial;

    final faltanteFormaComercialLoteCicloKg =
        faltanteFormaComercialKgHa * parametros.areaEquivalenteHa;

    final porcentajeEtapa = _porcentajeExtraccionEtapa(
      etapa: parametros.etapa,
      simbolo: simbolo,
    );

    final faltanteFormaComercialLoteKg =
        faltanteFormaComercialLoteCicloKg * porcentajeEtapa;

    final semanas =
        parametros.semanasEtapa <= 0 ? 1 : parametros.semanasEtapa;

    final faltanteFormaComercialSemanaKg =
        faltanteFormaComercialLoteKg / semanas;

    final faltanteFormaComercialMesKg =
        faltanteFormaComercialSemanaKg *
        ParametrosPlanNutricionalNpk.semanasPorMesReferencia;

    return NutrientePlanNpk(
      nombre: nombre,
      simbolo: simbolo,
      valorSensorMgKg: valorSensorMgKg,
      kgHaEnSuelo: kgHaEnSuelo,
      eficienciaExploracion: eficienciaExploracion,
      kgHaDisponibleReal: kgHaDisponibleReal,
      requerimientoKgHa: requerimientoTotalKgHa,
      faltanteKgHa: faltanteKgHa,
      eficienciaAplicacion: eficienciaAplicacion,
      faltanteAjustadoKgHa: faltanteAjustadoKgHa,
      factorFormaComercial: factorFormaComercial,
      nombreFormaComercial: nombreFormaComercial,
      faltanteFormaComercialKgHa: faltanteFormaComercialKgHa,
      faltanteFormaComercialLoteKg: faltanteFormaComercialLoteKg,
      faltanteFormaComercialSemanaKg: faltanteFormaComercialSemanaKg,
      faltanteFormaComercialMesKg: faltanteFormaComercialMesKg,
      estado: _clasificarEstado(
        faltanteKgHa: faltanteKgHa,
        requerimientoKgHa: requerimientoTotalKgHa,
      ),
    );
  }

  double _requerimientoTotalCicloKgHa({
    required String simbolo,
    required double valorConfiguradoKgHa,
  }) {
    if (valorConfiguradoKgHa > 0) {
      return valorConfiguradoKgHa;
    }

    switch (simbolo) {
      case 'N':
        return _requerimientoTotalN;
      case 'P':
        return _requerimientoTotalP;
      case 'K':
        return _requerimientoTotalK;
    }

    return 0;
  }

  double _ajustarPorEficienciaAplicacion({
    required double faltantePositivoKgHa,
    required double eficienciaAplicacion,
  }) {
    if (faltantePositivoKgHa <= 0) return 0;

    if (eficienciaAplicacion <= 0) {
      return faltantePositivoKgHa;
    }

    final eficiencia = eficienciaAplicacion > 1 ? 1.0 : eficienciaAplicacion;

    // Base Manzanillo:
    // necesidad de fertilización = déficit del suelo / eficiencia del nutriente.
    return faltantePositivoKgHa / eficiencia;
  }

  double _porcentajeExtraccionEtapa({
    required String etapa,
    required String simbolo,
  }) {
    final etapaNormalizada = etapa.toLowerCase();

    double porNpk({
      required double n,
      required double p,
      required double k,
    }) {
      switch (simbolo) {
        case 'N':
          return n;
        case 'P':
          return p;
        case 'K':
          return k;
      }
      return 0;
    }

    if (etapaNormalizada.contains('estolon')) {
      return porNpk(n: 0.20, p: 0.20, k: 0.20);
    }

    if (etapaNormalizada.contains('desarrollo')) {
      return porNpk(n: 0.30, p: 0.15, k: 0.15);
    }

    if (etapaNormalizada.contains('flor')) {
      return porNpk(n: 0.15, p: 0.30, k: 0.20);
    }

    if (etapaNormalizada.contains('fruct') ||
        etapaNormalizada.contains('alta')) {
      return porNpk(n: 0.10, p: 0.30, k: 0.40);
    }

    if (etapaNormalizada.contains('desyer') ||
        etapaNormalizada.contains('manten')) {
      return porNpk(n: 0.25, p: 0.05, k: 0.05);
    }

    // Si llega un nombre de etapa no reconocido, no se inventa una distribución.
    return 0;
  }

  double _sensorMgKgAKgHa({
    required double valorSensorMgKg,
    required double pesoSueloKgHa,
  }) {
    return valorSensorMgKg * pesoSueloKgHa / 1000000;
  }

  EstadoPlanNpk _clasificarEstado({
    required double faltanteKgHa,
    required double requerimientoKgHa,
  }) {
    if (faltanteKgHa <= 0) {
      return EstadoPlanNpk.suficiente;
    }

    if (requerimientoKgHa <= 0) {
      return EstadoPlanNpk.deficitModerado;
    }

    final proporcion = faltanteKgHa / requerimientoKgHa;

    if (proporcion >= 0.5) {
      return EstadoPlanNpk.deficitCritico;
    }

    if (proporcion >= 0.2) {
      return EstadoPlanNpk.deficitModerado;
    }

    return EstadoPlanNpk.deficitLeve;
  }

_ResultadoFertilizantes _calcularFertilizantesCompuestos({
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
  required List<FertilizanteDisponible> fertilizantesDisponibles,
}) {
  const tolerancia = 0.001;

  final necesidadRealN = necesidadN > tolerancia ? necesidadN : 0.0;
  final necesidadRealP2O5 =
      necesidadP2O5 > tolerancia ? necesidadP2O5 : 0.0;
  final necesidadRealK2O = necesidadK2O > tolerancia ? necesidadK2O : 0.0;

  final noRequiereCorreccion = necesidadRealN <= tolerancia &&
      necesidadRealP2O5 <= tolerancia &&
      necesidadRealK2O <= tolerancia;

  if (noRequiereCorreccion) {
    return _resultadoSinAplicacion(
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      observacion:
          'Con la lectura actual no se estima faltante semanal de N, P₂O₅ ni K₂O.',
    );
  }

  if (fertilizantesDisponibles.isEmpty) {
    return _resultadoSinAplicacion(
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      observacion:
          'No hay fertilizantes seleccionados para calcular el plan personalizado.',
    );
  }

  final abonosSimples = fertilizantesDisponibles
      .where(_esAbonoSimple)
      .toList();

  final abonosCompuestos = fertilizantesDisponibles
      .where((fertilizante) => !_esAbonoSimple(fertilizante))
      .toList();

  final sugeridos = <FertilizanteSugerido>[];

  if (abonosSimples.isNotEmpty) {
    final planN = _mejorAbonoSimpleParaObjetivo(
      objetivo: NutrienteObjetivo.nitrogeno,
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      fertilizantes: abonosSimples,
    );

    if (planN != null) {
      sugeridos.add(planN);
    }

    final planP = _mejorAbonoSimpleParaObjetivo(
      objetivo: NutrienteObjetivo.fosforo,
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      fertilizantes: abonosSimples,
    );

    if (planP != null) {
      sugeridos.add(planP);
    }

    final planK = _mejorAbonoSimpleParaObjetivo(
      objetivo: NutrienteObjetivo.potasio,
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      fertilizantes: abonosSimples,
    );

    if (planK != null) {
      sugeridos.add(planK);
    }
  }

  if (sugeridos.isEmpty && abonosCompuestos.isNotEmpty) {
    final mejorCompuesto = _mejorAbonoCompuesto(
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      fertilizantes: abonosCompuestos,
    );

    if (mejorCompuesto != null) {
      sugeridos.add(mejorCompuesto);
    }
  }

  if (sugeridos.isEmpty) {
  return _resultadoSinAplicacion(
    necesidadN: necesidadRealN,
    necesidadP2O5: necesidadRealP2O5,
    necesidadK2O: necesidadRealK2O,
    observacion: _mensajeSinCobertura(
      necesidadN: necesidadRealN,
      necesidadP2O5: necesidadRealP2O5,
      necesidadK2O: necesidadRealK2O,
      fertilizantes: fertilizantesDisponibles,
    ),
  );
}

  final aporteTotalN = sugeridos.fold<double>(
    0,
    (total, fertilizante) => total + fertilizante.aporteN,
  );

  final aporteTotalP2O5 = sugeridos.fold<double>(
    0,
    (total, fertilizante) => total + fertilizante.aporteP2O5,
  );

  final aporteTotalK2O = sugeridos.fold<double>(
    0,
    (total, fertilizante) => total + fertilizante.aporteK2O,
  );

  final costoTotal = sugeridos.fold<double>(
    0,
    (total, fertilizante) => total + fertilizante.costoEstimado,
  );

  final resumen = ResumenCoberturaNpk(
    necesidadN: necesidadRealN,
    necesidadP2O5: necesidadRealP2O5,
    necesidadK2O: necesidadRealK2O,
    aporteN: aporteTotalN,
    aporteP2O5: aporteTotalP2O5,
    aporteK2O: aporteTotalK2O,
    restanteN: _restarSinNegativo(necesidadRealN, aporteTotalN),
    restanteP2O5: _restarSinNegativo(necesidadRealP2O5, aporteTotalP2O5),
    restanteK2O: _restarSinNegativo(necesidadRealK2O, aporteTotalK2O),
    costoTotal: costoTotal,
  );

  return _ResultadoFertilizantes(
    fertilizantes: sugeridos,
    resumen: resumen,
  );
}

FertilizanteSugerido? _mejorAbonoSimpleParaObjetivo({
  required NutrienteObjetivo objetivo,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
  required List<FertilizanteDisponible> fertilizantes,
}) {
  const tolerancia = 0.001;

  final necesidadObjetivo = _necesidadSegunObjetivo(
    objetivo: objetivo,
    necesidadN: necesidadN,
    necesidadP2O5: necesidadP2O5,
    necesidadK2O: necesidadK2O,
  );

  if (necesidadObjetivo <= tolerancia) {
    return null;
  }

  final candidatos = fertilizantes.where((fertilizante) {
    final objetivoProducto = _objetivoAbonoSimple(fertilizante);
    if (objetivoProducto != objetivo) return false;

    final concentracionObjetivo = _concentracionSegunObjetivo(
      fertilizante: fertilizante,
      objetivo: objetivo,
    );

    return concentracionObjetivo > 0;
  }).toList();

  if (candidatos.isEmpty) return null;

  candidatos.sort((a, b) {
    final puntajeA = _puntajeAbonoSimple(
      fertilizante: a,
      objetivo: objetivo,
      necesidadN: necesidadN,
      necesidadP2O5: necesidadP2O5,
      necesidadK2O: necesidadK2O,
    );

    final puntajeB = _puntajeAbonoSimple(
      fertilizante: b,
      objetivo: objetivo,
      necesidadN: necesidadN,
      necesidadP2O5: necesidadP2O5,
      necesidadK2O: necesidadK2O,
    );

    return puntajeB.compareTo(puntajeA);
  });

  return _calcularAbonoSimple(
    fertilizante: candidatos.first,
    objetivo: objetivo,
    necesidadN: necesidadN,
    necesidadP2O5: necesidadP2O5,
    necesidadK2O: necesidadK2O,
  );
}

double _puntajeAbonoSimple({
  required FertilizanteDisponible fertilizante,
  required NutrienteObjetivo objetivo,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
}) {
  final concentracionObjetivo = _concentracionSegunObjetivo(
    fertilizante: fertilizante,
    objetivo: objetivo,
  );

  if (concentracionObjetivo <= 0) return -999999;

  final necesidadObjetivo = _necesidadSegunObjetivo(
    objetivo: objetivo,
    necesidadN: necesidadN,
    necesidadP2O5: necesidadP2O5,
    necesidadK2O: necesidadK2O,
  );

  if (necesidadObjetivo <= 0) return -999999;

  final kgProducto = necesidadObjetivo / (concentracionObjetivo / 100);

  final aporteN = kgProducto * fertilizante.concentracionN / 100;
  final aporteP2O5 = kgProducto * fertilizante.concentracionP2O5 / 100;
  final aporteK2O = kgProducto * fertilizante.concentracionK2O / 100;

  final aporteExtraN =
      objetivo == NutrienteObjetivo.nitrogeno ? 0.0 : aporteN;
  final aporteExtraP =
      objetivo == NutrienteObjetivo.fosforo ? 0.0 : aporteP2O5;
  final aporteExtraK =
      objetivo == NutrienteObjetivo.potasio ? 0.0 : aporteK2O;

  final aporteExtraTotal = aporteExtraN + aporteExtraP + aporteExtraK;

  // El precio no se usa como criterio principal.
  // Prioridad: concentración alta, bajo aporte extra y dosis razonable.
  return (concentracionObjetivo * 10) -
      (aporteExtraTotal * 25) -
      (kgProducto * 0.5);
}

FertilizanteSugerido? _calcularAbonoSimple({
  required FertilizanteDisponible fertilizante,
  required NutrienteObjetivo objetivo,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
}) {
  final necesidadObjetivo = _necesidadSegunObjetivo(
    objetivo: objetivo,
    necesidadN: necesidadN,
    necesidadP2O5: necesidadP2O5,
    necesidadK2O: necesidadK2O,
  );

  final concentracionObjetivo = _concentracionSegunObjetivo(
    fertilizante: fertilizante,
    objetivo: objetivo,
  );

  if (necesidadObjetivo <= 0 || concentracionObjetivo <= 0) {
    return null;
  }

  final kgProducto = necesidadObjetivo / (concentracionObjetivo / 100);

  if (kgProducto <= 0 || kgProducto.isNaN || kgProducto.isInfinite) {
    return null;
  }

  final aporteN = kgProducto * fertilizante.concentracionN / 100;
  final aporteP2O5 = kgProducto * fertilizante.concentracionP2O5 / 100;
  final aporteK2O = kgProducto * fertilizante.concentracionK2O / 100;

  final costoEstimado =
      fertilizante.precio > 0 ? kgProducto * fertilizante.precio : 0.0;

  return FertilizanteSugerido(
    nombre: fertilizante.nombre,
    kgPorSemana: kgProducto,
    concentracionN: fertilizante.concentracionN,
    concentracionP2O5: fertilizante.concentracionP2O5,
    concentracionK2O: fertilizante.concentracionK2O,
    nAntes: necesidadN,
    p2o5Antes: necesidadP2O5,
    k2oAntes: necesidadK2O,
    aporteN: aporteN,
    aporteP2O5: aporteP2O5,
    aporteK2O: aporteK2O,
    nDespues: _restarSinNegativo(necesidadN, aporteN),
    p2o5Despues: _restarSinNegativo(necesidadP2O5, aporteP2O5),
    k2oDespues: _restarSinNegativo(necesidadK2O, aporteK2O),
    satisfaceN: necesidadN > 0 ? aporteN / necesidadN : 0,
    satisfaceP2O5: necesidadP2O5 > 0 ? aporteP2O5 / necesidadP2O5 : 0,
    satisfaceK2O: necesidadK2O > 0 ? aporteK2O / necesidadK2O : 0,
    nutrienteObjetivo: _nombreObjetivo(objetivo),
    observacion: _observacionAbonoSimple(
      fertilizante: fertilizante,
      objetivo: objetivo,
      kgProducto: kgProducto,
      aporteN: aporteN,
      aporteP2O5: aporteP2O5,
      aporteK2O: aporteK2O,
      necesidadN: necesidadN,
      necesidadP2O5: necesidadP2O5,
      necesidadK2O: necesidadK2O,
    ),
    precioUnitario: fertilizante.precio,
    costoEstimado: costoEstimado,
  );
}

FertilizanteSugerido? _mejorAbonoCompuesto({
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
  required List<FertilizanteDisponible> fertilizantes,
}) {
  const tolerancia = 0.001;

  final requiereN = necesidadN > tolerancia;
  final requiereP = necesidadP2O5 > tolerancia;
  final requiereK = necesidadK2O > tolerancia;

  var candidatosFuente = [...fertilizantes];

  // Si hay potasio pendiente, se prefieren compuestos que no generen
  // un exceso desproporcionado de P₂O₅ para cubrir K₂O.
  if (requiereK) {
    final compuestosOrientadosAK = candidatosFuente.where((fertilizante) {
      return fertilizante.concentracionK2O > 0 &&
          fertilizante.concentracionK2O >= fertilizante.concentracionP2O5;
    }).toList();

    if (compuestosOrientadosAK.isNotEmpty) {
      candidatosFuente = compuestosOrientadosAK;
    }
  }

  final candidatos = candidatosFuente
      .map(
        (fertilizante) => _calcularAbonoCompuesto(
          fertilizante: fertilizante,
          necesidadN: necesidadN,
          necesidadP2O5: necesidadP2O5,
          necesidadK2O: necesidadK2O,
        ),
      )
      .whereType<FertilizanteSugerido>()
      .toList();

  if (candidatos.isEmpty) return null;

  candidatos.sort((a, b) {
    final puntajeA = _puntajeAbonoCompuesto(
      a,
      requiereN: requiereN,
      requiereP: requiereP,
      requiereK: requiereK,
    );

    final puntajeB = _puntajeAbonoCompuesto(
      b,
      requiereN: requiereN,
      requiereP: requiereP,
      requiereK: requiereK,
    );

    return puntajeB.compareTo(puntajeA);
  });

  return candidatos.first;
}

double _puntajeAbonoCompuesto(
  FertilizanteSugerido fertilizante, {
  required bool requiereN,
  required bool requiereP,
  required bool requiereK,
}) {
  const tolerancia = 0.001;

  final cubreN = !requiereN ||
      fertilizante.aporteN + tolerancia >= fertilizante.nAntes;
  final cubreP = !requiereP ||
      fertilizante.aporteP2O5 + tolerancia >= fertilizante.p2o5Antes;
  final cubreK = !requiereK ||
      fertilizante.aporteK2O + tolerancia >= fertilizante.k2oAntes;

  final nutrientesCubiertos = [
    requiereN && cubreN,
    requiereP && cubreP,
    requiereK && cubreK,
  ].where((cubre) => cubre).length;

  final nutrientesRequeridos = [
    requiereN,
    requiereP,
    requiereK,
  ].where((requiere) => requiere).length;

  final coberturaCompleta = nutrientesRequeridos > 0 &&
      nutrientesCubiertos == nutrientesRequeridos;

  final faltanteRestante = fertilizante.nDespues +
      fertilizante.p2o5Despues +
      fertilizante.k2oDespues;

  final excesoN = fertilizante.aporteN > fertilizante.nAntes
      ? fertilizante.aporteN - fertilizante.nAntes
      : 0.0;

  final excesoP = fertilizante.aporteP2O5 > fertilizante.p2o5Antes
      ? fertilizante.aporteP2O5 - fertilizante.p2o5Antes
      : 0.0;

  final excesoK = fertilizante.aporteK2O > fertilizante.k2oAntes
      ? fertilizante.aporteK2O - fertilizante.k2oAntes
      : 0.0;

  final excesoTotal = excesoN + excesoP + excesoK;

  // Balance general del producto:
  final balanceProduccion =
      (fertilizante.concentracionP2O5 * 1.2) +
      (fertilizante.concentracionK2O * 1.5) -
      (fertilizante.concentracionN * 0.4);

  return
      // cubrir la mayor cantidad de nutrientes requeridos.
      (nutrientesCubiertos * 100000) +

      // premiar si cubre todo.
      (coberturaCompleta ? 100000 : 0) +

      // castigar muy fuerte los faltantes.
      (faltanteRestante * -80000) +

      // favorecer balance para producción/fructificación.
      (balanceProduccion * 100) -

      // evitar excesos grandes.
      (excesoTotal * 900) -

      // entre productos parecidos, gana menor dosis.
      (fertilizante.kgPorSemana * 250);
}

FertilizanteSugerido? _calcularAbonoCompuesto({
  required FertilizanteDisponible fertilizante,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
}) {
  final dosisParaN = fertilizante.concentracionN > 0 && necesidadN > 0.001
      ? necesidadN / (fertilizante.concentracionN / 100)
      : 0.0;

  final dosisParaP2O5 =
      fertilizante.concentracionP2O5 > 0 && necesidadP2O5 > 0.001
          ? necesidadP2O5 / (fertilizante.concentracionP2O5 / 100)
          : 0.0;

  final dosisParaK2O =
      fertilizante.concentracionK2O > 0 && necesidadK2O > 0.001
          ? necesidadK2O / (fertilizante.concentracionK2O / 100)
          : 0.0;

  final dosisFinal = [
    dosisParaN,
    dosisParaP2O5,
    dosisParaK2O,
  ].reduce((a, b) => a > b ? a : b);

  if (dosisFinal <= 0 || dosisFinal.isNaN || dosisFinal.isInfinite) {
    return null;
  }

  final objetivo = _objetivoPorDosisMayor(
    dosisParaN: dosisParaN,
    dosisParaP2O5: dosisParaP2O5,
    dosisParaK2O: dosisParaK2O,
  );

  final aporteN = dosisFinal * fertilizante.concentracionN / 100;
  final aporteP2O5 = dosisFinal * fertilizante.concentracionP2O5 / 100;
  final aporteK2O = dosisFinal * fertilizante.concentracionK2O / 100;

  final costoEstimado =
      fertilizante.precio > 0 ? dosisFinal * fertilizante.precio : 0.0;

  return FertilizanteSugerido(
    nombre: fertilizante.nombre,
    kgPorSemana: dosisFinal,
    concentracionN: fertilizante.concentracionN,
    concentracionP2O5: fertilizante.concentracionP2O5,
    concentracionK2O: fertilizante.concentracionK2O,
    nAntes: necesidadN,
    p2o5Antes: necesidadP2O5,
    k2oAntes: necesidadK2O,
    aporteN: aporteN,
    aporteP2O5: aporteP2O5,
    aporteK2O: aporteK2O,
    nDespues: _restarSinNegativo(necesidadN, aporteN),
    p2o5Despues: _restarSinNegativo(necesidadP2O5, aporteP2O5),
    k2oDespues: _restarSinNegativo(necesidadK2O, aporteK2O),
    satisfaceN: necesidadN > 0 ? aporteN / necesidadN : 0,
    satisfaceP2O5: necesidadP2O5 > 0 ? aporteP2O5 / necesidadP2O5 : 0,
    satisfaceK2O: necesidadK2O > 0 ? aporteK2O / necesidadK2O : 0,
    nutrienteObjetivo: _nombreObjetivo(objetivo),
    observacion: _observacionAbonoCompuesto(
      fertilizante: fertilizante,
      objetivo: objetivo,
      kgProducto: dosisFinal,
      aporteN: aporteN,
      aporteP2O5: aporteP2O5,
      aporteK2O: aporteK2O,
      necesidadN: necesidadN,
      necesidadP2O5: necesidadP2O5,
      necesidadK2O: necesidadK2O,
    ),
    precioUnitario: fertilizante.precio,
    costoEstimado: costoEstimado,
  );
}

_ResultadoFertilizantes _resultadoSinAplicacion({
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
  required String observacion,
}) {
  return _ResultadoFertilizantes(
    fertilizantes: [
      FertilizanteSugerido(
        nombre: 'Sin aplicación sugerida',
        kgPorSemana: 0,
        concentracionN: 0,
        concentracionP2O5: 0,
        concentracionK2O: 0,
        nAntes: necesidadN,
        p2o5Antes: necesidadP2O5,
        k2oAntes: necesidadK2O,
        aporteN: 0,
        aporteP2O5: 0,
        aporteK2O: 0,
        nDespues: necesidadN,
        p2o5Despues: necesidadP2O5,
        k2oDespues: necesidadK2O,
        satisfaceN: 0,
        satisfaceP2O5: 0,
        satisfaceK2O: 0,
        nutrienteObjetivo: 'Mantenimiento',
        observacion: observacion,
        precioUnitario: 0,
        costoEstimado: 0,
      ),
    ],
    resumen: ResumenCoberturaNpk(
      necesidadN: necesidadN,
      necesidadP2O5: necesidadP2O5,
      necesidadK2O: necesidadK2O,
      aporteN: 0,
      aporteP2O5: 0,
      aporteK2O: 0,
      restanteN: necesidadN,
      restanteP2O5: necesidadP2O5,
      restanteK2O: necesidadK2O,
      costoTotal: 0,
    ),
  );
}

bool _esAbonoSimple(FertilizanteDisponible fertilizante) {
  final nombre = fertilizante.nombre.toLowerCase();

  // Productos simples conocidos por nombre.
  if (nombre.contains('urea') ||
      nombre.contains('amonio') ||
      nombre.contains('map') ||
      nombre.contains('monoamónico') ||
      nombre.contains('monoamonico') ||
      nombre.contains('nitrato de potasio') ||
      nombre.contains('sulfato de potasio')) {
    return true;
  }

  final nutrientesPrincipales = <double>[
    fertilizante.concentracionN,
    fertilizante.concentracionP2O5,
    fertilizante.concentracionK2O,
  ].where((valor) => valor > 0).length;


  if (nutrientesPrincipales == 1) {
    return true;
  }


  if (nutrientesPrincipales == 2) {
    return true;
  }

  return false;
}


NutrienteObjetivo? _objetivoAbonoSimple(FertilizanteDisponible fertilizante) {
  final nombre = fertilizante.nombre.toLowerCase();

  // Casos conocidos por nombre.
  if (nombre.contains('urea') || nombre.contains('amonio')) {
    return NutrienteObjetivo.nitrogeno;
  }

  if (nombre.contains('map') ||
      nombre.contains('monoamónico') ||
      nombre.contains('monoamonico')) {
    return NutrienteObjetivo.fosforo;
  }

  if (nombre.contains('nitrato de potasio') ||
      nombre.contains('sulfato de potasio')) {
    return NutrienteObjetivo.potasio;
  }


  final n = fertilizante.concentracionN;
  final p = fertilizante.concentracionP2O5;
  final k = fertilizante.concentracionK2O;

  if (n <= 0 && p <= 0 && k <= 0) {
    return null;
  }

  if (k >= n && k >= p && k > 0) {
    return NutrienteObjetivo.potasio;
  }

  if (p >= n && p >= k && p > 0) {
    return NutrienteObjetivo.fosforo;
  }

  if (n > 0) {
    return NutrienteObjetivo.nitrogeno;
  }

  return null;
}

NutrienteObjetivo _objetivoPorDosisMayor({
  required double dosisParaN,
  required double dosisParaP2O5,
  required double dosisParaK2O,
}) {
  if (dosisParaP2O5 >= dosisParaN && dosisParaP2O5 >= dosisParaK2O) {
    return NutrienteObjetivo.fosforo;
  }

  if (dosisParaK2O >= dosisParaN && dosisParaK2O >= dosisParaP2O5) {
    return NutrienteObjetivo.potasio;
  }

  return NutrienteObjetivo.nitrogeno;
}

double _necesidadSegunObjetivo({
  required NutrienteObjetivo objetivo,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
}) {
  switch (objetivo) {
    case NutrienteObjetivo.nitrogeno:
      return necesidadN;
    case NutrienteObjetivo.fosforo:
      return necesidadP2O5;
    case NutrienteObjetivo.potasio:
      return necesidadK2O;
  }
}

double _concentracionSegunObjetivo({
  required FertilizanteDisponible fertilizante,
  required NutrienteObjetivo objetivo,
}) {
  switch (objetivo) {
    case NutrienteObjetivo.nitrogeno:
      return fertilizante.concentracionN;
    case NutrienteObjetivo.fosforo:
      return fertilizante.concentracionP2O5;
    case NutrienteObjetivo.potasio:
      return fertilizante.concentracionK2O;
  }
}

String _nombreObjetivo(NutrienteObjetivo objetivo) {
  switch (objetivo) {
    case NutrienteObjetivo.nitrogeno:
      return 'N';
    case NutrienteObjetivo.fosforo:
      return 'P₂O₅';
    case NutrienteObjetivo.potasio:
      return 'K₂O';
  }
}

String _observacionAbonoSimple({
  required FertilizanteDisponible fertilizante,
  required NutrienteObjetivo objetivo,
  required double kgProducto,
  required double aporteN,
  required double aporteP2O5,
  required double aporteK2O,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
}) {
  final objetivoTexto = _nombreObjetivo(objetivo);

  return '${fertilizante.nombre} fue seleccionado como la mejor opción para cubrir $objetivoTexto, '
      'priorizando la concentración del nutriente y evitando aportes adicionales innecesarios. '
      'Dosis estimada: ${kgProducto.toStringAsFixed(2)} kg/semana.';
}

String _observacionAbonoCompuesto({
  required FertilizanteDisponible fertilizante,
  required NutrienteObjetivo objetivo,
  required double kgProducto,
  required double aporteN,
  required double aporteP2O5,
  required double aporteK2O,
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
}) {
  final objetivoTexto = _nombreObjetivo(objetivo);

  final resumen = <String>[
    _textoCobertura(
      nombre: 'N',
      requerido: necesidadN,
      aportado: aporteN,
    ),
    _textoCobertura(
      nombre: 'P₂O₅',
      requerido: necesidadP2O5,
      aportado: aporteP2O5,
    ),
    _textoCobertura(
      nombre: 'K₂O',
      requerido: necesidadK2O,
      aportado: aporteK2O,
    ),
  ].join(' ');

  return '${fertilizante.nombre} fue evaluado como abono compuesto. '
      'La dosis final es ${kgProducto.toStringAsFixed(2)} kg/semana porque el nutriente limitante es $objetivoTexto. '
      '$resumen';
}

String _textoCobertura({
  required String nombre,
  required double requerido,
  required double aportado,
}) {
  if (requerido <= 0.001 && aportado <= 0.001) {
    return '$nombre no requiere corrección.';
  }

  if (requerido <= 0.001 && aportado > 0.001) {
    return '$nombre no requería corrección y recibe ${aportado.toStringAsFixed(2)} kg adicionales.';
  }

  final diferencia = aportado - requerido;

  if (diferencia.abs() <= 0.001) {
    return '$nombre queda cubierto.';
  }

  if (diferencia > 0) {
    return '$nombre se excede en ${diferencia.toStringAsFixed(2)} kg.';
  }

  return '$nombre aún queda corto en ${diferencia.abs().toStringAsFixed(2)} kg.';
}

double _restarSinNegativo(double valor, double aporte) {
  final resultado = valor - aporte;
  return resultado > 0 ? resultado : 0.0;
}
}


String _mensajeSinCobertura({
  required double necesidadN,
  required double necesidadP2O5,
  required double necesidadK2O,
  required List<FertilizanteDisponible> fertilizantes,
}) {
  final faltantes = <String>[];

  if (necesidadN > 0.001) {
    faltantes.add('N');
  }

  if (necesidadP2O5 > 0.001) {
    faltantes.add('P₂O₅');
  }

  if (necesidadK2O > 0.001) {
    faltantes.add('K₂O');
  }

  final productos = fertilizantes.map((f) => f.nombre).join(', ');

  if (fertilizantes.isEmpty) {
    return 'No hay fertilizantes seleccionados. Selecciona al menos un producto disponible para calcular la dosis.';
  }

  if (faltantes.isEmpty) {
    return 'Con la lectura actual no se estima faltante semanal de N, P₂O₅ ni K₂O. No se requiere aplicar fertilizante.';
  }

  return 'Los productos seleccionados ($productos) no cubren los nutrientes que actualmente requieren corrección: ${faltantes.join(', ')}. '
      'Selecciona un fertilizante que aporte esos nutrientes.';
}



class _ResultadoFertilizantes {
  const _ResultadoFertilizantes({
    required this.fertilizantes,
    required this.resumen,
  });

  final List<FertilizanteSugerido> fertilizantes;
  final ResumenCoberturaNpk resumen;
}