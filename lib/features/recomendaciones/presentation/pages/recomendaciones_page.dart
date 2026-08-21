import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tema/app_colores.dart';
import '../../domain/entities/recomendacion.dart';
import '../providers/recomendaciones_provider.dart';
import '../../../lotes/domain/entities/lote_cultivo.dart';
import '../../../lotes/presentation/pages/lotes_page.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';

class RecomendacionesPage extends ConsumerStatefulWidget {
  const RecomendacionesPage({super.key});

  @override
  ConsumerState<RecomendacionesPage> createState() =>
      _RecomendacionesPageState();
}

class _RecomendacionesPageState extends ConsumerState<RecomendacionesPage> {
  _FiltroRecomendacion? _filtro;

  @override
  Widget build(BuildContext context) {
    final recomendacionesAsync = ref.watch(recomendacionesAsyncProvider);
    final lecturaBaseAsync = ref.watch(lecturaBaseRecomendacionesProvider);
    final loteSeleccionado = ref.watch(loteSeleccionadoProvider);

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: recomendacionesAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (error, _) => _ErrorView(mensaje: error.toString()),
          data: (recomendaciones) {
            final recomendacionesOrdenadas = [...recomendaciones]
              ..sort((a, b) => a.prioridad.compareTo(b.prioridad));

            if (recomendacionesOrdenadas.isEmpty) {
              final sinLecturaLote = lecturaBaseAsync.valueOrNull == null;

              return ListView(
                padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
                children: [
                  const _TituloRecomendacionesHeader(),
                  const SizedBox(height: 14),
                  _LoteRecomendacionesCard(
                    lote: loteSeleccionado,
                    onCambiarLote: _cambiarLote,
                  ),
                  const SizedBox(height: 16),
                  if (sinLecturaLote)
                    _SinLecturasLoteView(loteNombre: loteSeleccionado.nombre)
                  else
                    const _SinRecomendacionesView(),
                ],
              );
            }

            final recomendacionesFiltradas = _filtro == null
                ? <Recomendacion>[]
                : _filtrarRecomendaciones(recomendacionesOrdenadas);

            return ListView(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
              children: [
                const _TituloRecomendacionesHeader(),
                const SizedBox(height: 14),

                _LoteRecomendacionesCard(
                  lote: loteSeleccionado,
                  onCambiarLote: _cambiarLote,
                ),

                const SizedBox(height: 14),

                _VariablesConRecomendacionesCard(
                  recomendaciones: recomendacionesOrdenadas,
                ),

                const SizedBox(height: 14),

                _SelectorPrioridad(
                  recomendaciones: recomendacionesOrdenadas,
                  filtroActual: _filtro,
                  onChanged: (nuevoFiltro) {
                    setState(() {
                      _filtro = nuevoFiltro;
                    });
                  },
                ),

                const SizedBox(height: 16),

                if (_filtro == null)
                  const _SeleccionaFiltroCard()
                else ...[
                  _EncabezadoLista(
                    titulo: _tituloFiltro(),
                    descripcion: _descripcionFiltro(recomendacionesFiltradas.length),
                  ),
                  const SizedBox(height: 10),
                  if (recomendacionesFiltradas.isEmpty)
                    const _SinResultadosFiltro()
                  else
                    ...recomendacionesFiltradas.map(
                      (recomendacion) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _RecomendacionListaItem(
                          recomendacion: recomendacion,
                        ),
                      ),
                    ),
                ],
              ],
            );
          },
        ),
      ),
    );
  }


  Future<void> _cambiarLote() async {
    final lote = await Navigator.of(context).push<LoteCultivo>(
      MaterialPageRoute(
        builder: (_) => const LotesPage(),
      ),
    );

    if (lote == null) return;

    ref.read(loteSeleccionadoIdProvider.notifier).state = lote.id;
    setState(() {
      _filtro = null;
    });
  }

  List<Recomendacion> _filtrarRecomendaciones(
    List<Recomendacion> recomendaciones,
  ) {
    final filtro = _filtro;
    if (filtro == null) return <Recomendacion>[];

    switch (filtro) {
      case _FiltroRecomendacion.criticas:
        return recomendaciones.where((r) => r.prioridad == 1).toList();
      case _FiltroRecomendacion.medias:
        return recomendaciones.where((r) => r.prioridad == 2).toList();
      case _FiltroRecomendacion.bajas:
        return recomendaciones.where((r) => r.prioridad == 3).toList();
    }
  }

  String _tituloFiltro() {
    final filtro = _filtro;
    if (filtro == null) return 'Selecciona una prioridad';

    switch (filtro) {
      case _FiltroRecomendacion.criticas:
        return 'Recomendaciones críticas';
      case _FiltroRecomendacion.medias:
        return 'Recomendaciones medias';
      case _FiltroRecomendacion.bajas:
        return 'Recomendaciones bajas';
    }
  }

  String _descripcionFiltro(int total) {
    final cantidad = '$total recomendación${total == 1 ? '' : 'es'}';
    final filtro = _filtro;

    if (filtro == null) {
      return 'Toca una prioridad para ver las recomendaciones.';
    }

    switch (filtro) {
      case _FiltroRecomendacion.criticas:
        return '$cantidad que debe${total == 1 ? '' : 'n'} atenderse primero.';
      case _FiltroRecomendacion.medias:
        return '$cantidad para revisar y dar seguimiento.';
      case _FiltroRecomendacion.bajas:
        return '$cantidad preventiva${total == 1 ? '' : 's'}.';
    }
  }

}

