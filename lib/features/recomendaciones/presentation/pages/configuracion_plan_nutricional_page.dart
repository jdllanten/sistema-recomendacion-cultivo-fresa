import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tema/app_colores.dart';
import '../../domain/entities/plan_nutricional.dart';
import '../providers/configuracion_plan_nutricional_provider.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';

class ConfiguracionPlanNutricionalPage extends ConsumerStatefulWidget {
  const ConfiguracionPlanNutricionalPage({super.key});

  @override
  ConsumerState<ConfiguracionPlanNutricionalPage> createState() =>
      _ConfiguracionPlanNutricionalPageState();
}

class _ConfiguracionPlanNutricionalPageState
    extends ConsumerState<ConfiguracionPlanNutricionalPage> {
  late final TextEditingController _areaController;
  late final TextEditingController _plantasLoteController;
  late final TextEditingController _plantasHaController;
  late final TextEditingController _raizController;
  late final TextEditingController _densidadController;
  late final TextEditingController _semanasController;

  late final TextEditingController _reqNController;
  late final TextEditingController _reqPController;
  late final TextEditingController _reqKController;

  late final TextEditingController _exploracionNController;
  late final TextEditingController _exploracionPController;
  late final TextEditingController _exploracionKController;

  late final TextEditingController _aplicacionNController;
  late final TextEditingController _aplicacionPController;
  late final TextEditingController _aplicacionKController;

  @override
  void initState() {
    super.initState();

    final parametros = ref.read(configuracionPlanNutricionalProvider);

    _areaController = TextEditingController(
      text: parametros.areaM2.toStringAsFixed(0),
    );
    _plantasLoteController = TextEditingController(
      text: parametros.numeroPlantasLote.toString(),
    );
    _plantasHaController = TextEditingController(
      text: parametros.plantasPorHectarea.toString(),
    );
    _raizController = TextEditingController(
      text: parametros.profundidadRaizM.toStringAsFixed(2),
    );
    _densidadController = TextEditingController(
      text: parametros.densidadAparenteKgM3.toStringAsFixed(0),
    );
    _semanasController = TextEditingController(
      text: parametros.semanasEtapa.toString(),
    );

    _reqNController = TextEditingController(
      text: parametros.requerimientoNKgHa.toStringAsFixed(1),
    );
    _reqPController = TextEditingController(
      text: parametros.requerimientoPKgHa.toStringAsFixed(1),
    );
    _reqKController = TextEditingController(
      text: parametros.requerimientoKKgHa.toStringAsFixed(1),
    );

    _exploracionNController = TextEditingController(
      text: parametros.eficienciaExploracionN.toStringAsFixed(2),
    );
    _exploracionPController = TextEditingController(
      text: parametros.eficienciaExploracionP.toStringAsFixed(2),
    );
    _exploracionKController = TextEditingController(
      text: parametros.eficienciaExploracionK.toStringAsFixed(2),
    );

    _aplicacionNController = TextEditingController(
      text: parametros.eficienciaAplicacionN.toStringAsFixed(2),
    );
    _aplicacionPController = TextEditingController(
      text: parametros.eficienciaAplicacionP.toStringAsFixed(2),
    );
    _aplicacionKController = TextEditingController(
      text: parametros.eficienciaAplicacionK.toStringAsFixed(2),
    );
  }

  @override
  void dispose() {
    _areaController.dispose();
    _plantasLoteController.dispose();
    _plantasHaController.dispose();
    _raizController.dispose();
    _densidadController.dispose();
    _semanasController.dispose();

    _reqNController.dispose();
    _reqPController.dispose();
    _reqKController.dispose();

    _exploracionNController.dispose();
    _exploracionPController.dispose();
    _exploracionKController.dispose();

    _aplicacionNController.dispose();
    _aplicacionPController.dispose();
    _aplicacionKController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final etapaActual = ref.watch(etapaFenologicaNpkProvider);
    final datosEtapa = ref.watch(datosEtapaSeleccionadaProvider);

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _TituloConfiguracionCultivoHeader(),
            const SizedBox(height: 18),

            _GrupoConfiguracionCard(
              titulo: 'Etapa fenológica',
              descripcion:
                  'Selecciona la etapa del cultivo para cargar sus valores técnicos predeterminados.',
              icono: Icons.eco_rounded,
              children: [
                DropdownButtonFormField<EtapaFenologicaNpk>(
                  value: etapaActual,
                  decoration: InputDecoration(
                    labelText: 'Etapa del cultivo',
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(color: AppColores.borde),
                    ),
                    focusedBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(14),
                      borderSide: const BorderSide(
                        color: AppColores.primario,
                        width: 1.4,
                      ),
                    ),
                    isDense: true,
                    filled: true,
                    fillColor: AppColores.fondo,
                  ),
                  items: EtapaFenologicaNpk.values.map((etapa) {
                    return DropdownMenuItem(
                      value: etapa,
                      child: Text(etapa.nombre),
                    );
                  }).toList(),
                  onChanged: (etapa) {
                    if (etapa == null) return;

                    ref.read(etapaFenologicaNpkProvider.notifier).state =
                        etapa;

                    ref
                        .read(configuracionPlanNutricionalProvider.notifier)
                        .seleccionarEtapa(etapa);

                    _recargarControladores();
                  },
                ),
                const SizedBox(height: 12),
                _DatosPredeterminadosEtapaCard(datosEtapa: datosEtapa),
              ],
            ),

            const SizedBox(height: 18),

            _GrupoConfiguracionCard(
              titulo: 'Datos del cálculo',
              descripcion:
                  'Configura el lote y los parámetros usados para estimar la recomendación semanal.',
              icono: Icons.tune_rounded,
              children: [
                _SeccionParametrosCard(
                  icono: Icons.square_foot_rounded,
                  titulo: 'Lote y escala de cálculo',
                  descripcion:
                      'Área, densidad de siembra y condiciones del suelo.',
                  children: [
                    _CampoNumero(
                      controller: _areaController,
                      label: 'Área del lote',
                      unidad: 'm²',
                    ),
                    _CampoNumero(
                      controller: _plantasLoteController,
                      label: 'Plantas del lote',
                    ),
                    _CampoNumero(
                      controller: _plantasHaController,
                      label: 'Plantas por ha',
                    ),
                    _CampoNumero(
                      controller: _raizController,
                      label: 'Profundidad raíz',
                      unidad: 'm',
                    ),
                    _CampoNumero(
                      controller: _densidadController,
                      label: 'Densidad aparente',
                      unidad: 'kg/m³',
                    ),
                    _CampoNumero(
                      controller: _semanasController,
                      label: 'Duración cálculo',
                      unidad: 'sem',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SeccionParametrosCard(
                  icono: Icons.biotech_rounded,
                  titulo: 'Requerimientos de referencia',
                  descripcion:
                      'Cantidad elemental considerada para el ciclo del cultivo.',
                  badge: 'kg/ha',
                  children: [
                    _CampoNumero(
                      controller: _reqNController,
                      label: 'Nitrógeno (N)',
                      unidad: 'kg/ha',
                    ),
                    _CampoNumero(
                      controller: _reqPController,
                      label: 'Fósforo (P)',
                      unidad: 'kg/ha',
                    ),
                    _CampoNumero(
                      controller: _reqKController,
                      label: 'Potasio (K)',
                      unidad: 'kg/ha',
                    ),
                  ],
                ),

                const SizedBox(height: 12),

                _SeccionParametrosCard(
                  icono: Icons.speed_rounded,
                  titulo: 'Eficiencia de nutrientes',
                  descripcion:
                      'Valores entre 0 y 1. Ejemplo: 0,40 equivale a 40 %.',
                  badge: '0 – 1',
                  children: [
                    _CampoNumero(
                      controller: _aplicacionNController,
                      label: 'Eficiencia N',
                    ),
                    _CampoNumero(
                      controller: _aplicacionPController,
                      label: 'Eficiencia P',
                    ),
                    _CampoNumero(
                      controller: _aplicacionKController,
                      label: 'Eficiencia K',
                    ),
                  ],
                ),

                const SizedBox(height: 16),

                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColores.primariosuave.withOpacity(0.42),
                    borderRadius: BorderRadius.circular(18),
                    border: Border.all(
                      color: AppColores.primario.withOpacity(0.12),
                    ),
                  ),
                  child: Column(
                    children: [
                      SizedBox(
                        width: double.infinity,
                        height: 48,
                        child: FilledButton.icon(
                          onPressed: _guardar,
                          icon: const Icon(Icons.save_rounded, size: 20),
                          label: const Text(
                            'Guardar configuración',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: FilledButton.styleFrom(
                            backgroundColor: AppColores.primario,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(height: 9),
                      SizedBox(
                        width: double.infinity,
                        height: 46,
                        child: OutlinedButton.icon(
                          onPressed: _restablecer,
                          icon: const Icon(Icons.restore_rounded, size: 19),
                          label: const Text(
                            'Restablecer fructificación',
                            style: TextStyle(fontWeight: FontWeight.w900),
                          ),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColores.primario,
                            side: BorderSide(
                              color: AppColores.primario.withOpacity(0.30),
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(15),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

          ],
        ),
      ),
    );
  }

  Future<void> _guardar() async {
    final areaM2 = _double(_areaController.text);
    final plantasLote = _int(_plantasLoteController.text);
    final plantasHa = _int(_plantasHaController.text);
    final raiz = _double(_raizController.text);
    final densidad = _double(_densidadController.text);
    final semanas = _int(_semanasController.text);

    final reqN = _double(_reqNController.text);
    final reqP = _double(_reqPController.text);
    final reqK = _double(_reqKController.text);

    final exploracionN = _double(_exploracionNController.text);
    final exploracionP = _double(_exploracionPController.text);
    final exploracionK = _double(_exploracionKController.text);

    final aplicacionN = _double(_aplicacionNController.text);
    final aplicacionP = _double(_aplicacionPController.text);
    final aplicacionK = _double(_aplicacionKController.text);

    if (!_valoresValidos(
      areaM2: areaM2,
      plantasLote: plantasLote,
      plantasHa: plantasHa,
      raiz: raiz,
      densidad: densidad,
      semanas: semanas,
      reqN: reqN,
      reqP: reqP,
      reqK: reqK,
      exploracionN: exploracionN,
      exploracionP: exploracionP,
      exploracionK: exploracionK,
      aplicacionN: aplicacionN,
      aplicacionP: aplicacionP,
      aplicacionK: aplicacionK,
    )) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Revisa los datos. No deben quedar vacíos, en cero o fuera de rango.',
          ),
        ),
      );
      return;
    }

    final areaM2Segura = areaM2 ?? 0;
    final plantasLoteSeguras = plantasLote ?? 0;
    final plantasHaSeguras = plantasHa ?? 0;
    final raizSegura = raiz ?? 0;
    final densidadSegura = densidad ?? 0;
    final semanasSeguras = semanas ?? 0;
    final reqNSeguro = reqN ?? 0;
    final reqPSeguro = reqP ?? 0;
    final reqKSeguro = reqK ?? 0;
    final exploracionNSegura = exploracionN ?? 0;
    final exploracionPSegura = exploracionP ?? 0;
    final exploracionKSegura = exploracionK ?? 0;
    final aplicacionNSegura = aplicacionN ?? 0;
    final aplicacionPSegura = aplicacionP ?? 0;
    final aplicacionKSegura = aplicacionK ?? 0;

    ref.read(configuracionPlanNutricionalProvider.notifier).actualizar(
          areaM2: areaM2Segura,
          numeroPlantasLote: plantasLoteSeguras,
          plantasPorHectarea: plantasHaSeguras,
          profundidadRaizM: raizSegura,
          densidadAparenteKgM3: densidadSegura,
          semanasEtapa: semanasSeguras,
          requerimientoNKgHa: reqNSeguro,
          requerimientoPKgHa: reqPSeguro,
          requerimientoKKgHa: reqKSeguro,
          eficienciaExploracionN: exploracionNSegura,
          eficienciaExploracionP: exploracionPSegura,
          eficienciaExploracionK: exploracionKSegura,
          eficienciaAplicacionN: aplicacionNSegura,
          eficienciaAplicacionP: aplicacionPSegura,
          eficienciaAplicacionK: aplicacionKSegura,
        );

    final loteSeleccionado = ref.read(loteSeleccionadoProvider);

    try {
      await ref.read(lotesCultivoControllerProvider).actualizarLote(
            id: loteSeleccionado.id,
            nombre: loteSeleccionado.nombre,
            cultivo: loteSeleccionado.cultivo,
            etapa: loteSeleccionado.etapa,
            areaM2: areaM2Segura,
            numeroPlantas: plantasLoteSeguras,
            observaciones: loteSeleccionado.observaciones,
          );
    } catch (_) {

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Configuración guardada en la app, pero no se pudo actualizar el lote en la nube.',
          ),
        ),
      );
      return;
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'Configuración guardada y datos del lote actualizados.',
        ),
      ),
    );
  }

  void _restablecer() {
    ref.read(etapaFenologicaNpkProvider.notifier).state =
        EtapaFenologicaNpk.fructificacion;

    ref
        .read(configuracionPlanNutricionalProvider.notifier)
        .restablecerFructificacion();

    _recargarControladores();

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Configuración restablecida a fructificación.'),
      ),
    );
  }

  void _recargarControladores() {
    final parametros = ref.read(configuracionPlanNutricionalProvider);

    _areaController.text = parametros.areaM2.toStringAsFixed(0);
    _plantasLoteController.text = parametros.numeroPlantasLote.toString();
    _plantasHaController.text = parametros.plantasPorHectarea.toString();
    _raizController.text = parametros.profundidadRaizM.toStringAsFixed(2);
    _densidadController.text =
        parametros.densidadAparenteKgM3.toStringAsFixed(0);
    _semanasController.text = parametros.semanasEtapa.toString();

    _reqNController.text = parametros.requerimientoNKgHa.toStringAsFixed(1);
    _reqPController.text = parametros.requerimientoPKgHa.toStringAsFixed(1);
    _reqKController.text = parametros.requerimientoKKgHa.toStringAsFixed(1);

    _exploracionNController.text =
        parametros.eficienciaExploracionN.toStringAsFixed(2);
    _exploracionPController.text =
        parametros.eficienciaExploracionP.toStringAsFixed(2);
    _exploracionKController.text =
        parametros.eficienciaExploracionK.toStringAsFixed(2);

    _aplicacionNController.text =
        parametros.eficienciaAplicacionN.toStringAsFixed(2);
    _aplicacionPController.text =
        parametros.eficienciaAplicacionP.toStringAsFixed(2);
    _aplicacionKController.text =
        parametros.eficienciaAplicacionK.toStringAsFixed(2);

    setState(() {});
  }

  bool _valoresValidos({
    required double? areaM2,
    required int? plantasLote,
    required int? plantasHa,
    required double? raiz,
    required double? densidad,
    required int? semanas,
    required double? reqN,
    required double? reqP,
    required double? reqK,
    required double? exploracionN,
    required double? exploracionP,
    required double? exploracionK,
    required double? aplicacionN,
    required double? aplicacionP,
    required double? aplicacionK,
  }) {
    if (areaM2 == null || areaM2 <= 0) return false;
    if (plantasLote == null || plantasLote <= 0) return false;
    if (plantasHa == null || plantasHa <= 0) return false;
    if (raiz == null || raiz <= 0) return false;
    if (densidad == null || densidad <= 0) return false;
    if (semanas == null || semanas <= 0) return false;

    if (reqN == null || reqN < 0) return false;
    if (reqP == null || reqP < 0) return false;
    if (reqK == null || reqK < 0) return false;

    final eficiencias = [
      exploracionN,
      exploracionP,
      exploracionK,
      aplicacionN,
      aplicacionP,
      aplicacionK,
    ];

    for (final eficiencia in eficiencias) {
      if (eficiencia == null || eficiencia <= 0 || eficiencia > 1) {
        return false;
      }
    }

    return true;
  }

  double? _double(String value) {
    return double.tryParse(value.trim().replaceAll(',', '.'));
  }

  int? _int(String value) {
    return int.tryParse(value.trim());
  }
}

