import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/rutas/app_router.dart';
import '../../../../core/tema/app_colores.dart';
import '../../domain/entities/plan_nutricional.dart';
import '../../domain/entities/producto_fertilizante.dart';
import '../providers/configuracion_plan_nutricional_provider.dart';
import '../providers/fertilizantes_disponibles_provider.dart';
import '../providers/plan_nutricional_npk_provider.dart';
import '../../../lotes/domain/entities/lote_cultivo.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';

class PlanNutricionalNpkPage extends ConsumerWidget {
  const PlanNutricionalNpkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planNutricionalNpkProvider);
    final productosSeleccionados =
        ref.watch(productosFertilizantesSeleccionadosProvider);
    final sinSeleccion = productosSeleccionados.isEmpty;

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: planAsync.when(
          loading: () => const Center(
            child: CircularProgressIndicator(),
          ),
          error: (error, _) => _ErrorPlan(
            mensaje: error.toString(),
          ),
          data: (plan) {
            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const _TituloPlanNutricionalHeader(),
                const SizedBox(height: 18),

                _ConfiguracionResumenCard(parametros: plan.parametros),
                const SizedBox(height: 16),

                _NecesidadSemanalEstimadaCard(plan: plan),
                const SizedBox(height: 16),

                _EscogerFertilizantePlanCard(plan: plan),
                const SizedBox(height: 16),

                if (sinSeleccion) ...[
                  _DiagnosticoGeneralNpkCard(plan: plan),
                ] else ...[
                  _ResultadoRecomendacionMinimalCard(plan: plan),
                  const SizedBox(height: 16),

                  _DiagnosticoGeneralNpkCard(plan: plan),
                ],
              ],
            );
          },
        ),
      ),
    );
  }
}


