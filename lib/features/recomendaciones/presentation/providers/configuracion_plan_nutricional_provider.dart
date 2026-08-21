import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../domain/entities/plan_nutricional.dart';
import '../../../lotes/domain/entities/lote_cultivo.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';

enum EtapaFenologicaNpk {
  desarrolloVegetativo,
  desarrolloEstolones,
  floracion,
  fructificacion,
  desyerba,
}

extension EtapaFenologicaNpkTexto on EtapaFenologicaNpk {
  String get nombre {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return 'Desarrollo vegetativo';
      case EtapaFenologicaNpk.desarrolloEstolones:
        return 'Desarrollo de estolones';
      case EtapaFenologicaNpk.floracion:
        return 'Floración';
      case EtapaFenologicaNpk.fructificacion:
        return 'Fructificación';
      case EtapaFenologicaNpk.desyerba:
        return 'Desyerba';
    }
  }

  String get rangoDias {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return '0–90 días';
      case EtapaFenologicaNpk.desarrolloEstolones:
        return '90–150 días';
      case EtapaFenologicaNpk.floracion:
        return '150–190 días';
      case EtapaFenologicaNpk.fructificacion:
        return '190–310 días';
      case EtapaFenologicaNpk.desyerba:
        return '310–350 días';
    }
  }

  /// Se conserva para compatibilidad con pantallas anteriores.
  String get duracionMeses {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return '0 a 3 meses';
      case EtapaFenologicaNpk.desarrolloEstolones:
        return '3 a 5 meses';
      case EtapaFenologicaNpk.floracion:
        return '5 a 6,3 meses';
      case EtapaFenologicaNpk.fructificacion:
        return '6,3 a 10,3 meses';
      case EtapaFenologicaNpk.desyerba:
        return '10,3 a 11,7 meses';
    }
  }

  String get duracionSemanas => '$semanas semanas';

  int get semanas {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return 13;
      case EtapaFenologicaNpk.desarrolloEstolones:
        return 9;
      case EtapaFenologicaNpk.floracion:
        return 6;
      case EtapaFenologicaNpk.fructificacion:
        return 16;
      case EtapaFenologicaNpk.desyerba:
        return 6;
    }
  }

  /// Compatibilidad con código antiguo. El motor nuevo trabaja por semanas.
  int get mesesCalculo {
    final meses = (semanas / ParametrosPlanNutricionalNpk.semanasPorMesReferencia)
        .ceil();
    return meses <= 0 ? 1 : meses;
  }

  double get porcentajeN {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return 0.30;
      case EtapaFenologicaNpk.desarrolloEstolones:
        return 0.20;
      case EtapaFenologicaNpk.floracion:
        return 0.15;
      case EtapaFenologicaNpk.fructificacion:
        return 0.10;
      case EtapaFenologicaNpk.desyerba:
        return 0.25;
    }
  }

  double get porcentajeP {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return 0.15;
      case EtapaFenologicaNpk.desarrolloEstolones:
        return 0.20;
      case EtapaFenologicaNpk.floracion:
        return 0.30;
      case EtapaFenologicaNpk.fructificacion:
        return 0.30;
      case EtapaFenologicaNpk.desyerba:
        return 0.05;
    }
  }

  double get porcentajeK {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return 0.15;
      case EtapaFenologicaNpk.desarrolloEstolones:
        return 0.20;
      case EtapaFenologicaNpk.floracion:
        return 0.20;
      case EtapaFenologicaNpk.fructificacion:
        return 0.40;
      case EtapaFenologicaNpk.desyerba:
        return 0.05;
    }
  }

  /// El requerimiento elemental de referencia es del ciclo completo.
  /// La distribución por etapa se aplica después de convertir a forma comercial.
  double get requerimientoN => RequerimientosNutricionalesFresa.nTotalKgHa;
  double get requerimientoP => RequerimientosNutricionalesFresa.pTotalKgHa;
  double get requerimientoK => RequerimientosNutricionalesFresa.kTotalKgHa;

  String get descripcion {
    switch (this) {
      case EtapaFenologicaNpk.desarrolloVegetativo:
        return 'Etapa de establecimiento y crecimiento vegetativo inicial del cultivo.';
      case EtapaFenologicaNpk.desarrolloEstolones:
        return 'Etapa de desarrollo de estolones y expansión vegetativa.';
      case EtapaFenologicaNpk.floracion:
        return 'Etapa de formación y desarrollo de flores.';
      case EtapaFenologicaNpk.fructificacion:
        return 'Etapa de desarrollo, llenado y producción de frutos.';
      case EtapaFenologicaNpk.desyerba:
        return 'Etapa final de manejo contemplada en la base de datos agronómica suministrada.';
    }
  }
}

