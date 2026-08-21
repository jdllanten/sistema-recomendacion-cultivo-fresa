import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tema/app_colores.dart';
import '../../domain/entities/lote_cultivo.dart';
import '../providers/lotes_provider.dart';

class LotesPage extends ConsumerStatefulWidget {
  const LotesPage({super.key});

  @override
  ConsumerState<LotesPage> createState() => _LotesPageState();
}

class _LotesPageState extends ConsumerState<LotesPage> {
  String? loteExpandidoId;

  @override
  Widget build(BuildContext context) {
    final lotesAsync = ref.watch(lotesCultivoProvider);
    final loteSeleccionadoId = ref.watch(loteSeleccionadoIdProvider);

    return Scaffold(
      backgroundColor: AppColores.fondo,
      appBar: AppBar(
        backgroundColor: AppColores.fondo,
        elevation: 0,
        titleSpacing: 0,
        title: const _TituloLotesAppBar(),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _mostrarFormularioLote(context, ref),
        icon: const Icon(Icons.add_rounded),
        label: const Text(
          'Nuevo lote',
          style: TextStyle(fontWeight: FontWeight.w900),
        ),
        backgroundColor: AppColores.primario,
        foregroundColor: Colors.white,
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
      ),
      body: lotesAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, _) => _ErrorLotes(mensaje: error.toString()),
        data: (lotes) {
          if (lotes.isEmpty) {
            return const _LotesVacios();
          }

          return ListView.separated(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
            itemCount: lotes.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              final lote = lotes[index];
              final seleccionado = lote.id == loteSeleccionadoId;
              final expandido = lote.id == loteExpandidoId;

              return _LoteCardExpandible(
                lote: lote,
                seleccionado: seleccionado,
                expandido: expandido,
                onTap: () {
                  setState(() {
                    loteExpandidoId = expandido ? null : lote.id;
                  });
                },
                onSeleccionar: () => _seleccionarLote(context, lote),
                onEditar: () => _mostrarFormularioLote(
                  context,
                  ref,
                  loteEditar: lote,
                ),
                onEliminar: () => _confirmarEliminarLote(
                  context,
                  ref,
                  lote,
                  loteSeleccionadoId,
                ),
              );
            },
          );
        },
      ),
    );
  }

  void _seleccionarLote(BuildContext context, LoteCultivo lote) {
    ref.read(loteSeleccionadoIdProvider.notifier).state = lote.id;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('${lote.nombre} seleccionado.')),
    );

    // Si esta pantalla fue abierta desde Inicio/Mediciones para escoger un lote,
    // vuelve automáticamente a la ventana anterior y entrega el lote seleccionado.
    // Si Lotes está abierta como una pestaña principal, no fuerza ninguna ruta.
    Future.delayed(const Duration(milliseconds: 250), () {
      if (!context.mounted) return;

      final navigator = Navigator.of(context);
      if (navigator.canPop()) {
        navigator.pop(lote);
      }
    });
  }

  Future<void> _mostrarFormularioLote(
    BuildContext context,
    WidgetRef ref, {
    LoteCultivo? loteEditar,
  }) async {
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      useSafeArea: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        return _FormularioLoteSheet(
          ref: ref,
          loteEditar: loteEditar,
        );
      },
    );
  }

  Future<void> _confirmarEliminarLote(
    BuildContext context,
    WidgetRef ref,
    LoteCultivo lote,
    String loteSeleccionadoId,
  ) async {
    if (lote.id == 'lote_1') {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('El lote principal no se puede eliminar.'),
        ),
      );
      return;
    }

    final confirmar = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
          ),
          title: const Text('Eliminar lote'),
          content: Text(
            '¿Deseas eliminar ${lote.nombre}? No se borran las lecturas, solo se oculta el lote de la lista.',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                backgroundColor: AppColores.critico,
              ),
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Eliminar'),
            ),
          ],
        );
      },
    );

    if (confirmar != true) return;

    try {
      await ref.read(lotesCultivoControllerProvider).desactivarLote(lote.id);

      if (loteSeleccionadoId == lote.id) {
        ref.read(loteSeleccionadoIdProvider.notifier).state = 'lote_1';
      }

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${lote.nombre} eliminado.')),
      );
    } catch (error) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            error.toString().replaceFirst('Exception: ', ''),
          ),
        ),
      );
    }
  }
}