class _TituloPlanNutricionalHeader extends StatelessWidget {
  const _TituloPlanNutricionalHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 44,
          height: 42,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColores.primario.withOpacity(0.14),
            ),
          ),
          child: Icon(
            Icons.eco_rounded,
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
                'Plan nutricional NPK',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: AppColores.textoPrincipal,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Cálculo semanal por lote y concentración NPK',
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

class _AvisoSeleccionarFertilizantesCard extends StatelessWidget {
  const _AvisoSeleccionarFertilizantesCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.advertenciasuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColores.advertencia.withOpacity(0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.inventory_2_outlined,
              color: AppColores.advertencia,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Selecciona fertilizantes',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 5),
                  const Text(
                    'El modo personalizado está activo. Para calcular la dosis, selecciona al menos un fertilizante disponible.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColores.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 12),
                  SizedBox(
                    width: double.infinity,
                    child: FilledButton.icon(
                      onPressed: () {
                        context.push(RutasApp.fertilizantesDisponibles);
                      },
                      icon: const Icon(Icons.add_circle_outline_rounded),
                      label: const Text('Escoger fertilizantes'),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}



class _ResumenPlanCard extends StatelessWidget {
  const _ResumenPlanCard({
    required this.plan,
  });

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context) {
    final color = plan.requiereCorreccion
        ? AppColores.prioridadMedia
        : AppColores.primario;

    final titulo = plan.requiereCorreccion
        ? 'Plan nutricional con correcciones'
        : 'NPK dentro del plan estimado';

    final descripcion = plan.requiereCorreccion
        ? 'Se estimaron faltantes nutricionales y se calcula una dosis semanal según los productos disponibles.'
        : 'Según los parámetros actuales, no se estima faltante nutricional semanal significativo.';

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: color.withOpacity(0.12),
                borderRadius: BorderRadius.circular(16),
              ),
              child: Icon(
                plan.requiereCorreccion
                    ? Icons.eco_rounded
                    : Icons.check_circle_rounded,
                color: color,
                size: 25,
              ),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                  const SizedBox(height: 5),
                  Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 13,
                      height: 1.35,
                      fontWeight: FontWeight.w600,
                      color: AppColores.textoSecundario,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _NecesidadSemanalEstimadaCard extends StatelessWidget {
  const _NecesidadSemanalEstimadaCard({
    required this.plan,
  });

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context) {
    final tieneArea = plan.parametros.areaEquivalenteHa > 0;
    final requiereAlgo = tieneArea && plan.requiereCorreccion;

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: !tieneArea
              ? AppColores.advertencia.withOpacity(0.24)
              : requiereAlgo
                  ? AppColores.prioridadMedia.withOpacity(0.24)
                  : AppColores.primario.withOpacity(0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  !tieneArea
                      ? Icons.info_outline_rounded
                      : requiereAlgo
                          ? Icons.playlist_add_check_rounded
                          : Icons.check_circle_rounded,
                  color: !tieneArea
                      ? AppColores.advertencia
                      : requiereAlgo
                          ? AppColores.prioridadMedia
                          : AppColores.primario,
                ),
                const SizedBox(width: 10),
                const Expanded(
                  child: Text(
                    'Necesidad semanal estimada',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              !tieneArea
                  ? 'No es posible estimar la necesidad semanal porque el lote no tiene un área válida definida.'
                  : requiereAlgo
                      ? 'Con base en la lectura actual, el sistema estima los nutrientes que requieren corrección durante la semana.'
                      : 'Con la lectura actual no se estima una corrección nutricional semanal.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: _NecesidadNutrienteItem(
                    titulo: 'N',
                    nutriente: plan.nitrogeno,
                    tieneArea: tieneArea,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NecesidadNutrienteItem(
                    titulo: 'P₂O₅',
                    nutriente: plan.fosforo,
                    tieneArea: tieneArea,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _NecesidadNutrienteItem(
                    titulo: 'K₂O',
                    nutriente: plan.potasio,
                    tieneArea: tieneArea,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _NecesidadNutrienteItem extends StatelessWidget {
  const _NecesidadNutrienteItem({
    required this.titulo,
    required this.nutriente,
    required this.tieneArea,
  });

  final String titulo;
  final NutrientePlanNpk nutriente;
  final bool tieneArea;

  @override
  Widget build(BuildContext context) {
    final requiere = tieneArea && nutriente.tieneDeficit;
    final valorKgSemana = nutriente.faltanteFormaComercialSemanaKg;
    final tieneValorSemanal = tieneArea && valorKgSemana > 0;

    final color = !tieneArea
        ? AppColores.advertencia
        : requiere
            ? AppColores.prioridadMedia
            : AppColores.primario;

    final textoPrincipal = !tieneArea
        ? 'No calculado'
        : !requiere
            ? 'No requiere'
            : tieneValorSemanal
                ? _numero(valorKgSemana)
                : 'Requiere';

    final textoSecundario = !tieneArea
        ? 'Definir área'
        : !requiere
            ? null
            : tieneValorSemanal
                ? 'kg/semana'
                : 'Definir área';

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 8,
        vertical: 11,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            textoPrincipal,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: tieneValorSemanal ? 14 : 11.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          if (textoSecundario != null) ...[
            const SizedBox(height: 2),
            Text(
              textoSecundario,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 10.5,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}



class _EscogerFertilizantePlanCard extends ConsumerWidget {
  const _EscogerFertilizantePlanCard({required this.plan});

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final seleccionadas = ref.watch(productosFertilizantesSeleccionadosProvider);
    final cantidad = seleccionadas.length;

    return Container(
      padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColores.borde),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.045),
            blurRadius: 18,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                color: AppColores.primario,
                size: 21,
              ),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Fertilizante',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            cantidad == 0
                ? 'Escoge o ingresa una concentración para calcular la dosis.'
                : '$cantidad concentración(es) usadas en el cálculo.',
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.35,
              color: AppColores.textoSecundario,
              fontWeight: FontWeight.w600,
            ),
          ),
          if (seleccionadas.isNotEmpty) ...[
            const SizedBox(height: 12),
            ...seleccionadas.map(
              (producto) => Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: _ConcentracionSeleccionadaPlanItem(
                  concentracion: producto.nombre,
                  temporal: producto.esTemporal,
                  onQuitar: () {
                    ref
                        .read(productosFertilizantesProvider.notifier)
                        .alternarSeleccion(producto.id);
                  },
                ),
              ),
            ),
          ],
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            height: 44,
            child: FilledButton.icon(
              onPressed: () {
                _mostrarModalFertilizantesPlan(
                  context: context,
                  ref: ref,
                  plan: plan,
                );
              },
              icon: const Icon(
                Icons.add_circle_outline_rounded,
                size: 20,
              ),
              label: Text(
                cantidad == 0 ? 'Escoger fertilizante' : 'Agregar otro fertilizante',
                style: const TextStyle(
                  fontSize: 14.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColores.primario.withOpacity(0.92),
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcentracionSeleccionadaPlanItem extends StatelessWidget {
  const _ConcentracionSeleccionadaPlanItem({
    required this.concentracion,
    required this.temporal,
    required this.onQuitar,
  });

  final String concentracion;
  final bool temporal;
  final VoidCallback onQuitar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 9),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.science_outlined,
            size: 18,
            color: AppColores.primario,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              concentracion,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.8,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
          IconButton(
            onPressed: onQuitar,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.close_rounded,
              size: 19,
              color: AppColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

Future<void> _mostrarModalFertilizantesPlan({
  required BuildContext context,
  required WidgetRef ref,
  required PlanNutricionalNpk plan,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _ModalFertilizantesPlanSheet(plan: plan);
    },
  );
}

class _ModalFertilizantesPlanSheet extends ConsumerStatefulWidget {
  const _ModalFertilizantesPlanSheet({required this.plan});

  final PlanNutricionalNpk plan;

  @override
  ConsumerState<_ModalFertilizantesPlanSheet> createState() =>
      _ModalFertilizantesPlanSheetState();
}

class _ModalFertilizantesPlanSheetState
    extends ConsumerState<_ModalFertilizantesPlanSheet> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _nController;
  late final TextEditingController _pController;
  late final TextEditingController _kController;

  bool _guardando = false;
  String? _editandoId;

  @override
  void initState() {
    super.initState();
    _nController = TextEditingController();
    _pController = TextEditingController();
    _kController = TextEditingController();
  }

  @override
  void dispose() {
    _nController.dispose();
    _pController.dispose();
    _kController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final teclado = MediaQuery.of(context).viewInsets.bottom;
    final productos = ref.watch(productosFertilizantesProvider);
    final planActual = ref.watch(planNutricionalNpkProvider).valueOrNull ?? widget.plan;
    final fertilizantesAplicados =
        planActual.fertilizantes.where((f) => f.kgPorSemana > 0).toList();
    final guardadas = productos.where((producto) => producto.esManual).toList();

    final n = _aDouble(_nController.text) ?? 0;
    final p = _aDouble(_pController.text) ?? 0;
    final k = _aDouble(_kController.text) ?? 0;

    final seleccionadas = productos.where((producto) => producto.seleccionado).toList();
    final indiceEditando = _editandoId == null
        ? -1
        : guardadas.indexWhere((producto) => producto.id == _editandoId);
    final numeroProducto = indiceEditando >= 0
        ? indiceEditando + 1
        : seleccionadas.length + 1;
    final tituloProducto = 'Producto $numeroProducto';
    final concentracionTexto = n <= 0 && p <= 0 && k <= 0
        ? 'Concentración'
        : '${_numeroConcentracion(n)}-${_numeroConcentracion(p)}-${_numeroConcentracion(k)}';

    final vistaPrevia = _calcularVistaPreviaConcentracion(
      plan: planActual,
      n: n,
      p2o5: p,
      k2o: k,
    );

    final necesidadCubiertaConProducto =
        vistaPrevia.dosisKgSemana > 0 &&
        vistaPrevia.faltanteDespuesN <= 0.001 &&
        vistaPrevia.faltanteDespuesP2O5 <= 0.001 &&
        vistaPrevia.faltanteDespuesK2O <= 0.001;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 18 + teclado),
      decoration: const BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 42,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColores.borde,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColores.primariosuave,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(
                      Icons.science_outlined,
                      color: AppColores.primario,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      _editandoId == null
                          ? 'Escoger fertilizante'
                          : 'Editar concentración',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _guardando ? null : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                decoration: BoxDecoration(
                  color: AppColores.primariosuave.withOpacity(0.48),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.14),
                  ),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.calendar_view_week_rounded,
                      size: 18,
                      color: AppColores.primario,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        '${planActual.parametros.etapa}  ·  '
                        '${_numero(planActual.parametros.areaEquivalenteHa)} ha  ·  '
                        '${planActual.parametros.semanasEtapa} semanas',
                        style: const TextStyle(
                          fontSize: 11.8,
                          fontWeight: FontWeight.w800,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              _BloqueNutrientesModal(
                titulo: 'Necesidad semanal por cubrir',
                colorearPorEstado: true,
                valores: [
                  _NutrienteModalValor('N', vistaPrevia.necesidadN),
                  _NutrienteModalValor('P₂O₅', vistaPrevia.necesidadP2O5),
                  _NutrienteModalValor('K₂O', vistaPrevia.necesidadK2O),
                ],
              ),

              if (fertilizantesAplicados.isNotEmpty) ...[
                const SizedBox(height: 12),
                _ProductosAplicadosModalExpansionCard(
                  plan: planActual,
                  fertilizantes: fertilizantesAplicados,
                ),
              ],

              const SizedBox(height: 14),
              const _TituloIngresoConcentracion(),

              const SizedBox(height: 10),
              Row(
                children: [
                  Expanded(
                    child: _CampoConcentracionModal(
                      controller: _nController,
                      label: 'N',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _CampoConcentracionModal(
                      controller: _pController,
                      label: 'P₂O₅',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                  const SizedBox(width: 9),
                  Expanded(
                    child: _CampoConcentracionModal(
                      controller: _kController,
                      label: 'K₂O',
                      onChanged: (_) => setState(() {}),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 14),
              _VistaPreviaConcentracionCard(
                vistaPrevia: vistaPrevia,
                tituloProducto: tituloProducto,
                concentracionTexto: concentracionTexto,
              ),

              const SizedBox(height: 14),
              if (_editandoId == null) ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: OutlinedButton.icon(
                    onPressed: _guardando || necesidadCubiertaConProducto
                        ? null
                        : _agregarOtraConcentracion,
                    icon: Icon(
                      necesidadCubiertaConProducto
                          ? Icons.check_circle_outline_rounded
                          : Icons.add_circle_outline_rounded,
                    ),
                    label: Text(
                      necesidadCubiertaConProducto
                          ? 'Necesidad semanal cubierta'
                          : 'Agregar otra concentración',
                      style: const TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColores.primario,
                      side: BorderSide(
                        color: AppColores.primario.withOpacity(0.35),
                      ),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 9),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _guardarYUsarEnPlan,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text(
                      'Guardar y usar en el plan',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColores.primario,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 46,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : _guardarEdicion,
                    icon: const Icon(Icons.save_rounded),
                    label: const Text('Guardar cambios'),
                  ),
                ),
                const SizedBox(height: 8),
                SizedBox(
                  width: double.infinity,
                  child: TextButton(
                    onPressed: _guardando ? null : _limpiarFormulario,
                    child: const Text('Cancelar edición'),
                  ),
                ),
              ],
              if (guardadas.isNotEmpty) ...[
                const SizedBox(height: 20),
                const Text(
                  'Guardadas',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 10),
                ...guardadas.map(
                  (producto) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _ConcentracionGuardadaModalItem(
                      producto: producto,
                      onSeleccionar: () {
                        ref
                            .read(productosFertilizantesProvider.notifier)
                            .alternarSeleccion(producto.id);
                        ref.read(modoCalculoFertilizanteProvider.notifier).state =
                            ModoCalculoFertilizante.personalizado;
                      },
                      onEditar: () => _cargarParaEditar(producto),
                      onEliminar: () => _eliminar(producto),
                    ),
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }


  Future<void> _agregarOtraConcentracion() async {
    final planActual =
        ref.read(planNutricionalNpkProvider).valueOrNull ?? widget.plan;

    // Si el plan YA estaba cubierto antes de digitar otro producto,
    // no permite continuar agregando concentraciones.
    if (_planSinFaltantes(planActual)) {
      await _mostrarRequerimientoCubierto(planActual);
      return;
    }

    if (!_validarCampos()) return;

    final n = _aDouble(_nController.text)!;
    final p = _aDouble(_pController.text)!;
    final k = _aDouble(_kController.text)!;

    // Calcula primero cómo quedaría el balance con la concentración que
    // el usuario acaba de digitar. Así podemos detectar si ESTE producto
    // ya cubre todo y genera excedente.
    final vistaPrevia = _calcularVistaPreviaConcentracion(
      plan: planActual,
      n: n,
      p2o5: p,
      k2o: k,
    );

    // Agrega el producto actual al cálculo.
    ref.read(productosFertilizantesProvider.notifier).usarComposicionTemporal(
          n: n,
          p2o5: p,
          k2o: k,
        );

    ref.read(modoCalculoFertilizanteProvider.notifier).state =
        ModoCalculoFertilizante.personalizado;

    if (!mounted) return;

    final sinFaltantesDespues =
        vistaPrevia.faltanteDespuesN <= 0.001 &&
        vistaPrevia.faltanteDespuesP2O5 <= 0.001 &&
        vistaPrevia.faltanteDespuesK2O <= 0.001;

    if (sinFaltantesDespues) {
      _nController.clear();
      _pController.clear();
      _kController.clear();

      setState(() {
        _editandoId = null;
      });

      await _mostrarRequerimientoCubiertoDesdeVistaPrevia(vistaPrevia);
      return;
    }

    _prepararSiguienteConcentracion(
      mensaje: 'Producto agregado al cálculo. Puedes ingresar otra concentración.',
    );
  }

  Future<void> _guardarYUsarEnPlan() async {
    if (_guardando) return;

    final n = _aDouble(_nController.text) ?? 0;
    final p = _aDouble(_pController.text) ?? 0;
    final k = _aDouble(_kController.text) ?? 0;
    final hayDatosDigitados = n > 0 || p > 0 || k > 0;

    if (hayDatosDigitados) {
      if (!_validarCampos()) return;

      ref.read(productosFertilizantesProvider.notifier).usarComposicionTemporal(
            n: n,
            p2o5: p,
            k2o: k,
          );

      ref.read(modoCalculoFertilizanteProvider.notifier).state =
          ModoCalculoFertilizante.personalizado;
    }

    final seleccionadas =
        ref.read(productosFertilizantesSeleccionadosProvider);

    if (seleccionadas.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Agrega al menos una concentración antes de guardar.'),
        ),
      );
      return;
    }

    setState(() => _guardando = true);

    final notifier = ref.read(productosFertilizantesProvider.notifier);

    // Las concentraciones se usan solo para calcular el plan actual.
    // No se guardan como documentos independientes en fertilizantes_manuales.
    final planGuardar =
        ref.read(planNutricionalNpkProvider).valueOrNull ?? widget.plan;
    final lote = ref.read(loteSeleccionadoProvider);

    final productosPlan =
        planGuardar.fertilizantes.where((f) => f.kgPorSemana > 0).toList();

    final datosPlan = <String, dynamic>{
      'etapa': ref.read(etapaFenologicaNpkProvider).nombre,
      'periodoCalculo': 'semanal',
      'semanasEtapa': planGuardar.parametros.semanasEtapa,
      'areaM2': planGuardar.parametros.areaM2,
      'areaHa': planGuardar.parametros.areaEquivalenteHa,
      'pesoSueloKgHa': planGuardar.parametros.pesoSueloKgHa,
      'necesidadInicial': {
        'n': planGuardar.resumenCobertura.necesidadN,
        'p2o5': planGuardar.resumenCobertura.necesidadP2O5,
        'k2o': planGuardar.resumenCobertura.necesidadK2O,
      },
      'aporteTotal': {
        'n': planGuardar.resumenCobertura.aporteN,
        'p2o5': planGuardar.resumenCobertura.aporteP2O5,
        'k2o': planGuardar.resumenCobertura.aporteK2O,
      },
      'faltanteFinal': {
        'n': _positivo(
          planGuardar.resumenCobertura.necesidadN -
              planGuardar.resumenCobertura.aporteN,
        ),
        'p2o5': _positivo(
          planGuardar.resumenCobertura.necesidadP2O5 -
              planGuardar.resumenCobertura.aporteP2O5,
        ),
        'k2o': _positivo(
          planGuardar.resumenCobertura.necesidadK2O -
              planGuardar.resumenCobertura.aporteK2O,
        ),
      },
      'excedenteFinal': {
        'n': _normalizarCero(
          _positivo(
            planGuardar.resumenCobertura.aporteN -
                planGuardar.resumenCobertura.necesidadN,
          ),
        ),
        'p2o5': _normalizarCero(
          _positivo(
            planGuardar.resumenCobertura.aporteP2O5 -
                planGuardar.resumenCobertura.necesidadP2O5,
          ),
        ),
        'k2o': _normalizarCero(
          _positivo(
            planGuardar.resumenCobertura.aporteK2O -
                planGuardar.resumenCobertura.necesidadK2O,
          ),
        ),
      },
      'productos': [
        for (var i = 0; i < productosPlan.length; i++)
          {
            'numero': i + 1,
            'nombre': productosPlan[i].nombre,
            'concentracion': {
              'n': productosPlan[i].concentracionN,
              'p2o5': productosPlan[i].concentracionP2O5,
              'k2o': productosPlan[i].concentracionK2O,
            },
            'dosisKgSemana': productosPlan[i].kgPorSemana,
            'aporte': {
              'n': productosPlan[i].kgPorSemana *
                  (productosPlan[i].concentracionN / 100),
              'p2o5': productosPlan[i].kgPorSemana *
                  (productosPlan[i].concentracionP2O5 / 100),
              'k2o': productosPlan[i].kgPorSemana *
                  (productosPlan[i].concentracionK2O / 100),
            },
          },
      ],
    };

    final planGuardado = await notifier.guardarResultadoPlan(
      loteId: lote.id,
      loteNombre: lote.nombre,
      datos: datosPlan,
    );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (!planGuardado) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'El plan quedó aplicado localmente, pero Firestore no confirmó el guardado del plan.',
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Plan guardado en Firestore y aplicado correctamente.'),
        ),
      );
    }

    Navigator.of(context).pop();
  }

  bool _planSinFaltantes(PlanNutricionalNpk plan) {
    final faltanteN = _positivo(
      plan.resumenCobertura.necesidadN - plan.resumenCobertura.aporteN,
    );
    final faltanteP = _positivo(
      plan.resumenCobertura.necesidadP2O5 - plan.resumenCobertura.aporteP2O5,
    );
    final faltanteK = _positivo(
      plan.resumenCobertura.necesidadK2O - plan.resumenCobertura.aporteK2O,
    );

    return faltanteN <= 0.001 &&
        faltanteP <= 0.001 &&
        faltanteK <= 0.001;
  }

  Future<void> _mostrarRequerimientoCubierto(
    PlanNutricionalNpk plan,
  ) async {
    final excesoN = _positivo(
      plan.resumenCobertura.aporteN - plan.resumenCobertura.necesidadN,
    );
    final excesoP = _positivo(
      plan.resumenCobertura.aporteP2O5 - plan.resumenCobertura.necesidadP2O5,
    );
    final excesoK = _positivo(
      plan.resumenCobertura.aporteK2O - plan.resumenCobertura.necesidadK2O,
    );

    final hayExceso = excesoN > 0.001 || excesoP > 0.001 || excesoK > 0.001;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            hayExceso
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: hayExceso ? AppColores.advertencia : AppColores.primario,
            size: 30,
          ),
          title: Text(
            hayExceso
                ? 'Requerimiento cubierto con excedente'
                : 'Requerimiento cubierto',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hayExceso
                    ? 'Ya no existe faltante de N, P₂O₅ o K₂O. Revisa los excedentes antes de agregar otra concentración.'
                    : 'El requerimiento nutricional del lote ya está cubierto. No es necesario agregar otra concentración.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.35,
                  color: AppColores.textoSecundario,
                ),
              ),
              if (hayExceso) ...[
                const SizedBox(height: 14),
                _BloqueNutrientesModal(
                  titulo: 'Excedente actual',
                  color: AppColores.advertencia,
                  valores: [
                    if (excesoN > 0.001)
                      _NutrienteModalValor('N +', excesoN),
                    if (excesoP > 0.001)
                      _NutrienteModalValor('P₂O₅ +', excesoP),
                    if (excesoK > 0.001)
                      _NutrienteModalValor('K₂O +', excesoK),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _mostrarRequerimientoCubiertoDesdeVistaPrevia(
    _VistaPreviaDosis vistaPrevia,
  ) async {
    final hayExceso =
        vistaPrevia.excesoN > 0.001 ||
        vistaPrevia.excesoP2O5 > 0.001 ||
        vistaPrevia.excesoK2O > 0.001;

    await showDialog<void>(
      context: context,
      builder: (context) {
        return AlertDialog(
          icon: Icon(
            hayExceso
                ? Icons.info_outline_rounded
                : Icons.check_circle_outline_rounded,
            color: hayExceso ? AppColores.advertencia : AppColores.primario,
            size: 30,
          ),
          title: Text(
            hayExceso
                ? 'Requerimiento cubierto con excedente'
                : 'Requerimiento cubierto',
            textAlign: TextAlign.center,
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                hayExceso
                    ? 'Con este producto ya no queda faltante de N, P₂O₅ o K₂O. No es necesario agregar otra concentración. Revisa el excedente y guarda el plan.'
                    : 'Con este producto el requerimiento nutricional del lote quedó cubierto. No es necesario agregar otra concentración.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  height: 1.35,
                  color: AppColores.textoSecundario,
                ),
              ),
              if (hayExceso) ...[
                const SizedBox(height: 14),
                _BloqueNutrientesModal(
                  titulo: 'Excedente generado',
                  color: AppColores.advertencia,
                  valores: [
                    if (vistaPrevia.excesoN > 0.001)
                      _NutrienteModalValor('N +', vistaPrevia.excesoN),
                    if (vistaPrevia.excesoP2O5 > 0.001)
                      _NutrienteModalValor('P₂O₅ +', vistaPrevia.excesoP2O5),
                    if (vistaPrevia.excesoK2O > 0.001)
                      _NutrienteModalValor('K₂O +', vistaPrevia.excesoK2O),
                  ],
                ),
              ],
            ],
          ),
          actions: [
            FilledButton.icon(
              onPressed: () => Navigator.of(context).pop(),
              icon: const Icon(Icons.check_rounded),
              label: const Text('Entendido'),
            ),
          ],
        );
      },
    );
  }

  Future<void> _guardarEdicion() async {
    if (_editandoId == null) return;
    if (!_validarCampos()) return;

    setState(() => _guardando = true);

    final n = _aDouble(_nController.text)!;
    final p = _aDouble(_pController.text)!;
    final k = _aDouble(_kController.text)!;

    final ok = await ref
        .read(productosFertilizantesProvider.notifier)
        .editarComposicionNpk(
          id: _editandoId!,
          n: n,
          p2o5: p,
          k2o: k,
        );

    if (!mounted) return;
    setState(() => _guardando = false);

    if (ok) {
      _limpiarFormulario();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No se pudo editar la concentración.')),
      );
    }
  }

  void _cargarParaEditar(ProductoFertilizante producto) {
    _nController.text = _numero(producto.n);
    _pController.text = _numero(producto.p2o5);
    _kController.text = _numero(producto.k2o);
    setState(() => _editandoId = producto.id);
  }

  void _limpiarFormulario() {
    _nController.clear();
    _pController.clear();
    _kController.clear();
    setState(() => _editandoId = null);
  }

  void _prepararSiguienteConcentracion({required String mensaje}) {
    _nController.clear();
    _pController.clear();
    _kController.clear();

    setState(() {
      _editandoId = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(mensaje)),
    );
  }

  Future<void> _eliminar(ProductoFertilizante producto) async {
    await ref
        .read(productosFertilizantesProvider.notifier)
        .eliminarFertilizanteManual(producto.id);
  }

  bool _validarCampos() {
    final valido = _formKey.currentState?.validate() ?? false;
    if (!valido) return false;

    final n = _aDouble(_nController.text) ?? 0;
    final p = _aDouble(_pController.text) ?? 0;
    final k = _aDouble(_kController.text) ?? 0;

    if (n <= 0 && p <= 0 && k <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa al menos una concentración mayor que cero.'),
        ),
      );
      return false;
    }

    return true;
  }
}


class _ConcentracionesAplicadasModalCard extends StatelessWidget {
  const _ConcentracionesAplicadasModalCard({
    required this.cantidad,
    required this.siguienteProducto,
  });

  final int cantidad;
  final int siguienteProducto;

  @override
  Widget build(BuildContext context) {
    final hayAgregadas = cantidad > 0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: hayAgregadas
            ? AppColores.primariosuave.withOpacity(0.68)
            : AppColores.fondo,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: hayAgregadas
              ? AppColores.primario.withOpacity(0.18)
              : AppColores.borde,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            hayAgregadas
                ? Icons.add_task_rounded
                : Icons.info_outline_rounded,
            size: 20,
            color: hayAgregadas
                ? AppColores.primario
                : AppColores.textoSecundario,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              hayAgregadas
                  ? 'Ya agregaste $cantidad concentración(es). Digita la siguiente concentración para el Producto $siguienteProducto.'
                  : 'Digita la concentración del fertilizante disponible para crear el Producto 1.',
              style: const TextStyle(
                fontSize: 12.2,
                height: 1.3,
                fontWeight: FontWeight.w700,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _ProductosAplicadosModalExpansionCard extends StatelessWidget {
  const _ProductosAplicadosModalExpansionCard({
    required this.plan,
    required this.fertilizantes,
  });

  final PlanNutricionalNpk plan;
  final List<FertilizanteSugerido> fertilizantes;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(18),
        child: ExpansionTile(
          tilePadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
          childrenPadding: const EdgeInsets.fromLTRB(12, 0, 12, 12),
          leading: const Icon(
            Icons.inventory_2_rounded,
            color: AppColores.primario,
            size: 21,
          ),
          title: Text(
            fertilizantes.length == 1
                ? 'Producto agregado al cálculo'
                : 'Productos agregados al cálculo',
            style: const TextStyle(
              fontSize: 13.3,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          subtitle: Text(
            fertilizantes.length == 1
                ? 'Toca para ver el detalle del Producto 1.'
                : 'Toca para ver el detalle de los ${fertilizantes.length} productos.',
            style: const TextStyle(
              fontSize: 11.4,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          children: _construirProductosConBalance(),
        ),
      ),
    );
  }

  List<Widget> _construirProductosConBalance() {
    final widgets = <Widget>[];

    final necesidadInicialN = plan.resumenCobertura.necesidadN;
    final necesidadInicialP = plan.resumenCobertura.necesidadP2O5;
    final necesidadInicialK = plan.resumenCobertura.necesidadK2O;

    double acumuladoN = 0;
    double acumuladoP = 0;
    double acumuladoK = 0;

    for (var index = 0; index < fertilizantes.length; index++) {
      final fertilizante = fertilizantes[index];
      final aporteN = fertilizante.kgPorSemana * (fertilizante.concentracionN / 100);
      final aporteP = fertilizante.kgPorSemana * (fertilizante.concentracionP2O5 / 100);
      final aporteK = fertilizante.kgPorSemana * (fertilizante.concentracionK2O / 100);

      acumuladoN += aporteN;
      acumuladoP += aporteP;
      acumuladoK += aporteK;

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: index == fertilizantes.length - 1 ? 0 : 10,
          ),
          child: _ProductoAplicadoModalItem(
            numero: index + 1,
            fertilizante: fertilizante,
            faltanteDespuesN: _positivo(necesidadInicialN - acumuladoN),
            faltanteDespuesP2O5: _positivo(necesidadInicialP - acumuladoP),
            faltanteDespuesK2O: _positivo(necesidadInicialK - acumuladoK),
            excesoDespuesN: _positivo(acumuladoN - necesidadInicialN),
            excesoDespuesP2O5: _positivo(acumuladoP - necesidadInicialP),
            excesoDespuesK2O: _positivo(acumuladoK - necesidadInicialK),
          ),
        ),
      );
    }

    return widgets;
  }
}

class _ProductoAplicadoModalItem extends StatelessWidget {
  const _ProductoAplicadoModalItem({
    required this.numero,
    required this.fertilizante,
    required this.faltanteDespuesN,
    required this.faltanteDespuesP2O5,
    required this.faltanteDespuesK2O,
    required this.excesoDespuesN,
    required this.excesoDespuesP2O5,
    required this.excesoDespuesK2O,
  });

  final int numero;
  final FertilizanteSugerido fertilizante;
  final double faltanteDespuesN;
  final double faltanteDespuesP2O5;
  final double faltanteDespuesK2O;
  final double excesoDespuesN;
  final double excesoDespuesP2O5;
  final double excesoDespuesK2O;

  @override
  Widget build(BuildContext context) {
    final aporteN = fertilizante.kgPorSemana * (fertilizante.concentracionN / 100);
    final aporteP = fertilizante.kgPorSemana * (fertilizante.concentracionP2O5 / 100);
    final aporteK = fertilizante.kgPorSemana * (fertilizante.concentracionK2O / 100);
    final concentracion =
        '${_numero(fertilizante.concentracionN)}-${_numero(fertilizante.concentracionP2O5)}-${_numero(fertilizante.concentracionK2O)}';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.primario.withOpacity(0.14)),
      ),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(top: 10),
        initiallyExpanded: false,
        leading: Container(
          width: 34,
          height: 34,
          decoration: BoxDecoration(
            color: AppColores.primariosuave.withOpacity(0.75),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Center(
            child: Text(
              '$numero',
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w900,
                color: AppColores.primario,
              ),
            ),
          ),
        ),
        title: Text(
          'Producto $numero',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),
        subtitle: Text(
          'Concentración $concentracion',
          style: const TextStyle(
            fontSize: 11.7,
            fontWeight: FontWeight.w700,
            color: AppColores.textoSecundario,
          ),
        ),
        children: [
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
            decoration: BoxDecoration(
              color: AppColores.primariosuave.withOpacity(0.55),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: AppColores.primario.withOpacity(0.15)),
            ),
            child: Row(
              children: [
                const Expanded(
                  child: Text(
                    'Resultado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      color: AppColores.textoSecundario,
                    ),
                  ),
                ),
                Text(
                  '${_numero(fertilizante.kgPorSemana)} kg/semana',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.primario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 10),
          const Text(
            'Aporte semanal de este producto',
            style: TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _AporteChip(titulo: 'N', valor: aporteN),
              _AporteChip(titulo: 'P₂O₅', valor: aporteP),
              _AporteChip(titulo: 'K₂O', valor: aporteK),
            ],
          ),
          const SizedBox(height: 10),
          _BloqueNutrientesModal(
            titulo: 'Faltante después del Producto $numero',
            colorearPorEstado: true,
            valores: [
              _NutrienteModalValor('N', faltanteDespuesN),
              _NutrienteModalValor('P₂O₅', faltanteDespuesP2O5),
              _NutrienteModalValor('K₂O', faltanteDespuesK2O),
            ],
          ),
          if (excesoDespuesN > 0 ||
              excesoDespuesP2O5 > 0 ||
              excesoDespuesK2O > 0) ...[
            const SizedBox(height: 10),
            _BloqueNutrientesModal(
              titulo: 'Exceso acumulado después del Producto $numero',
              color: AppColores.advertencia,
              valores: [
                if (excesoDespuesN > 0)
                  _NutrienteModalValor('N +', excesoDespuesN),
                if (excesoDespuesP2O5 > 0)
                  _NutrienteModalValor('P₂O₅ +', excesoDespuesP2O5),
                if (excesoDespuesK2O > 0)
                  _NutrienteModalValor('K₂O +', excesoDespuesK2O),
              ],
            ),
          ],
        ],
      ),
    );
  }
}

class _TituloIngresoConcentracion extends StatelessWidget {
  const _TituloIngresoConcentracion();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 11, 12, 11),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.52),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.16),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.edit_note_rounded,
            color: AppColores.primario,
            size: 21,
          ),
          SizedBox(width: 9),
          Expanded(
            child: Text(
              'Digite la concentración del fertilizante',
              style: TextStyle(
                fontSize: 13.2,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _CampoConcentracionModal extends StatelessWidget {
  const _CampoConcentracionModal({
    required this.controller,
    required this.label,
    required this.onChanged,
  });

  final TextEditingController controller;
  final String label;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(9, 9, 9, 8),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: AppColores.primario,
            ),
          ),
          const SizedBox(height: 5),
          TextFormField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            onChanged: onChanged,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
            decoration: InputDecoration(
              hintText: '0',
              suffixText: '%',
              suffixStyle: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: AppColores.textoSecundario,
              ),
              isDense: true,
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColores.borde),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(
                  color: AppColores.primario,
                  width: 1.5,
                ),
              ),
              filled: true,
              fillColor: AppColores.superficie,
            ),
            validator: (valor) {
              final numero = _aDouble(valor);
              if (numero == null) return 'Inválido';
              if (numero < 0 || numero > 100) return '0 a 100';
              return null;
            },
          ),
        ],
      ),
    );
  }
}