class _TituloConfiguracionCultivoHeader extends StatelessWidget {
  const _TituloConfiguracionCultivoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () {
            Navigator.of(context).pop();
          },
          child: Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColores.borde),
            ),
            child: const Icon(
              Icons.arrow_back_rounded,
              color: AppColores.textoPrincipal,
              size: 22,
            ),
          ),
        ),
        const SizedBox(width: 12),
        Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColores.primario.withOpacity(0.14),
            ),
          ),
          child: const Icon(
            Icons.tune_rounded,
            color: AppColores.primario,
            size: 25,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Configuración del cultivo',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: AppColores.textoPrincipal,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Ajusta los datos del plan nutricional',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}


class _DatosPredeterminadosEtapaCard extends StatefulWidget {
  const _DatosPredeterminadosEtapaCard({
    required this.datosEtapa,
  });

  final DatosEtapaNpk datosEtapa;

  @override
  State<_DatosPredeterminadosEtapaCard> createState() =>
      _DatosPredeterminadosEtapaCardState();
}

class _DatosPredeterminadosEtapaCardState
    extends State<_DatosPredeterminadosEtapaCard> {
  bool expandido = false;

  @override
  Widget build(BuildContext context) {
    final datosEtapa = widget.datosEtapa;

    return Container(
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.18),
        ),
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          borderRadius: BorderRadius.circular(20),
          onTap: () {
            setState(() {
              expandido = !expandido;
            });
          },
          child: Padding(
            padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        color: AppColores.primariosuave.withOpacity(0.85),
                        borderRadius: BorderRadius.circular(13),
                        border: Border.all(
                          color: AppColores.primario.withOpacity(0.12),
                        ),
                      ),
                      child: const Icon(
                        Icons.fact_check_rounded,
                        color: AppColores.primario,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Datos predeterminados de ${datosEtapa.etapa.nombre}',
                        style: const TextStyle(
                          fontSize: 14.5,
                          fontWeight: FontWeight.w900,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                    ),
                    AnimatedRotation(
                      turns: expandido ? 0.5 : 0,
                      duration: const Duration(milliseconds: 180),
                      child: const Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: AppColores.primario,
                        size: 25,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  datosEtapa.descripcion,
                  style: const TextStyle(
                    fontSize: 12.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 11),
                Wrap(
                  spacing: 7,
                  runSpacing: 7,
                  children: [
                    _MiniDatoEtapa(
                      icono: Icons.schedule_rounded,
                      texto: '${datosEtapa.duracionSemanas} sem',
                    ),
                    _MiniDatoEtapa(
                      icono: Icons.science_outlined,
                      texto: 'N ${_porcentaje(datosEtapa.porcentajeN)}',
                    ),
                    _MiniDatoEtapa(
                      icono: Icons.science_outlined,
                      texto: 'P ${_porcentaje(datosEtapa.porcentajeP)}',
                    ),
                    _MiniDatoEtapa(
                      icono: Icons.science_outlined,
                      texto: 'K ${_porcentaje(datosEtapa.porcentajeK)}',
                    ),
                  ],
                ),
                const SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                      expandido
                          ? Icons.expand_less_rounded
                          : Icons.expand_more_rounded,
                      size: 20,
                      color: AppColores.primario,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      expandido
                          ? 'Ver menos información'
                          : 'Ver más información',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColores.primario,
                      ),
                    ),
                  ],
                ),
                AnimatedCrossFade(
                  firstChild: const SizedBox.shrink(),
                  secondChild: Padding(
                    padding: const EdgeInsets.only(top: 14),
                    child: _ContenidoDatosEtapaExpandido(
                      datosEtapa: datosEtapa,
                    ),
                  ),
                  crossFadeState: expandido
                      ? CrossFadeState.showSecond
                      : CrossFadeState.showFirst,
                  duration: const Duration(milliseconds: 220),
                  firstCurve: Curves.easeOut,
                  secondCurve: Curves.easeOut,
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _ContenidoDatosEtapaExpandido extends StatelessWidget {
  const _ContenidoDatosEtapaExpandido({
    required this.datosEtapa,
  });

  final DatosEtapaNpk datosEtapa;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _BloqueDatosEtapa(
          titulo: 'Duración de la etapa',
          items: [
            _DatoEtapaItem(
              titulo: 'Rango',
              valor: datosEtapa.rangoDias,
            ),
            _DatoEtapaItem(
              titulo: 'Semanas',
              valor: datosEtapa.duracionSemanas,
            ),
            _DatoEtapaItem(
              titulo: 'Periodo',
              valor: 'Cálculo semanal',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BloqueDatosEtapa(
          titulo: 'Extracción por etapa',
          items: [
            _DatoEtapaItem(
              titulo: 'N',
              valor: _porcentaje(datosEtapa.porcentajeN),
            ),
            _DatoEtapaItem(
              titulo: 'P',
              valor: _porcentaje(datosEtapa.porcentajeP),
            ),
            _DatoEtapaItem(
              titulo: 'K',
              valor: _porcentaje(datosEtapa.porcentajeK),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BloqueDatosEtapa(
          titulo: 'Requerimiento elemental de referencia',
          items: [
            _DatoEtapaItem(
              titulo: 'N',
              valor: '${_numero(datosEtapa.requerimientoN)} kg/ha',
            ),
            _DatoEtapaItem(
              titulo: 'P',
              valor: '${_numero(datosEtapa.requerimientoP)} kg/ha',
            ),
            _DatoEtapaItem(
              titulo: 'K',
              valor: '${_numero(datosEtapa.requerimientoK)} kg/ha',
            ),
          ],
        ),
        const SizedBox(height: 12),
        _BloqueDatosEtapa(
          titulo: 'Eficiencia de nutrientes',
          items: const [
            _DatoEtapaItem(
              titulo: 'N',
              valor: '40 %',
            ),
            _DatoEtapaItem(
              titulo: 'P',
              valor: '10 %',
            ),
            _DatoEtapaItem(
              titulo: 'K',
              valor: '50 %',
            ),
          ],
        ),
      ],
    );
  }
}

class _BloqueDatosEtapa extends StatelessWidget {
  const _BloqueDatosEtapa({
    required this.titulo,
    required this.items,
  });

  final String titulo;
  final List<_DatoEtapaItem> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 9),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: items,
          ),
        ],
      ),
    );
  }
}