abstract final class RequerimientosNutricionalesFresa {
  /// Requerimientos elementales de la planta para el ciclo de referencia
  /// asociado a 100 t/ha en la nueva hoja.
  static const double nTotalKgHa = 104.4;
  static const double pTotalKgHa = 15.0;
  static const double kTotalKgHa = 229.5;

  /// Eficiencia de nutrientes definida en la nueva hoja.
  static const double eficienciaN = 0.40;
  static const double eficienciaP = 0.10;
  static const double eficienciaK = 0.50;

  /// Compatibilidad. La nueva hoja no define umbrales bajo/alto independientes.
  static const double umbralBajoN = nTotalKgHa;
  static const double umbralAltoN = nTotalKgHa;
  static const double umbralBajoP = pTotalKgHa;
  static const double umbralAltoP = pTotalKgHa;
  static const double umbralBajoK = kTotalKgHa;
  static const double umbralAltoK = kTotalKgHa;
}

class DatosEtapaNpk {
  const DatosEtapaNpk({
    required this.etapa,
    required this.rangoDias,
    required this.duracionMeses,
    required this.duracionSemanas,
    required this.semanas,
    required this.mesesCalculo,
    required this.porcentajeN,
    required this.porcentajeP,
    required this.porcentajeK,
    required this.requerimientoN,
    required this.requerimientoP,
    required this.requerimientoK,
    required this.descripcion,
  });

  final EtapaFenologicaNpk etapa;
  final String rangoDias;
  final String duracionMeses;
  final String duracionSemanas;
  final int semanas;
  final int mesesCalculo;
  final double porcentajeN;
  final double porcentajeP;
  final double porcentajeK;
  final double requerimientoN;
  final double requerimientoP;
  final double requerimientoK;
  final String descripcion;
}

final etapaFenologicaNpkProvider = StateProvider<EtapaFenologicaNpk>((ref) {
  return EtapaFenologicaNpk.fructificacion;
});

final lotePlanNutricionalProvider = StateProvider<String>((ref) {
  return 'Lote 1';
});

final datosEtapaSeleccionadaProvider = Provider<DatosEtapaNpk>((ref) {
  final etapa = ref.watch(etapaFenologicaNpkProvider);

  return DatosEtapaNpk(
    etapa: etapa,
    rangoDias: etapa.rangoDias,
    duracionMeses: etapa.duracionMeses,
    duracionSemanas: etapa.duracionSemanas,
    semanas: etapa.semanas,
    mesesCalculo: etapa.mesesCalculo,
    porcentajeN: etapa.porcentajeN,
    porcentajeP: etapa.porcentajeP,
    porcentajeK: etapa.porcentajeK,
    requerimientoN: etapa.requerimientoN,
    requerimientoP: etapa.requerimientoP,
    requerimientoK: etapa.requerimientoK,
    descripcion: etapa.descripcion,
  );
});

final configuracionPlanNutricionalProvider = StateNotifierProvider<
    ConfiguracionPlanNutricionalNotifier,
    ParametrosPlanNutricionalNpk>((ref) {
  final notifier = ConfiguracionPlanNutricionalNotifier();

  final loteInicial = ref.read(loteSeleccionadoProvider);
  final etapaInicial = _etapaDesdeTexto(loteInicial.etapa);
  ref.read(etapaFenologicaNpkProvider.notifier).state = etapaInicial;
  notifier.actualizarDesdeLote(loteInicial, etapaForzada: etapaInicial);

  ref.listen<LoteCultivo>(
    loteSeleccionadoProvider,
    (previous, next) {
      final etapa = _etapaDesdeTexto(next.etapa);
      ref.read(etapaFenologicaNpkProvider.notifier).state = etapa;
      notifier.actualizarDesdeLote(next, etapaForzada: etapa);
    },
  );

  return notifier;
});