class _VistaPreviaConcentracionCard extends StatelessWidget {
  const _VistaPreviaConcentracionCard({
    required this.vistaPrevia,
    required this.tituloProducto,
    required this.concentracionTexto,
  });

  final _VistaPreviaDosis vistaPrevia;
  final String tituloProducto;
  final String concentracionTexto;

  @override
  Widget build(BuildContext context) {
    final tieneResultado = vistaPrevia.dosisKgSemana > 0;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(13),
          decoration: BoxDecoration(
            color: AppColores.fondo,
            borderRadius: BorderRadius.circular(18),
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
                      color: AppColores.primariosuave.withOpacity(0.75),
                      borderRadius: BorderRadius.circular(13),
                      border: Border.all(
                        color: AppColores.primario.withOpacity(0.14),
                      ),
                    ),
                    child: const Icon(
                      Icons.inventory_2_outlined,
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
                          tituloProducto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 14.5,
                            fontWeight: FontWeight.w900,
                            color: AppColores.textoPrincipal,
                          ),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          'Concentración $concentracionTexto',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12.2,
                            fontWeight: FontWeight.w800,
                            color: AppColores.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 13),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                decoration: BoxDecoration(
                  color: AppColores.superficie,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.14),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Resultado',
                      style: TextStyle(
                        fontSize: 11.5,
                        fontWeight: FontWeight.w800,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      tieneResultado
                          ? '${_numero(vistaPrevia.dosisKgSemana)} kg/semana'
                          : 'Ingresa una concentración para calcular.',
                      style: TextStyle(
                        fontSize: tieneResultado ? 23 : 12.5,
                        height: 1.05,
                        fontWeight: FontWeight.w900,
                        color: tieneResultado
                            ? AppColores.primario
                            : AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Aporte semanal de esta concentración',
                style: TextStyle(
                  fontSize: 12.3,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  _AporteChip(titulo: 'N', valor: vistaPrevia.aporteN),
                  _AporteChip(titulo: 'P₂O₅', valor: vistaPrevia.aporteP2O5),
                  _AporteChip(titulo: 'K₂O', valor: vistaPrevia.aporteK2O),
                ],
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        _BloqueNutrientesModal(
          titulo: 'Faltante semanal después de aplicar',
          colorearPorEstado: true,
          valores: [
            _NutrienteModalValor('N', vistaPrevia.faltanteDespuesN),
            _NutrienteModalValor('P₂O₅', vistaPrevia.faltanteDespuesP2O5),
            _NutrienteModalValor('K₂O', vistaPrevia.faltanteDespuesK2O),
          ],
        ),
        if (vistaPrevia.excesoN > 0 ||
            vistaPrevia.excesoP2O5 > 0 ||
            vistaPrevia.excesoK2O > 0) ...[
          const SizedBox(height: 12),
          _BloqueNutrientesModal(
            titulo: 'Exceso semanal después de aplicar',
            color: AppColores.advertencia,
            valores: [
              if (vistaPrevia.excesoN > 0)
                _NutrienteModalValor('N +', vistaPrevia.excesoN),
              if (vistaPrevia.excesoP2O5 > 0)
                _NutrienteModalValor('P₂O₅ +', vistaPrevia.excesoP2O5),
              if (vistaPrevia.excesoK2O > 0)
                _NutrienteModalValor('K₂O +', vistaPrevia.excesoK2O),
            ],
          ),
        ],
      ],
    );
  }
}