class _TituloRecomendacionesHeader extends StatelessWidget {
  const _TituloRecomendacionesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColores.primario.withOpacity(0.14),
            ),
          ),
          child: const Icon(
            Icons.recommend_rounded,
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
                'Recomendaciones',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: AppColores.textoPrincipal,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Qué revisar y qué hacer primero',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 12.2,
                  fontWeight: FontWeight.w700,
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


class _LoteRecomendacionesCard extends StatelessWidget {
  const _LoteRecomendacionesCard({
    required this.lote,
    required this.onCambiarLote,
  });

  final LoteCultivo lote;
  final VoidCallback onCambiarLote;

  @override
  Widget build(BuildContext context) {
    final plantasTexto = lote.numeroPlantas > 0
        ? '${lote.numeroPlantas} plantas'
        : 'Plantas sin definir';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 10, 10, 10),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
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
            child: const Icon(
              Icons.grass_rounded,
              color: AppColores.primario,
              size: 20,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Recomendaciones del lote',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    fontSize: 11.2,
                    fontWeight: FontWeight.w800,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  children: [
                    Flexible(
                      child: Text(
                        lote.nombre,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 14.3,
                          height: 1.1,
                          fontWeight: FontWeight.w900,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: AppColores.primariosuave.withOpacity(0.75),
                        borderRadius: BorderRadius.circular(999),
                      ),
                      child: Text(
                        plantasTexto,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 10,
                          height: 1,
                          fontWeight: FontWeight.w900,
                          color: AppColores.primario,
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          TextButton(
            onPressed: onCambiarLote,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              foregroundColor: AppColores.primario,
            ),
            child: const Text(
              'Cambiar',
              style: TextStyle(
                fontSize: 11.5,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SinLecturasLoteView extends StatelessWidget {
  const _SinLecturasLoteView({required this.loteNombre});

  final String loteNombre;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 26, 22, 26),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: AppColores.advertenciasuave,
                borderRadius: BorderRadius.circular(22),
                border: Border.all(
                  color: AppColores.advertencia.withOpacity(0.16),
                ),
              ),
              child: const Icon(
                Icons.sensors_off_rounded,
                color: AppColores.advertencia,
                size: 36,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'No hay lecturas para $loteNombre',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Lee el sensor o guarda un promedio de este lote para generar recomendaciones específicas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                height: 1.4,
                color: AppColores.textoSecundario,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}


class _ResumenAccionPrincipal extends StatelessWidget {
  const _ResumenAccionPrincipal({required this.recomendaciones});

  final List<Recomendacion> recomendaciones;

  @override
  Widget build(BuildContext context) {
    final principal = recomendaciones.first;
    final color = _colorPrioridad(principal.prioridad);
    final icono = _iconoPrioridad(principal.prioridad);
    final accion = _textoLimpio(principal.accionSugerida).isNotEmpty
        ? _textoLimpio(principal.accionSugerida)
        : _textoLimpio(principal.descripcion);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 48,
            height: 48,
            decoration: BoxDecoration(
              color: color.withOpacity(0.11),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Icon(icono, color: color, size: 26),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Primero revisa esto',
                  style: TextStyle(
                    fontSize: 16.5,
                    height: 1.15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  principal.titulo,
                  style: TextStyle(
                    fontSize: 12.7,
                    height: 1.25,
                    fontWeight: FontWeight.w900,
                    color: color,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  accion,
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.7,
                    height: 1.32,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
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


class _VariablesConRecomendacionesCard extends StatelessWidget {
  const _VariablesConRecomendacionesCard({
    required this.recomendaciones,
  });

  final List<Recomendacion> recomendaciones;

  @override
  Widget build(BuildContext context) {
    final variables = _agruparVariables(recomendaciones);

    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColores.borde),
      ),
      clipBehavior: Clip.antiAlias,
      child: Theme(
        data: Theme.of(context).copyWith(
          dividerColor: Colors.transparent,
          splashColor: Colors.transparent,
          highlightColor: Colors.transparent,
        ),
        child: ExpansionTile(
          initiallyExpanded: false,
          tilePadding: const EdgeInsets.fromLTRB(14, 10, 12, 10),
          childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
          iconColor: AppColores.primario,
          collapsedIconColor: AppColores.textoSecundario,
          leading: Container(
            width: 38,
            height: 38,
            decoration: BoxDecoration(
              color: AppColores.primariosuave,
              borderRadius: BorderRadius.circular(13),
              border: Border.all(
                color: AppColores.primario.withOpacity(0.14),
              ),
            ),
            child: const Icon(
              Icons.checklist_rounded,
              color: AppColores.primario,
              size: 22,
            ),
          ),
          title: const Text(
            'Variables con recomendaciones',
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 16.2,
              height: 1.12,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          subtitle: Padding(
            padding: const EdgeInsets.only(top: 3),
            child: Text(
              variables.isEmpty
                  ? 'No hay variables pendientes por revisar'
                  : '${variables.length} variable${variables.length == 1 ? '' : 's'} para revisar. Toca para verlas.',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 12.1,
                height: 1.25,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
          children: [
            if (variables.isEmpty)
              const _VariablesVaciasCard()
            else ...[
              const SizedBox(height: 2),
              LayoutBuilder(
                builder: (context, constraints) {
                  const spacing = 8.0;
                  final anchoItem = (constraints.maxWidth - spacing) / 2;

                  return Wrap(
                    spacing: spacing,
                    runSpacing: 8,
                    children: variables
                        .map(
                          (variable) => SizedBox(
                            width: anchoItem,
                            child: _VariableResumenChip(variable: variable),
                          ),
                        )
                        .toList(),
                  );
                },
              ),
            ],
          ],
        ),
      ),
    );
  }

  List<_VariableResumenData> _agruparVariables(
    List<Recomendacion> recomendaciones,
  ) {
    final agrupadas = <String, List<Recomendacion>>{};

    for (final recomendacion in recomendaciones) {
      final variable = _nombreVariableCorto(recomendacion);
      agrupadas.putIfAbsent(variable, () => <Recomendacion>[]).add(recomendacion);
    }

    final variables = agrupadas.entries.map((entry) {
      final items = [...entry.value]
        ..sort((a, b) => a.prioridad.compareTo(b.prioridad));

      final principal = items.first;
      final prioridad = principal.prioridad;
      final color = _colorPrioridad(prioridad);

      return _VariableResumenData(
        nombre: entry.key,
        cantidad: items.length,
        prioridad: prioridad,
        color: color,
        icono: _iconoTipo(principal.tipo),
        valor: _textoLimpio(principal.valorActual),
        problemaPrincipal: principal.titulo,
      );
    }).toList();

    variables.sort((a, b) {
      final prioridad = a.prioridad.compareTo(b.prioridad);
      if (prioridad != 0) return prioridad;
      return a.nombre.toLowerCase().compareTo(b.nombre.toLowerCase());
    });

    return variables;
  }

  String _nombreVariableCorto(Recomendacion recomendacion) {
    final variable = _textoLimpio(recomendacion.variable);

    if (variable.isEmpty) {
      return 'General';
    }

    final limpia = variable
        .replaceAll('del suelo', '')
        .replaceAll('de suelo', '')
        .trim();

    if (limpia.contains('Nitrógeno')) return 'Nitrógeno';
    if (limpia.contains('Fósforo')) return 'Fósforo';
    if (limpia.contains('Potasio')) return 'Potasio';
    if (limpia.toLowerCase().contains('conductividad')) return 'EC';
    if (limpia.toLowerCase().contains('humedad')) return 'Humedad';
    if (limpia.toLowerCase().contains('temperatura')) return 'Temperatura';
    if (limpia.toLowerCase().contains('ph')) return 'pH';
    if (limpia.contains('+')) return limpia;

    return limpia;
  }
}

class _VariableResumenData {
  const _VariableResumenData({
    required this.nombre,
    required this.cantidad,
    required this.prioridad,
    required this.color,
    required this.icono,
    required this.valor,
    required this.problemaPrincipal,
  });

  final String nombre;
  final int cantidad;
  final int prioridad;
  final Color color;
  final IconData icono;
  final String valor;
  final String problemaPrincipal;
}

class _VariableResumenChip extends StatelessWidget {
  const _VariableResumenChip({
    required this.variable,
  });

  final _VariableResumenData variable;

  @override
  Widget build(BuildContext context) {
    final prioridad = _textoPrioridad(variable.prioridad);
    final cantidadTexto = '${variable.cantidad} rec.';
    final detalleInferior = variable.valor.isEmpty
        ? cantidadTexto
        : '${variable.valor}  •  $cantidadTexto';

    return Container(
      constraints: const BoxConstraints(minHeight: 82),
      padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
      decoration: BoxDecoration(
        color: variable.color.withOpacity(0.045),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: variable.color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Row(
            children: [
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: variable.color.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  variable.icono,
                  size: 18,
                  color: variable.color,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  variable.nombre,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 13.2,
                    height: 1.05,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            variable.problemaPrincipal,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11.1,
              height: 1.18,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              _VariableEstadoPill(
                texto: prioridad,
                color: variable.color,
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Text(
                  detalleInferior,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  textAlign: TextAlign.end,
                  style: const TextStyle(
                    fontSize: 10.7,
                    height: 1,
                    fontWeight: FontWeight.w800,
                    color: AppColores.textoSecundario,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _VariableEstadoPill extends StatelessWidget {
  const _VariableEstadoPill({
    required this.texto,
    required this.color,
  });

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 4),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 9.8,
          height: 1,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _VariablesVaciasCard extends StatelessWidget {
  const _VariablesVaciasCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColores.primariosuave.withOpacity(0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppColores.primario.withOpacity(0.12)),
      ),
      child: const Text(
        'No hay variables fuera de rango.',
        style: TextStyle(
          fontSize: 12.8,
          fontWeight: FontWeight.w800,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }
}


enum _FiltroRecomendacion {
  criticas,
  medias,
  bajas,
}

class _SelectorPrioridad extends StatelessWidget {
  const _SelectorPrioridad({
    required this.recomendaciones,
    required this.filtroActual,
    required this.onChanged,
  });

  final List<Recomendacion> recomendaciones;
  final _FiltroRecomendacion? filtroActual;
  final ValueChanged<_FiltroRecomendacion?> onChanged;

  @override
  Widget build(BuildContext context) {
    final criticas = recomendaciones.where((r) => r.prioridad == 1).length;
    final medias = recomendaciones.where((r) => r.prioridad == 2).length;
    final bajas = recomendaciones.where((r) => r.prioridad == 3).length;

    return Row(
      children: [
        Expanded(
          child: _PrioridadFiltroCard(
            cantidad: criticas,
            texto: 'Críticas',
            color: AppColores.prioridadAlta,
            seleccionado: filtroActual == _FiltroRecomendacion.criticas,
            onTap: () => onChanged(
              filtroActual == _FiltroRecomendacion.criticas
                  ? null
                  : _FiltroRecomendacion.criticas,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PrioridadFiltroCard(
            cantidad: medias,
            texto: 'Medias',
            color: AppColores.prioridadMedia,
            seleccionado: filtroActual == _FiltroRecomendacion.medias,
            onTap: () => onChanged(
              filtroActual == _FiltroRecomendacion.medias
                  ? null
                  : _FiltroRecomendacion.medias,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _PrioridadFiltroCard(
            cantidad: bajas,
            texto: 'Bajas',
            color: AppColores.prioridadBaja,
            seleccionado: filtroActual == _FiltroRecomendacion.bajas,
            onTap: () => onChanged(
              filtroActual == _FiltroRecomendacion.bajas
                  ? null
                  : _FiltroRecomendacion.bajas,
            ),
          ),
        ),
      ],
    );
  }
}

class _PrioridadFiltroCard extends StatelessWidget {
  const _PrioridadFiltroCard({
    required this.cantidad,
    required this.texto,
    required this.color,
    required this.seleccionado,
    required this.onTap,
  });

  final int cantidad;
  final String texto;
  final Color color;
  final bool seleccionado;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      borderRadius: BorderRadius.circular(16),
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 11),
        decoration: BoxDecoration(
          color: seleccionado ? color.withOpacity(0.13) : AppColores.superficie,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: seleccionado ? color.withOpacity(0.55) : color.withOpacity(0.16),
            width: seleccionado ? 1.4 : 1,
          ),
        ),
        child: Column(
          children: [
            Text(
              cantidad.toString(),
              style: TextStyle(
                fontSize: 19,
                height: 1,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
            const SizedBox(height: 5),
            Text(
              texto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 11.2,
                fontWeight: FontWeight.w900,
                color: color,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _EncabezadoLista extends StatelessWidget {
  const _EncabezadoLista({
    required this.titulo,
    required this.descripcion,
  });

  final String titulo;
  final String descripcion;

  @override
  Widget build(BuildContext context) {
    return Column(
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
        const SizedBox(height: 3),
        Text(
          descripcion,
          style: const TextStyle(
            fontSize: 12.5,
            height: 1.30,
            color: AppColores.textoSecundario,
            fontWeight: FontWeight.w700,
          ),
        ),
      ],
    );
  }
}

class _RecomendacionListaItem extends StatelessWidget {
  const _RecomendacionListaItem({required this.recomendacion});

  final Recomendacion recomendacion;

  @override
  Widget build(BuildContext context) {
    final color = _colorPrioridad(recomendacion.prioridad);
    final icono = _iconoTipo(recomendacion.tipo);
    final prioridad = _textoPrioridad(recomendacion.prioridad);
    final variable = _textoLimpio(recomendacion.variable);
    final valor = _textoLimpio(recomendacion.valorActual);
    final etiquetaIcono = _etiquetaCortaRecomendacion(recomendacion);

    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(18),
        onTap: () => _mostrarDetalleRecomendacion(context, recomendacion),
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: AppColores.superficie,
            borderRadius: BorderRadius.circular(18),
            border: Border.all(color: AppColores.borde),
          ),
          child: Row(
            children: [
              SizedBox(
                width: 52,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(icono, color: color, size: 22),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      etiquetaIcono,
                      textAlign: TextAlign.center,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(
                        fontSize: 10.2,
                        height: 1,
                        fontWeight: FontWeight.w900,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      recomendacion.titulo,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 14.7,
                        height: 1.18,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Wrap(
                      spacing: 7,
                      runSpacing: 6,
                      children: [
                        _DatoMiniChip(texto: prioridad, color: color),
                        if (variable.isNotEmpty)
                          _DatoMiniChip(texto: variable, color: color),
                        if (valor.isNotEmpty)
                          _DatoMiniChip(texto: valor, color: color),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.chevron_right_rounded,
                color: color,
                size: 24,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _PrioridadPill extends StatelessWidget {
  const _PrioridadPill({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.20)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          fontSize: 10.5,
          height: 1,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}

class _DatoMiniChip extends StatelessWidget {
  const _DatoMiniChip({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Text(
        texto,
        style: const TextStyle(
          fontSize: 11.3,
          height: 1,
          fontWeight: FontWeight.w800,
          color: AppColores.textoPrincipal,
        ),
      ),
    );
  }
}

void _mostrarDetalleRecomendacion(
  BuildContext context,
  Recomendacion recomendacion,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) => _DetalleRecomendacionSheet(recomendacion: recomendacion),
  );
}

class _DetalleRecomendacionSheet extends StatelessWidget {
  const _DetalleRecomendacionSheet({required this.recomendacion});

  final Recomendacion recomendacion;

  @override
  Widget build(BuildContext context) {
    final color = _colorPrioridad(recomendacion.prioridad);
    final icono = _iconoTipo(recomendacion.tipo);
    final descripcion = _textoLimpio(recomendacion.descripcion);
    final accion = _textoLimpio(recomendacion.accionSugerida);
    final explicacion = _textoLimpio(recomendacion.explicacion);
    final variable = _textoLimpio(recomendacion.variable);
    final valor = _textoLimpio(recomendacion.valorActual);
    final rango = _textoLimpio(recomendacion.rangoIdeal);

    return DraggableScrollableSheet(
      initialChildSize: 0.68,
      minChildSize: 0.30,
      maxChildSize: 0.90,
      builder: (context, scrollController) {
        return Container(
          decoration: const BoxDecoration(
            color: AppColores.superficie,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: SingleChildScrollView(
            controller: scrollController,
            padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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
                const SizedBox(height: 10),
                Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ),
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Container(
                      width: 54,
                      height: 54,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.10),
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Icon(icono, color: color, size: 29),
                    ),
                    const SizedBox(width: 13),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            recomendacion.titulo,
                            style: const TextStyle(
                              fontSize: 20,
                              height: 1.12,
                              fontWeight: FontWeight.w900,
                              color: AppColores.textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 7),
                          _PrioridadPill(
                            texto: _textoPrioridad(recomendacion.prioridad),
                            color: color,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                _DetalleBloque(
                  titulo: 'Resumen',
                  icono: Icons.short_text_rounded,
                  color: color,
                  child: Text(
                    descripcion,
                    style: const TextStyle(
                      fontSize: 13.2,
                      height: 1.40,
                      fontWeight: FontWeight.w700,
                      color: AppColores.textoSecundario,
                    ),
                  ),
                ),
                if (variable.isNotEmpty || valor.isNotEmpty || rango.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  _DetalleBloque(
                    titulo: 'Lectura evaluada',
                    icono: Icons.analytics_outlined,
                    color: color,
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: [
                        if (variable.isNotEmpty)
                          _DatoDetalle(titulo: 'Variable', valor: variable),
                        if (valor.isNotEmpty)
                          _DatoDetalle(titulo: 'Actual', valor: valor),
                        if (rango.isNotEmpty)
                          _DatoDetalle(titulo: 'Ideal', valor: rango),
                      ],
                    ),
                  ),
                ],
                if (accion.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  _DetalleBloque(
                    titulo: 'Qué hacer',
                    icono: Icons.check_circle_outline_rounded,
                    color: color,
                    child: Text(
                      accion,
                      style: const TextStyle(
                        fontSize: 13.2,
                        height: 1.40,
                        fontWeight: FontWeight.w800,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                  ),
                ],
                if (explicacion.isNotEmpty) ...[
                  const SizedBox(height: 11),
                  _DetalleBloque(
                    titulo: 'Explicación técnica',
                    icono: Icons.info_outline_rounded,
                    color: color,
                    child: Text(
                      explicacion,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.40,
                        fontWeight: FontWeight.w700,
                        color: AppColores.textoSecundario,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        );
      },
    );
  }
}

class _DetalleBloque extends StatelessWidget {
  const _DetalleBloque({
    required this.titulo,
    required this.icono,
    required this.color,
    required this.child,
  });

  final String titulo;
  final IconData icono;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.045),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withOpacity(0.12)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icono, color: color, size: 18),
              const SizedBox(width: 8),
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          child,
        ],
      ),
    );
  }
}

class _DatoDetalle extends StatelessWidget {
  const _DatoDetalle({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 98, maxWidth: 145),
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
            style: const TextStyle(
              fontSize: 10.5,
              fontWeight: FontWeight.w800,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 3),
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


class _SeleccionaFiltroCard extends StatelessWidget {
  const _SeleccionaFiltroCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 18, 18, 18),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(color: AppColores.borde),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          Icon(
            Icons.touch_app_rounded,
            color: AppColores.primario,
            size: 34,
          ),
          SizedBox(height: 10),
          Text(
            'Selecciona una prioridad',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
          SizedBox(height: 6),
          Text(
            'Toca Críticas, Medias o Bajas para mostrar únicamente esas recomendaciones.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12.8,
              height: 1.35,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
        ],
      ),
    );
  }
}

class _SinResultadosFiltro extends StatelessWidget {
  const _SinResultadosFiltro();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: const Padding(
        padding: EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.filter_alt_off_rounded, color: AppColores.textoSecundario),
            SizedBox(width: 12),
            Expanded(
              child: Text(
                'No hay recomendaciones para esta prioridad. Puedes seleccionar otra opción.',
                style: TextStyle(
                  color: AppColores.textoSecundario,
                  height: 1.4,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SinRecomendacionesView extends StatelessWidget {
  const _SinRecomendacionesView();

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(22, 28, 22, 28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: AppColores.primariosuave,
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.check_circle_rounded,
                color: AppColores.primario,
                size: 42,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Cultivo dentro de rangos adecuados',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'No se generaron recomendaciones porque las variables actuales se encuentran dentro de los rangos definidos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColores.textoSecundario,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  const _ErrorView({required this.mensaje});

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
            fontWeight: FontWeight.w700,
          ),
        ),
      ),
    );
  }
}

Color _colorPrioridad(int prioridad) {
  if (prioridad == 1) return AppColores.prioridadAlta;
  if (prioridad == 2) return AppColores.prioridadMedia;
  return AppColores.prioridadBaja;
}

IconData _iconoPrioridad(int prioridad) {
  if (prioridad == 1) return Icons.priority_high_rounded;
  if (prioridad == 2) return Icons.warning_amber_rounded;
  return Icons.tips_and_updates_rounded;
}

String _textoPrioridad(int prioridad) {
  if (prioridad == 1) return 'Crítica';
  if (prioridad == 2) return 'Media';
  return 'Baja';
}

IconData _iconoTipo(TipoRecomendacion tipo) {
  switch (tipo) {
    case TipoRecomendacion.riego:
      return Icons.water_drop_rounded;
    case TipoRecomendacion.fertilizacion:
      return Icons.eco_rounded;
    case TipoRecomendacion.ph:
      return Icons.science_rounded;
    case TipoRecomendacion.temperatura:
      return Icons.thermostat_rounded;
    case TipoRecomendacion.salinidad:
      return Icons.bolt_rounded;
    case TipoRecomendacion.general:
      return Icons.tips_and_updates_rounded;
  }
}

String _etiquetaCortaRecomendacion(Recomendacion recomendacion) {
  final variable = _textoLimpio(recomendacion.variable).toLowerCase();

  if (variable.contains('nitrógeno') || variable.contains('nitrogeno') ||
      variable == 'n') {
    return 'N';
  }

  if (variable.contains('fósforo') || variable.contains('fosforo') ||
      variable.contains('(p') || variable == 'p') {
    return 'P';
  }

  if (variable.contains('potasio') || variable.contains('(k') ||
      variable == 'k') {
    return 'K';
  }

  if (variable.contains('ph')) {
    return 'pH';
  }

  if (variable.contains('conductividad') || variable.contains('ec') ||
      variable.contains('salinidad')) {
    return 'EC';
  }

  if (variable.contains('humedad') || recomendacion.tipo == TipoRecomendacion.riego) {
    return 'Riego';
  }

  if (variable.contains('temperatura') ||
      recomendacion.tipo == TipoRecomendacion.temperatura) {
    return 'Temp.';
  }

  if (variable.contains('npk')) {
    return 'NPK';
  }

  switch (recomendacion.tipo) {
    case TipoRecomendacion.riego:
      return 'Riego';
    case TipoRecomendacion.fertilizacion:
      return 'NPK';
    case TipoRecomendacion.ph:
      return 'pH';
    case TipoRecomendacion.temperatura:
      return 'Temp.';
    case TipoRecomendacion.salinidad:
      return 'EC';
    case TipoRecomendacion.general:
      return 'General';
  }
}

String _textoLimpio(String? texto) {
  return (texto ?? '').trim();
}
