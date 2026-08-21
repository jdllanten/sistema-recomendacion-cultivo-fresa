class ParametrosPlanNutricionalNpk {
  const ParametrosPlanNutricionalNpk({
    this.areaM2 = 1000,
    this.numeroPlantasLote = 6000,
    this.plantasPorHectarea = 60000,
    this.profundidadRaizM = 0.20,
    this.densidadAparenteKgM3 = 1000,
    this.semanasEtapa = 16,
    this.mesesEtapa = 4,
    this.etapa = 'Fructificación',
    this.eficienciaExploracionN = 1.0,
    this.eficienciaExploracionP = 1.0,
    this.eficienciaExploracionK = 1.0,
    this.eficienciaAplicacionN = 0.40,
    this.eficienciaAplicacionP = 0.10,
    this.eficienciaAplicacionK = 0.50,
    this.requerimientoNKgHa = 104.4,
    this.requerimientoPKgHa = 15,
    this.requerimientoKKgHa = 229.5,
  });

  final double areaM2;
  final int numeroPlantasLote;
  final int plantasPorHectarea;
  final double profundidadRaizM;
  final double densidadAparenteKgM3;

  //Periodo principal de cálculo de la nueva base: semanas por etapa.
  final int semanasEtapa;

  final int mesesEtapa;
  final String etapa;


  final double eficienciaExploracionN;
  final double eficienciaExploracionP;
  final double eficienciaExploracionK;


  final double eficienciaAplicacionN;
  final double eficienciaAplicacionP;
  final double eficienciaAplicacionK;


  final double requerimientoNKgHa;
  final double requerimientoPKgHa;
  final double requerimientoKKgHa;

  static const int plantasPorHectareaReferencia = 60000;
  static const double semanasPorMesReferencia = 4.345;

  double get pesoSueloKgHa {
    return 10000 * profundidadRaizM * densidadAparenteKgM3;
  }

  double get areaEquivalenteHaPorPlantas {
    if (numeroPlantasLote <= 0) {
      return areaM2 > 0 ? areaM2 / 10000 : 0;
    }

    final densidad = plantasPorHectarea > 0
        ? plantasPorHectarea
        : plantasPorHectareaReferencia;

    return numeroPlantasLote / densidad;
  }

  double get areaEquivalenteHaPorArea {
    return areaM2 > 0 ? areaM2 / 10000 : 0;
  }

  double get areaEquivalenteHa {
    if (areaM2 > 0) {
      return areaEquivalenteHaPorArea;
    }

    return areaEquivalenteHaPorPlantas;
  }

  double get eficienciaNutrienteN => eficienciaAplicacionN;
  double get eficienciaNutrienteP => eficienciaAplicacionP;
  double get eficienciaNutrienteK => eficienciaAplicacionK;
}

class NutrientePlanNpk {
  const NutrientePlanNpk({
    required this.nombre,
    required this.simbolo,
    required this.valorSensorMgKg,
    required this.kgHaEnSuelo,
    required this.eficienciaExploracion,
    required this.kgHaDisponibleReal,
    required this.requerimientoKgHa,
    required this.faltanteKgHa,
    required this.eficienciaAplicacion,
    required this.faltanteAjustadoKgHa,
    required this.factorFormaComercial,
    required this.nombreFormaComercial,
    required this.faltanteFormaComercialKgHa,
    required this.faltanteFormaComercialLoteKg,
    required this.faltanteFormaComercialSemanaKg,
    required this.faltanteFormaComercialMesKg,
    required this.estado,
  });

  final String nombre;
  final String simbolo;
  final double valorSensorMgKg;
  final double kgHaEnSuelo;

  
  final double eficienciaExploracion;
  final double kgHaDisponibleReal;
  final double requerimientoKgHa;
  final double faltanteKgHa;

 
  final double eficienciaAplicacion;
  final double faltanteAjustadoKgHa;
  final double factorFormaComercial;
  final String nombreFormaComercial;
  final double faltanteFormaComercialKgHa;


  final double faltanteFormaComercialLoteKg;

  
  final double faltanteFormaComercialSemanaKg;

  
  final double faltanteFormaComercialMesKg;
  final EstadoPlanNpk estado;

  bool get tieneDeficit => faltanteKgHa > 0;

  bool get requiereAplicacionSemanal {
    return faltanteFormaComercialSemanaKg > 0;
  }

  bool get requiereAplicacionMensual {
    return faltanteFormaComercialMesKg > 0;
  }
}