class _NutrienteModalValor {
  const _NutrienteModalValor(this.titulo, this.valor);

  final String titulo;
  final double valor;
}

class _BloqueNutrientesModal extends StatelessWidget {
  const _BloqueNutrientesModal({
    required this.titulo,
    required this.valores,
    this.color = AppColores.primario,
    this.colorearPorEstado = false,
  });

  final String titulo;
  final List<_NutrienteModalValor> valores;
  final Color color;
  final bool colorearPorEstado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 12.3,
              fontWeight: FontWeight.w900,
              color: color == AppColores.primario
                  ? AppColores.textoPrincipal
                  : color,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: valores.map((item) {
              return Expanded(
                child: Padding(
                  padding: const EdgeInsets.only(right: 7),
                  child: _CuadroNutrienteModal(
                    titulo: item.titulo,
                    valor: item.valor,
                    color: color,
                    colorearPorEstado: colorearPorEstado,
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

class _CuadroNutrienteModal extends StatelessWidget {
  const _CuadroNutrienteModal({
    required this.titulo,
    required this.valor,
    required this.color,
    required this.colorearPorEstado,
  });

  final String titulo;
  final double valor;
  final Color color;
  final bool colorearPorEstado;

  @override
  Widget build(BuildContext context) {
    final colorEstado = colorearPorEstado
        ? (valor > 0.001 ? AppColores.prioridadMedia : AppColores.primario)
        : color;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: colorEstado.withOpacity(0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorEstado.withOpacity(0.22)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: colorEstado,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_numero(valor)} kg/sem',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.5,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _AporteChip extends StatelessWidget {
  const _AporteChip({required this.titulo, required this.valor});

  final String titulo;
  final double valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.65),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppColores.primario.withOpacity(0.15)),
      ),
      child: Text(
        '$titulo ${_numero(valor)} kg/sem',
        style: const TextStyle(
          fontSize: 11.5,
          fontWeight: FontWeight.w900,
          color: AppColores.primario,
        ),
      ),
    );
  }
}

class _ConcentracionGuardadaModalItem extends StatelessWidget {
  const _ConcentracionGuardadaModalItem({
    required this.producto,
    required this.onSeleccionar,
    required this.onEditar,
    required this.onEliminar,
  });

  final ProductoFertilizante producto;
  final VoidCallback onSeleccionar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: producto.seleccionado
            ? AppColores.primariosuave.withOpacity(0.68)
            : AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: producto.seleccionado
              ? AppColores.primario.withOpacity(0.25)
              : AppColores.borde,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: producto.seleccionado,
            onChanged: (_) => onSeleccionar(),
            visualDensity: VisualDensity.compact,
          ),
          Expanded(
            child: Text(
              producto.nombre,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13.3,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
          IconButton(
            onPressed: onEditar,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.edit_rounded,
              size: 19,
              color: AppColores.primario,
            ),
          ),
          IconButton(
            onPressed: onEliminar,
            visualDensity: VisualDensity.compact,
            icon: const Icon(
              Icons.delete_outline_rounded,
              size: 20,
              color: AppColores.advertencia,
            ),
          ),
        ],
      ),
    );
  }
}

