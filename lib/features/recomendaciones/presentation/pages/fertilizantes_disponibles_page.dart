import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/tema/app_colores.dart';
import '../../domain/entities/producto_fertilizante.dart';
import '../providers/fertilizantes_disponibles_provider.dart';

class FertilizantesDisponiblesPage extends ConsumerWidget {
  const FertilizantesDisponiblesPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final composiciones = ref.watch(productosFertilizantesProvider);
    final seleccionadas =
        composiciones.where((producto) => producto.seleccionado).length;

    final guardadas =
        composiciones.where((producto) => producto.esManual).toList();
    final temporales =
        composiciones.where((producto) => producto.esTemporal).toList();

    return Scaffold(
      backgroundColor: AppColores.fondo,
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 28),
          children: [
            const _TituloConcentracionesHeader(),
            const SizedBox(height: 18),

            _ResumenConcentracionesCard(
              total: composiciones.length,
              seleccionadas: seleccionadas,
            ),
            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: () {
                  _mostrarFormularioConcentracion(
                    context: context,
                    ref: ref,
                  );
                },
                icon: const Icon(Icons.add_rounded),
                label: Text(
                  seleccionadas > 0
                      ? 'Agregar otra concentración'
                      : 'Agregar concentración',
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
            const SizedBox(height: 18),

            if (temporales.isNotEmpty) ...[
              _ConcentracionesCard(
                titulo: temporales.length == 1 ? 'Usada solo esta vez' : 'Usadas solo esta vez',
                descripcion: '',
                icono: Icons.calculate_rounded,
                composiciones: temporales,
                onChanged: (producto) => _alternar(ref, producto),
                onEditar: null,
                onEliminar: (producto) => _quitarTemporal(ref, producto),
              ),
              const SizedBox(height: 16),
            ],

            if (guardadas.isNotEmpty) ...[
              _ConcentracionesCard(
                titulo: 'Concentraciones guardadas',
                descripcion: '',
                icono: Icons.bookmark_rounded,
                composiciones: guardadas,
                onChanged: (producto) => _alternar(ref, producto),
                onEditar: (producto) => _mostrarFormularioConcentracion(
                  context: context,
                  ref: ref,
                  producto: producto,
                ),
                onEliminar: (producto) => _confirmarEliminar(
                  context: context,
                  ref: ref,
                  producto: producto,
                ),
              ),
              const SizedBox(height: 16),
            ],

            SizedBox(
              width: double.infinity,
              height: 48,
              child: FilledButton.icon(
                onPressed: seleccionadas == 0
                    ? null
                    : () {
                        ref.read(modoCalculoFertilizanteProvider.notifier).state =
                            ModoCalculoFertilizante.personalizado;
                        Navigator.of(context).pop();
                      },
                icon: const Icon(Icons.calculate_rounded),
                label: const Text(
                  'Aplicar y calcular plan',
                  style: TextStyle(
                    fontSize: 14.5,
                    fontWeight: FontWeight.w900,
                  ),
                ),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColores.primario,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: AppColores.borde,
                  disabledForegroundColor: AppColores.textoSecundario,
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

void _alternar(WidgetRef ref, ProductoFertilizante producto) {
  ref.read(modoCalculoFertilizanteProvider.notifier).state =
      ModoCalculoFertilizante.personalizado;
  ref
      .read(productosFertilizantesProvider.notifier)
      .alternarSeleccion(producto.id);
}

void _quitarTemporal(WidgetRef ref, ProductoFertilizante producto) {
  ref
      .read(productosFertilizantesProvider.notifier)
      .eliminarFertilizanteManual(producto.id);
}

Future<void> _mostrarFormularioConcentracion({
  required BuildContext context,
  required WidgetRef ref,
  ProductoFertilizante? producto,
}) async {
  await showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return _FormularioConcentracionSheet(
        producto: producto,
        onGuardar: ({
          required double n,
          required double p2o5,
          required double k2o,
        }) async {
          final notifier = ref.read(productosFertilizantesProvider.notifier);

          final ok = producto == null
              ? await notifier.guardarComposicionNpk(
                  n: n,
                  p2o5: p2o5,
                  k2o: k2o,
                )
              : await notifier.editarComposicionNpk(
                  id: producto.id,
                  n: n,
                  p2o5: p2o5,
                  k2o: k2o,
                );

          if (ok) {
            ref.read(modoCalculoFertilizanteProvider.notifier).state =
                ModoCalculoFertilizante.personalizado;
          }

          return ok;
        },
        onUsarTemporal: ({
          required double n,
          required double p2o5,
          required double k2o,
        }) async {
          ref
              .read(productosFertilizantesProvider.notifier)
              .usarComposicionTemporal(n: n, p2o5: p2o5, k2o: k2o);

          ref.read(modoCalculoFertilizanteProvider.notifier).state =
              ModoCalculoFertilizante.personalizado;

          return true;
        },
      );
    },
  );
}

Future<void> _confirmarEliminar({
  required BuildContext context,
  required WidgetRef ref,
  required ProductoFertilizante producto,
}) async {
  final eliminar = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Eliminar concentración'),
            content: Text('¿Deseas eliminar ${producto.nombre} de la lista?'),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                style: FilledButton.styleFrom(
                  backgroundColor: AppColores.advertencia,
                ),
                child: const Text('Eliminar'),
              ),
            ],
          );
        },
      ) ??
      false;

  if (!eliminar) return;

  await ref
      .read(productosFertilizantesProvider.notifier)
      .eliminarFertilizanteManual(producto.id);
}