class ConfiguracionPlanNutricionalNotifier
    extends StateNotifier<ParametrosPlanNutricionalNpk> {
  ConfiguracionPlanNutricionalNotifier()
      : super(_parametrosPorEtapa(EtapaFenologicaNpk.fructificacion));

  void seleccionarEtapa(EtapaFenologicaNpk etapa) {
    state = _parametrosPorEtapa(
      etapa,
      areaM2: state.areaM2,
      numeroPlantasLote: state.numeroPlantasLote,
      plantasPorHectarea: state.plantasPorHectarea,
      profundidadRaizM: state.profundidadRaizM,
      densidadAparenteKgM3: state.densidadAparenteKgM3,
    );
  }

  void actualizarNumeroPlantas(int numeroPlantasLote) {
    if (numeroPlantasLote <= 0) return;

    final plantasHaActual = state.plantasPorHectarea > 0
        ? state.plantasPorHectarea
        : ParametrosPlanNutricionalNpk.plantasPorHectareaReferencia;

    state = ParametrosPlanNutricionalNpk(
      areaM2: state.areaM2,
      numeroPlantasLote: numeroPlantasLote,
      plantasPorHectarea: plantasHaActual,
      profundidadRaizM: state.profundidadRaizM,
      densidadAparenteKgM3: state.densidadAparenteKgM3,
      semanasEtapa: state.semanasEtapa,
      mesesEtapa: state.mesesEtapa,
      etapa: state.etapa,
      eficienciaExploracionN: state.eficienciaExploracionN,
      eficienciaExploracionP: state.eficienciaExploracionP,
      eficienciaExploracionK: state.eficienciaExploracionK,
      eficienciaAplicacionN: state.eficienciaAplicacionN,
      eficienciaAplicacionP: state.eficienciaAplicacionP,
      eficienciaAplicacionK: state.eficienciaAplicacionK,
      requerimientoNKgHa: state.requerimientoNKgHa,
      requerimientoPKgHa: state.requerimientoPKgHa,
      requerimientoKKgHa: state.requerimientoKKgHa,
    );
  }

  void actualizar({
    double? areaM2,
    int? numeroPlantasLote,
    int? plantasPorHectarea,
    double? profundidadRaizM,
    double? densidadAparenteKgM3,
    int? semanasEtapa,
    int? mesesEtapa,
    String? etapa,
    double? eficienciaExploracionN,
    double? eficienciaExploracionP,
    double? eficienciaExploracionK,
    double? eficienciaAplicacionN,
    double? eficienciaAplicacionP,
    double? eficienciaAplicacionK,
    double? requerimientoNKgHa,
    double? requerimientoPKgHa,
    double? requerimientoKKgHa,
  }) {
    final plantas = numeroPlantasLote ?? state.numeroPlantasLote;
    var plantasHa = plantasPorHectarea ?? state.plantasPorHectarea;
    var area = areaM2 ?? state.areaM2;

    if (plantas > 0 && plantasHa <= 0) {
      plantasHa = ParametrosPlanNutricionalNpk.plantasPorHectareaReferencia;
    }

    if (area <= 0 && plantas > 0 && plantasHa > 0) {
      area = (plantas / plantasHa) * 10000;
    }

    state = ParametrosPlanNutricionalNpk(
      areaM2: area,
      numeroPlantasLote: plantas,
      plantasPorHectarea: plantasHa,
      profundidadRaizM: profundidadRaizM ?? state.profundidadRaizM,
      densidadAparenteKgM3:
          densidadAparenteKgM3 ?? state.densidadAparenteKgM3,
      semanasEtapa: semanasEtapa ?? state.semanasEtapa,
      mesesEtapa: mesesEtapa ?? state.mesesEtapa,
      etapa: etapa ?? state.etapa,
      eficienciaExploracionN:
          eficienciaExploracionN ?? state.eficienciaExploracionN,
      eficienciaExploracionP:
          eficienciaExploracionP ?? state.eficienciaExploracionP,
      eficienciaExploracionK:
          eficienciaExploracionK ?? state.eficienciaExploracionK,
      eficienciaAplicacionN:
          eficienciaAplicacionN ?? state.eficienciaAplicacionN,
      eficienciaAplicacionP:
          eficienciaAplicacionP ?? state.eficienciaAplicacionP,
      eficienciaAplicacionK:
          eficienciaAplicacionK ?? state.eficienciaAplicacionK,
      requerimientoNKgHa:
          requerimientoNKgHa ?? state.requerimientoNKgHa,
      requerimientoPKgHa:
          requerimientoPKgHa ?? state.requerimientoPKgHa,
      requerimientoKKgHa:
          requerimientoKKgHa ?? state.requerimientoKKgHa,
    );
  }

  void actualizarDesdeLote(
    LoteCultivo lote, {
    EtapaFenologicaNpk? etapaForzada,
  }) {
    final numeroPlantasLote = lote.numeroPlantas > 0 ? lote.numeroPlantas : 0;
    var areaM2 = lote.areaM2 > 0 ? lote.areaM2 : 0.0;

    var plantasPorHectarea = areaM2 > 0 && numeroPlantasLote > 0
        ? ((numeroPlantasLote / areaM2) * 10000).round()
        : 0;

    if (numeroPlantasLote > 0 && plantasPorHectarea <= 0) {
      plantasPorHectarea =
          ParametrosPlanNutricionalNpk.plantasPorHectareaReferencia;
    }

    if (areaM2 <= 0 && numeroPlantasLote > 0 && plantasPorHectarea > 0) {
      areaM2 = (numeroPlantasLote / plantasPorHectarea) * 10000;
    }

    final etapa = etapaForzada ?? _etapaDesdeTexto(lote.etapa);

    state = _parametrosPorEtapa(
      etapa,
      areaM2: areaM2,
      numeroPlantasLote: numeroPlantasLote,
      plantasPorHectarea: plantasPorHectarea,
      profundidadRaizM: state.profundidadRaizM,
      densidadAparenteKgM3: state.densidadAparenteKgM3,
    );
  }

  void restablecerFructificacion() {
    state = _parametrosPorEtapa(
      EtapaFenologicaNpk.fructificacion,
      areaM2: state.areaM2,
      numeroPlantasLote: state.numeroPlantasLote,
      plantasPorHectarea: state.plantasPorHectarea,
      profundidadRaizM: 0.20,
      densidadAparenteKgM3: 1000,
    );
  }

  /// Alias para que código antiguo no deje de compilar.
  void restablecerAltaProduccion() => restablecerFructificacion();
}