class _VistaPreviaDosis {
  const _VistaPreviaDosis({
    required this.dosisKgSemana,
    required this.necesidadN,
    required this.necesidadP2O5,
    required this.necesidadK2O,
    required this.aporteN,
    required this.aporteP2O5,
    required this.aporteK2O,
    required this.faltanteDespuesN,
    required this.faltanteDespuesP2O5,
    required this.faltanteDespuesK2O,
    required this.excesoN,
    required this.excesoP2O5,
    required this.excesoK2O,
  });

  final double dosisKgSemana;
  final double necesidadN;
  final double necesidadP2O5;
  final double necesidadK2O;
  final double aporteN;
  final double aporteP2O5;
  final double aporteK2O;
  final double faltanteDespuesN;
  final double faltanteDespuesP2O5;
  final double faltanteDespuesK2O;
  final double excesoN;
  final double excesoP2O5;
  final double excesoK2O;
}

_VistaPreviaDosis _calcularVistaPreviaConcentracion({
  required PlanNutricionalNpk plan,
  required double n,
  required double p2o5,
  required double k2o,
}) {
  final necesidadInicialN = plan.resumenCobertura.necesidadN;
  final necesidadInicialP = plan.resumenCobertura.necesidadP2O5;
  final necesidadInicialK = plan.resumenCobertura.necesidadK2O;

  final aporteAnteriorN = plan.resumenCobertura.aporteN;
  final aporteAnteriorP = plan.resumenCobertura.aporteP2O5;
  final aporteAnteriorK = plan.resumenCobertura.aporteK2O;

  final necesidadN = _positivo(necesidadInicialN - aporteAnteriorN);
  final necesidadP = _positivo(necesidadInicialP - aporteAnteriorP);
  final necesidadK = _positivo(necesidadInicialK - aporteAnteriorK);

  if (n <= 0 && p2o5 <= 0 && k2o <= 0) {
    return _VistaPreviaDosis(
      dosisKgSemana: 0,
      necesidadN: necesidadN,
      necesidadP2O5: necesidadP,
      necesidadK2O: necesidadK,
      aporteN: 0,
      aporteP2O5: 0,
      aporteK2O: 0,
      faltanteDespuesN: necesidadN,
      faltanteDespuesP2O5: necesidadP,
      faltanteDespuesK2O: necesidadK,
      excesoN: _positivo(aporteAnteriorN - necesidadInicialN),
      excesoP2O5: _positivo(aporteAnteriorP - necesidadInicialP),
      excesoK2O: _positivo(aporteAnteriorK - necesidadInicialK),
    );
  }

  final opciones = <double>[];
  if (necesidadN > 0 && n > 0) opciones.add(necesidadN / (n / 100));
  if (necesidadP > 0 && p2o5 > 0) opciones.add(necesidadP / (p2o5 / 100));
  if (necesidadK > 0 && k2o > 0) opciones.add(necesidadK / (k2o / 100));

  final dosis = opciones.isEmpty
      ? 0.0
      : opciones.reduce((a, b) => a > b ? a : b);

  final aporteN = dosis * (n / 100);
  final aporteP = dosis * (p2o5 / 100);
  final aporteK = dosis * (k2o / 100);

  final aporteTotalN = aporteAnteriorN + aporteN;
  final aporteTotalP = aporteAnteriorP + aporteP;
  final aporteTotalK = aporteAnteriorK + aporteK;

  return _VistaPreviaDosis(
    dosisKgSemana: dosis,
    necesidadN: necesidadN,
    necesidadP2O5: necesidadP,
    necesidadK2O: necesidadK,
    aporteN: aporteN,
    aporteP2O5: aporteP,
    aporteK2O: aporteK,
    faltanteDespuesN: _positivo(necesidadInicialN - aporteTotalN),
    faltanteDespuesP2O5: _positivo(necesidadInicialP - aporteTotalP),
    faltanteDespuesK2O: _positivo(necesidadInicialK - aporteTotalK),
    excesoN: _positivo(aporteTotalN - necesidadInicialN),
    excesoP2O5: _positivo(aporteTotalP - necesidadInicialP),
    excesoK2O: _positivo(aporteTotalK - necesidadInicialK),
  );
}

double _positivo(double valor) {
  return valor > 0 ? valor : 0;
}

double _normalizarCero(double valor) {
  return valor.abs() < 0.001 ? 0.0 : valor;
}


class _ConfiguracionResumenCard extends ConsumerStatefulWidget {
  const _ConfiguracionResumenCard({
    required this.parametros,
  });

  final ParametrosPlanNutricionalNpk parametros;

  @override
  ConsumerState<_ConfiguracionResumenCard> createState() =>
      _ConfiguracionResumenCardState();
}