typedef _GuardarConcentracion = Future<bool> Function({
  required double n,
  required double p2o5,
  required double k2o,
});

class _FormularioConcentracionSheet extends StatefulWidget {
  const _FormularioConcentracionSheet({
    required this.onGuardar,
    required this.onUsarTemporal,
    this.producto,
  });

  final ProductoFertilizante? producto;
  final _GuardarConcentracion onGuardar;
  final _GuardarConcentracion onUsarTemporal;

  @override
  State<_FormularioConcentracionSheet> createState() =>
      _FormularioConcentracionSheetState();
}

class _FormularioConcentracionSheetState
    extends State<_FormularioConcentracionSheet> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nController;
  late final TextEditingController _pController;
  late final TextEditingController _kController;

  bool _guardando = false;
  String? _errorGuardado;

  @override
  void initState() {
    super.initState();

    final producto = widget.producto;
    _nController = TextEditingController(text: _valorInicial(producto?.n));
    _pController = TextEditingController(text: _valorInicial(producto?.p2o5));
    _kController = TextEditingController(text: _valorInicial(producto?.k2o));
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
    final editando = widget.producto != null;
    final teclado = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.92,
      ),
      padding: EdgeInsets.fromLTRB(16, 14, 16, 18 + teclado),
      decoration: const BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
        ),
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
                    child: Icon(
                      editando ? Icons.edit_rounded : Icons.add_rounded,
                      color: AppColores.primario,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      editando ? 'Editar concentración' : 'Agregar concentración',
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
              const SizedBox(height: 18),

              const Text(
                'Concentración (%)',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 10),

              Row(
                children: [
                  Expanded(
                    child: _CampoPorcentaje(
                      controller: _nController,
                      etiqueta: 'N',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoPorcentaje(
                      controller: _pController,
                      etiqueta: 'P₂O₅',
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: _CampoPorcentaje(
                      controller: _kController,
                      etiqueta: 'K₂O',
                    ),
                  ),
                ],
              ),

              if (_errorGuardado != null) ...[
                const SizedBox(height: 12),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: AppColores.advertenciasuave,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(
                      color: AppColores.advertencia.withOpacity(0.25),
                    ),
                  ),
                  child: Text(
                    _errorGuardado!,
                    style: const TextStyle(
                      fontWeight: FontWeight.w800,
                      color: AppColores.advertencia,
                    ),
                  ),
                ),
              ],

              const SizedBox(height: 20),

              if (!editando) ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : () => _guardar(guardar: true),
                    icon: _guardando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.bookmark_add_rounded),
                    label: const Text(
                      'Guardar concentración',
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
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  height: 48,
                  child: OutlinedButton.icon(
                    onPressed: _guardando ? null : () => _guardar(guardar: false),
                    icon: const Icon(Icons.calculate_rounded),
                    label: const Text(
                      'Salir',
                      style: TextStyle(fontWeight: FontWeight.w900),
                    ),
                  ),
                ),
              ] else ...[
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: FilledButton.icon(
                    onPressed: _guardando ? null : () => _guardar(guardar: true),
                    icon: _guardando
                        ? const SizedBox(
                            width: 19,
                            height: 19,
                            child: CircularProgressIndicator(
                              strokeWidth: 2.2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: const Text(
                      'Guardar cambios',
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
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardar({required bool guardar}) async {
    setState(() => _errorGuardado = null);

    if (!_formKey.currentState!.validate()) return;

    final n = _aDouble(_nController.text) ?? 0;
    final p = _aDouble(_pController.text) ?? 0;
    final k = _aDouble(_kController.text) ?? 0;

    if (n <= 0 && p <= 0 && k <= 0) {
      setState(() {
        _errorGuardado = 'Ingresa al menos una concentración mayor que cero.';
      });
      return;
    }

    setState(() => _guardando = true);

    final ok = guardar
        ? await widget.onGuardar(n: n, p2o5: p, k2o: k)
        : await widget.onUsarTemporal(n: n, p2o5: p, k2o: k);

    if (!mounted) return;

    setState(() => _guardando = false);

    if (!ok) {
      setState(() {
        _errorGuardado =
            'No se pudo procesar la concentración. Revisa los porcentajes.';
      });
      return;
    }

    Navigator.of(context).pop();

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          guardar
              ? 'Concentración guardada.'
              : 'Concentración agregada al plan.',
        ),
      ),
    );
  }
}

class _CampoPorcentaje extends StatelessWidget {
  const _CampoPorcentaje({
    required this.controller,
    required this.etiqueta,
  });

  final TextEditingController controller;
  final String etiqueta;

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [_formatoNumero],
      decoration: InputDecoration(
        labelText: etiqueta,
        suffixText: '%',
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
      validator: (valor) {
        final numero = _aDouble(valor);
        if (numero == null || numero < 0 || numero > 100) {
          return '0 a 100';
        }
        return null;
      },
    );
  }
}

