import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../app/rutas/app_router.dart';
import '../../../../core/tema/app_colores.dart';
import '../../../../core/constantes/rangos_agronomicos.dart';
import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../historial/presentation/providers/historial_provider.dart';
import '../../domain/entities/datos_sensor_suelo.dart';
import '../providers/sensor_suelo_provider.dart';
import '../providers/estado_sensor_visual_provider.dart';
import '../../data/datasource/sensor_usb_rs485_datasource.dart';
import '../../../recomendaciones/presentation/providers/recomendaciones_provider.dart';
import '../../../recomendaciones/domain/entities/plan_nutricional.dart';
import '../../../recomendaciones/presentation/providers/plan_nutricional_npk_provider.dart';
import '../../../recomendaciones/presentation/providers/configuracion_plan_nutricional_provider.dart';
import '../../../lotes/domain/entities/lote_cultivo.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';
import '../../../lotes/presentation/pages/lotes_page.dart';

class MedicionesSensorPage extends ConsumerWidget {
  const MedicionesSensorPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturaAsync = ref.watch(lecturaSensorStreamProvider);
    final ultimaLecturaHive = ref.watch(ultimaLecturaHistorialProvider);

    return Scaffold(
      appBar: AppBar(
        toolbarHeight: 66,
        elevation: 0,
        backgroundColor: AppColores.superficie,
        surfaceTintColor: Colors.transparent,
        titleSpacing: 16,
        title: const _TituloAppMediciones(),
        flexibleSpace: Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                AppColores.primariosuave.withOpacity(0.88),
                AppColores.superficie,
              ],
            ),
          ),
        ),
      ),
      body: lecturaAsync.when(
        data: (lectura) {
          return _ContenidoMedicionesSensor(
            lectura: lectura,
            origen: 'MQTT',
            estadoSensor: 'Activo',
            descripcionEstado:
                'Lectura recibida en tiempo real desde el sensor.',
            esTiempoReal: true,
          );
        },
        loading: () {
          if (ultimaLecturaHive != null) {
            final lectura = _convertirHistorialADatosSensor(ultimaLecturaHive);

            return _ContenidoMedicionesSensor(
              lectura: lectura,
              origen: 'Hive / Firebase',
              estadoSensor: 'Última lectura guardada',
              descripcionEstado:
                  'Todavía no llega una lectura nueva por MQTT. Se muestra la última lectura sincronizada.',
              esTiempoReal: false,
            );
          }

          return const _EstadoSinLectura();
        },
        error: (error, stackTrace) {
          if (ultimaLecturaHive != null) {
            final lectura = _convertirHistorialADatosSensor(ultimaLecturaHive);

            return _ContenidoMedicionesSensor(
              lectura: lectura,
              origen: 'Hive / Firebase',
              estadoSensor: 'Última lectura guardada',
              descripcionEstado:
                  'No se pudo leer MQTT en este momento. Se muestra la última lectura disponible.',
              esTiempoReal: false,
            );
          }

          return _EstadoErrorLectura(
            mensaje: error.toString(),
          );
        },
      ),
    );
  }
}


class _TituloAppMediciones extends StatelessWidget {
  const _TituloAppMediciones();

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: AppColores.primario.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColores.primario.withOpacity(0.18),
            ),
          ),
          alignment: Alignment.center,
          child: const Text(
            '🍓',
            style: TextStyle(fontSize: 22),
          ),
        ),
        const SizedBox(width: 12),
        const Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Mediciones del sensor',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 18.5,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                  letterSpacing: -0.2,
                ),
              ),
              SizedBox(height: 3),
              Text(
                'Monitoreo del suelo en tiempo real',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 10.8,
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


class _ContenidoMedicionesSensor extends ConsumerStatefulWidget {
  const _ContenidoMedicionesSensor({
    required this.lectura,
    required this.origen,
    required this.estadoSensor,
    required this.descripcionEstado,
    required this.esTiempoReal,
  });

  final DatosSensorSuelo lectura;
  final String origen;
  final String estadoSensor;
  final String descripcionEstado;
  final bool esTiempoReal;

  @override
  ConsumerState<_ContenidoMedicionesSensor> createState() =>
      _ContenidoMedicionesSensorState();
}

class _ContenidoMedicionesSensorState extends ConsumerState<_ContenidoMedicionesSensor> {
  DatosSensorSuelo? _lecturaPromedioManual;
  String? _lotePromedioManual;
  int _cantidadPlantasPromedio = 0;

  DatosSensorSuelo get _lecturaActiva {
    return _lecturaPromedioManual ?? widget.lectura;
  }

  bool get _usandoPromedioManual => _lecturaPromedioManual != null;

  @override
  Widget build(BuildContext context) {
    final loteSeleccionado = ref.watch(loteSeleccionadoProvider);
    final loteSeleccionadoId = loteSeleccionado.id;
    final lecturaLoteAsync = ref.watch(lecturaUltimaPorLotePlanProvider);
    final lecturaFirestoreLote = lecturaLoteAsync.valueOrNull;

    final mostrandoPromedioDelLote = _lecturaPromedioManual != null &&
        _lotePromedioManual == loteSeleccionadoId;

    final lectura = mostrandoPromedioDelLote
        ? _lecturaPromedioManual
        : lecturaFirestoreLote ??
            (loteSeleccionadoId == 'lote_1' ? widget.lectura : null);

    final usandoPromedioManual = mostrandoPromedioDelLote;

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 24),
      children: [
        _EncabezadoDatosLoteCard(
          loteId: loteSeleccionadoId,
          loteNombre: loteSeleccionado.nombre,
          numeroPlantas: loteSeleccionado.numeroPlantas,
          usandoPromedioUsb: usandoPromedioManual,
          cantidadPlantas: _cantidadPlantasPromedio,
          cargandoLectura: lecturaLoteAsync.isLoading,
          onSeleccionarLote: () async {
            final lote = await Navigator.of(context).push<LoteCultivo>(
              MaterialPageRoute(
                builder: (_) => const LotesPage(),
              ),
            );

            if (lote == null) return;

            ref.read(loteSeleccionadoIdProvider.notifier).state = lote.id;
            ref.read(lotePlanNutricionalProvider.notifier).state = lote.nombre;
          },

          onVolverSensor: usandoPromedioManual
              ? () {
                  setState(() {
                    _lecturaPromedioManual = null;
                    _lotePromedioManual = null;
                    _cantidadPlantasPromedio = 0;
                  });

                  ref.read(fechaLecturaUsbActivaProvider.notifier).state = null;
                }
              : null,
        ),
        const SizedBox(height: 4),

        _LecturaDatosCard(
          onIniciar: () async {
            final lecturaBase = lectura ?? widget.lectura;

            final resultado = await _mostrarModalLecturaDatos(
              context,
              lecturaBase,
              loteSeleccionadoId,
            );

            if (resultado == null) return;

            setState(() {
              _lecturaPromedioManual = resultado.promedio;
              _lotePromedioManual = resultado.loteId;
              _cantidadPlantasPromedio = resultado.cantidadPlantas;
            });

            final lotes = ref.read(lotesCultivoProvider).valueOrNull ??
                <LoteCultivo>[LoteCultivo.loteInicial()];

            final loteResultado = lotes.firstWhere(
              (lote) => lote.id == resultado.loteId,
              orElse: () => LoteCultivo.loteInicial(),
            );

            ref.read(loteSeleccionadoIdProvider.notifier).state =
                resultado.loteId;
            ref.read(lotePlanNutricionalProvider.notifier).state =
                loteResultado.nombre;


            ref.read(fechaLecturaUsbActivaProvider.notifier).state =
                resultado.promedio.fechaLectura;

            try {
              await _guardarPromedioEnFirestore(resultado);

              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'Promedio de ${_nombreLote(resultado.loteId)} guardado y mostrado como lectura principal.',
                  ),
                ),
              );
            } catch (error) {
              if (!context.mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text(
                    'El promedio se mostró, pero no se pudo guardar: ${error.toString().replaceFirst('Exception: ', '')}',
                  ),
                ),
              );
            }
          },
        ),
        const SizedBox(height: 8),

        if (lectura == null) ...[
          _EstadoSinLecturaLote(
            loteId: loteSeleccionadoId,
            loteNombre: loteSeleccionado.nombre,
          ),
          const SizedBox(height: 10),
        ] else ...[
          _VariablesSueloCard(lectura: lectura),
          const SizedBox(height: 10),
          _NpkResumenCard(lectura: lectura),
          const SizedBox(height: 10),
        ],

      ],
    );
  }

  Future<void> _guardarPromedioEnFirestore(
    _ResultadoLecturaDatos resultado,
  ) async {
    final promedio = resultado.promedio;
    final loteId = resultado.loteId;
    final loteActual = ref.read(loteSeleccionadoProvider);

    final nombreLote = loteActual.id == loteId
        ? loteActual.nombre
        : _nombreLote(loteId);

    final fecha = promedio.fechaLectura;
    final docId = fecha.toUtc().toIso8601String().replaceAll(':', '-');

    final datosLectura = <String, dynamic>{
      'usuarioId': 'jdh2010',
      'fincaId': 'finca_esperanza',
      'loteId': loteId,
      'nombreLote': nombreLote,
      'sensorId': 'sensor_usb_rs485_7en1',
      'cultivo': 'Fresa Albión',
      'etapa': 'Fructificación',
      'tipo': 'promedio_muestreo',
      'origen': 'usb_rs485_promedio_lote',
      'cantidadPlantas': resultado.cantidadPlantas,
      'humedadSuelo': promedio.humedadSuelo,
      'temperaturaSuelo': promedio.temperaturaSuelo,
      'conductividadElectrica': promedio.conductividadElectrica,
      'phSuelo': promedio.phSuelo,
      'nitrogeno': promedio.nitrogeno,
      'fosforo': promedio.fosforo,
      'potasio': promedio.potasio,
      'fechaLectura': Timestamp.fromDate(fecha),
      'creadoEn': FieldValue.serverTimestamp(),
    };

    final firestore = FirebaseFirestore.instance;

    final loteRef = firestore
        .collection('usuarios')
        .doc('jdh2010')
        .collection('fincas')
        .doc('finca_esperanza')
        .collection('lotes')
        .doc(loteId);

    await loteRef.set(
      {
        'id': loteId,
        'nombre': nombreLote,
        'cultivo': 'Fresa Albión',
        'etapa': 'Fructificación',
        'activo': true,
        'actualizadoEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    await loteRef.collection('lecturas').doc(docId).set(datosLectura);

    await loteRef.collection('muestreos').doc(docId).set({
      ...datosLectura,
      'lecturaId': docId,
    });
  }
}


class _EstadoSinLecturaLote extends StatelessWidget {
  const _EstadoSinLecturaLote({
    required this.loteId,
    required this.loteNombre,
  });

  final String loteId;
  final String loteNombre;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.advertenciasuave,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColores.advertencia.withOpacity(0.22),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.info_outline_rounded,
            color: AppColores.advertencia,
            size: 22,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'No hay lecturas guardadas para $loteNombre. Puedes tomar un promedio USB o esperar una lectura automática de ese lote.',
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _InfoLecturaCompactaCard extends StatelessWidget {
  const _InfoLecturaCompactaCard({
    required this.estadoSensor,
    required this.origen,
    required this.descripcion,
    required this.fechaLectura,
    required this.esTiempoReal,
  });

  final String estadoSensor;
  final String origen;
  final String descripcion;
  final DateTime fechaLectura;
  final bool esTiempoReal;

  @override
  Widget build(BuildContext context) {
    final color = esTiempoReal ? AppColores.primario : AppColores.advertencia;

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: ExpansionTile(
        tilePadding: const EdgeInsets.symmetric(horizontal: 14),
        childrenPadding: const EdgeInsets.fromLTRB(14, 0, 14, 14),
        leading: Icon(
          esTiempoReal ? Icons.sensors_rounded : Icons.history_rounded,
          color: color,
        ),
        title: const Text(
          'Información de lectura',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w900,
            color: AppColores.textoPrincipal,
          ),
        ),
        subtitle: Text(
          'Última actualización: ${_fechaCorta(fechaLectura)}',
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: AppColores.textoSecundario,
          ),
        ),
        children: [
          _FilaInfoLectura(titulo: 'Estado', valor: estadoSensor, color: color),
          const SizedBox(height: 8),
          _FilaInfoLectura(titulo: 'Origen', valor: origen, color: color),
          const SizedBox(height: 8),
          _FilaInfoLectura(titulo: 'Detalle', valor: descripcion, color: color),
        ],
      ),
    );
  }
}