class _DatoEtapaItem extends StatelessWidget {
  const _DatoEtapaItem({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 126,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.3,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}


class _CamposCard extends StatelessWidget {
  const _CamposCard({required this.children});

  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: Wrap(
        spacing: 10,
        runSpacing: 10,
        children: children,
      ),
    );
  }
}

class _CampoNumero extends StatelessWidget {
  const _CampoNumero({
    required this.controller,
    required this.label,
    this.unidad,
  });

  final TextEditingController controller;
  final String label;
  final String? unidad;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 145,
      child: TextField(
        controller: controller,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        style: const TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColores.textoPrincipal,
        ),
        decoration: InputDecoration(
          labelText: label,
          suffixText: unidad,
          suffixStyle: const TextStyle(
            fontSize: 10.5,
            fontWeight: FontWeight.w800,
            color: AppColores.textoSecundario,
          ),
          labelStyle: const TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColores.textoSecundario,
          ),
          contentPadding: const EdgeInsets.fromLTRB(13, 14, 11, 13),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(color: AppColores.borde),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(15),
            borderSide: const BorderSide(
              color: AppColores.primario,
              width: 1.5,
            ),
          ),
          isDense: true,
          filled: true,
          fillColor: AppColores.superficie,
        ),
      ),
    );
  }
}