class _TituloConcentracionesHeader extends StatelessWidget {
  const _TituloConcentracionesHeader();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        InkWell(
          borderRadius: BorderRadius.circular(14),
          onTap: () => Navigator.of(context).pop(),
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
            Icons.science_rounded,
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
                'Concentraciones',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  height: 1.05,
                  color: AppColores.textoPrincipal,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _ResumenConcentracionesCard extends StatelessWidget {
  const _ResumenConcentracionesCard({
    required this.total,
    required this.seleccionadas,
  });

  final int total;
  final int seleccionadas;

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
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColores.primariosuave,
                borderRadius: BorderRadius.circular(14),
              ),
              child: const Icon(
                Icons.format_list_numbered_rounded,
                color: AppColores.primario,
              ),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '$seleccionadas seleccionada(s)',
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
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

class _ConcentracionesCard extends StatelessWidget {
  const _ConcentracionesCard({
    required this.titulo,
    required this.descripcion,
    required this.icono,
    required this.composiciones,
    required this.onChanged,
    required this.onEditar,
    required this.onEliminar,
  });

  final String titulo;
  final String descripcion;
  final IconData icono;
  final List<ProductoFertilizante> composiciones;
  final ValueChanged<ProductoFertilizante> onChanged;
  final ValueChanged<ProductoFertilizante>? onEditar;
  final ValueChanged<ProductoFertilizante>? onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
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
                    fontSize: 16,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),
            ],
          ),
          if (descripcion.trim().isNotEmpty) ...[
            const SizedBox(height: 6),
            Text(
              descripcion,
              style: const TextStyle(
                fontSize: 12.2,
                height: 1.35,
                fontWeight: FontWeight.w600,
                color: AppColores.textoSecundario,
              ),
            ),
          ],
          const SizedBox(height: 12),
          ...composiciones.map(
            (producto) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: _ConcentracionTile(
                producto: producto,
                onChanged: () => onChanged(producto),
                onEditar: onEditar == null ? null : () => onEditar!(producto),
                onEliminar:
                    onEliminar == null ? null : () => onEliminar!(producto),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _ConcentracionTile extends StatelessWidget {
  const _ConcentracionTile({
    required this.producto,
    required this.onChanged,
    required this.onEditar,
    required this.onEliminar,
  });

  final ProductoFertilizante producto;
  final VoidCallback onChanged;
  final VoidCallback? onEditar;
  final VoidCallback? onEliminar;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 9),
      decoration: BoxDecoration(
        color: producto.seleccionado
            ? AppColores.primariosuave.withOpacity(0.70)
            : AppColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: producto.seleccionado
              ? AppColores.primario.withOpacity(0.22)
              : AppColores.borde,
        ),
      ),
      child: Row(
        children: [
          Checkbox(
            value: producto.seleccionado,
            onChanged: (_) => onChanged(),
            visualDensity: VisualDensity.compact,
          ),
          const SizedBox(width: 4),
          Expanded(
            child: Text(
              producto.concentracionTexto,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
          if (onEditar != null)
            IconButton(
              onPressed: onEditar,
              icon: const Icon(Icons.edit_rounded),
              color: AppColores.primario,
              tooltip: 'Editar',
            ),
          if (onEliminar != null)
            IconButton(
              onPressed: onEliminar,
              icon: const Icon(Icons.delete_outline_rounded),
              color: AppColores.advertencia,
              tooltip: 'Eliminar',
            ),
        ],
      ),
    );
  }
}

final _formatoNumero = FilteringTextInputFormatter.allow(
  RegExp(r'[0-9\.,]'),
);

double? _aDouble(String? value) {
  return double.tryParse(value?.trim().replaceAll(',', '.') ?? '');
}

String _valorInicial(double? valor) {
  if (valor == null || valor <= 0) return '';
  if (valor == valor.roundToDouble()) return valor.toStringAsFixed(0);
  return valor.toStringAsFixed(1);
}