ParametrosPlanNutricionalNpk _parametrosPorEtapa(
  EtapaFenologicaNpk etapa, {
  double areaM2 = 0,
  int numeroPlantasLote = 0,
  int plantasPorHectarea = 0,
  double profundidadRaizM = 0.20,
  double densidadAparenteKgM3 = 1000,
}) {
  var area = areaM2;
  var plantasHa = plantasPorHectarea;

  if (numeroPlantasLote > 0 && plantasHa <= 0) {
    plantasHa = ParametrosPlanNutricionalNpk.plantasPorHectareaReferencia;
  }

  if (area <= 0 && numeroPlantasLote > 0 && plantasHa > 0) {
    area = (numeroPlantasLote / plantasHa) * 10000;
  }

  return ParametrosPlanNutricionalNpk(
    areaM2: area,
    numeroPlantasLote: numeroPlantasLote,
    plantasPorHectarea: plantasHa,
    profundidadRaizM: profundidadRaizM,
    densidadAparenteKgM3: densidadAparenteKgM3,
    semanasEtapa: etapa.semanas,
    mesesEtapa: etapa.mesesCalculo,
    etapa: etapa.nombre,
    eficienciaExploracionN: 1.0,
    eficienciaExploracionP: 1.0,
    eficienciaExploracionK: 1.0,
    eficienciaAplicacionN: RequerimientosNutricionalesFresa.eficienciaN,
    eficienciaAplicacionP: RequerimientosNutricionalesFresa.eficienciaP,
    eficienciaAplicacionK: RequerimientosNutricionalesFresa.eficienciaK,
    requerimientoNKgHa: RequerimientosNutricionalesFresa.nTotalKgHa,
    requerimientoPKgHa: RequerimientosNutricionalesFresa.pTotalKgHa,
    requerimientoKKgHa: RequerimientosNutricionalesFresa.kTotalKgHa,
  );
}

EtapaFenologicaNpk _etapaDesdeTexto(String texto) {
  final normalizado = texto.trim().toLowerCase();

  if (normalizado.contains('estolon')) {
    return EtapaFenologicaNpk.desarrolloEstolones;
  }
  if (normalizado.contains('flor')) {
    return EtapaFenologicaNpk.floracion;
  }
  if (normalizado.contains('fruct') || normalizado.contains('alta')) {
    return EtapaFenologicaNpk.fructificacion;
  }
  if (normalizado.contains('desyer') || normalizado.contains('manten')) {
    return EtapaFenologicaNpk.desyerba;
  }
  if (normalizado.contains('desarrollo') || normalizado.contains('veget')) {
    return EtapaFenologicaNpk.desarrolloVegetativo;
  }

  return EtapaFenologicaNpk.fructificacion;
}