class _SeccionParametrosCard extends StatelessWidget {
  const _SeccionParametrosCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.children,
    this.badge,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final List<Widget> children;
  final String? badge;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColores.primariosuave,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.12),
                  ),
                ),
                child: Icon(
                  icono,
                  size: 19,
                  color: AppColores.primario,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 13.5,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      descripcion,
                      style: const TextStyle(
                        fontSize: 10.8,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              if (badge != null) ...[
                const SizedBox(width: 8),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
                  decoration: BoxDecoration(
                    color: AppColores.primariosuave.withOpacity(0.72),
                    borderRadius: BorderRadius.circular(999),
                  ),
                  child: Text(
                    badge!,
                    style: const TextStyle(
                      fontSize: 9.5,
                      fontWeight: FontWeight.w900,
                      color: AppColores.primario,
                    ),
                  ),
                ),
              ],
            ],
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 10,
            runSpacing: 10,
            children: children,
          ),
        ],
      ),
    );
  }
}

class _MiniDatoEtapa extends StatelessWidget {
  const _MiniDatoEtapa({
    required this.icono,
    required this.texto,
  });

  final IconData icono;
  final String texto;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.62),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icono,
            size: 13,
            color: AppColores.primario,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            style: const TextStyle(
              fontSize: 10.3,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}


class _GrupoConfiguracionCard extends StatelessWidget {
  const _GrupoConfiguracionCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.children,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final List<Widget> children;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColores.borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 14,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColores.primariosuave.withOpacity(0.80),
                  borderRadius: BorderRadius.circular(13),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.12),
                  ),
                ),
                child: Icon(
                  icono,
                  color: AppColores.primario,
                  size: 21,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  titulo,
                  style: const TextStyle(
                    fontSize: 15.5,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 12.4,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 14),
          ...children,
        ],
      ),
    );
  }
}

class _SubtituloGrupoConfiguracion extends StatelessWidget {
  const _SubtituloGrupoConfiguracion({
    required this.titulo,
    required this.descripcion,
  });

  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(left: 2),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 14.5,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            descripcion,
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.32,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}


String _numero(double valor) {
  if (valor.abs() >= 1000) {
    return valor.toStringAsFixed(0);
  }

  if (valor.abs() >= 100) {
    return valor.toStringAsFixed(1);
  }

  if (valor.abs() >= 10) {
    return valor.toStringAsFixed(2);
  }

  return valor.toStringAsFixed(2);
}

String _porcentaje(double valor) {
  return '${(valor * 100).toStringAsFixed(0)}%';
}