class _ConfiguracionResumenCardState
    extends ConsumerState<_ConfiguracionResumenCard> {
  late final TextEditingController _plantasController;
  late final FocusNode _plantasFocusNode;

  @override
  void initState() {
    super.initState();
    _plantasController = TextEditingController(
      text: widget.parametros.numeroPlantasLote.toString(),
    );
    _plantasFocusNode = FocusNode();
  }

  @override
  void didUpdateWidget(covariant _ConfiguracionResumenCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    final nuevoTexto = widget.parametros.numeroPlantasLote.toString();
    if (!_plantasFocusNode.hasFocus && _plantasController.text != nuevoTexto) {
      _plantasController.text = nuevoTexto;
    }
  }

  @override
  void dispose() {
    _plantasController.dispose();
    _plantasFocusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final loteSeleccionado = ref.watch(loteSeleccionadoProvider);
    final etapaActual = ref.watch(etapaFenologicaNpkProvider);

    return Container(
      padding: const EdgeInsets.fromLTRB(13, 12, 13, 9),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(20),
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
          const Row(
            children: [
              Icon(
                Icons.fact_check_rounded,
                color: AppColores.primario,
                size: 19,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Datos del cálculo',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),

          Row(
            children: [
              Expanded(
                child: _SelectorLoteInline(
                  loteActualId: loteSeleccionado.id,
                  onChanged: (loteNuevoId) {
                    if (loteNuevoId == null) return;

                    final lotes = ref.read(lotesCultivoProvider).valueOrNull ??
                        <LoteCultivo>[LoteCultivo.loteInicial()];

                    final loteNuevo = lotes.firstWhere(
                      (lote) => lote.id == loteNuevoId,
                      orElse: () => LoteCultivo.loteInicial(),
                    );

                    ref.read(loteSeleccionadoIdProvider.notifier).state =
                        loteNuevo.id;
                    ref.read(lotePlanNutricionalProvider.notifier).state =
                        loteNuevo.nombre;
                    ref
                        .read(configuracionPlanNutricionalProvider.notifier)
                        .actualizarDesdeLote(loteNuevo);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _SelectorEtapaInline(
                  etapaActual: etapaActual,
                  onChanged: (etapaNueva) {
                    if (etapaNueva == null) return;
                    ref.read(etapaFenologicaNpkProvider.notifier).state =
                        etapaNueva;
                    ref
                        .read(configuracionPlanNutricionalProvider.notifier)
                        .seleccionarEtapa(etapaNueva);
                  },
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: _CampoPlantasInline(
                  controller: _plantasController,
                  focusNode: _plantasFocusNode,
                  onGuardar: _guardarPlantas,
                ),
              ),
            ],
          ),

          const SizedBox(height: 8),
          Align(
            alignment: Alignment.centerRight,
            child: TextButton.icon(
              onPressed: () {
                context.push(RutasApp.configuracionPlanNutricional);
              },
              icon: const Icon(
                Icons.tune_rounded,
                size: 17,
              ),
              label: const Text('Editar configuración'),
              style: TextButton.styleFrom(
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 8),
                textStyle: const TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _guardarPlantas() {
    final valor = int.tryParse(_plantasController.text.trim());

    if (valor == null || valor <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ingresa un número válido de plantas.'),
        ),
      );
      return;
    }

    ref
        .read(configuracionPlanNutricionalProvider.notifier)
        .actualizarNumeroPlantas(valor);

    _plantasFocusNode.unfocus();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Plantas actualizadas a $valor.'),
      ),
    );
  }
}

class _SelectorLoteInline extends ConsumerWidget {
  const _SelectorLoteInline({
    required this.loteActualId,
    required this.onChanged,
  });

  final String loteActualId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesCultivoProvider);
    final lotes = lotesAsync.valueOrNull ?? <LoteCultivo>[
      LoteCultivo.loteInicial(),
    ];

    final value = lotes.any((lote) => lote.id == loteActualId)
        ? loteActualId
        : lotes.first.id;

    return _CajaDatoCalculo(
      icono: Icons.place_rounded,
      titulo: 'Lote',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<String>(
          value: value,
          isExpanded: true,
          isDense: true,
          iconSize: 18,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(
            fontSize: 12.2,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
          selectedItemBuilder: (context) {
            return lotes.map((lote) {
              return Text(
                lote.nombre,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          items: lotes.map((lote) {
            return DropdownMenuItem<String>(
              value: lote.id,
              child: Text(lote.nombre),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}
class _SelectorEtapaInline extends StatelessWidget {
  const _SelectorEtapaInline({
    required this.etapaActual,
    required this.onChanged,
  });

  final EtapaFenologicaNpk etapaActual;
  final ValueChanged<EtapaFenologicaNpk?> onChanged;

  @override
  Widget build(BuildContext context) {
    return _CajaDatoCalculo(
      icono: Icons.eco_rounded,
      titulo: 'Etapa',
      child: DropdownButtonHideUnderline(
        child: DropdownButton<EtapaFenologicaNpk>(
          value: etapaActual,
          isExpanded: true,
          isDense: true,
          iconSize: 18,
          borderRadius: BorderRadius.circular(14),
          style: const TextStyle(
            fontSize: 12.2,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
          selectedItemBuilder: (context) {
            return EtapaFenologicaNpk.values.map((etapa) {
              return Text(
                _nombreCortoEtapa(etapa),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              );
            }).toList();
          },
          items: EtapaFenologicaNpk.values.map((etapa) {
            return DropdownMenuItem(
              value: etapa,
              child: Text(etapa.nombre),
            );
          }).toList(),
          onChanged: onChanged,
        ),
      ),
    );
  }
}

class _CampoPlantasInline extends StatelessWidget {
  const _CampoPlantasInline({
    required this.controller,
    required this.focusNode,
    required this.onGuardar,
  });

  final TextEditingController controller;
  final FocusNode focusNode;
  final VoidCallback onGuardar;

  @override
  Widget build(BuildContext context) {
    return _CajaDatoCalculo(
      icono: Icons.groups_rounded,
      titulo: 'Plantas',
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              focusNode: focusNode,
              keyboardType: TextInputType.number,
              textInputAction: TextInputAction.done,
              onSubmitted: (_) => onGuardar(),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                contentPadding: EdgeInsets.zero,
              ),
              style: const TextStyle(
                fontSize: 12.2,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
          InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: onGuardar,
            child: const Padding(
              padding: EdgeInsets.all(3),
              child: Icon(
                Icons.check_circle_rounded,
                size: 18,
                color: AppColores.primario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _CajaDatoCalculo extends StatelessWidget {
  const _CajaDatoCalculo({
    required this.icono,
    required this.titulo,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minHeight: 64),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: AppColores.borde.withOpacity(0.9)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            children: [
              Icon(
                icono,
                size: 15,
                color: AppColores.primario,
              ),
              const SizedBox(width: 5),
              Expanded(
                child: Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.3,
                    fontWeight: FontWeight.w800,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          child,
        ],
      ),
    );
  }
}

String _nombreCortoEtapa(EtapaFenologicaNpk etapa) {
  switch (etapa) {
    case EtapaFenologicaNpk.desarrolloVegetativo:
      return 'Vegetativo';
    case EtapaFenologicaNpk.desarrolloEstolones:
      return 'Estolones';
    case EtapaFenologicaNpk.floracion:
      return 'Floración';
    case EtapaFenologicaNpk.fructificacion:
      return 'Fructificación';
    case EtapaFenologicaNpk.desyerba:
      return 'Desyerba';
  }
}

class _ResultadoRecomendacionMinimalCard extends ConsumerWidget {
  const _ResultadoRecomendacionMinimalCard({
    required this.plan,
  });

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fertilizantes =
        plan.fertilizantes.where((f) => f.kgPorSemana > 0).toList();

    if (fertilizantes.isEmpty) {
      final observacion = plan.fertilizantes.isNotEmpty
          ? plan.fertilizantes.first.observacion
          : 'No hay concentraciones seleccionadas para calcular el plan.';

      return Card(
        elevation: 0,
        color: AppColores.advertenciasuave,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: BorderSide(
            color: AppColores.advertencia.withOpacity(0.24),
          ),
        ),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(14, 13, 14, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.info_outline_rounded,
                color: AppColores.advertencia,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  observacion,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: AppColores.primario.withOpacity(0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.eco_rounded,
                  color: AppColores.primario,
                  size: 22,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Resultado del plan',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 13),

          _ProductosPlanCard(
  fertilizantes: fertilizantes,
),

const SizedBox(height: 12),

_DetalleAplicacionPlanCard(
  plan: plan,
  fertilizantes: fertilizantes,
),


const SizedBox(height: 12),

SizedBox(
  width: double.infinity,
  height: 44,
  child: FilledButton.icon(
    onPressed: () {
      _mostrarModalFertilizantesPlan(
        context: context,
        ref: ref,
        plan: plan,
      );
    },
    icon: const Icon(Icons.add_circle_outline_rounded),
    label: const Text(
      'Agregar otra concentración',
      style: TextStyle(fontWeight: FontWeight.w900),
    ),
  ),
),
          ],
        ),
      ),
    );
  }
}



class _DetalleAplicacionPlanCard extends StatelessWidget {
  const _DetalleAplicacionPlanCard({
    required this.plan,
    required this.fertilizantes,
  });

  final PlanNutricionalNpk plan;
  final List<FertilizanteSugerido> fertilizantes;

  @override
  Widget build(BuildContext context) {
    final widgets = <Widget>[];

    final necesidadInicialN = plan.resumenCobertura.necesidadN;
    final necesidadInicialP = plan.resumenCobertura.necesidadP2O5;
    final necesidadInicialK = plan.resumenCobertura.necesidadK2O;

    double acumuladoN = 0;
    double acumuladoP = 0;
    double acumuladoK = 0;

    for (var index = 0; index < fertilizantes.length; index++) {
      final fertilizante = fertilizantes[index];

      final aporteN =
          fertilizante.kgPorSemana * (fertilizante.concentracionN / 100);
      final aporteP =
          fertilizante.kgPorSemana * (fertilizante.concentracionP2O5 / 100);
      final aporteK =
          fertilizante.kgPorSemana * (fertilizante.concentracionK2O / 100);

      acumuladoN += aporteN;
      acumuladoP += aporteP;
      acumuladoK += aporteK;

      final faltanteN = _normalizarCero(
        _positivo(necesidadInicialN - acumuladoN),
      );
      final faltanteP = _normalizarCero(
        _positivo(necesidadInicialP - acumuladoP),
      );
      final faltanteK = _normalizarCero(
        _positivo(necesidadInicialK - acumuladoK),
      );

      final excesoN = _normalizarCero(
        _positivo(acumuladoN - necesidadInicialN),
      );
      final excesoP = _normalizarCero(
        _positivo(acumuladoP - necesidadInicialP),
      );
      final excesoK = _normalizarCero(
        _positivo(acumuladoK - necesidadInicialK),
      );

      widgets.add(
        Padding(
          padding: EdgeInsets.only(
            bottom: index == fertilizantes.length - 1 ? 0 : 12,
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColores.fondo,
              borderRadius: BorderRadius.circular(17),
              border: Border.all(color: AppColores.borde),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 34,
                      height: 34,
                      decoration: BoxDecoration(
                        color: AppColores.primariosuave,
                        borderRadius: BorderRadius.circular(11),
                      ),
                      alignment: Alignment.center,
                      child: Text(
                        '${index + 1}',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: AppColores.primario,
                        ),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Producto ${index + 1}',
                            style: const TextStyle(
                              fontSize: 13.5,
                              fontWeight: FontWeight.w900,
                              color: AppColores.textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Concentración ${_numero(fertilizante.concentracionN)}-'
                            '${_numero(fertilizante.concentracionP2O5)}-'
                            '${_numero(fertilizante.concentracionK2O)}',
                            style: const TextStyle(
                              fontSize: 11.5,
                              fontWeight: FontWeight.w700,
                              color: AppColores.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Text(
                      '${_numero(fertilizante.kgPorSemana)} kg/semana',
                      style: const TextStyle(
                        fontSize: 12.5,
                        fontWeight: FontWeight.w900,
                        color: AppColores.primario,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                const Text(
                  'Aporte de este producto',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 7),
                _DetalleNpkFilaPlan(
                  n: aporteN,
                  p: aporteP,
                  k: aporteK,
                  tipo: _TipoDetallePlan.aporte,
                ),

                const SizedBox(height: 11),
                const Text(
                  'Faltante semanal después de aplicar',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 7),
                _DetalleNpkFilaPlan(
                  n: faltanteN,
                  p: faltanteP,
                  k: faltanteK,
                  tipo: _TipoDetallePlan.faltante,
                ),

                if (excesoN > 0.001 ||
                    excesoP > 0.001 ||
                    excesoK > 0.001) ...[
                  const SizedBox(height: 11),
                  const Text(
                    'Excedente acumulado',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColores.advertencia,
                    ),
                  ),
                  const SizedBox(height: 7),
                  _DetalleNpkFilaPlan(
                    n: excesoN,
                    p: excesoP,
                    k: excesoK,
                    tipo: _TipoDetallePlan.exceso,
                  ),
                ],
              ],
            ),
          ),
        ),
      );
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.analytics_outlined,
                size: 20,
                color: AppColores.primario,
              ),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Detalle de aplicación',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          const Text(
            'Muestra el aporte, el faltante restante y el excedente de cada producto.',
            style: TextStyle(
              fontSize: 11.2,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 11),
          ...widgets,
        ],
      ),
    );
  }
}

enum _TipoDetallePlan {
  aporte,
  faltante,
  exceso,
}

class _DetalleNpkFilaPlan extends StatelessWidget {
  const _DetalleNpkFilaPlan({
    required this.n,
    required this.p,
    required this.k,
    required this.tipo,
  });

  final double n;
  final double p;
  final double k;
  final _TipoDetallePlan tipo;

  @override
  Widget build(BuildContext context) {
    Color colorPara(double valor) {
      switch (tipo) {
        case _TipoDetallePlan.aporte:
          return AppColores.primario;
        case _TipoDetallePlan.faltante:
          return valor > 0.001
              ? AppColores.advertencia
              : AppColores.primario;
        case _TipoDetallePlan.exceso:
          return valor > 0.001
              ? AppColores.advertencia
              : AppColores.primario;
      }
    }

    return Row(
      children: [
        Expanded(
          child: _DetalleNpkValorPlan(
            titulo: 'N',
            valor: n,
            color: colorPara(n),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _DetalleNpkValorPlan(
            titulo: 'P₂O₅',
            valor: p,
            color: colorPara(p),
          ),
        ),
        const SizedBox(width: 7),
        Expanded(
          child: _DetalleNpkValorPlan(
            titulo: 'K₂O',
            valor: k,
            color: colorPara(k),
          ),
        ),
      ],
    );
  }
}

class _DetalleNpkValorPlan extends StatelessWidget {
  const _DetalleNpkValorPlan({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  final String titulo;
  final double valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 9),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: color.withOpacity(0.16)),
      ),
      child: Column(
        children: [
          Text(
            titulo,
            style: TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            '${_numero(valor)} kg',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11.2,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ProductosPlanCard extends StatelessWidget {
  const _ProductosPlanCard({
    required this.fertilizantes,
  });

  final List<FertilizanteSugerido> fertilizantes;

  @override
  Widget build(BuildContext context) {
    final esUnoSolo = fertilizantes.length == 1;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 15, 16, 16),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.18),
        ),
      ),
      child: esUnoSolo
          ? _ProductoUnicoPlan(
              fertilizante: fertilizantes.first,
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Concentraciones del plan',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 12),
                ...fertilizantes.map(
                  (fertilizante) => Padding(
                    padding: const EdgeInsets.only(bottom: 9),
                    child: _ProductoFilaPlan(
                      fertilizante: fertilizante,
                    ),
                  ),
                ),
              ],
            ),
    );
  }
}
class _ProductoUnicoPlan extends StatelessWidget {
  const _ProductoUnicoPlan({
    required this.fertilizante,
  });

  final FertilizanteSugerido fertilizante;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        const Row(
          children: [
            Icon(
              Icons.inventory_2_outlined,
              size: 20,
              color: AppColores.primario,
            ),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Concentración usada',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
            ),
          ],
        ),

        const SizedBox(height: 18),

        Text(
          fertilizante.nombre,
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 19,
            height: 1.15,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),

        const SizedBox(height: 14),

        const Text(
          'Dosis semanal',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 11.5,
            fontWeight: FontWeight.w700,
            color: AppColores.textoSecundario,
          ),
        ),

        const SizedBox(height: 5),

        Text(
          '${_numero(fertilizante.kgPorSemana)} kg/semana',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 30,
            height: 1,
            fontWeight: FontWeight.w900,
            color: AppColores.primario,
            letterSpacing: -0.5,
          ),
        ),
      ],
    );
  }
}

class _ProductoFilaPlan extends StatelessWidget {
  const _ProductoFilaPlan({
    required this.fertilizante,
  });

  final FertilizanteSugerido fertilizante;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(
            fertilizante.nombre,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 13,
              height: 1.2,
              fontWeight: FontWeight.w800,
              color: AppColores.textoPrincipal,
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          '${_numero(fertilizante.kgPorSemana)} kg',
          style: const TextStyle(
            fontSize: 13.5,
            fontWeight: FontWeight.w900,
            color: AppColores.primario,
          ),
        ),
      ],
    );
  }
}



class _ResumenInterpretacionPlanCard extends StatelessWidget {
  const _ResumenInterpretacionPlanCard({
    required this.fertilizantes,
  });

  final List<FertilizanteSugerido> fertilizantes;

  @override
  Widget build(BuildContext context) {
    final esUnoSolo = fertilizantes.length == 1;

    final texto = esUnoSolo
        ? 'La dosis se calculó para el producto seleccionado según el nutriente que necesita corrección.'
        : 'Cada producto se muestra con su dosis semanal calculada. La aplicación organiza el plan según los nutrientes que requieren corrección.';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            size: 20,
            color: AppColores.primario,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              texto,
              style: const TextStyle(
                fontSize: 12.2,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
class _ProductoPrincipalPlanCard extends StatelessWidget {
  const _ProductoPrincipalPlanCard({
    required this.fertilizante,
  });

  final FertilizanteSugerido fertilizante;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 15, 14, 15),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.72),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.18),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(14),
              border: Border.all(
                color: AppColores.primario.withOpacity(0.16),
              ),
            ),
            child: const Icon(
              Icons.inventory_2_outlined,
              size: 22,
              color: AppColores.primario,
            ),
          ),
          const SizedBox(height: 10),

          const Text(
            'Concentración usada',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w800,
              color: AppColores.primario,
            ),
          ),

          const SizedBox(height: 5),

          Text(
            fertilizante.nombre,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 18,
              height: 1.15,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(
              horizontal: 13,
              vertical: 14,
            ),
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppColores.primario.withOpacity(0.16),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  'Dosis semanal recomendada',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  '${_numero(fertilizante.kgPorSemana)} kg/semana',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: AppColores.primario,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _DatoResultadoPrincipal extends StatelessWidget {
  const _DatoResultadoPrincipal({
    required this.titulo,
    required this.valor,
    required this.color,
  });

  final String titulo;
  final String valor;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 10,
      ),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: color.withOpacity(0.16),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResumenInterpretacionDosisCard extends StatelessWidget {
  const _ResumenInterpretacionDosisCard({
    required this.fertilizante,
    required this.plan,
  });

  final FertilizanteSugerido fertilizante;
  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context) {
    final nNecesario = plan.nitrogeno.faltanteFormaComercialSemanaKg;
    final pNecesario = plan.fosforo.faltanteFormaComercialSemanaKg;
    final kNecesario = plan.potasio.faltanteFormaComercialSemanaKg;

    final dosisParaN = fertilizante.concentracionN > 0 && nNecesario > 0
        ? nNecesario / (fertilizante.concentracionN / 100)
        : 0.0;

    final dosisParaP = fertilizante.concentracionP2O5 > 0 && pNecesario > 0
        ? pNecesario / (fertilizante.concentracionP2O5 / 100)
        : 0.0;

    final dosisParaK = fertilizante.concentracionK2O > 0 && kNecesario > 0
        ? kNecesario / (fertilizante.concentracionK2O / 100)
        : 0.0;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Interpretación rápida',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'La app recomienda ${_numero(fertilizante.kgPorSemana)} kg/semana porque la concentración debe cubrir principalmente ${fertilizante.nutrienteObjetivo}.',
            style: const TextStyle(
              fontSize: 12.2,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 11),
          _FilaDosisSimple(
            nutriente: 'N',
            dosis: dosisParaN,
            seleccionado: fertilizante.nutrienteObjetivo == 'N',
          ),
          const SizedBox(height: 7),
          _FilaDosisSimple(
            nutriente: 'P₂O₅',
            dosis: dosisParaP,
            seleccionado: fertilizante.nutrienteObjetivo == 'P₂O₅',
          ),
          const SizedBox(height: 7),
          _FilaDosisSimple(
            nutriente: 'K₂O',
            dosis: dosisParaK,
            seleccionado: fertilizante.nutrienteObjetivo == 'K₂O',
          ),
        ],
      ),
    );
  }
}