class _TituloLotesAppBar extends StatelessWidget {
  const _TituloLotesAppBar();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 42,
          height: 42,
          decoration: BoxDecoration(
            color: AppColores.primariosuave,
            borderRadius: BorderRadius.circular(14),
            border: Border.all(
              color: AppColores.primario.withOpacity(0.16),
            ),
          ),
          child: const Icon(
            Icons.grid_view_rounded,
            color: AppColores.primario,
            size: 22,
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisSize: MainAxisSize.min,
            children: [
              Text(
                'Lotes',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                  height: 1.05,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Organiza y selecciona el lote de trabajo',
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

class _LoteCardExpandible extends StatelessWidget {
  const _LoteCardExpandible({
    required this.lote,
    required this.seleccionado,
    required this.expandido,
    required this.onTap,
    required this.onSeleccionar,
    required this.onEditar,
    required this.onEliminar,
  });

  final LoteCultivo lote;
  final bool seleccionado;
  final bool expandido;
  final VoidCallback onTap;
  final VoidCallback onSeleccionar;
  final VoidCallback onEditar;
  final VoidCallback onEliminar;

  @override
  Widget build(BuildContext context) {
    final plantasTexto = lote.numeroPlantas > 0
        ? '${_formatearEntero(lote.numeroPlantas)} plantas'
        : 'Sin plantas';
    final areaTexto = lote.areaM2 > 0
        ? '${_formatearNumero(lote.areaM2)} m²'
        : 'Sin área';
    final observaciones = lote.observaciones.trim();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      curve: Curves.easeOut,
      decoration: BoxDecoration(
        color: seleccionado ? AppColores.primariosuave : AppColores.superficie,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: seleccionado
              ? AppColores.primario.withOpacity(0.40)
              : AppColores.borde,
          width: seleccionado ? 1.2 : 1,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.035),
            blurRadius: 16,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: Material(
          color: Colors.transparent,
          child: InkWell(
            onTap: onTap,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(14, 14, 10, 14),
              child: Column(
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _IconoLote(seleccionado: seleccionado),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    lote.nombre,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: const TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w900,
                                      color: AppColores.textoPrincipal,
                                    ),
                                  ),
                                ),
                                if (seleccionado) const _ChipActivo(),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${_cultivoVisible(lote.cultivo)} · ${lote.etapa}',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: const TextStyle(
                                fontSize: 12.5,
                                fontWeight: FontWeight.w800,
                                color: AppColores.textoSecundario,
                              ),
                            ),
                            const SizedBox(height: 6),
                            _ResumenPlantasLote(
                              texto: plantasTexto,
                              seleccionado: seleccionado,
                            ),
                            if (expandido) ...[
                              const SizedBox(height: 5),
                              const Text(
                                'Toca para ocultar detalles',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 11.2,
                                  fontWeight: FontWeight.w800,
                                  color: AppColores.primario,
                                ),
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 4),
                      Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          PopupMenuButton<_AccionLote>(
                            tooltip: 'Opciones del lote',
                            icon: const Icon(
                              Icons.more_vert_rounded,
                              color: AppColores.textoSecundario,
                            ),
                            onSelected: (accion) {
                              if (accion == _AccionLote.seleccionar) {
                                onSeleccionar();
                                return;
                              }

                              if (accion == _AccionLote.editar) {
                                onEditar();
                                return;
                              }

                              if (accion == _AccionLote.eliminar) {
                                onEliminar();
                              }
                            },
                            itemBuilder: (context) {
                              return [
                                const PopupMenuItem(
                                  value: _AccionLote.seleccionar,
                                  child: Row(
                                    children: [
                                      Icon(Icons.check_circle_outline_rounded),
                                      SizedBox(width: 8),
                                      Text('Seleccionar'),
                                    ],
                                  ),
                                ),
                                const PopupMenuItem(
                                  value: _AccionLote.editar,
                                  child: Row(
                                    children: [
                                      Icon(Icons.edit_outlined),
                                      SizedBox(width: 8),
                                      Text('Editar'),
                                    ],
                                  ),
                                ),
                                PopupMenuItem(
                                  value: _AccionLote.eliminar,
                                  enabled: lote.id != 'lote_1',
                                  child: Row(
                                    children: [
                                      Icon(
                                        Icons.delete_outline_rounded,
                                        color: lote.id == 'lote_1'
                                            ? AppColores.textoSecundario
                                            : AppColores.critico,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        lote.id == 'lote_1'
                                            ? 'No se puede eliminar'
                                            : 'Eliminar',
                                        style: TextStyle(
                                          color: lote.id == 'lote_1'
                                              ? AppColores.textoSecundario
                                              : AppColores.critico,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ];
                            },
                          ),
                          AnimatedRotation(
                            turns: expandido ? 0.5 : 0,
                            duration: const Duration(milliseconds: 180),
                            child: const Icon(
                              Icons.keyboard_arrow_down_rounded,
                              color: AppColores.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                  AnimatedCrossFade(
                    firstChild: const SizedBox.shrink(),
                    secondChild: Padding(
                      padding: const EdgeInsets.only(top: 14),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Divider(height: 1, color: AppColores.borde),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: _DetalleLoteItem(
                                  icono: Icons.groups_rounded,
                                  titulo: 'Plantas',
                                  valor: plantasTexto,
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: _DetalleLoteItem(
                                  icono: Icons.straighten_rounded,
                                  titulo: 'Área',
                                  valor: areaTexto,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          _DetalleLoteItem(
                            icono: Icons.schedule_rounded,
                            titulo: 'Tiempo estimado',
                            valor: _tiempoEtapa(lote.etapa).replaceFirst('Tiempo estimado: ', ''),
                          ),
                          const SizedBox(height: 10),
                          _ObservacionesLote(
                            texto: observaciones.isEmpty
                                ? 'Sin observaciones registradas.'
                                : observaciones,
                          ),
                          const SizedBox(height: 14),
                          Row(
                            children: [
                              Expanded(
                                child: OutlinedButton.icon(
                                  onPressed: onEditar,
                                  icon: const Icon(Icons.edit_outlined, size: 18),
                                  label: const Text('Editar'),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: AppColores.primario,
                                    side: BorderSide(
                                      color: AppColores.primario.withOpacity(0.35),
                                    ),
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),
                              Expanded(
                                child: FilledButton.icon(
                                  onPressed: seleccionado ? null : onSeleccionar,
                                  icon: const Icon(Icons.check_rounded, size: 18),
                                  label: Text(seleccionado ? 'Activo' : 'Usar lote'),
                                  style: FilledButton.styleFrom(
                                    backgroundColor: AppColores.primario,
                                    foregroundColor: Colors.white,
                                    disabledBackgroundColor:
                                        AppColores.primario.withOpacity(0.12),
                                    disabledForegroundColor: AppColores.primario,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(15),
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    crossFadeState: expandido
                        ? CrossFadeState.showSecond
                        : CrossFadeState.showFirst,
                    duration: const Duration(milliseconds: 180),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _IconoLote extends StatelessWidget {
  const _IconoLote({required this.seleccionado});

  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 46,
      height: 46,
      decoration: BoxDecoration(
        color: Colors.white.withOpacity(seleccionado ? 0.75 : 1),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: AppColores.primario.withOpacity(0.12),
        ),
      ),
      child: const Icon(
        Icons.grass_rounded,
        color: AppColores.primario,
        size: 23,
      ),
    );
  }
}

class _ChipActivo extends StatelessWidget {
  const _ChipActivo();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColores.primario.withOpacity(0.12),
        borderRadius: BorderRadius.circular(999),
      ),
      child: const Text(
        'Activo',
        style: TextStyle(
          fontSize: 10.5,
          fontWeight: FontWeight.w900,
          color: AppColores.primario,
        ),
      ),
    );
  }
}

class _ResumenPlantasLote extends StatelessWidget {
  const _ResumenPlantasLote({
    required this.texto,
    required this.seleccionado,
  });

  final String texto;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    final sinDefinir = texto.toLowerCase().contains('sin');

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 5),
      decoration: BoxDecoration(
        color: seleccionado
            ? Colors.white.withOpacity(0.65)
            : AppColores.fondo.withOpacity(0.75),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(
          color: AppColores.borde.withOpacity(0.85),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            Icons.groups_rounded,
            size: 13,
            color: sinDefinir ? AppColores.textoSecundario : AppColores.primario,
          ),
          const SizedBox(width: 5),
          Text(
            texto,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              fontSize: 11.1,
              height: 1,
              fontWeight: FontWeight.w900,
              color: sinDefinir
                  ? AppColores.textoSecundario
                  : AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleLoteItem extends StatelessWidget {
  const _DetalleLoteItem({
    required this.icono,
    required this.titulo,
    required this.valor,
  });

  final IconData icono;
  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
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
              color: AppColores.primariosuave.withOpacity(0.75),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, size: 17, color: AppColores.primario),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  titulo,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w700,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  valor,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: const TextStyle(
                    fontSize: 12.4,
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

class _ObservacionesLote extends StatelessWidget {
  const _ObservacionesLote({required this.texto});

  final String texto;

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
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.notes_rounded,
            size: 18,
            color: AppColores.textoSecundario,
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Observaciones',
                  style: TextStyle(
                    fontSize: 10.8,
                    fontWeight: FontWeight.w800,
                    color: AppColores.textoSecundario,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  texto,
                  style: const TextStyle(
                    fontSize: 12.3,
                    height: 1.28,
                    fontWeight: FontWeight.w700,
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

class _FormularioLoteSheet extends StatefulWidget {
  const _FormularioLoteSheet({
    required this.ref,
    this.loteEditar,
  });

  final WidgetRef ref;
  final LoteCultivo? loteEditar;

  @override
  State<_FormularioLoteSheet> createState() => _FormularioLoteSheetState();
}

class _FormularioLoteSheetState extends State<_FormularioLoteSheet> {
  static const List<String> etapas = [
    'Desarrollo vegetativo',
    'Floración',
    'Fructificación',
    'Alta producción',
    'Mantenimiento',
  ];

  late final TextEditingController nombreController;
  late final TextEditingController plantasController;
  late final TextEditingController areaController;
  late final TextEditingController observacionesController;

  late String etapaSeleccionada;
  bool guardando = false;

  bool get esEdicion => widget.loteEditar != null;

  @override
  void initState() {
    super.initState();

    final loteEditar = widget.loteEditar;
    final etapaInicial = loteEditar?.etapa.trim();

    nombreController = TextEditingController(text: loteEditar?.nombre ?? '');
    plantasController = TextEditingController(
      text: loteEditar != null && loteEditar.numeroPlantas > 0
          ? loteEditar.numeroPlantas.toString()
          : '',
    );
    areaController = TextEditingController(
      text: loteEditar != null && loteEditar.areaM2 > 0
          ? _formatearNumero(loteEditar.areaM2)
          : '',
    );
    observacionesController = TextEditingController(
      text: loteEditar?.observaciones ?? '',
    );

    etapaSeleccionada = etapas.contains(etapaInicial)
        ? etapaInicial!
        : _normalizarEtapa(etapaInicial);
  }

  @override
  void dispose() {
    nombreController.dispose();
    plantasController.dispose();
    areaController.dispose();
    observacionesController.dispose();
    super.dispose();
  }

  Future<void> guardar() async {
    if (guardando) return;

    final nombre = nombreController.text.trim();

    if (nombre.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Escribe el nombre del lote.')),
      );
      return;
    }

    setState(() => guardando = true);

    final area = double.tryParse(areaController.text.replaceAll(',', '.')) ?? 0;
    final plantas = int.tryParse(plantasController.text.trim()) ?? 0;

    try {
      if (esEdicion) {
        final loteEditar = widget.loteEditar!;

        await widget.ref.read(lotesCultivoControllerProvider).actualizarLote(
              id: loteEditar.id,
              nombre: nombre,
              cultivo: 'Fresa',
              etapa: etapaSeleccionada,
              areaM2: area,
              numeroPlantas: plantas,
              observaciones: observacionesController.text,
            );

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Lote actualizado.')),
        );
      } else {
        final lote = await widget.ref.read(lotesCultivoControllerProvider).crearLote(
              nombre: nombre,
              cultivo: 'Fresa',
              etapa: etapaSeleccionada,
              areaM2: area,
              numeroPlantas: plantas,
              observaciones: observacionesController.text,
            );

        widget.ref.read(loteSeleccionadoIdProvider.notifier).state = lote.id;

        if (!mounted) return;
        Navigator.of(context).pop();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('${lote.nombre} creado.')),
        );
      }
    } catch (error) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(error.toString().replaceFirst('Exception: ', '')),
        ),
      );
    } finally {
      if (mounted) setState(() => guardando = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      decoration: const BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
      ),
      child: SingleChildScrollView(
        padding: EdgeInsets.fromLTRB(
          18,
          10,
          18,
          MediaQuery.of(context).viewInsets.bottom + 18,
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Container(
                width: 42,
                height: 4,
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
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColores.primariosuave,
                    borderRadius: BorderRadius.circular(15),
                  ),
                  child: Icon(
                    esEdicion ? Icons.edit_rounded : Icons.add_rounded,
                    color: AppColores.primario,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        esEdicion ? 'Editar lote' : 'Nuevo lote',
                        style: const TextStyle(
                          fontSize: 19,
                          fontWeight: FontWeight.w900,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                      const SizedBox(height: 2),
                      const Text(
                        'La etapa se selecciona de la lista para evitar errores.',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColores.textoSecundario,
                        ),
                      ),
                    ],
                  ),
                ),
                IconButton(
                  onPressed: guardando ? null : () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ],
            ),
            const SizedBox(height: 18),
            _CampoFormulario(
              controller: nombreController,
              label: 'Nombre del lote',
              hint: 'Ejemplo: Lote 2',
              icono: Icons.grid_view_rounded,
              textInputAction: TextInputAction.next,
            ),
            const SizedBox(height: 12),
            const _CampoCultivoFijo(),
            const SizedBox(height: 12),
            DropdownButtonFormField<String>(
              value: etapaSeleccionada,
              isExpanded: true,
              decoration: _decoracionCampo(
                label: 'Etapa del cultivo',
                icono: Icons.local_florist_rounded,
              ),
              items: etapas
                  .map(
                    (etapa) => DropdownMenuItem<String>(
                      value: etapa,
                      child: Text(etapa),
                    ),
                  )
                  .toList(),
              onChanged: guardando
                  ? null
                  : (valor) {
                      if (valor == null) return;
                      setState(() => etapaSeleccionada = valor);
                    },
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                Expanded(
                  child: _CampoFormulario(
                    controller: plantasController,
                    label: 'Plantas',
                    hint: 'Ej. 9000',
                    icono: Icons.groups_rounded,
                    keyboardType: TextInputType.number,
                    textInputAction: TextInputAction.next,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: _CampoFormulario(
                    controller: areaController,
                    label: 'Área',
                    hint: 'm²',
                    icono: Icons.straighten_rounded,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    textInputAction: TextInputAction.next,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _CampoFormulario(
              controller: observacionesController,
              label: 'Observaciones',
              hint: 'Opcional',
              icono: Icons.notes_rounded,
              maxLines: 2,
            ),
            const SizedBox(height: 18),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: FilledButton.icon(
                onPressed: guardando ? null : guardar,
                icon: guardando
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : Icon(esEdicion ? Icons.save_as_rounded : Icons.save_rounded),
                label: Text(
                  guardando
                      ? 'Guardando...'
                      : esEdicion
                          ? 'Guardar cambios'
                          : 'Guardar lote',
                  style: const TextStyle(fontWeight: FontWeight.w900),
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
      ),
    );
  }
}

class _CampoFormulario extends StatelessWidget {
  const _CampoFormulario({
    required this.controller,
    required this.label,
    required this.hint,
    required this.icono,
    this.keyboardType,
    this.textInputAction,
    this.maxLines = 1,
  });

  final TextEditingController controller;
  final String label;
  final String hint;
  final IconData icono;
  final TextInputType? keyboardType;
  final TextInputAction? textInputAction;
  final int maxLines;

  @override
  Widget build(BuildContext context) {
    return TextField(
      controller: controller,
      keyboardType: keyboardType,
      textInputAction: textInputAction,
      maxLines: maxLines,
      decoration: _decoracionCampo(
        label: label,
        hint: hint,
        icono: icono,
      ),
    );
  }
}

class _CampoCultivoFijo extends StatelessWidget {
  const _CampoCultivoFijo();

  @override
  Widget build(BuildContext context) {
    return InputDecorator(
      decoration: _decoracionCampo(
        label: 'Cultivo',
        icono: Icons.spa_rounded,
      ),
      child: const Text(
        'Fresa',
        style: TextStyle(
          fontSize: 15,
          fontWeight: FontWeight.w800,
          color: AppColores.textoPrincipal,
        ),
      ),
    );
  }
}

InputDecoration _decoracionCampo({
  required String label,
  required IconData icono,
  String? hint,
}) {
  return InputDecoration(
    labelText: label,
    hintText: hint,
    prefixIcon: Icon(icono, size: 20),
    filled: true,
    fillColor: AppColores.fondo,
    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
    border: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColores.borde),
    ),
    enabledBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColores.borde),
    ),
    focusedBorder: OutlineInputBorder(
      borderRadius: BorderRadius.circular(16),
      borderSide: const BorderSide(color: AppColores.primario, width: 1.4),
    ),
  );
}

String _cultivoVisible(String cultivo) {
  // Por ahora no se manejan variedades. Aunque el dato viejo venga como
  // "Fresa Albión", en la interfaz se muestra solamente "Fresa".
  return 'Fresa';
}

String _normalizarEtapa(String? etapa) {
  final texto = (etapa ?? '').trim().toLowerCase();

  if (texto.contains('vegetativo')) return 'Desarrollo vegetativo';
  if (texto.contains('flor')) return 'Floración';
  if (texto.contains('alta')) return 'Alta producción';
  if (texto.contains('manten')) return 'Mantenimiento';

  return 'Fructificación';
}

String _tiempoEtapa(String etapa) {
  final texto = etapa.toLowerCase();

  if (texto.contains('vegetativo')) return 'Tiempo estimado: 1 a 6 meses';
  if (texto.contains('flor')) return 'Tiempo estimado: 4 a 7 meses';
  if (texto.contains('alta')) return 'Tiempo estimado: 7 a 15 meses';
  if (texto.contains('manten')) return 'Tiempo estimado: 16 a 24 meses';

  return 'Tiempo estimado: 7 a 15 meses';
}

String _formatearEntero(int valor) {
  return valor.toString().replaceAllMapped(
        RegExp(r'\B(?=(\d{3})+(?!\d))'),
        (_) => '.',
      );
}

String _formatearNumero(double valor) {
  if (valor == valor.roundToDouble()) {
    return _formatearEntero(valor.round());
  }

  return valor.toStringAsFixed(1).replaceAll('.', ',');
}

enum _AccionLote {
  seleccionar,
  editar,
  eliminar,
}

class _LotesVacios extends StatelessWidget {
  const _LotesVacios();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 64,
              height: 64,
              decoration: BoxDecoration(
                color: AppColores.primariosuave,
                borderRadius: BorderRadius.circular(22),
              ),
              child: const Icon(
                Icons.grass_rounded,
                color: AppColores.primario,
                size: 32,
              ),
            ),
            const SizedBox(height: 14),
            const Text(
              'Todavía no hay lotes creados.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
            const SizedBox(height: 4),
            const Text(
              'Crea el primer lote para empezar a registrar lecturas por separado.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12.5,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ErrorLotes extends StatelessWidget {
  const _ErrorLotes({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Text(
          'No se pudieron cargar los lotes:\n$mensaje',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontWeight: FontWeight.w700,
            color: AppColores.textoSecundario,
          ),
        ),
      ),
    );
  }
}