class _FilaInfoLectura extends StatelessWidget {
  const _FilaInfoLectura({
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
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: color.withOpacity(0.07),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withOpacity(0.14)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            titulo,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w800,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 3),
          Text(
            valor,
            style: const TextStyle(
              fontSize: 12.5,
              height: 1.35,
              fontWeight: FontWeight.w800,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _VariablesSueloCard extends StatelessWidget {
  const _VariablesSueloCard({required this.lectura});

  final DatosSensorSuelo lectura;

  @override
  Widget build(BuildContext context) {
    final humedad = _detalleHumedad(lectura.humedadSuelo);
    final temperatura = _detalleTemperatura(lectura.temperaturaSuelo);
    final ph = _detallePh(lectura.phSuelo);
    final ec = _detalleEc(lectura.conductividadElectrica);

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TituloSeccionSimple(
              icono: Icons.grass_rounded,
              titulo: 'Variables del suelo',
              //subtitulo: 'Lecturas principales del sensor.',
            ),
            const SizedBox(height: 7),
            const _IndicadorInteraccion(
              texto:
                  'Toca una variable para ver detalle, recomendación e historial',
            ),
            const SizedBox(height: 10),
            GridView.count(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              crossAxisCount: 2,
              mainAxisSpacing: 9,
              crossAxisSpacing: 9,
              childAspectRatio: 1.30,
              children: [
                _VariableMedicionCard(
                  titulo: 'Humedad',
                  valor: humedad.valor,
                  unidad: humedad.unidad,
                  icono: humedad.icono,
                  estado: humedad.estado,
                  color: humedad.color,
                  onTap: () => _mostrarDetalleVariable(context, humedad),
                ),
                _VariableMedicionCard(
                  titulo: 'Temperatura',
                  valor: temperatura.valor,
                  unidad: temperatura.unidad,
                  icono: temperatura.icono,
                  estado: temperatura.estado,
                  color: temperatura.color,
                  onTap: () => _mostrarDetalleVariable(context, temperatura),
                ),
                _VariableMedicionCard(
                  titulo: 'pH',
                  valor: ph.valor,
                  unidad: ph.unidad,
                  icono: ph.icono,
                  estado: ph.estado,
                  color: ph.color,
                  onTap: () => _mostrarDetalleVariable(context, ph),
                ),
                _VariableMedicionCard(
                  titulo: 'Conductividad',
                  valor: ec.valor,
                  unidad: ec.unidad,
                  icono: ec.icono,
                  estado: ec.estado,
                  color: ec.color,
                  onTap: () => _mostrarDetalleVariable(context, ec),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _VariableMedicionCard extends StatelessWidget {
  const _VariableMedicionCard({
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.icono,
    required this.estado,
    required this.color,
    required this.onTap,
  });

  final String titulo;
  final String valor;
  final String unidad;
  final IconData icono;
  final String estado;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 180),
          padding: const EdgeInsets.fromLTRB(10, 10, 10, 10),
          decoration: BoxDecoration(
            color: color.withOpacity(0.055),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: color.withOpacity(0.20)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -3,
                right: -3,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 19,
                  color: AppColores.textoSecundario.withOpacity(0.72),
                ),
              ),
              Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 35,
                      height: 35,
                      decoration: BoxDecoration(
                        color: AppColores.superficie.withOpacity(0.92),
                        shape: BoxShape.circle,
                        border: Border.all(color: color.withOpacity(0.16)),
                      ),
                      child: Icon(
                        icono,
                        color: color,
                        size: 18.5,
                      ),
                    ),
                    const SizedBox(height: 7),
                    SizedBox(
                      height: 15,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          titulo,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 12,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: AppColores.textoSecundario,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 5),
                    FittedBox(
                      fit: BoxFit.scaleDown,
                      child: RichText(
                        textAlign: TextAlign.center,
                        text: TextSpan(
                          children: [
                            TextSpan(
                              text: valor,
                              style: TextStyle(
                                fontSize: 24.5,
                                height: 1,
                                fontWeight: FontWeight.w900,
                                color: color,
                                letterSpacing: -0.4,
                              ),
                            ),
                            if (unidad.isNotEmpty)
                              TextSpan(
                                text: ' $unidad',
                                style: const TextStyle(
                                  fontSize: 10.5,
                                  height: 1,
                                  fontWeight: FontWeight.w800,
                                  color: AppColores.textoSecundario,
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EstadoMiniBadge extends StatelessWidget {
  const _EstadoMiniBadge({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: AppColores.superficie.withOpacity(0.88),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        texto,
        maxLines: 1,
        overflow: TextOverflow.ellipsis,
        style: TextStyle(
          fontSize: 10.3,
          fontWeight: FontWeight.w900,
          color: color,
        ),
      ),
    );
  }
}


class _NpkResumenCard extends ConsumerWidget {
  const _NpkResumenCard({required this.lectura});

  final DatosSensorSuelo lectura;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final plan = ref.watch(planNutricionalNpkProvider).asData?.value;

    final nitrogeno = _detalleNutrienteNpk(
      codigo: 'N',
      nombre: 'Nitrógeno',
      valor: lectura.nitrogeno,
      icono: Icons.biotech_rounded,
      necesidadPlanKg: _necesidadPlanPorCodigo(plan, 'N'),
    );
    final fosforo = _detalleNutrienteNpk(
      codigo: 'P₂O₅',
      nombre: 'Fósforo',
      valor: lectura.fosforo,
      icono: Icons.biotech_rounded,
      necesidadPlanKg: _necesidadPlanPorCodigo(plan, 'P₂O₅'),
    );
    final potasio = _detalleNutrienteNpk(
      codigo: 'K₂O',
      nombre: 'Potasio',
      valor: lectura.potasio,
      icono: Icons.biotech_rounded,
      necesidadPlanKg: _necesidadPlanPorCodigo(plan, 'K₂O'),
    );

    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: const BorderSide(color: AppColores.borde),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(11, 11, 11, 12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TituloSeccionSimple(
              icono: Icons.biotech_rounded,
              titulo: 'Nutrientes NPK',
              //subtitulo: 'El color usa el rango técnico del asesor.',
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                Expanded(child: _NpkChip(detalle: nitrogeno, onTap: () => _mostrarDetalleVariable(context, nitrogeno))),
                const SizedBox(width: 8),
                Expanded(child: _NpkChip(detalle: fosforo, onTap: () => _mostrarDetalleVariable(context, fosforo))),
                const SizedBox(width: 8),
                Expanded(child: _NpkChip(detalle: potasio, onTap: () => _mostrarDetalleVariable(context, potasio))),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

double? _necesidadPlanPorCodigo(
  PlanNutricionalNpk? plan,
  String codigo,
) {
  if (plan == null) return null;

  if (codigo == 'N') {
    return plan.nitrogeno.faltanteFormaComercialMesKg;
  }

  if (codigo == 'P₂O₅') {
    return plan.fosforo.faltanteFormaComercialMesKg;
  }

  return plan.potasio.faltanteFormaComercialMesKg;
}

class _NpkChip extends StatelessWidget {
  const _NpkChip({required this.detalle, required this.onTap});

  final _DetalleVariableData detalle;
  final VoidCallback onTap;

  String get _simboloVisible {
    if (detalle.codigo == 'P₂O₅') return 'P';
    if (detalle.codigo == 'K₂O') return 'K';
    return detalle.codigo;
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        borderRadius: BorderRadius.circular(20),
        onTap: onTap,
        child: Container(
          height: 110,
          padding: const EdgeInsets.fromLTRB(6, 8, 6, 8),
          decoration: BoxDecoration(
            color: detalle.color.withOpacity(0.055),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: detalle.color.withOpacity(0.20)),
          ),
          child: Stack(
            children: [
              Positioned(
                top: -3,
                right: -3,
                child: Icon(
                  Icons.chevron_right_rounded,
                  size: 17,
                  color: AppColores.textoSecundario.withOpacity(0.72),
                ),
              ),
              Center(
                child: FittedBox(
                  fit: BoxFit.scaleDown,
                  child: SizedBox(
                    width: 96,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: AppColores.superficie.withOpacity(0.92),
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: detalle.color.withOpacity(0.16),
                            ),
                          ),
                          alignment: Alignment.center,
                          child: Text(
                            _simboloVisible,
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 22.5,
                              height: 1,
                              fontWeight: FontWeight.w900,
                              color: detalle.color,
                            ),
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          detalle.titulo,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: AppColores.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          detalle.valor,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            fontSize: 18,
                            height: 1,
                            fontWeight: FontWeight.w900,
                            color: detalle.color,
                            letterSpacing: -0.2,
                          ),
                        ),
                        const SizedBox(height: 3),
                        const Text(
                          'mg/kg',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            fontSize: 9.8,
                            height: 1,
                            fontWeight: FontWeight.w700,
                            color: AppColores.textoSecundario,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}


class _AccesosRapidosCard extends StatelessWidget {
  const _AccesosRapidosCard({required this.lectura});

  final DatosSensorSuelo lectura;

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
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const _TituloSeccion(
              icono: Icons.touch_app_rounded,
              titulo: 'Acciones rápidas',
              subtitulo: 'Continúa con el análisis de esta lectura.',
            ),
            const SizedBox(height: 14),
            Row(
              children: [
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(RutasApp.planNutricionalNpk),
                    icon: const Icon(Icons.eco_rounded),
                    label: const Text('Plan nutric.'),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    onPressed: () => context.go(RutasApp.recomendaciones),
                    icon: const Icon(Icons.recommend_rounded),
                    label: const Text('Recom.'),
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


class _EstadoSinLectura extends StatelessWidget {
  const _EstadoSinLectura();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 24),
      children: const [
        _EstadoSimpleCard(
          icono: Icons.hourglass_empty_rounded,
          titulo: 'Esperando datos del sensor',
          descripcion:
              'Cuando llegue una lectura por MQTT o se sincronice una lectura desde Firebase, aparecerá aquí.',
          color: AppColores.advertencia,
          fondo: AppColores.advertenciasuave,
        ),
      ],
    );
  }
}

class _EstadoErrorLectura extends StatelessWidget {
  const _EstadoErrorLectura({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 9, 12, 24),
      children: [
        _EstadoSimpleCard(
          icono: Icons.error_outline_rounded,
          titulo: 'No se pudo leer el sensor',
          descripcion: mensaje,
          color: AppColores.advertencia,
          fondo: AppColores.advertenciasuave,
        ),
      ],
    );
  }
}

class _EstadoSimpleCard extends StatelessWidget {
  const _EstadoSimpleCard({
    required this.icono,
    required this.titulo,
    required this.descripcion,
    required this.color,
    required this.fondo,
  });

  final IconData icono;
  final String titulo;
  final String descripcion;
  final Color color;
  final Color fondo;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: fondo,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(color: color.withOpacity(0.24)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icono, color: color),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 15,
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


class _TituloSeccion extends StatelessWidget {
  const _TituloSeccion({
    required this.icono,
    required this.titulo,
    required this.subtitulo,
  });

  final IconData icono;
  final String titulo;
  final String subtitulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icono, color: AppColores.primario),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                titulo,
                style: const TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 3),
              Text(
                subtitulo,
                style: const TextStyle(
                  fontSize: 12.5,
                  height: 1.3,
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


class _TituloSeccionSimple extends StatelessWidget {
  const _TituloSeccionSimple({
    required this.icono,
    required this.titulo,
  });

  final IconData icono;
  final String titulo;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icono,
          color: AppColores.primario,
          size: 21,
        ),
        const SizedBox(width: 8),
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
    );
  }
}


class _IndicadorInteraccion extends StatelessWidget {
  const _IndicadorInteraccion({
    required this.texto,
  });

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Container(
          width: 28,
          height: 28,
          decoration: BoxDecoration(
            color: AppColores.primariosuave.withOpacity(0.78),
            shape: BoxShape.circle,
          ),
          child: const Icon(
            Icons.touch_app_rounded,
            size: 16,
            color: AppColores.primario,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            texto,
            style: const TextStyle(
              fontSize: 11.2,
              height: 1.25,
              fontWeight: FontWeight.w700,
              color: AppColores.textoSecundario,
            ),
          ),
        ),
      ],
    );
  }
}

void _mostrarDetalleVariable(
  BuildContext context,
  _DetalleVariableData detalle,
) {
  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _DetalleVariableBottomSheet(detalle: detalle);
    },
  );
}

class _DetalleVariableBottomSheet extends ConsumerWidget {
  const _DetalleVariableBottomSheet({required this.detalle});

  final _DetalleVariableData detalle;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final planAsync = ref.watch(planNutricionalNpkProvider);
    final lecturasHistorial = ref.watch(historialLecturasProvider);

    return SafeArea(
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.88,
        ),
        decoration: const BoxDecoration(
          color: AppColores.superficie,
          borderRadius: BorderRadius.vertical(top: Radius.circular(30)),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(18, 10, 18, 24),
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

              const SizedBox(height: 10),

              Align(
                alignment: Alignment.centerRight,
                child: IconButton(
                  onPressed: () => Navigator.of(context).pop(),
                  icon: const Icon(Icons.close_rounded),
                ),
              ),

              Center(
                child: Text(
                  detalle.titulo,
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    fontSize: 28,
                    height: 1.1,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                    letterSpacing: -0.4,
                  ),
                ),
              ),

              const SizedBox(height: 22),

              _DetalleLecturaActualCard(detalle: detalle),

              const SizedBox(height: 12),

              _DetalleRecomendacionCard(detalle: detalle),

              const SizedBox(height: 12),

              if (detalle.esNpk) ...[
                planAsync.when(
                  loading: () => const _DetalleCargandoPlanCard(),
                  error: (_, __) => const _DetallePlanErrorCard(),
                  data: (plan) => _DetallePlanNutricionalVariableCard(
                    detalle: detalle,
                    plan: plan,
                  ),
                ),
                const SizedBox(height: 12),
              ],

              _HistorialVariableCard(
                detalle: detalle,
                lecturas: lecturasHistorial,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DetalleEncabezado extends StatelessWidget {
  const _DetalleEncabezado({required this.detalle});

  final _DetalleVariableData detalle;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 48,
          height: 48,
          decoration: BoxDecoration(
            color: detalle.color.withOpacity(0.12),
            borderRadius: BorderRadius.circular(16),
          ),
          child: Icon(detalle.icono, color: detalle.color),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: Text(
            detalle.titulo,
            style: const TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ),
        IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.close_rounded),
        ),
      ],
    );
  }
}

class _DetalleLecturaActualCard extends StatelessWidget {
  const _DetalleLecturaActualCard({required this.detalle});

  final _DetalleVariableData detalle;

  @override
  Widget build(BuildContext context) {
    return _DetalleCardBase(
      icono: Icons.eco_rounded,
      titulo: 'Lectura actual',
      color: detalle.color,
      child: Row(
        children: [
          Expanded(
            flex: 6,
            child: FittedBox(
              alignment: Alignment.centerLeft,
              fit: BoxFit.scaleDown,
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    detalle.valor,
                    style: TextStyle(
                      fontSize: 48,
                      fontWeight: FontWeight.w900,
                      color: detalle.color,
                      letterSpacing: -0.8,
                    ),
                  ),
                  if (detalle.unidad.isNotEmpty) ...[
                    const SizedBox(width: 6),
                    Padding(
                      padding: const EdgeInsets.only(bottom: 7),
                      child: Text(
                        detalle.unidad,
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),

          Container(
            width: 1,
            height: 58,
            margin: const EdgeInsets.symmetric(horizontal: 14),
            color: AppColores.borde,
          ),

          Expanded(
            flex: 5,
            child: Text(
              detalle.estado,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 18,
                height: 1.25,
                fontWeight: FontWeight.w800,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _DetalleRecomendacionCard extends StatelessWidget {
  const _DetalleRecomendacionCard({required this.detalle});

  final _DetalleVariableData detalle;

  @override
  Widget build(BuildContext context) {
    final recomendaciones = _separarRecomendaciones(detalle.recomendacion);

    return _DetalleCardBase(
      icono: Icons.eco_rounded,
      titulo: 'Recomendación',
      color: detalle.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (detalle.interpretacion.trim().isNotEmpty) ...[
            Text(
              detalle.interpretacion,
              style: const TextStyle(
                fontSize: 13,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
            const SizedBox(height: 12),
          ],

          ...recomendaciones.map(
            (texto) => Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Icon(
                      Icons.circle_rounded,
                      size: 7,
                      color: detalle.color,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      texto,
                      style: const TextStyle(
                        fontSize: 14,
                        height: 1.35,
                        fontWeight: FontWeight.w700,
                        color: AppColores.textoPrincipal,
                      ),
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

  List<String> _separarRecomendaciones(String texto) {
    final limpio = texto.trim();

    if (limpio.isEmpty) {
      return <String>['Mantenga seguimiento de la variable en el historial.'];
    }

    return limpio
        .split(RegExp(r'\.\s*'))
        .map((item) => item.trim())
        .where((item) => item.isNotEmpty)
        .toList();
  }
}

class _DetalleEstadoCard extends StatelessWidget {
  const _DetalleEstadoCard({required this.detalle});

  final _DetalleVariableData detalle;

  @override
  Widget build(BuildContext context) {
    return _DetalleCardBase(
      icono: Icons.info_outline_rounded,
      titulo: 'Estado e indicación',
      color: detalle.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _EstadoBadge(texto: detalle.estado, color: detalle.color),
          const SizedBox(height: 10),
          Text(
            detalle.interpretacion,
            style: const TextStyle(
              fontSize: 13,
              height: 1.4,
              fontWeight: FontWeight.w600,
              color: AppColores.textoSecundario,
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(11),
            decoration: BoxDecoration(
              color: detalle.color.withOpacity(0.08),
              borderRadius: BorderRadius.circular(14),
              border: Border.all(color: detalle.color.withOpacity(0.16)),
            ),
            child: Text(
              detalle.recomendacion,
              style: const TextStyle(
                fontSize: 13,
                height: 1.4,
                fontWeight: FontWeight.w800,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EstadoBadge extends StatelessWidget {
  const _EstadoBadge({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 11, vertical: 7),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.circle_rounded, size: 9, color: color),
          const SizedBox(width: 7),
          Text(
            texto,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}


enum _PeriodoHistorialVariable { semana, mes, todo }

class _HistorialVariableCard extends StatefulWidget {
  const _HistorialVariableCard({
    required this.detalle,
    required this.lecturas,
  });

  final _DetalleVariableData detalle;
  final List<LecturaHistorial> lecturas;

  @override
  State<_HistorialVariableCard> createState() => _HistorialVariableCardState();
}

class _HistorialVariableCardState extends State<_HistorialVariableCard> {
  _PeriodoHistorialVariable periodo = _PeriodoHistorialVariable.semana;

  @override
  Widget build(BuildContext context) {
    final puntos = _filtrarPuntos(
      widget.lecturas,
      widget.detalle.codigo,
      periodo,
    );

    final tieneDatos = puntos.isNotEmpty;
    final estadisticas = tieneDatos ? _estadisticasPuntos(puntos) : null;

    return _DetalleCardBase(
      icono: Icons.eco_rounded,
      titulo: 'Historial de la variable',
      color: widget.detalle.color,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _SelectorPeriodoHistorial(
            periodo: periodo,
            onChanged: (nuevoPeriodo) {
              setState(() {
                periodo = nuevoPeriodo;
              });
            },
          ),
          const SizedBox(height: 12),
          if (!tieneDatos)
            const _MensajeHistorialVacio()
          else ...[
            SizedBox(
              height: 178,
              width: double.infinity,
              child: CustomPaint(
                painter: _MiniGraficaVariablePainter(
                  puntos: puntos.map((p) => p.valor).toList(),
                  color: widget.detalle.color,
                  unidad: widget.detalle.unidad,
                ),
              ),
            ),
            const SizedBox(height: 12),
            if (estadisticas != null)
              Row(
                children: [
                  Expanded(
                    child: _ResumenHistorialItem(
                      titulo: 'Mín.',
                      valor: _numero(estadisticas.minimo),
                      unidad: widget.detalle.unidad,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ResumenHistorialItem(
                      titulo: 'Prom.',
                      valor: _numero(estadisticas.promedio),
                      unidad: widget.detalle.unidad,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: _ResumenHistorialItem(
                      titulo: 'Máx.',
                      valor: _numero(estadisticas.maximo),
                      unidad: widget.detalle.unidad,
                    ),
                  ),
                ],
              ),
            const SizedBox(height: 10),
            Text(
              _mensajeTendencia(codigo: widget.detalle.codigo, puntos: puntos),
              style: const TextStyle(
                fontSize: 12.5,
                height: 1.35,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectorPeriodoHistorial extends StatelessWidget {
  const _SelectorPeriodoHistorial({required this.periodo, required this.onChanged});

  final _PeriodoHistorialVariable periodo;
  final ValueChanged<_PeriodoHistorialVariable> onChanged;

  @override
  Widget build(BuildContext context) {
    return SegmentedButton<_PeriodoHistorialVariable>(
      segments: const [
        ButtonSegment(value: _PeriodoHistorialVariable.semana, label: Text('Semana')),
        ButtonSegment(value: _PeriodoHistorialVariable.mes, label: Text('Mes')),
        ButtonSegment(value: _PeriodoHistorialVariable.todo, label: Text('Todo')),
      ],
      selected: {periodo},
      onSelectionChanged: (seleccion) {
        if (seleccion.isEmpty) return;
        onChanged(seleccion.first);
      },
      style: ButtonStyle(
        visualDensity: VisualDensity.compact,
        textStyle: WidgetStateProperty.all(
          const TextStyle(fontSize: 12, fontWeight: FontWeight.w800),
        ),
      ),
    );
  }
}

class _MensajeHistorialVacio extends StatelessWidget {
  const _MensajeHistorialVacio();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
      ),
      child: const Text(
        'Todavía no hay suficientes lecturas en este periodo para graficar la variable.',
        style: TextStyle(
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w700,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }
}

class _ResumenHistorialItem extends StatelessWidget {
  const _ResumenHistorialItem({
    required this.titulo,
    required this.valor,
    required this.unidad,
  });

  final String titulo;
  final String valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 9),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
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
            unidad.isEmpty ? valor : '$valor $unidad',
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 10.8,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _MiniGraficaVariablePainter extends CustomPainter {
  const _MiniGraficaVariablePainter({
    required this.puntos,
    required this.color,
    required this.unidad,
  });

  final List<double> puntos;
  final Color color;
  final String unidad;

  @override
  void paint(Canvas canvas, Size size) {
    final textPainter = TextPainter(textDirection: TextDirection.ltr);

    final labelWidth = 52.0;
    final bottomHeight = 20.0;
    final left = labelWidth;
    final top = 8.0;
    final right = size.width - 6;
    final bottom = size.height - bottomHeight;
    final chartWidth = right - left;
    final chartHeight = bottom - top;

    final borderPaint = Paint()
      ..color = AppColores.borde
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;

    final gridPaint = Paint()
      ..color = AppColores.borde.withOpacity(0.60)
      ..strokeWidth = 1;

    final axisPaint = Paint()
      ..color = AppColores.textoSecundario.withOpacity(0.32)
      ..strokeWidth = 1.2;

    final linePaint = Paint()
      ..color = color
      ..strokeWidth = 2.8
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..style = PaintingStyle.stroke;

    final pointPaint = Paint()
      ..color = color
      ..style = PaintingStyle.fill;

    final background = RRect.fromRectAndRadius(
      Rect.fromLTWH(0, 0, size.width, size.height),
      const Radius.circular(16),
    );

    canvas.drawRRect(background, borderPaint);

    if (puntos.isEmpty) return;

    final minValor = puntos.reduce((a, b) => a < b ? a : b);
    final maxValor = puntos.reduce((a, b) => a > b ? a : b);
    final rango = (maxValor - minValor).abs() < 0.0001 ? 1.0 : maxValor - minValor;
    final medio = minValor + rango / 2;

    void drawLabel(String texto, Offset offset, {TextAlign align = TextAlign.left}) {
      textPainter.text = TextSpan(
        text: texto,
        style: const TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w700,
          color: AppColores.textoSecundario,
        ),
      );
      textPainter.textAlign = align;
      textPainter.layout(maxWidth: labelWidth - 6);
      textPainter.paint(canvas, offset);
    }

    final etiquetas = [
      (_numero(maxValor), top - 3),
      (_numero(medio), top + chartHeight / 2 - 6),
      (_numero(minValor), bottom - 11),
    ];

    for (final etiqueta in etiquetas) {
      final texto = unidad.isEmpty ? etiqueta.$1 : '${etiqueta.$1} $unidad';
      drawLabel(texto, Offset(4, etiqueta.$2));
    }

    for (var i = 0; i <= 2; i++) {
      final y = top + chartHeight * i / 2;
      canvas.drawLine(Offset(left, y), Offset(right, y), gridPaint);
    }

    canvas.drawLine(Offset(left, top), Offset(left, bottom), axisPaint);
    canvas.drawLine(Offset(left, bottom), Offset(right, bottom), axisPaint);

    Offset puntoEnGrafica(int index, double valor) {
      final x = puntos.length == 1 ? left + chartWidth / 2 : left + index * chartWidth / (puntos.length - 1);
      final normalizado = (valor - minValor) / rango;
      final y = bottom - (normalizado * chartHeight);
      return Offset(x, y);
    }

    final path = Path();

    for (var i = 0; i < puntos.length; i++) {
      final punto = puntoEnGrafica(i, puntos[i]);
      if (i == 0) {
        path.moveTo(punto.dx, punto.dy);
      } else {
        path.lineTo(punto.dx, punto.dy);
      }
    }

    canvas.drawPath(path, linePaint);

    for (var i = 0; i < puntos.length; i++) {
      final punto = puntoEnGrafica(i, puntos[i]);
      canvas.drawCircle(punto, 3.2, pointPaint);
    }

    drawLabel('Inicio', Offset(left, size.height - 16));
    drawLabel('Fin', Offset(right - 24, size.height - 16));
  }

  @override
  bool shouldRepaint(covariant _MiniGraficaVariablePainter oldDelegate) {
    return oldDelegate.puntos != puntos ||
        oldDelegate.color != color ||
        oldDelegate.unidad != unidad;
  }
}

class _PuntoHistorialVariable {
  const _PuntoHistorialVariable({required this.fecha, required this.valor});

  final DateTime fecha;
  final double valor;
}

class _EstadisticasVariable {
  const _EstadisticasVariable({
    required this.minimo,
    required this.promedio,
    required this.maximo,
  });

  final double minimo;
  final double promedio;
  final double maximo;
}


class _DetallePlanNutricionalVariableCard extends StatelessWidget {
  const _DetallePlanNutricionalVariableCard({
    required this.detalle,
    required this.plan,
  });

  final _DetalleVariableData detalle;
  final PlanNutricionalNpk plan;

  @override
  Widget build(BuildContext context) {
    final nutriente = _nutrientePlanPorCodigo(plan, detalle.codigo);
    final necesidad = nutriente.faltanteFormaComercialMesKg;

    final fertilizantes = plan.fertilizantes
        .where(
          (fertilizante) =>
              fertilizante.kgPorMes > 0 &&
              fertilizante.nutrienteObjetivo == nutriente.nombreFormaComercial,
        )
        .toList();

    final fertilizante = fertilizantes.isNotEmpty ? fertilizantes.first : null;

    String descripcion;

    if (necesidad <= 0.001) {
      descripcion =
          'Con la lectura actual no se estima corrección mensual de ${nutriente.nombreFormaComercial}.';
    } else if (fertilizante == null) {
      descripcion =
          'Se requiere ${_numero(necesidad)} kg/mes de ${nutriente.nombreFormaComercial}, pero no hay fertilizante seleccionado que lo cubra.';
    } else {
      descripcion =
          'Producto sugerido: ${fertilizante.nombre}. Dosis estimada: ${_numero(fertilizante.kgPorMes)} kg/mes.';
    }

    return _DetalleCardBase(
      icono: Icons.eco_rounded,
      titulo: 'Plan nutricional relacionado',
      color: AppColores.primario,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _FilaDetallePlan(
            titulo: 'Necesidad estimada',
            valor: necesidad > 0.001 ? '${_numero(necesidad)} kg/mes' : 'No requiere',
          ),
          const SizedBox(height: 8),
          if (fertilizante != null) ...[
            _FilaDetallePlan(titulo: 'Fertilizante sugerido', valor: fertilizante.nombre),
            const SizedBox(height: 8),
            _FilaDetallePlan(titulo: 'Dosis', valor: '${_numero(fertilizante.kgPorMes)} kg/mes'),
            const SizedBox(height: 8),
          ],
          Text(
  descripcion,
  style: const TextStyle(
    fontSize: 13,
    height: 1.4,
    fontWeight: FontWeight.w600,
    color: AppColores.textoSecundario,
  ),
),

if (necesidad > 0.001 && fertilizante == null) ...[
  const SizedBox(height: 12),
  SizedBox(
    width: double.infinity,
    child: FilledButton.icon(
  onPressed: () {
    final router = GoRouter.of(context);

    Future.microtask(() {
      router.push(RutasApp.fertilizantesDisponibles);
    });
  },
  icon: const Icon(Icons.playlist_add_check_rounded),
  label: const Text('Seleccionar fertilizantes'),
),
  ),
],
        ],
      ),
    );
  }

  NutrientePlanNpk _nutrientePlanPorCodigo(PlanNutricionalNpk plan, String codigo) {
    if (codigo == 'N') return plan.nitrogeno;
    if (codigo == 'P₂O₅') return plan.fosforo;
    return plan.potasio;
  }
}

class _DetalleCargandoPlanCard extends StatelessWidget {
  const _DetalleCargandoPlanCard();

  @override
  Widget build(BuildContext context) {
    return const _DetalleCardBase(
      icono: Icons.eco_rounded,
      titulo: 'Plan nutricional relacionado',
      color: AppColores.primario,
      child: Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: LinearProgressIndicator(),
      ),
    );
  }
}

class _DetallePlanErrorCard extends StatelessWidget {
  const _DetallePlanErrorCard();

  @override
  Widget build(BuildContext context) {
    return const _DetalleCardBase(
      icono: Icons.eco_rounded,
      titulo: 'Plan nutricional relacionado',
      color: AppColores.advertencia,
      child: Text(
        'No se pudo cargar el plan nutricional en este momento.',
        style: TextStyle(
          fontSize: 13,
          height: 1.4,
          fontWeight: FontWeight.w600,
          color: AppColores.textoSecundario,
        ),
      ),
    );
  }
}


class _DetalleAccionesCard extends StatelessWidget {
  const _DetalleAccionesCard({required this.detalle});

  final _DetalleVariableData detalle;

  @override
  Widget build(BuildContext context) {
    return _DetalleCardBase(
      icono: Icons.touch_app_rounded,
      titulo: 'Acciones',
      color: AppColores.primario,
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(RutasApp.historial);
                  },
                  icon: const Icon(Icons.history_rounded),
                  label: const Text('Historial'),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    context.go(RutasApp.recomendaciones);
                  },
                  icon: const Icon(Icons.recommend_rounded),
                  label: const Text('Recom.'),
                ),
              ),
            ],
          ),
          if (detalle.esNpk) ...[
            const SizedBox(height: 10),
            SizedBox(
              width: double.infinity,
              child: FilledButton.icon(
                onPressed: () {
                  Navigator.of(context).pop();
                  context.go(RutasApp.planNutricionalNpk);
                },
                icon: const Icon(Icons.eco_rounded),
                label: const Text('Ver plan nutricional'),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _DetalleCardBase extends StatelessWidget {
  const _DetalleCardBase({
    required this.icono,
    required this.titulo,
    required this.color,
    required this.child,
  });

  final IconData icono;
  final String titulo;
  final Color color;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.superficie,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(22),
        side: BorderSide(
          color: color.withOpacity(0.22),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(14, 14, 14, 15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.10),
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: color.withOpacity(0.24),
                    ),
                  ),
                  child: Icon(
                    icono,
                    color: color,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    titulo,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            child,
          ],
        ),
      ),
    );
  }
}

class _FilaDetallePlan extends StatelessWidget {
  const _FilaDetallePlan({required this.titulo, required this.valor});

  final String titulo;
  final String valor;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(13),
        border: Border.all(color: AppColores.borde),
      ),
      child: Row(
        children: [
          Expanded(
            child: Text(
              titulo,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Flexible(
            child: Text(
              valor,
              textAlign: TextAlign.end,
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


class _DetalleVariableData {
  const _DetalleVariableData({
    required this.codigo,
    required this.titulo,
    required this.valor,
    required this.valorNumerico,
    required this.unidad,
    required this.icono,
    required this.estado,
    required this.color,
    required this.interpretacion,
    required this.recomendacion,
    required this.esNpk,
  });

  final String codigo;
  final String titulo;
  final String valor;
  final double valorNumerico;
  final String unidad;
  final IconData icono;
  final String estado;
  final Color color;
  final String interpretacion;
  final String recomendacion;
  final bool esNpk;
}

_DetalleVariableData _detalleHumedad(double valor) {
  if (valor < 35) {
    return _crearDetalleBase(
      codigo: 'humedad',
      titulo: 'Humedad de suelo',
      valor: valor,
      unidad: '%',
      icono: Icons.water_drop_rounded,
      estado: 'Muy baja',
      color: AppColores.prioridadAlta,
      interpretacion: 'La humedad está muy baja para el cultivo.',
      recomendacion: 'Revise riego de inmediato y confirme la tendencia en el historial.',
    );
  }

  if (valor < 45) {
    return _crearDetalleBase(
      codigo: 'humedad',
      titulo: 'Humedad de suelo',
      valor: valor,
      unidad: '%',
      icono: Icons.water_drop_rounded,
      estado: 'Baja',
      color: AppColores.prioridadMedia,
      interpretacion: 'La humedad está por debajo del rango esperado.',
      recomendacion: 'Revise frecuencia de riego y observe si continúa bajando.',
    );
  }

  if (valor <= 65) {
    return _crearDetalleBase(
      codigo: 'humedad',
      titulo: 'Humedad de suelo',
      valor: valor,
      unidad: '%',
      icono: Icons.water_drop_rounded,
      estado: 'Adecuada',
      color: AppColores.primario,
      interpretacion: 'La humedad está dentro del rango esperado.',
      recomendacion: 'Mantenga seguimiento en el historial.',
    );
  }

  if (valor <= 75) {
    return _crearDetalleBase(
      codigo: 'humedad',
      titulo: 'Humedad de suelo',
      valor: valor,
      unidad: '%',
      icono: Icons.water_drop_rounded,
      estado: 'Alta',
      color: AppColores.prioridadMedia,
      interpretacion: 'La humedad está por encima del rango esperado.',
      recomendacion: 'Revise drenaje y frecuencia de riego.',
    );
  }

  return _crearDetalleBase(
    codigo: 'humedad',
    titulo: 'Humedad de suelo',
    valor: valor,
    unidad: '%',
    icono: Icons.water_drop_rounded,
    estado: 'Suelo saturado',
    color: AppColores.prioridadAlta,
    interpretacion: 'La humedad está muy alta y puede indicar saturación del suelo.',
    recomendacion:
        'Suspender riego. Posible lavado de nutrientes. Favorece incidencia de enfermedades.',
  );
}

_DetalleVariableData _detalleTemperatura(double valor) {
  if (valor < 8) {
    return _crearDetalleBase(
      codigo: 'temperatura',
      titulo: 'Temperatura del suelo',
      valor: valor,
      unidad: '°C',
      icono: Icons.thermostat_rounded,
      estado: 'Muy baja',
      color: AppColores.prioridadAlta,
      interpretacion:
          'La temperatura está por debajo del rango nocturno ideal indicado para fresa.',
      recomendacion:
          'Monitoree el lote, evite riegos excesivos en horas frías y revise si se requiere protección del cultivo.',
    );
  }

  if (valor <= 10) {
    return _crearDetalleBase(
      codigo: 'temperatura',
      titulo: 'Temperatura del suelo',
      valor: valor,
      unidad: '°C',
      icono: Icons.thermostat_rounded,
      estado: 'Adecuada noche',
      color: AppColores.primario,
      interpretacion:
          'La temperatura está dentro del rango nocturno ideal indicado por el asesor para fresa.',
      recomendacion:
          'Mantenga seguimiento normal. Si esta lectura ocurre durante el día, compárela con el historial.',
    );
  }

  if (valor < 15) {
    return _crearDetalleBase(
      codigo: 'temperatura',
      titulo: 'Temperatura del suelo',
      valor: valor,
      unidad: '°C',
      icono: Icons.thermostat_rounded,
      estado: 'Baja',
      color: AppColores.prioridadMedia,
      interpretacion:
          'La temperatura está baja para el rango diurno ideal del cultivo.',
      recomendacion:
          'Compare la lectura con la hora del día y revise humedad e historial antes de actuar.',
    );
  }

  if (valor <= 25) {
    return _crearDetalleBase(
      codigo: 'temperatura',
      titulo: 'Temperatura del suelo',
      valor: valor,
      unidad: '°C',
      icono: Icons.thermostat_rounded,
      estado: valor <= 18 ? 'Ideal día' : 'Adecuada',
      color: AppColores.primario,
      interpretacion:
          valor <= 18 ? 'La temperatura está dentro del rango diurno ideal indicado por el asesor.' : 'La temperatura está dentro del rango operativo aceptable de la app.',
      recomendacion: 'Mantenga seguimiento normal.',
    );
  }

  if (valor <= 30) {
    return _crearDetalleBase(
      codigo: 'temperatura',
      titulo: 'Temperatura del suelo',
      valor: valor,
      unidad: '°C',
      icono: Icons.thermostat_rounded,
      estado: 'Alta',
      color: AppColores.prioridadMedia,
      interpretacion:
          'La temperatura está alta y puede aumentar evaporación y estrés del cultivo.',
      recomendacion:
          'Revise humedad, riego, cobertura, acolchado o sombreo.',
    );
  }

  return _crearDetalleBase(
    codigo: 'temperatura',
    titulo: 'Temperatura del suelo',
    valor: valor,
    unidad: '°C',
    icono: Icons.thermostat_rounded,
    estado: 'Muy alta',
    color: AppColores.prioridadAlta,
    interpretacion:
        'La temperatura está muy alta y puede generar estrés térmico.',
    recomendacion:
        'Priorice la revisión de riego, humedad, cobertura y ventilación o sombreo.',
  );
}

_DetalleVariableData _detallePh(double valor) {
  if (valor < 5.2) {
    return _crearDetalleBase(
      codigo: 'ph',
      titulo: 'pH del suelo',
      valor: valor,
      unidad: '',
      icono: Icons.science_rounded,
      estado: 'Muy ácido',
      color: AppColores.prioridadAlta,
      interpretacion: 'El pH está muy bajo y puede afectar la disponibilidad de nutrientes.',
      recomendacion: 'Revise recomendaciones y valide con asesor técnico antes de corregir.',
    );
  }

  if (valor < 5.7) {
    return _crearDetalleBase(
      codigo: 'ph',
      titulo: 'pH del suelo',
      valor: valor,
      unidad: '',
      icono: Icons.science_rounded,
      estado: 'Ácido',
      color: AppColores.prioridadMedia,
      interpretacion: 'El pH está por debajo del rango recomendado.',
      recomendacion: 'Revise tendencia e impacto en el plan nutricional.',
    );
  }

  if (valor <= 6.5) {
    return _crearDetalleBase(
      codigo: 'ph',
      titulo: 'pH del suelo',
      valor: valor,
      unidad: '',
      icono: Icons.science_rounded,
      estado: 'Adecuado',
      color: AppColores.primario,
      interpretacion: 'El pH está dentro del rango recomendado.',
      recomendacion: 'Mantenga seguimiento porque influye en la nutrición.',
    );
  }

  if (valor <= 7.0) {
    return _crearDetalleBase(
      codigo: 'ph',
      titulo: 'pH del suelo',
      valor: valor,
      unidad: '',
      icono: Icons.science_rounded,
      estado: 'Alto',
      color: AppColores.prioridadMedia,
      interpretacion: 'El pH está por encima del rango recomendado.',
      recomendacion: 'Revise tendencia y recomendaciones antes de corregir.',
    );
  }

  return _crearDetalleBase(
    codigo: 'ph',
    titulo: 'pH del suelo',
    valor: valor,
    unidad: '',
    icono: Icons.science_rounded,
    estado: 'Muy alto',
    color: AppColores.prioridadAlta,
    interpretacion: 'El pH está muy alto y puede limitar la absorción de nutrientes.',
    recomendacion: 'Valide con asesor técnico y revise manejo del suelo.',
  );
}

_DetalleVariableData _detalleEc(double valor) {
  final ec = RangosAgronomicos.normalizarEcADsM(valor);

  if (ec < 0) {
    return _crearDetalleBase(
      codigo: 'ec',
      titulo: 'Conductividad eléctrica',
      valor: ec,
      unidad: 'dS/m',
      icono: Icons.bolt_rounded,
      estado: 'Inválida',
      color: AppColores.prioridadAlta,
      interpretacion:
          'La EC no debería ser negativa. Puede existir error de lectura o conversión.',
      recomendacion:
          'Revise el JSON, la lectura Modbus y la conversión antes de tomar decisiones agronómicas.',
    );
  }

  if (ec == 0) {
    return _crearDetalleBase(
      codigo: 'ec',
      titulo: 'Conductividad eléctrica',
      valor: ec,
      unidad: 'dS/m',
      icono: Icons.bolt_rounded,
      estado: 'Verificar',
      color: AppColores.prioridadMedia,
      interpretacion:
          'La EC está en cero. Puede ser una lectura no representativa o falta de contacto del sensor.',
      recomendacion:
          'Verifique sensor, humedad del suelo, conexión y espere una nueva lectura.',
    );
  }

  if (ec < 0.8) {
    return _crearDetalleBase(
      codigo: 'ec',
      titulo: 'Conductividad eléctrica',
      valor: ec,
      unidad: 'dS/m',
      icono: Icons.bolt_rounded,
      estado: 'Baja',
      color: AppColores.prioridadMedia,
      interpretacion:
          'La EC está por debajo del rango normal de 0.8 a 1.8 dS/m.',
      recomendacion:
          'Revise plan nutricional, NPK y tendencia histórica antes de aumentar fertilización.',
    );
  }

  if (ec <= 1.8) {
    return _crearDetalleBase(
      codigo: 'ec',
      titulo: 'Conductividad eléctrica',
      valor: ec,
      unidad: 'dS/m',
      icono: Icons.bolt_rounded,
      estado: 'Adecuada',
      color: AppColores.primario,
      interpretacion:
          'La EC está dentro del rango normal indicado por el asesor para fresa.',
      recomendacion: 'Mantenga seguimiento normal.',
    );
  }

  if (ec <= 2.0) {
    return _crearDetalleBase(
      codigo: 'ec',
      titulo: 'Conductividad eléctrica',
      valor: ec,
      unidad: 'dS/m',
      icono: Icons.bolt_rounded,
      estado: 'Cercana al límite',
      color: AppColores.prioridadMedia,
      interpretacion:
          'La EC supera el rango normal y se acerca al límite de 2.0 dS/m.',
      recomendacion:
          'Evite aumentar fertilización salina y revise calidad del agua, fertirriego y tendencia.',
    );
  }

  return _crearDetalleBase(
    codigo: 'ec',
    titulo: 'Conductividad eléctrica',
    valor: ec,
    unidad: 'dS/m',
    icono: Icons.bolt_rounded,
    estado: 'Riesgo salino',
    color: AppColores.prioridadAlta,
    interpretacion:
        'La EC supera 2.0 dS/m. Hay riesgo de salinidad para el cultivo.',
    recomendacion:
        'Suspenda aumentos de fertilización, revise fertirriego, calidad del agua, drenaje y posible lavado de sales con asesoría técnica.',
  );
}

_DetalleVariableData _detalleNutrienteNpk({
  required String codigo,
  required String nombre,
  required double valor,
  required IconData icono,
  double? necesidadPlanKg,
}) {
  final config = _clasificarNutrienteNpk(
    codigo,
    valor,
    necesidadPlanKg: necesidadPlanKg,
  );

  return _DetalleVariableData(
    codigo: codigo,
    titulo: nombre,
    valor: _numero(valor),
    valorNumerico: valor,
    unidad: 'mg/kg',
    icono: icono,
    estado: config.estado,
    color: config.color,
    interpretacion: config.interpretacion,
    recomendacion: config.recomendacion,
    esNpk: true,
  );
}

_DetalleVariableData _crearDetalleBase({
  required String codigo,
  required String titulo,
  required double valor,
  required String unidad,
  required IconData icono,
  required String estado,
  required Color color,
  required String interpretacion,
  required String recomendacion,
}) {
  return _DetalleVariableData(
    codigo: codigo,
    titulo: titulo,
    valor: _numero(valor),
    valorNumerico: valor,
    unidad: unidad,
    icono: icono,
    estado: estado,
    color: color,
    interpretacion: interpretacion,
    recomendacion: recomendacion,
    esNpk: false,
  );
}

class _ClasificacionVariable {
  const _ClasificacionVariable({
    required this.estado,
    required this.color,
    required this.interpretacion,
    required this.recomendacion,
  });

  final String estado;
  final Color color;
  final String interpretacion;
  final String recomendacion;
}

_ClasificacionVariable _clasificarNutrienteNpk(
  String codigo,
  double valor, {
  double? necesidadPlanKg,
}) {
  // IMPORTANTE:
  // Las tarjetas NPK se colorean únicamente con el rango técnico del sensor.
  // El plan nutricional puede calcular dosis de mantenimiento, pero no debe
  // volver naranja una tarjeta cuando N, P o K están dentro del rango del asesor.

  if (codigo == 'N') {
    if (valor <= 0) {
      return const _ClasificacionVariable(
        estado: 'Verificar',
        color: AppColores.prioridadMedia,
        interpretacion: 'El nitrógeno aparece en cero o con una lectura no representativa.',
        recomendacion: 'Verifique la instalación del sensor antes de interpretar deficiencia de N.',
      );
    }
    if (valor < 50) {
      return const _ClasificacionVariable(
        estado: 'Muy bajo',
        color: AppColores.prioridadAlta,
        interpretacion: 'El nitrógeno está muy bajo frente al rango de referencia 72–129 mg/kg.',
        recomendacion: 'Revise el plan nutricional, humedad, pH y CE antes de corregir N.',
      );
    }
    if (valor < 72) {
      return const _ClasificacionVariable(
        estado: 'Bajo',
        color: AppColores.prioridadMedia,
        interpretacion: 'El nitrógeno está por debajo del rango recomendado por el asesor.',
        recomendacion: 'Revise la necesidad de N en el plan nutricional y valide con las demás variables.',
      );
    }
    if (valor <= 129) {
      return const _ClasificacionVariable(
        estado: 'Adecuado',
        color: AppColores.primario,
        interpretacion: 'El nitrógeno está dentro del rango técnico recomendado para fresa.',
        recomendacion: 'Mantenga seguimiento. Una dosis de mantenimiento, si aparece, se interpreta en el plan nutricional.',
      );
    }
    if (valor <= 160) {
      return const _ClasificacionVariable(
        estado: 'Alto',
        color: AppColores.prioridadMedia,
        interpretacion: 'El nitrógeno está por encima del rango recomendado.',
        recomendacion: 'Evite aumentar aportes nitrogenados y revise CE e historial.',
      );
    }
    return const _ClasificacionVariable(
      estado: 'Muy alto',
      color: AppColores.prioridadAlta,
      interpretacion: 'El nitrógeno está muy alto y puede desbalancear el cultivo.',
      recomendacion: 'No aplique más N sin validación técnica y revise el plan de fertilización.',
    );
  }

  if (codigo == 'P₂O₅') {
    if (valor <= 0) {
      return const _ClasificacionVariable(
        estado: 'Verificar',
        color: AppColores.prioridadMedia,
        interpretacion: 'El fósforo aparece en cero o con una lectura no representativa.',
        recomendacion: 'Verifique la instalación del sensor antes de interpretar deficiencia de P.',
      );
    }
    if (valor < 10) {
      return const _ClasificacionVariable(
        estado: 'Muy bajo',
        color: AppColores.prioridadAlta,
        interpretacion: 'El fósforo está muy bajo frente al rango de referencia 20–40 mg/kg.',
        recomendacion: 'Revise el plan nutricional, pH y disponibilidad de una fuente fosfatada.',
      );
    }
    if (valor < 20) {
      return const _ClasificacionVariable(
        estado: 'Bajo',
        color: AppColores.prioridadMedia,
        interpretacion: 'El fósforo está por debajo del rango recomendado por el asesor.',
        recomendacion: 'Revise la necesidad como P₂O₅ en el plan nutricional.',
      );
    }
    if (valor <= 40) {
      return const _ClasificacionVariable(
        estado: 'Adecuado',
        color: AppColores.primario,
        interpretacion: 'El fósforo está dentro del rango técnico recomendado para fresa.',
        recomendacion: 'Mantenga seguimiento. El cálculo de dosis se revisa en el plan nutricional.',
      );
    }
    if (valor <= 60) {
      return const _ClasificacionVariable(
        estado: 'Alto',
        color: AppColores.prioridadMedia,
        interpretacion: 'El fósforo está por encima del rango recomendado.',
        recomendacion: 'Evite aumentar fuentes fosfatadas y revise pH, CE e historial.',
      );
    }
    return const _ClasificacionVariable(
      estado: 'Muy alto',
      color: AppColores.prioridadAlta,
      interpretacion: 'El fósforo está muy alto y puede generar desbalances nutricionales.',
      recomendacion: 'No aplique más P sin validación técnica y revise el plan de fertilización.',
    );
  }

  if (valor <= 0) {
    return const _ClasificacionVariable(
      estado: 'Verificar',
      color: AppColores.prioridadMedia,
      interpretacion: 'El potasio aparece en cero o con una lectura no representativa.',
      recomendacion: 'Verifique la instalación del sensor antes de interpretar deficiencia de K.',
    );
  }
  if (valor < 50) {
    return const _ClasificacionVariable(
      estado: 'Muy bajo',
      color: AppColores.prioridadAlta,
      interpretacion: 'El potasio está muy bajo frente al rango de referencia 82–160 mg/kg como K.',
      recomendacion: 'Revise el plan nutricional y disponibilidad de una fuente de K.',
    );
  }
  if (valor < 82) {
    return const _ClasificacionVariable(
      estado: 'Bajo',
      color: AppColores.prioridadMedia,
      interpretacion: 'El potasio está por debajo del rango recomendado por el asesor.',
      recomendacion: 'Revise la necesidad como K₂O en el plan nutricional.',
    );
  }
  if (valor <= 160) {
    return const _ClasificacionVariable(
      estado: 'Adecuado',
      color: AppColores.primario,
      interpretacion: 'El potasio está dentro del rango técnico recomendado para fresa.',
      recomendacion: 'Mantenga seguimiento por su relación con llenado, calidad de fruto y resistencia de planta.',
    );
  }
  if (valor <= 220) {
    return const _ClasificacionVariable(
      estado: 'Alto',
      color: AppColores.prioridadMedia,
      interpretacion: 'El potasio está por encima del rango recomendado.',
      recomendacion: 'Evite aumentar fuentes potásicas y revise balance nutricional.',
    );
  }
  return const _ClasificacionVariable(
    estado: 'Muy alto',
    color: AppColores.prioridadAlta,
    interpretacion: 'El potasio está muy alto y puede causar desbalance con otros nutrientes.',
    recomendacion: 'No aplique más K sin validación técnica y revise CE, historial y plan de fertilización.',
  );
}


List<_PuntoHistorialVariable> _filtrarPuntos(
  List<LecturaHistorial> lecturas,
  String codigo,
  _PeriodoHistorialVariable periodo,
) {
  final ahora = DateTime.now();

  final filtradas = lecturas.where((lectura) {
    if (periodo == _PeriodoHistorialVariable.todo) return true;
    final diferencia = ahora.difference(lectura.fechaLectura);
    if (periodo == _PeriodoHistorialVariable.semana) return diferencia.inDays <= 7;
    return diferencia.inDays <= 30;
  }).toList()
    ..sort((a, b) => a.fechaLectura.compareTo(b.fechaLectura));

  final puntos = filtradas
      .map((lectura) => _PuntoHistorialVariable(
            fecha: lectura.fechaLectura,
            valor: _valorVariableHistorial(lectura, codigo),
          ))
      .where((punto) => punto.valor.isFinite)
      .toList();

  if (puntos.length <= 30) return puntos;

  final salto = (puntos.length / 30).ceil();
  final reducidos = <_PuntoHistorialVariable>[];

  for (var i = 0; i < puntos.length; i += salto) {
    reducidos.add(puntos[i]);
  }

  if (reducidos.last.fecha != puntos.last.fecha) {
    reducidos.add(puntos.last);
  }

  return reducidos;
}

double _valorVariableHistorial(LecturaHistorial lectura, String codigo) {
  switch (codigo) {
    case 'humedad':
      return lectura.humedad;
    case 'temperatura':
      return lectura.temperatura;
    case 'ph':
      return lectura.ph;
    case 'ec':
      return lectura.ec;
    case 'N':
      return lectura.nitrogeno;
    case 'P₂O₅':
      return lectura.fosforo;
    case 'K₂O':
      return lectura.potasio;
    default:
      return 0;
  }
}

_EstadisticasVariable _estadisticasPuntos(List<_PuntoHistorialVariable> puntos) {
  final valores = puntos.map((punto) => punto.valor).toList();
  final minimo = valores.reduce((a, b) => a < b ? a : b);
  final maximo = valores.reduce((a, b) => a > b ? a : b);
  final promedio = valores.reduce((a, b) => a + b) / valores.length;

  return _EstadisticasVariable(
    minimo: minimo,
    promedio: promedio,
    maximo: maximo,
  );
}

String _mensajeTendencia({
  required String codigo,
  required List<_PuntoHistorialVariable> puntos,
}) {
  if (puntos.length < 2) {
    return 'Agregue más lecturas para ver la tendencia de esta variable.';
  }

  final primero = puntos.first.valor;
  final ultimo = puntos.last.valor;
  final diferencia = ultimo - primero;

  if (diferencia.abs() < 0.01) {
    return 'La variable se ha mantenido estable en el periodo seleccionado.';
  }

  final nombre = _nombreCortoVariable(codigo);

  if (diferencia > 0) {
    return '$nombre muestra una tendencia al aumento en el periodo seleccionado.';
  }

  return '$nombre muestra una tendencia a la disminución en el periodo seleccionado.';
}

String _nombreCortoVariable(String codigo) {
  switch (codigo) {
    case 'humedad':
      return 'La humedad';
    case 'temperatura':
      return 'La temperatura';
    case 'ph':
      return 'El pH';
    case 'ec':
      return 'La EC';
    case 'N':
      return 'El nitrógeno';
    case 'P₂O₅':
      return 'El fósforo';
    case 'K₂O':
      return 'El potasio';
    default:
      return 'La variable';
  }
}

DatosSensorSuelo _convertirHistorialADatosSensor(LecturaHistorial lectura) {
  return DatosSensorSuelo(
    humedadSuelo: lectura.humedad,
    temperaturaSuelo: lectura.temperatura,
    conductividadElectrica: lectura.ec,
    phSuelo: lectura.ph,
    nitrogeno: lectura.nitrogeno,
    fosforo: lectura.fosforo,
    potasio: lectura.potasio,
    fechaLectura: lectura.fechaLectura,
  );
}


String _numero(double valor) {
  if (valor.abs() >= 1000000) return valor.toStringAsFixed(0);
  if (valor.abs() >= 1000) return valor.toStringAsFixed(0);
  if (valor.abs() >= 100) return valor.toStringAsFixed(1);
  return valor.toStringAsFixed(2);
}

String _fechaCorta(DateTime fecha) {
  final local = fecha.toLocal();
  final dia = local.day.toString().padLeft(2, '0');
  final mes = local.month.toString().padLeft(2, '0');
  final anio = local.year.toString();
  final hora = local.hour.toString().padLeft(2, '0');
  final minuto = local.minute.toString().padLeft(2, '0');
  return '$dia/$mes/$anio $hora:$minuto';
}


class _ResumenRapidoRecomendacionesCard extends ConsumerWidget {
  const _ResumenRapidoRecomendacionesCard();

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final recomendacionesAsync = ref.watch(recomendacionesAsyncProvider);

    return recomendacionesAsync.when(
      loading: () => const SizedBox.shrink(),
      error: (_, __) => const SizedBox.shrink(),
      data: (recomendaciones) {
        if (recomendaciones.isEmpty) {
          return Card(
            elevation: 0,
            color: AppColores.primariosuave,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(22),
              side: BorderSide(color: AppColores.primario.withOpacity(0.22)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Row(
                children: [
                  Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      color: AppColores.primario.withOpacity(0.12),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Icon(Icons.check_circle_rounded, color: AppColores.primario),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Sin alertas activas',
                          style: TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w900,
                            color: AppColores.textoPrincipal,
                          ),
                        ),
                        SizedBox(height: 4),
                        Text(
                          'Las variables actuales no generan recomendaciones importantes.',
                          style: TextStyle(
                            fontSize: 12.5,
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

        final ordenadas = [...recomendaciones]
          ..sort((a, b) => a.prioridad.compareTo(b.prioridad));

        final principal = ordenadas.first;
        final total = ordenadas.length;
        final altas = recomendaciones.where((r) => r.prioridad == 1).length;
        final medias = recomendaciones.where((r) => r.prioridad == 2).length;
        final bajas = recomendaciones.where((r) => r.prioridad == 3).length;
        final color = _colorPrioridadResumen(principal.prioridad);
        final textoPrioridad = _textoPrioridadResumen(principal.prioridad);

        return Card(
          elevation: 0,
          color: AppColores.superficie,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(22),
            side: BorderSide(color: color.withOpacity(0.24)),
          ),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: color.withOpacity(0.12),
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(Icons.tips_and_updates_rounded, color: color),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Resumen rápido',
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w900,
                              color: AppColores.textoPrincipal,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '$total recomendación${total == 1 ? '' : 'es'} activa${total == 1 ? '' : 's'}',
                            style: const TextStyle(
                              fontSize: 12.5,
                              height: 1.35,
                              fontWeight: FontWeight.w600,
                              color: AppColores.textoSecundario,
                            ),
                          ),
                        ],
                      ),
                    ),
                    _BadgePrioridadResumen(texto: textoPrioridad, color: color),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(child: _PrioridadResumenItem(titulo: 'Alta', cantidad: altas, color: AppColores.prioridadAlta)),
                    const SizedBox(width: 8),
                    Expanded(child: _PrioridadResumenItem(titulo: 'Media', cantidad: medias, color: AppColores.prioridadMedia)),
                    const SizedBox(width: 8),
                    Expanded(child: _PrioridadResumenItem(titulo: 'Baja', cantidad: bajas, color: AppColores.prioridadBaja)),
                  ],
                ),
                const SizedBox(height: 14),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.08),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: color.withOpacity(0.16)),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Principal',
                        style: TextStyle(
                          fontSize: 10.8,
                          fontWeight: FontWeight.w800,
                          color: AppColores.textoSecundario,
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        principal.titulo,
                        style: const TextStyle(
                          fontSize: 13.5,
                          fontWeight: FontWeight.w900,
                          color: AppColores.textoPrincipal,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: () => context.go(RutasApp.recomendaciones),
                    icon: const Icon(Icons.open_in_new_rounded),
                    label: const Text('Ver recomendaciones'),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Color _colorPrioridadResumen(int prioridad) {
    if (prioridad == 1) return AppColores.prioridadAlta;
    if (prioridad == 2) return AppColores.prioridadMedia;
    return AppColores.prioridadBaja;
  }

  String _textoPrioridadResumen(int prioridad) {
    if (prioridad == 1) return 'Alta';
    if (prioridad == 2) return 'Media';
    return 'Baja';
  }
}

class _PrioridadResumenItem extends StatelessWidget {
  const _PrioridadResumenItem({
    required this.titulo,
    required this.cantidad,
    required this.color,
  });

  final String titulo;
  final int cantidad;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(color: color.withOpacity(0.18)),
      ),
      child: Column(
        children: [
          Text(
            cantidad.toString(),
            style: TextStyle(fontSize: 17, fontWeight: FontWeight.w900, color: color),
          ),
          const SizedBox(height: 2),
          Text(
            titulo,
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w800, color: color),
          ),
        ],
      ),
    );
  }
}

class _BadgePrioridadResumen extends StatelessWidget {
  const _BadgePrioridadResumen({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: color.withOpacity(0.24)),
      ),
      child: Text(
        texto,
        style: TextStyle(fontSize: 11, fontWeight: FontWeight.w900, color: color),
      ),
    );
  }
}


class _LecturaDatosCard extends StatelessWidget {
  const _LecturaDatosCard({
    required this.onIniciar,
  });

  final VoidCallback onIniciar;

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 2),
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
      decoration: BoxDecoration(
        color: AppColores.superficie,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColores.borde.withOpacity(0.90),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 29,
            height: 29,
            decoration: BoxDecoration(
              color: AppColores.primariosuave,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Icon(
              Icons.sensors_rounded,
              color: AppColores.primario,
              size: 16,
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'Leer sensor',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                fontSize: 13.0,
                height: 1,
                fontWeight: FontWeight.w900,
                color: AppColores.textoPrincipal,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Material(
            color: AppColores.primario,
            borderRadius: BorderRadius.circular(999),
            child: InkWell(
              borderRadius: BorderRadius.circular(999),
              onTap: onIniciar,
              child: const Padding(
                padding: EdgeInsets.symmetric(horizontal: 11, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.play_arrow_rounded,
                      color: Colors.white,
                      size: 15,
                    ),
                    SizedBox(width: 3),
                    Text(
                      'Iniciar',
                      style: TextStyle(
                        color: Colors.white,
                        fontSize: 10.8,
                        height: 1,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _EncabezadoDatosLoteCard extends StatelessWidget {
  const _EncabezadoDatosLoteCard({
    required this.loteId,
    required this.loteNombre,
    required this.numeroPlantas,
    required this.usandoPromedioUsb,
    required this.cantidadPlantas,
    required this.cargandoLectura,
    required this.onSeleccionarLote,
    required this.onVolverSensor,
  });

  final String loteId;
  final String loteNombre;
  final int numeroPlantas;
  final bool usandoPromedioUsb;
  final int cantidadPlantas;
  final bool cargandoLectura;
  final VoidCallback onSeleccionarLote;
  final VoidCallback? onVolverSensor;

  @override
  Widget build(BuildContext context) {
    final plantasTexto = numeroPlantas > 0
        ? '$numeroPlantas plantas'
        : 'Plantas sin definir';

    final estadoTexto = usandoPromedioUsb
        ? '$cantidadPlantas medidas'
        : cargandoLectura
            ? 'Cargando...'
            : 'Cambiar lote';

    return Row(
      children: [
        Expanded(
          child: Material(
            color: Colors.transparent,
            child: InkWell(
              borderRadius: BorderRadius.circular(18),
              onTap: onSeleccionarLote,
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 7),
                decoration: BoxDecoration(
                  color: AppColores.superficie,
                  borderRadius: BorderRadius.circular(18),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.18),
                  ),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 31,
                      height: 31,
                      decoration: BoxDecoration(
                        color: AppColores.primariosuave,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(
                        Icons.eco_rounded,
                        color: AppColores.primario,
                        size: 16,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Text(
                            'Lote seleccionado',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 10.3,
                              height: 1,
                              fontWeight: FontWeight.w800,
                              color: AppColores.textoSecundario,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Row(
                            children: [
                              Flexible(
                                child: Text(
                                  loteNombre,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 13.1,
                                    height: 1,
                                    fontWeight: FontWeight.w900,
                                    color: AppColores.textoPrincipal,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 7),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 3.5,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColores.primariosuave,
                                  borderRadius: BorderRadius.circular(999),
                                  border: Border.all(
                                    color: AppColores.primario.withOpacity(0.12),
                                  ),
                                ),
                                child: Text(
                                  plantasTexto,
                                  maxLines: 1,
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 10.2,
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
                    const SizedBox(width: 8),
                    Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          estadoTexto,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 10.5,
                            height: 1,
                            fontWeight: FontWeight.w800,
                            color: AppColores.textoSecundario,
                          ),
                        ),
                        const SizedBox(height: 1),
                        const Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppColores.primario,
                          size: 19,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
        if (onVolverSensor != null) ...[
          const SizedBox(width: 8),
          TextButton(
            onPressed: onVolverSensor,
            style: TextButton.styleFrom(
              visualDensity: VisualDensity.compact,
              padding: const EdgeInsets.symmetric(horizontal: 9),
              minimumSize: const Size(0, 32),
              tapTargetSize: MaterialTapTargetSize.shrinkWrap,
            ),
            child: const Text(
              'Sensor',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _PromedioManualActivoCard extends StatelessWidget {
  const _PromedioManualActivoCard({
    required this.loteId,
    required this.cantidadPlantas,
    required this.onVolverSensor,
  });

  final String loteId;
  final int cantidadPlantas;
  final VoidCallback onVolverSensor;

  @override
  Widget build(BuildContext context) {
    return Card(
      elevation: 0,
      color: AppColores.primariosuave,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: AppColores.primario.withOpacity(0.20),
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Icon(
              Icons.check_circle_outline_rounded,
              color: AppColores.primario,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                'Mostrando promedio de ${_nombreLote(loteId)} con $cantidadPlantas plantas medidas.',
                style: const TextStyle(
                  fontSize: 13,
                  height: 1.35,
                  fontWeight: FontWeight.w800,
                  color: AppColores.textoPrincipal,
                ),
              ),
            ),
            TextButton(
              onPressed: onVolverSensor,
              child: const Text('Sensor'),
            ),
          ],
        ),
      ),
    );
  }
}


Future<String?> _mostrarSelectorLoteMediciones(
  BuildContext context,
  String loteActual,
) {
  return showModalBottomSheet<String>(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (modalContext) {
      return SafeArea(
        child: Container(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
          decoration: const BoxDecoration(
            color: AppColores.superficie,
            borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
              const Text(
                'Mostrar datos del lote',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColores.textoPrincipal,
                ),
              ),
              const SizedBox(height: 12),
              _OpcionLoteMediciones(
                texto: 'Lote 1',
                loteId: 'lote_1',
                seleccionado: loteActual == 'lote_1',
              ),
              _OpcionLoteMediciones(
                texto: 'Lote 2',
                loteId: 'lote_2',
                seleccionado: loteActual == 'lote_2',
              ),
              _OpcionLoteMediciones(
                texto: 'Lote 3',
                loteId: 'lote_3',
                seleccionado: loteActual == 'lote_3',
              ),
            ],
          ),
        ),
      );
    },
  );
}

class _OpcionLoteMediciones extends StatelessWidget {
  const _OpcionLoteMediciones({
    required this.texto,
    required this.loteId,
    required this.seleccionado,
  });

  final String texto;
  final String loteId;
  final bool seleccionado;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Material(
        color: seleccionado
            ? AppColores.primariosuave.withOpacity(0.80)
            : AppColores.fondo,
        borderRadius: BorderRadius.circular(15),
        child: InkWell(
          borderRadius: BorderRadius.circular(15),
          onTap: () => Navigator.of(context).pop(loteId),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(15),
              border: Border.all(
                color: seleccionado
                    ? AppColores.primario.withOpacity(0.22)
                    : AppColores.borde,
              ),
            ),
            child: Row(
              children: [
                Icon(
                  seleccionado
                      ? Icons.check_circle_rounded
                      : Icons.place_outlined,
                  color: seleccionado
                      ? AppColores.primario
                      : AppColores.textoSecundario,
                  size: 21,
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    texto,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w900,
                      color: AppColores.textoPrincipal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

Future<_ResultadoLecturaDatos?> _mostrarModalLecturaDatos(
  BuildContext context,
  DatosSensorSuelo lecturaBase,
  String loteInicial,
) {
  return showModalBottomSheet<_ResultadoLecturaDatos>(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (_) {
      return _ModalLecturaDatos(
        lecturaBase: lecturaBase,
        loteInicial: loteInicial,
      );
    },
  );
}

class _ModalLecturaDatos extends ConsumerStatefulWidget {
  const _ModalLecturaDatos({
    required this.lecturaBase,
    required this.loteInicial,
  });

  final DatosSensorSuelo lecturaBase;
  final String loteInicial;

  @override
  ConsumerState<_ModalLecturaDatos> createState() => _ModalLecturaDatosState();
}

class _ModalLecturaDatosState extends ConsumerState<_ModalLecturaDatos> {
  late String _loteSeleccionado;
  DatosSensorSuelo? _lecturaActual;
  String? _mensajeEstadoUsb;
  bool _leyendoUsb = false;
  final List<DatosSensorSuelo> _muestras = <DatosSensorSuelo>[];
  final SensorUsbRs485Datasource _usbDatasource = SensorUsbRs485Datasource();

  @override
  void initState() {
    super.initState();
    _loteSeleccionado = widget.loteInicial;
  }

  @override
  Widget build(BuildContext context) {
    final lotesAsync = ref.watch(lotesCultivoProvider);
    final lotes = lotesAsync.valueOrNull ?? <LoteCultivo>[
      LoteCultivo.loteInicial(),
    ];

    final loteExiste = lotes.any((lote) => lote.id == _loteSeleccionado);

    if (!loteExiste && lotes.isNotEmpty) {
      _loteSeleccionado = lotes.first.id;
    }

    final promedio = _muestras.isEmpty ? null : _calcularPromedio(_muestras);

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
          padding: const EdgeInsets.fromLTRB(18, 12, 18, 22),
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

              const SizedBox(height: 16),

              Row(
                children: [
                  const Expanded(
                    child: Text(
                      'Lectura de datos',
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                        color: AppColores.textoPrincipal,
                      ),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                  ),
                ],
              ),

              const SizedBox(height: 14),

              DropdownButtonFormField<String>(
                value: _loteSeleccionado,
                decoration: InputDecoration(
                  labelText: 'Lote',
                  filled: true,
                  fillColor: AppColores.fondo,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(14),
                  ),
                  contentPadding: const EdgeInsets.symmetric(
                    horizontal: 12,
                    vertical: 10,
                  ),
                ),
                items: lotes.map((lote) {
                  return DropdownMenuItem<String>(
                    value: lote.id,
                    child: Text(lote.nombre),
                  );
                }).toList(),
                onChanged: (value) {
                  if (value == null) return;

                  setState(() {
                    _loteSeleccionado = value;
                    _lecturaActual = null;
                    _muestras.clear();
                  });
                },
              ),

              const SizedBox(height: 14),


              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _leyendoUsb ? null : _leerDatosDesdeUsb,
                  icon: _leyendoUsb
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2),
                        )
                      : const Icon(Icons.usb_rounded),
                  label: Text(_leyendoUsb ? 'Leyendo USB...' : 'Leer datos'),
                ),
              ),


              if (_mensajeEstadoUsb != null) ...[
                const SizedBox(height: 10),
                _MensajeEstadoUsb(mensaje: _mensajeEstadoUsb!),
              ],

              const SizedBox(height: 14),

              if (_lecturaActual != null) ...[
                const SizedBox(height: 14),
                _DatosLeidosCard(lectura: _lecturaActual!),
              ],

              const SizedBox(height: 14),

              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: _lecturaActual == null ? null : _guardarPlanta,
                  icon: const Icon(Icons.add_circle_outline_rounded),
                  label: const Text('Guardar planta'),
                ),
              ),

              const SizedBox(height: 12),

              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: AppColores.primariosuave,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: AppColores.primario.withOpacity(0.16),
                  ),
                ),
                child: Text(
                  'Plantas guardadas: ${_muestras.length}',
                  style: const TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
              ),

              const SizedBox(height: 14),

              if (promedio != null) ...[
                const Text(
                  'Promedio actual',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w900,
                    color: AppColores.textoPrincipal,
                  ),
                ),
                const SizedBox(height: 8),
                _DatosLeidosCard(lectura: promedio),
                const SizedBox(height: 14),
              ],

              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: promedio == null ? null : _mostrarPromedio,
                  icon: const Icon(Icons.check_circle_outline_rounded),
                  label: const Text('Mostrar promedio'),
                ),
              ),

              const SizedBox(height: 10),

              SizedBox(
                width: double.infinity,
                child: TextButton.icon(
                  onPressed: _muestras.isEmpty && _lecturaActual == null
                      ? null
                      : _limpiar,
                  icon: const Icon(Icons.delete_outline_rounded),
                  label: const Text('Limpiar'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _leerDatosDesdeUsb() async {
    setState(() {
      _leyendoUsb = true;
      _mensajeEstadoUsb = null;
    });

    try {
      final lectura = await _usbDatasource.leerSensor();

      if (!mounted) return;

      setState(() {
        _lecturaActual = lectura;
        _mensajeEstadoUsb = 'Lectura recibida desde USB-RS485.';
      });
    } catch (error) {
      if (!mounted) return;

      setState(() {
        _mensajeEstadoUsb = error.toString().replaceFirst('Exception: ', '');
      });

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'No se pudo leer por USB-RS485: ${error.toString().replaceFirst('Exception: ', '')}',
          ),
        ),
      );
    } finally {
      await _usbDatasource.cerrar();

      if (!mounted) return;

      setState(() {
        _leyendoUsb = false;
      });
    }
  }

  void _guardarPlanta() {
    final lectura = _lecturaActual;

    if (lectura == null) return;

    setState(() {
      _muestras.add(lectura);
      _lecturaActual = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Planta ${_muestras.length} guardada.',
        ),
      ),
    );
  }

  void _mostrarPromedio() {
    if (_muestras.isEmpty) return;

    final promedio = _calcularPromedio(_muestras);

    Navigator.of(context).pop(
      _ResultadoLecturaDatos(
        loteId: _loteSeleccionado,
        cantidadPlantas: _muestras.length,
        promedio: promedio,
      ),
    );
  }

  void _limpiar() {
    setState(() {
      _lecturaActual = null;
      _muestras.clear();
    });
  }
}

class _MensajeEstadoUsb extends StatelessWidget {
  const _MensajeEstadoUsb({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    final esError = mensaje.toLowerCase().contains('no se') ||
        mensaje.toLowerCase().contains('error') ||
        mensaje.toLowerCase().contains('respond');

    final color = esError ? AppColores.advertencia : AppColores.primario;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withOpacity(0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withOpacity(0.22)),
      ),
      child: Text(
        mensaje,
        style: const TextStyle(
          fontSize: 12.5,
          height: 1.35,
          fontWeight: FontWeight.w800,
          color: AppColores.textoPrincipal,
        ),
      ),
    );
  }
}

class _DatosLeidosCard extends StatelessWidget {
  const _DatosLeidosCard({
    required this.lectura,
  });

  final DatosSensorSuelo lectura;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: AppColores.fondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColores.borde),
      ),
      child: Column(
        children: [
          _FilaDatoLeido(
            etiqueta: 'Humedad',
            valor: lectura.humedadSuelo,
            unidad: '%',
          ),
          _FilaDatoLeido(
            etiqueta: 'Temperatura',
            valor: lectura.temperaturaSuelo,
            unidad: '°C',
          ),
          _FilaDatoLeido(
            etiqueta: 'EC',
            valor: lectura.conductividadElectrica,
            unidad: 'dS/m',
          ),
          _FilaDatoLeido(
            etiqueta: 'pH',
            valor: lectura.phSuelo,
            unidad: '',
          ),
          _FilaDatoLeido(
            etiqueta: 'N',
            valor: lectura.nitrogeno,
            unidad: 'mg/kg',
          ),
          _FilaDatoLeido(
            etiqueta: 'P',
            valor: lectura.fosforo,
            unidad: 'mg/kg',
          ),
          _FilaDatoLeido(
            etiqueta: 'K',
            valor: lectura.potasio,
            unidad: 'mg/kg',
          ),
        ],
      ),
    );
  }
}

class _FilaDatoLeido extends StatelessWidget {
  const _FilaDatoLeido({
    required this.etiqueta,
    required this.valor,
    required this.unidad,
  });

  final String etiqueta;
  final double valor;
  final String unidad;

  @override
  Widget build(BuildContext context) {
    final textoValor = unidad.isEmpty
        ? valor.toStringAsFixed(2)
        : '${valor.toStringAsFixed(2)} $unidad';

    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Expanded(
            child: Text(
              etiqueta,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w700,
                color: AppColores.textoSecundario,
              ),
            ),
          ),
          Text(
            textoValor,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: AppColores.textoPrincipal,
            ),
          ),
        ],
      ),
    );
  }
}

class _ResultadoLecturaDatos {
  const _ResultadoLecturaDatos({
    required this.loteId,
    required this.cantidadPlantas,
    required this.promedio,
  });

  final String loteId;
  final int cantidadPlantas;
  final DatosSensorSuelo promedio;
}

DatosSensorSuelo _calcularPromedio(List<DatosSensorSuelo> muestras) {
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

  final total = muestras.length;

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

String _loteIdDesdeTexto(String lote) {
  final texto = lote.trim().toLowerCase();
  if (texto == 'lote_2' || texto.contains('2')) return 'lote_2';
  if (texto == 'lote_3' || texto.contains('3')) return 'lote_3';
  return 'lote_1';
}

String _nombreLote(String loteId) {
  if (loteId == 'lote_2') return 'Lote 2';
  if (loteId == 'lote_3') return 'Lote 3';
  return 'Lote 1';
}