class FertilizanteDisponible {
  const FertilizanteDisponible({
    required this.nombre,
    required this.precio,
    required this.concentracionN,
    required this.concentracionP2O5,
    required this.concentracionK2O,
    this.concentracionMgO = 0,
    this.concentracionCa = 0,
    this.concentracionB = 0,
    this.disponible = true,
  });

  final String nombre;
  final double precio;


  final double concentracionN;
  final double concentracionP2O5;
  final double concentracionK2O;

  final double concentracionMgO;
  final double concentracionCa;
  final double concentracionB;
  final bool disponible;

  bool get aportaN => concentracionN > 0;
  bool get aportaP2O5 => concentracionP2O5 > 0;
  bool get aportaK2O => concentracionK2O > 0;

  int get numeroNutrientesNpk {
    var total = 0;
    if (aportaN) total++;
    if (aportaP2O5) total++;
    if (aportaK2O) total++;
    return total;
  }

  bool get esCompuesto => numeroNutrientesNpk >= 2;
}

class FertilizanteSugerido {
  const FertilizanteSugerido({
    required this.nombre,
    required this.kgPorSemana,
    required this.concentracionN,
    required this.concentracionP2O5,
    required this.concentracionK2O,
    required this.nAntes,
    required this.p2o5Antes,
    required this.k2oAntes,
    required this.aporteN,
    required this.aporteP2O5,
    required this.aporteK2O,
    required this.nDespues,
    required this.p2o5Despues,
    required this.k2oDespues,
    required this.satisfaceN,
    required this.satisfaceP2O5,
    required this.satisfaceK2O,
    required this.nutrienteObjetivo,
    required this.observacion,
    required this.precioUnitario,
    required this.costoEstimado,
  });

  final String nombre;

  
  final double kgPorSemana;

 
  double get kgPorMes =>
      kgPorSemana * ParametrosPlanNutricionalNpk.semanasPorMesReferencia;

  final double concentracionN;
  final double concentracionP2O5;
  final double concentracionK2O;

  final double nAntes;
  final double p2o5Antes;
  final double k2oAntes;

  final double aporteN;
  final double aporteP2O5;
  final double aporteK2O;

  final double nDespues;
  final double p2o5Despues;
  final double k2oDespues;

  final double satisfaceN;
  final double satisfaceP2O5;
  final double satisfaceK2O;

  final String nutrienteObjetivo;
  final String observacion;

  final double precioUnitario;
  final double costoEstimado;
}

class ResumenCoberturaNpk {
  const ResumenCoberturaNpk({
    required this.necesidadN,
    required this.necesidadP2O5,
    required this.necesidadK2O,
    required this.aporteN,
    required this.aporteP2O5,
    required this.aporteK2O,
    required this.restanteN,
    required this.restanteP2O5,
    required this.restanteK2O,
    required this.costoTotal,
  });

  
  final double necesidadN;
  final double necesidadP2O5;
  final double necesidadK2O;

  final double aporteN;
  final double aporteP2O5;
  final double aporteK2O;

  final double restanteN;
  final double restanteP2O5;
  final double restanteK2O;

  final double costoTotal;
}

class PlanNutricionalNpk {
  const PlanNutricionalNpk({
    required this.parametros,
    required this.nitrogeno,
    required this.fosforo,
    required this.potasio,
    required this.fertilizantes,
    required this.resumenCobertura,
    required this.notaTecnica,
  });

  final ParametrosPlanNutricionalNpk parametros;
  final NutrientePlanNpk nitrogeno;
  final NutrientePlanNpk fosforo;
  final NutrientePlanNpk potasio;
  final List<FertilizanteSugerido> fertilizantes;
  final ResumenCoberturaNpk resumenCobertura;
  final String notaTecnica;

  bool get requiereCorreccion {
    return nitrogeno.tieneDeficit ||
        fosforo.tieneDeficit ||
        potasio.tieneDeficit;
  }

  bool get requiereAplicacionSemanal {
    return nitrogeno.requiereAplicacionSemanal ||
        fosforo.requiereAplicacionSemanal ||
        potasio.requiereAplicacionSemanal;
  }

  bool get requiereAplicacionMensual {
    return nitrogeno.requiereAplicacionMensual ||
        fosforo.requiereAplicacionMensual ||
        potasio.requiereAplicacionMensual;
  }
}

enum EstadoPlanNpk {
  suficiente,
  deficitLeve,
  deficitModerado,
  deficitCritico,
  exceso,
}

enum NutrienteObjetivo {
  nitrogeno,
  fosforo,
  potasio,
}
