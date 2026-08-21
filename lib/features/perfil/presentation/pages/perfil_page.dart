import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tema/app_colores.dart';
import '../../../lotes/domain/entities/lote_cultivo.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';
import '../../../sensores/data/datasource/sensor_usb_rs485_datasource.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import 'calculadora_nutricional_manual_page.dart';

class PerfilPage extends ConsumerWidget {
  const PerfilPage({super.key});

  static const String _nombreFinca = 'Finca Fresa';

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lotesAsync = ref.watch(lotesCultivoProvider);
    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _TituloPerfilCultivoHeader(),
            const SizedBox(height: 16),
            lotesAsync.when(
              data: (lotes) {
                final lotesActivos = lotes.where((lote) => lote.activo).toList();
                final lotesMostrar = lotesActivos.isEmpty
                    ? <LoteCultivo>[LoteCultivo.loteInicial()]
                    : lotesActivos;

                final totalPlantas = lotesMostrar.fold<int>(
                  0,
                  (total, lote) => total + lote.numeroPlantas,
                );
                final totalArea = lotesMostrar.fold<double>(
                  0,
                  (total, lote) => total + lote.areaM2,
                );

                return Column(
                  children: [
                    _TarjetaResumenFinca(
                      nombreFinca: _nombreFinca,
                      totalLotes: lotesMostrar.length,
                      totalPlantas: totalPlantas,
                      totalAreaM2: totalArea,
                    ),
                    const SizedBox(height: 14),
                    _TarjetaLotesFinca(
                      lotes: lotesMostrar,
                    ),
                    const SizedBox(height: 14),
                    const _TarjetaHerramientasPerfil(),
                  ],
                );
              },
              loading: () => const _TarjetaCargaPerfil(),
              error: (error, stackTrace) {
                return Column(
                  children: [
                    _TarjetaResumenFinca(
                      nombreFinca: _nombreFinca,
                      totalLotes: 1,
                      totalPlantas: 0,
                      totalAreaM2: 0,
                    ),
                    const SizedBox(height: 14),
                    _TarjetaErrorPerfil(
                      mensaje:
                          'No se pudieron cargar los lotes. Revisa la conexión o intenta de nuevo.',
                    ),
                    const SizedBox(height: 14),
                    const _TarjetaHerramientasPerfil(),
                  ],
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}


class _TituloPerfilCultivoHeader extends StatelessWidget {
  const _TituloPerfilCultivoHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
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
            Icons.account_tree_rounded,
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
                'Perfil de la finca',
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
                'Resumen general de la finca y sus lotes',
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


class _TarjetaResumenFinca extends StatelessWidget {
  const _TarjetaResumenFinca({
    required this.nombreFinca,
    required this.totalLotes,
    required this.totalPlantas,
    required this.totalAreaM2,
  });

  final String nombreFinca;
  final int totalLotes;
  final int totalPlantas;
  final double totalAreaM2;
  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(24),
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
                width: 46,
                height: 46,
                decoration: BoxDecoration(
                  color: AppColores.primariosuave,
                  borderRadius: BorderRadius.circular(16),
                ),
                child: const Icon(
                  Icons.agriculture_rounded,
                  color: AppColores.primario,
                  size: 25,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      nombreFinca,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      'Cultivo de fresa',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: _ResumenNumeroCard(
                  titulo: 'Lotes',
                  valor: totalLotes.toString(),
                  icono: Icons.grid_view_rounded,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _ResumenNumeroCard(
                  titulo: 'Plantas',
                  valor: totalPlantas > 0 ? _entero(totalPlantas) : 'Sin definir',
                  icono: Icons.spa_rounded,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          _ResumenNumeroCard(
            titulo: 'Área total',
            valor: totalAreaM2 > 0 ? '${_numero(totalAreaM2)} m²' : 'Sin definir',
            icono: Icons.square_foot_rounded,
            anchoCompleto: true,
          ),
        ],
      ),
    );
  }
}

class _ResumenNumeroCard extends StatelessWidget {
  const _ResumenNumeroCard({
    required this.titulo,
    required this.valor,
    required this.icono,
    this.anchoCompleto = false,
  });

  final String titulo;
  final String valor;
  final IconData icono;
  final bool anchoCompleto;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: anchoCompleto ? double.infinity : null,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
        children: [
          Container(
            width: 30,
            height: 30,
            decoration: BoxDecoration(
              color: AppColores.primariosuave,
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(
              icono,
              color: AppColores.primario,
              size: 17,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.5,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
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


class _TarjetaLotesFinca extends StatelessWidget {
  const _TarjetaLotesFinca({
    required this.lotes,
  });

  final List<LoteCultivo> lotes;

  @override
  Widget build(BuildContext context) {
    return _TarjetaPerfilSimple(
      icono: Icons.view_list_rounded,
      titulo: 'Lotes registrados',
      subtitulo: 'Etapa, tiempo aproximado, plantas y área por lote.',
      child: Column(
        children: [
          for (var i = 0; i < lotes.length; i++) ...[
            _FilaLoteResumen(lote: lotes[i]),
            if (i != lotes.length - 1) const _SeparadorSuave(),
          ],
        ],
      ),
    );
  }
}

class _FilaLoteResumen extends StatelessWidget {
  const _FilaLoteResumen({
    required this.lote,
  });

  final LoteCultivo lote;

  @override
  Widget build(BuildContext context) {
    final plantas = lote.numeroPlantas > 0
        ? '${_entero(lote.numeroPlantas)} plantas'
        : 'Plantas sin definir';
    final area = lote.areaM2 > 0 ? '${_numero(lote.areaM2)} m²' : 'Área sin definir';
    final etapa = lote.etapa.trim().isEmpty ? 'Etapa sin definir' : lote.etapa.trim();
    final tiempoEtapa = _tiempoEtapa(etapa);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: Row(
        children: [
          Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColores.primariosuave.withOpacity(0.85),
              borderRadius: BorderRadius.circular(14),
            ),
            child: const Icon(
              Icons.grass_rounded,
              color: AppColores.primario,
              size: 21,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  lote.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  lote.cultivo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 6),
                Wrap(
                  spacing: 6,
                  runSpacing: 5,
                  children: [
                    _MiniEtiquetaLote(
                      texto: 'Etapa: $etapa',
                      icono: Icons.local_florist_rounded,
                    ),
                    _MiniEtiquetaLote(
                      texto: 'Tiempo: $tiempoEtapa',
                      icono: Icons.schedule_rounded,
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(
                plantas,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                area,
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 11.2,
                  fontWeight: FontWeight.w700,
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


class _MiniEtiquetaLote extends StatelessWidget {
  const _MiniEtiquetaLote({
    required this.texto,
    required this.icono,
  });

  final String texto;
  final IconData icono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.55),
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
            size: 12,
            color: AppColores.primario,
          ),
          const SizedBox(width: 4),
          Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.2,
              fontWeight: FontWeight.w800,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}


class _TarjetaResumenNutricionalSimple extends StatelessWidget {
  const _TarjetaResumenNutricionalSimple({
    required this.n,
    required this.p,
    required this.k,
  });

  final double n;
  final double p;
  final double k;

  @override
  Widget build(BuildContext context) {
    return _TarjetaPerfilSimple(
      icono: Icons.science_rounded,
      titulo: 'Plan nutricional',
      subtitulo: 'Requerimientos generales usados para el cálculo.',
      child: Row(
        children: [
          Expanded(
            child: _NutrienteResumen(
              letra: 'N',
              nombre: 'Nitrógeno',
              valor: '${_numero(n)} kg/ha',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NutrienteResumen(
              letra: 'P',
              nombre: 'Fósforo',
              valor: '${_numero(p)} kg/ha',
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: _NutrienteResumen(
              letra: 'K',
              nombre: 'Potasio',
              valor: '${_numero(k)} kg/ha',
            ),
          ),
        ],
      ),
    );
  }
}

class _NutrienteResumen extends StatelessWidget {
  const _NutrienteResumen({
    required this.letra,
    required this.nombre,
    required this.valor,
  });

  final String letra;
  final String nombre;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        children: [
          Text(
            letra,
            style: const TextStyle(
              fontSize: 22,
              height: 1,
              fontWeight: FontWeight.w900,
              color: AppColores.primario,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            nombre,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 5),
          Text(
            valor,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
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


class _TarjetaHerramientasPerfil extends ConsumerStatefulWidget {
  const _TarjetaHerramientasPerfil();

  @override
  ConsumerState<_TarjetaHerramientasPerfil> createState() =>
      _TarjetaHerramientasPerfilState();
}

class _TarjetaHerramientasPerfilState
    extends ConsumerState<_TarjetaHerramientasPerfil> {
  bool _abriendoMuestreo = false;

  @override
  Widget build(BuildContext context) {
    return _TarjetaPerfilSimple(
      icono: Icons.tune_rounded,
      titulo: 'Herramientas',
      subtitulo: 'Opciones de apoyo y respaldo.',
      child: Column(
        children: [
          Container(
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
                const Row(
                  children: [
                    Icon(
                      Icons.bolt_rounded,
                      size: 20,
                      color: AppColores.primario,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Muestreo rápido de respaldo',
                        style: TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 5),
                const Text(
                  'Permite tomar lecturas inmediatas de varias plantas y calcular '
                  'el promedio del lote si el modo estabilizado presenta problemas.',
                  style: TextStyle(
                    fontSize: 11.5,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 11),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _abriendoMuestreo ? null : _abrirMuestreoRapido,
                    icon: const Icon(Icons.flash_on_rounded, size: 19),
                    label: const Text(
                      'Iniciar muestreo rápido',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColores.primario,
                      side: BorderSide(
                        color: AppColores.primario.withOpacity(0.32),
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
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            height: 46,
            child: FilledButton.icon(
              onPressed: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => const CalculadoraNutricionalManualPage(),
                  ),
                );
              },
              icon: const Icon(Icons.calculate_rounded, size: 20),
              label: const Text(
                'Simular cálculo nutricional',
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
        ],
      ),
    );
  }

  Future<void> _abrirMuestreoRapido() async {
    setState(() => _abriendoMuestreo = true);

    try {
      final lote = ref.read(loteSeleccionadoProvider);

      await showModalBottomSheet<void>(
        context: context,
        isScrollControlled: true,
        backgroundColor: Colors.transparent,
        builder: (_) => _ModalMuestreoRapidoRespaldo(
          lote: lote,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _abriendoMuestreo = false);
      }
    }
  }
}

class _ModalMuestreoRapidoRespaldo extends StatefulWidget {
  const _ModalMuestreoRapidoRespaldo({
    required this.lote,
  });

  final LoteCultivo lote;

  @override
  State<_ModalMuestreoRapidoRespaldo> createState() =>
      _ModalMuestreoRapidoRespaldoState();
}

class _ModalMuestreoRapidoRespaldoState
    extends State<_ModalMuestreoRapidoRespaldo> {
  final SensorUsbRs485Datasource _datasource = SensorUsbRs485Datasource();
  final List<DatosSensorSuelo> _muestras = <DatosSensorSuelo>[];

  DatosSensorSuelo? _lecturaActual;
  bool _leyendo = false;
  bool _guardandoPromedio = false;
  String? _mensaje;

  @override
  Widget build(BuildContext context) {
    final promedio =
        _muestras.isEmpty ? null : _calcularPromedioRespaldo(_muestras);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.90,
        ),
        decoration: const BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.vertical(
            top: Radius.circular(28),
          ),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Center(
                child: Container(
                  width: 44,
                  height: 5,
                  decoration: BoxDecoration(
                    color: AppColores.borde,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
              const SizedBox(height: 15),
              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Muestreo rápido de respaldo',
                      style: TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: _guardandoPromedio
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),
              Text(
                '${widget.lote.nombre} · ${_muestras.length} planta${_muestras.length == 1 ? '' : 's'} guardada${_muestras.length == 1 ? '' : 's'}',
                style: const TextStyle(
                  fontSize: 11.8,
                  fontWeight: FontWeight.w700,
                  color: AppColores.textoSecundario,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(11),
                decoration: BoxDecoration(
                  color: AppColores.advertenciasuave.withOpacity(0.50),
                  borderRadius: BorderRadius.circular(15),
                  border: Border.all(
                    color: AppColores.advertencia.withOpacity(0.18),
                  ),
                ),
                child: const Text(
                  'Modo de respaldo: cada planta usa una sola lectura directa. '
                  'Al finalizar, “Mostrar promedio” guarda el promedio del lote '
                  'como lectura principal de respaldo.',
                  style: TextStyle(
                    fontSize: 11.2,
                    height: 1.35,
                    fontWeight: FontWeight.w600,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ),
              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                height: 46,
                child: FilledButton.icon(
                  onPressed: _leyendo ? null : _leerPlanta,
                  icon: _leyendo
                      ? const SizedBox(
                          width: 17,
                          height: 17,
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: Colors.white,
                          ),
                        )
                      : const Icon(Icons.usb_rounded),
                  label: Text(
                    _leyendo
                        ? 'Leyendo planta...'
                        : 'Leer planta ${_muestras.length + 1}',
                    style: const TextStyle(fontWeight: FontWeight.w900),
                  ),
                ),
              ),

              if (_mensaje != null) ...[
                const SizedBox(height: 10),
                Text(
                  _mensaje!,
                  style: const TextStyle(
                    fontSize: 11.5,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ],

              if (_lecturaActual != null) ...[
                const SizedBox(height: 14),
                _TarjetaLecturaRapida(
                  titulo: 'Lectura actual',
                  lectura: _lecturaActual!,
                ),
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 44,
                  child: OutlinedButton.icon(
                    onPressed: _guardarPlantaActual,
                    icon: const Icon(Icons.add_circle_outline_rounded),
                    label: const Text(
                      'Guardar planta en el muestreo',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ],

              if (_muestras.isNotEmpty) ...[
                const SizedBox(height: 16),
                _TarjetaConteoMuestras(
                  cantidad: _muestras.length,
                ),
                const SizedBox(height: 10),
                if (promedio != null)
                  _TarjetaLecturaRapida(
                    titulo: 'Promedio actual',
                    lectura: promedio,
                    esPromedio: true,
                  ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: OutlinedButton.icon(
                        onPressed: _guardandoPromedio ? null : _limpiarMuestras,
                        icon: const Icon(Icons.delete_sweep_outlined),
                        label: const Text('Limpiar'),
                      ),
                    ),
                    const SizedBox(width: 9),
                    Expanded(
                      flex: 2,
                      child: FilledButton.icon(
                        onPressed:
                            _guardandoPromedio ? null : _mostrarPromedio,
                        icon: _guardandoPromedio
                            ? const SizedBox(
                                width: 16,
                                height: 16,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.analytics_rounded),
                        label: Text(
                          _guardandoPromedio
                              ? 'Guardando...'
                              : 'Mostrar promedio',
                          style: const TextStyle(
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leerPlanta() async {
    setState(() {
      _leyendo = true;
      _mensaje = null;
      _lecturaActual = null;
    });

    try {
      final lectura = await _datasource.leerSensorInmediato();

      if (!mounted) return;

      setState(() {
        _lecturaActual = lectura;
        _mensaje =
            'Lectura recibida. Revisa los valores y guárdala como planta si son coherentes.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _mensaje =
            error.toString().replaceFirst('Exception: ', '').trim();
      });
    } finally {
      if (mounted) {
        setState(() => _leyendo = false);
      }
    }
  }

  void _guardarPlantaActual() {
    final lectura = _lecturaActual;
    if (lectura == null) return;

    setState(() {
      _muestras.add(lectura);
      _lecturaActual = null;
      _mensaje = 'Planta ${_muestras.length} agregada al muestreo.';
    });
  }

  void _limpiarMuestras() {
    setState(() {
      _muestras.clear();
      _lecturaActual = null;
      _mensaje = 'Muestreo reiniciado.';
    });
  }

  Future<void> _mostrarPromedio() async {
    if (_muestras.isEmpty || _guardandoPromedio) return;

    setState(() => _guardandoPromedio = true);

    final promedio = _calcularPromedioRespaldo(_muestras);

    try {
      await _guardarMuestreoRespaldoEnFirestore(
        lote: widget.lote,
        muestras: _muestras,
        promedio: promedio,
      );

      if (!mounted) return;

      await showDialog<void>(
        context: context,
        builder: (context) {
          return AlertDialog(
            icon: const Icon(
              Icons.analytics_rounded,
              color: AppColores.primario,
              size: 31,
            ),
            title: const Text(
              'Promedio del lote',
              textAlign: TextAlign.center,
            ),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    'Promedio de ${_muestras.length} planta${_muestras.length == 1 ? '' : 's'}. '
                    'Se guardó como lectura principal de respaldo.',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 11.7,
                      height: 1.35,
                      fontWeight: FontWeight.w700,
                      color: AppColores.textoSecundario,
                    ),
                  ),
                  const SizedBox(height: 12),
                  _TarjetaLecturaRapida(
                    titulo: 'Resultado',
                    lectura: promedio,
                    esPromedio: true,
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Al volver a Inicio, este promedio podrá aparecer como la '
                    'última lectura del lote seleccionado.',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.35,
                      color: AppColores.textoSecundario,
                    ),
                  ),
                ],
              ),
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

      if (!mounted) return;
      Navigator.of(context).pop();
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _mensaje =
            'El promedio se calculó, pero no se pudo guardar: '
            '${error.toString().replaceFirst('Exception: ', '')}';
      });
    } finally {
      if (mounted) {
        setState(() => _guardandoPromedio = false);
      }
    }
  }

  Future<void> _guardarMuestreoRespaldoEnFirestore({
    required LoteCultivo lote,
    required List<DatosSensorSuelo> muestras,
    required DatosSensorSuelo promedio,
  }) async {
    final ahora = promedio.fechaLectura;
    final idBase =
        ahora.toUtc().toIso8601String().replaceAll(':', '-');
    final docId = 'respaldo_promedio_$idBase';

    final loteRef = FirebaseFirestore.instance
        .collection('usuarios')
        .doc('jdh2010')
        .collection('fincas')
        .doc('finca_esperanza')
        .collection('lotes')
        .doc(lote.id);

    final datosPromedio = <String, dynamic>{
      'usuarioId': 'jdh2010',
      'fincaId': 'finca_esperanza',
      'loteId': lote.id,
      'nombreLote': lote.nombre,
      'sensorId': 'sensor_usb_rs485_7en1',
      'cultivo': lote.cultivo,
      'etapa': lote.etapa,
      'tipo': 'promedio_muestreo_respaldo',
      'origen': 'usb_rs485_respaldo_promedio',
      'cantidadPlantas': muestras.length,
      'esLecturaEstabilizada': false,
      'esLecturaValida': true,
      'humedadSuelo': promedio.humedadSuelo,
      'temperaturaSuelo': promedio.temperaturaSuelo,
      'conductividadElectrica': promedio.conductividadElectrica,
      'phSuelo': promedio.phSuelo,
      'nitrogeno': promedio.nitrogeno,
      'fosforo': promedio.fosforo,
      'potasio': promedio.potasio,
      'fechaLectura': Timestamp.fromDate(ahora),
      'creadoEn': FieldValue.serverTimestamp(),
    };

    // Esta es la lectura que verá el resto de la app como última lectura del lote.
    await loteRef.collection('lecturas').doc(docId).set(datosPromedio);

    // Guarda también el muestreo completo como respaldo/auditoría.
    final muestreoRef =
        loteRef.collection('muestreos_respaldo').doc(docId);

    await muestreoRef.set({
      ...datosPromedio,
      'lecturaId': docId,
    });

    for (var i = 0; i < muestras.length; i++) {
      final muestra = muestras[i];

      await muestreoRef
          .collection('muestras')
          .doc('planta_${(i + 1).toString().padLeft(3, '0')}')
          .set({
        'numeroPlanta': i + 1,
        'humedadSuelo': muestra.humedadSuelo,
        'temperaturaSuelo': muestra.temperaturaSuelo,
        'conductividadElectrica': muestra.conductividadElectrica,
        'phSuelo': muestra.phSuelo,
        'nitrogeno': muestra.nitrogeno,
        'fosforo': muestra.fosforo,
        'potasio': muestra.potasio,
        'fechaLectura': Timestamp.fromDate(muestra.fechaLectura),
        'tipo': 'muestra_individual_respaldo',
        'origen': 'usb_rs485_lectura_rapida',
      });
    }

    // Mantiene compatibilidad con el esquema de muestreos que ya usa Mediciones.
    await loteRef.collection('muestreos').doc(docId).set({
      ...datosPromedio,
      'lecturaId': docId,
    });
  }
}

class _TarjetaConteoMuestras extends StatelessWidget {
  const _TarjetaConteoMuestras({
    required this.cantidad,
  });

  final int cantidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.55),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.14),
        ),
      ),
      child: Row(
        children: [
          const Icon(
            Icons.grass_rounded,
            color: AppColores.primario,
            size: 20,
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Text(
              '$cantidad planta${cantidad == 1 ? '' : 's'} incluida${cantidad == 1 ? '' : 's'} en el promedio',
              style: const TextStyle(
                fontSize: 12,
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

class _TarjetaLecturaRapida extends StatelessWidget {
  const _TarjetaLecturaRapida({
    required this.titulo,
    required this.lectura,
    this.esPromedio = false,
  });

  final String titulo;
  final DatosSensorSuelo lectura;
  final bool esPromedio;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: esPromedio
            ? AppColores.primariosuave.withOpacity(0.45)
            : AppColores.fondo,
        borderRadius: BorderRadius.circular(17),
        border: Border.all(
          color: esPromedio
              ? AppColores.primario.withOpacity(0.18)
              : AppColores.borde,
        ),
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
          const SizedBox(height: 8),
          _FilaLecturaRapida(
            titulo: 'Humedad',
            valor: '${_numero(lectura.humedadSuelo)} %',
          ),
          _FilaLecturaRapida(
            titulo: 'Temperatura',
            valor: '${_numero(lectura.temperaturaSuelo)} °C',
          ),
          _FilaLecturaRapida(
            titulo: 'pH',
            valor: _numero(lectura.phSuelo),
          ),
          _FilaLecturaRapida(
            titulo: 'EC',
            valor: '${_numero(lectura.conductividadElectrica)} dS/m',
          ),
          _FilaLecturaRapida(
            titulo: 'N',
            valor: '${_numero(lectura.nitrogeno)} mg/kg',
          ),
          _FilaLecturaRapida(
            titulo: 'P',
            valor: '${_numero(lectura.fosforo)} mg/kg',
          ),
          _FilaLecturaRapida(
            titulo: 'K',
            valor: '${_numero(lectura.potasio)} mg/kg',
          ),
        ],
      ),
    );
  }
}

class _FilaLecturaRapida extends StatelessWidget {
  const _FilaLecturaRapida({
    required this.titulo,
    required this.valor,
  });

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.5),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 11.8,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
          const SizedBox(width: 10),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12.2,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

DatosSensorSuelo _calcularPromedioRespaldo(
  List<DatosSensorSuelo> muestras,
) {
  double humedad = 0;
  double temperatura = 0;
  double ec = 0;
  double ph = 0;
  double n = 0;
  double p = 0;
  double k = 0;

  for (final muestra in muestras) {
    humedad += muestra.humedadSuelo;
    temperatura += muestra.temperaturaSuelo;
    ec += muestra.conductividadElectrica;
    ph += muestra.phSuelo;
    n += muestra.nitrogeno;
    p += muestra.fosforo;
    k += muestra.potasio;
  }

  final total = muestras.length.toDouble();

  return DatosSensorSuelo(
    humedadSuelo: humedad / total,
    temperaturaSuelo: temperatura / total,
    conductividadElectrica: ec / total,
    phSuelo: ph / total,
    nitrogeno: n / total,
    fosforo: p / total,
    potasio: k / total,
    fechaLectura: DateTime.now(),
  );
}


class _TarjetaCargaPerfil extends StatelessWidget {
  const _TarjetaCargaPerfil();

  @override
  Widget build(BuildContext context) {
    return _TarjetaPerfilSimple(
      icono: Icons.hourglass_top_rounded,
      titulo: 'Cargando perfil',
      subtitulo: 'Consultando la información de la finca.',
      child: const LinearProgressIndicator(),
    );
  }
}

class _TarjetaErrorPerfil extends StatelessWidget {
  const _TarjetaErrorPerfil({
    required this.mensaje,
  });

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return _TarjetaPerfilSimple(
      icono: Icons.warning_amber_rounded,
      titulo: 'Información no disponible',
      subtitulo: 'No se pudo completar el resumen.',
      child: Text(
        mensaje,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w600,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }
}


class _TarjetaPerfilSimple extends StatelessWidget {
  const _TarjetaPerfilSimple({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColores.borde,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.032),
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
                  color: AppColores.primariosuave.withOpacity(0.9),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.10),
                  ),
                ),
                child: Icon(
                  icono,
                  color: AppColores.primario,
                  size: 21,
                ),
              ),
              const SizedBox(width: 11),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      titulo,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 15.5,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      subtitulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 11.5,
                        height: 1.25,
                        fontWeight: FontWeight.w600,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          child,
        ],
      ),
    );
  }
}

class _SeparadorSuave extends StatelessWidget {
  const _SeparadorSuave();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      color: AppColores.borde,
    );
  }
}


String _tiempoEtapa(String etapa) {
  final texto = etapa.toLowerCase().trim();

  if (texto.contains('desarrollo') || texto.contains('vegetativo')) {
    return '1 a 6 meses';
  }

  if (texto.contains('alta') ||
      texto.contains('produccion') ||
      texto.contains('producción') ||
      texto.contains('fructificacion') ||
      texto.contains('fructificación')) {
    return '7 a 15 meses';
  }

  if (texto.contains('mantenimiento')) {
    return '16 a 24 meses';
  }

  return 'Tiempo sin definir';
}

String _numero(double valor) {
  if (valor == valor.roundToDouble()) {
    return valor.toStringAsFixed(0);
  }

  if (valor.abs() >= 10) {
    return valor.toStringAsFixed(1);
  }

  return valor.toStringAsFixed(2);
}

String _entero(int valor) {
  return valor.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}