class _FilaDosisSimple extends StatelessWidget {
  const _FilaDosisSimple({
    required this.nutriente,
    required this.dosis,
    required this.seleccionado,
  });

  final String nutriente;
  final double dosis;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    final color =
        seleccionado ? AppColores.primario : AppColores.textoSecundario;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: seleccionado
            ? AppColores.primariosuave.withOpacity(0.72)
            : AppColores.superficie,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: seleccionado
              ? AppColores.primario.withOpacity(0.22)
              : AppColores.borde,
        ),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              seleccionado ? '$nutriente cubierto por este producto' : nutriente,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
                color: color,
              ),
            ),
          ),
          Text(
            dosis > 0 ? '${_numero(dosis)} kg/semana' : 'No requiere',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: seleccionado
                  ? AppColores.primario
                  : AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _CoberturaSimplePlanCard extends StatelessWidget {
  const _CoberturaSimplePlanCard({
    required this.resumen,
  });

  final ResumenCoberturaNpk resumen;

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
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Resumen de cobertura',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 4),
          const Text(
            'Muestra si la dosis sugerida cubre lo que el cultivo necesita.',
            style: TextStyle(
              fontSize: 11.8,
              height: 1.3,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          _FilaCoberturaSimple(
            nutriente: 'N',
            requerido: resumen.necesidadN,
            aportado: resumen.aporteN,
          ),
          const SizedBox(height: 7),
          _FilaCoberturaSimple(
            nutriente: 'P₂O₅',
            requerido: resumen.necesidadP2O5,
            aportado: resumen.aporteP2O5,
          ),
          const SizedBox(height: 7),
          _FilaCoberturaSimple(
            nutriente: 'K₂O',
            requerido: resumen.necesidadK2O,
            aportado: resumen.aporteK2O,
          ),
        ],
      ),
    );
  }
}

class _FilaCoberturaSimple extends StatelessWidget {
  const _FilaCoberturaSimple({
    required this.nutriente,
    required this.requerido,
    required this.aportado,
  });

  final String nutriente;
  final double requerido;
  final double aportado;

  @override
  Widget build(BuildContext context) {
    final diferencia = aportado - requerido;

    String estado;
    Color color;

    if (requerido <= 0 && aportado <= 0) {
      estado = 'No requiere';
      color = AppColores.primario;
    } else if (requerido <= 0 && aportado > 0) {
      estado = 'Aporte adicional';
      color = AppColores.prioridadMedia;
    } else if (diferencia >= 0) {
      estado = diferencia <= 0.01 ? 'Cubierto' : 'Exceso';
      color = diferencia <= 0.01
          ? AppColores.primario
          : AppColores.prioridadMedia;
    } else {
      estado = 'Falta';
      color = AppColores.advertencia;
    }

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 9,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(13),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 34,
            decoration: BoxDecoration(
              color: color.withOpacity(0.10),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Center(
              child: Text(
                nutriente,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              estado,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ),
          Text(
            'Req. ${_numero(requerido)} / Aporta ${_numero(aportado)} kg',
            textAlign: TextAlign.end,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _OtrosFertilizantesSugeridosCard extends StatelessWidget {
  const _OtrosFertilizantesSugeridosCard({
    required this.fertilizantes,
  });

  final List<FertilizanteSugerido> fertilizantes;

  @override
  Widget build(BuildContext context) {
    if (fertilizantes.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Otros productos calculados',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          ...fertilizantes.map(
            (fertilizante) => Padding(
              padding: const EdgeInsets.only(bottom: 7),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      fertilizante.nombre,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w800,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    '${_numero(fertilizante.kgPorSemana)} kg/semana',
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w900,
                      color: AppColores.primario,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}


class _DiagnosticoGeneralNpkCard extends StatelessWidget {
  const _DiagnosticoGeneralNpkCard({
    required this.plan,
  });

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(
                  Icons.analytics_rounded,
                  color: AppColores.primario,
                ),
                SizedBox(width: 10),
                Expanded(
                  child: Text(
                    'Balance nutricional estimado',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 6),
            const Text(
              'Compara la cantidad estimada en el suelo con el requerimiento elemental de referencia de la nueva base de cálculo.',
              style: TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
            const SizedBox(height: 14),
            _FilaDiagnosticoNpk(
              simbolo: 'N',
              nombre: 'Nitrógeno',
              nutriente: plan.nitrogeno,
            ),
            const SizedBox(height: 10),
            _FilaDiagnosticoNpk(
              simbolo: 'P',
              nombre: 'Fósforo',
              nutriente: plan.fosforo,
            ),
            const SizedBox(height: 10),
            _FilaDiagnosticoNpk(
              simbolo: 'K',
              nombre: 'Potasio',
              nutriente: plan.potasio,
            ),
          ],
        ),
      ),
    );
  }
}

class _FilaDiagnosticoNpk extends StatelessWidget {
  const _FilaDiagnosticoNpk({
    required this.simbolo,
    required this.nombre,
    required this.nutriente,
  });

  final String simbolo;
  final String nombre;
  final NutrientePlanNpk nutriente;

  @override
  Widget build(BuildContext context) {
    final disponible = nutriente.kgHaDisponibleReal;
    final requerido = nutriente.requerimientoKgHa;
    final tieneDeficit = nutriente.faltanteKgHa > 0.001;

    final color =
        tieneDeficit ? AppColores.prioridadMedia : AppColores.primario;
    final estado = tieneDeficit ? 'Déficit' : 'Cubierto';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Row(
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: color.withOpacity(0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Center(
              child: Text(
                simbolo,
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  nombre,
                  style: const TextStyle(
                    fontSize: 12.2,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Disponible: ${_numero(disponible)} kg/ha',
                  style: const TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  'Referencia: ${_numero(requerido)} kg/ha',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 8),
          _EstadoBadge(
            texto: estado,
            color: color,
          ),
        ],
      ),
    );
  }
}

class _DetalleTecnicoExpansionCard extends ConsumerWidget {
  const _DetalleTecnicoExpansionCard({
    required this.plan,
  });

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fertilizantes =
        plan.fertilizantes.where((f) => f.kgPorSemana > 0).toList();

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: const BorderSide(
          color: AppColores.borde,
        ),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 16),
        childrenPadding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
        leading: const Icon(
          Icons.functions_rounded,
          color: AppColores.primario,
        ),
        title: const Text(
          'Ver cálculo detallado',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),
        subtitle: const Text(
          'Fórmulas, disponibilidad y cobertura del plan.',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColores.textoSecundario,
          ),
        ),
        children: [
          _DisponibilidadTecnicaCard(plan: plan),
          const SizedBox(height: 12),
          _CoberturaTecnicaCard(resumen: plan.resumenCobertura),
          if (fertilizantes.isNotEmpty) ...[
            const SizedBox(height: 12),
            _FormulaFertilizanteCard(fertilizante: fertilizantes.first),
          ],
        ],
      ),
    );
  }
}

class _DisponibilidadTecnicaCard extends StatelessWidget {
  const _DisponibilidadTecnicaCard({
    required this.plan,
  });

  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        _NutrienteDetalleCompacto(nutriente: plan.nitrogeno),
        const SizedBox(height: 8),
        _NutrienteDetalleCompacto(nutriente: plan.fosforo),
        const SizedBox(height: 8),
        _NutrienteDetalleCompacto(nutriente: plan.potasio),
      ],
    );
  }
}

class _NutrienteDetalleCompacto extends StatelessWidget {
  const _NutrienteDetalleCompacto({
    required this.nutriente,
  });

  final NutrientePlanNpk nutriente;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            '${nutriente.nombre} (${nutriente.simbolo})',
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _DatoCompacto(
                titulo: 'Sensor',
                valor: '${_numero(nutriente.valorSensorMgKg)} mg/kg',
              ),
              _DatoCompacto(
                titulo: 'Disponible',
                valor: '${_numero(nutriente.kgHaDisponibleReal)} kg/ha',
              ),
              _DatoCompacto(
                titulo: 'Faltante',
                valor:
                    '${_numero(nutriente.faltanteKgHa > 0 ? nutriente.faltanteKgHa : 0)} kg/ha',
              ),
              _DatoCompacto(
                titulo: nutriente.nombreFormaComercial,
                valor:
                    '${_numero(nutriente.faltanteFormaComercialSemanaKg)} kg/semana',
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _CoberturaTecnicaCard extends StatelessWidget {
  const _CoberturaTecnicaCard({
    required this.resumen,
  });

  final ResumenCoberturaNpk resumen;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Cobertura del plan',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 8),
          _LineaCobertura(
            titulo: 'N',
            requerido: resumen.necesidadN,
            aportado: resumen.aporteN,
          ),
          _LineaCobertura(
            titulo: 'P₂O₅',
            requerido: resumen.necesidadP2O5,
            aportado: resumen.aporteP2O5,
          ),
          _LineaCobertura(
            titulo: 'K₂O',
            requerido: resumen.necesidadK2O,
            aportado: resumen.aporteK2O,
          ),
          if (resumen.costoTotal > 0) ...[
            const SizedBox(height: 8),
            Text(
              'Costo estimado semanal: \$${_numero(resumen.costoTotal)}',
              style: const TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _LineaCobertura extends StatelessWidget {
  const _LineaCobertura({
    required this.titulo,
    required this.requerido,
    required this.aportado,
  });

  final String titulo;
  final double requerido;
  final double aportado;

  @override
  Widget build(BuildContext context) {
    final diferencia = aportado - requerido;

    String estado;
    Color color;

    if (requerido <= 0 && aportado <= 0) {
      estado = 'No requiere';
      color = AppColores.primario;
    } else if (requerido <= 0 && aportado > 0) {
      estado = 'Aporte adicional ${_numero(aportado)} kg';
      color = AppColores.prioridadMedia;
    } else if (diferencia >= 0) {
      estado = diferencia <= 0.01
          ? 'Cubierto'
          : 'Exceso ${_numero(diferencia)} kg';
      color = diferencia <= 0.01
          ? AppColores.primario
          : AppColores.prioridadMedia;
    } else {
      estado = 'Falta ${_numero(diferencia.abs())} kg';
      color = AppColores.advertencia;
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 7),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 8),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: color.withOpacity(0.18),
        ),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  titulo,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
              ),
              Text(
                estado,
                style: TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w900,
                  color: color,
                ),
              ),
            ],
          ),
          const SizedBox(height: 3),
          Row(
            children: [
              Expanded(
                child: Text(
                  'Requerido: ${_numero(requerido)} kg',
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ),
              Text(
                'Aportado: ${_numero(aportado)} kg',
                style: const TextStyle(
                  fontSize: 11.5,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoSecundario,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _FormulaFertilizanteCard extends StatelessWidget {
  const _FormulaFertilizanteCard({
    required this.fertilizante,
  });

  final FertilizanteSugerido fertilizante;

  @override
  Widget build(BuildContext context) {
    final concentracionObjetivo = _concentracionObjetivo(fertilizante);
    final faltanteObjetivo = _faltanteObjetivo(fertilizante);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Fórmula del asesor',
            style: TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'kg fertilizante = kg faltante semanal ÷ concentración del nutriente',
            style: TextStyle(
              fontSize: 12,
              height: 1.35,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            '${_numero(faltanteObjetivo)} kg ÷ ${_numero(concentracionObjetivo / 100)} = ${_numero(fertilizante.kgPorSemana)} kg/semana',
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w900,
              color: AppColores.primario,
            ),
          ),
        ],
      ),
    );
  }

  double _concentracionObjetivo(FertilizanteSugerido fertilizante) {
    switch (fertilizante.nutrienteObjetivo) {
      case 'N':
        return fertilizante.concentracionN;
      case 'P₂O₅':
        return fertilizante.concentracionP2O5;
      case 'K₂O':
        return fertilizante.concentracionK2O;
      default:
        return fertilizante.concentracionP2O5;
    }
  }

  double _faltanteObjetivo(FertilizanteSugerido fertilizante) {
    switch (fertilizante.nutrienteObjetivo) {
      case 'N':
        return fertilizante.nAntes;
      case 'P₂O₅':
        return fertilizante.p2o5Antes;
      case 'K₂O':
        return fertilizante.k2oAntes;
      default:
        return fertilizante.p2o5Antes;
    }
  }
}

class AccesoConfiguracionCultivoCard extends StatelessWidget {
  const AccesoConfiguracionCultivoCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _AccesoCard(
      icono: Icons.tune_rounded,
      titulo: 'Editar configuración del cultivo',
      subtitulo: 'Etapa, área, plantas, raíz, semanas y eficiencias.',
      onTap: () {
        context.push(RutasApp.configuracionPlanNutricional);
      },
    );
  }
}

class AccesoFertilizantesDisponiblesCard extends StatelessWidget {
  const AccesoFertilizantesDisponiblesCard({super.key});

  @override
  Widget build(BuildContext context) {
    return _AccesoCard(
      icono: Icons.inventory_2_rounded,
      titulo: 'Fertilizantes disponibles',
      subtitulo: 'Selecciona productos y define el cálculo personalizado.',
      onTap: () {
        context.push(RutasApp.fertilizantesDisponibles);
      },
    );
  }
}

class _AccesoCard extends StatelessWidget {
  const _AccesoCard({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.onTap,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.primariosuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColores.primario.withOpacity(0.22),
        ),
      ),
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            children: [
              Icon(
                icono,
                color: AppColores.primario,
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      subtitulo,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.3,
                        fontWeight: FontWeight.w600,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.chevron_right_rounded,
                color: AppColores.primario,
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _DatoCompacto extends StatelessWidget {
  const _DatoCompacto({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 138,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: AppColores.borde,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 12.5,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({
    required this.texto,
    required this.color,
  });

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 6,
      ),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: color.withOpacity(0.24),
        ),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 11,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _NotaTecnicaCard extends StatelessWidget {
  const _NotaTecnicaCard({
    required this.texto,
  });

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.advertenciasuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(
          color: AppColores.advertencia.withOpacity(0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.info_outline_rounded,
              color: AppColores.advertencia,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                texto,
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.4,
                  fontWeight: FontWeight.w600,
                  color: AppColores.textoSecundario,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorPlan extends StatelessWidget {
  const _ErrorPlan({
    required this.mensaje,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Text(
          mensaje,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: AppColores.textoSecundario,
            height: 1.4,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}



String _numeroConcentracion(double valor) {
  if ((valor - valor.roundToDouble()).abs() < 0.000001) {
    return valor.round().toString();
  }

  final texto = valor.toStringAsFixed(2);
  return texto.replaceFirst(RegExp(r'0+$'), '').replaceFirst(RegExp(r'\.$'), '');
}

String _numero(double valor) {
  if (valor.abs() >= 1000000) {
    return valor.toStringAsFixed(0);
  }

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

double? _aDouble(String? valor) {
  if (valor == null) return null;
  final limpio = valor.trim().replaceAll(',', '.');
  if (limpio.isEmpty) return 0;
  return double.tryParse(limpio);
}
