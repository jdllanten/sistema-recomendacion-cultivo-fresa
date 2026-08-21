import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constantes/rangos_agronomicos.dart';
import '../../../../core/tema/app_colores.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../../../sensores/presentation/providers/sensor_suelo_provider.dart';
import '../../domain/services/calculador_npk.dart';
import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../historial/presentation/providers/historial_provider.dart';

class NpkPage extends ConsumerWidget {
  const NpkPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lecturaAsync = ref.watch(lecturaSensorStreamProvider);
    final ultimaLecturaHive = ref.watch(ultimaLecturaHistorialProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Análisis NPK'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 12),
            child: FilledButton.tonal(
              onPressed: () {
                _mostrarMetodologiaNpk(context);
              },
              child: const Text('Metodología'),
            ),
          ),
        ],
      ),
      body: lecturaAsync.when(
        data: (lectura) {
          return _NpkContenido(
            lectura: lectura,
            usandoLecturaLocal: false,
          );
        },
        loading: () {
          if (ultimaLecturaHive != null) {
            return _NpkContenido(
              lectura: _convertirHistorialADatosSensor(ultimaLecturaHive),
              usandoLecturaLocal: true,
            );
          }

          return const _NpkLoading();
        },
        error: (error, stackTrace) {
          if (ultimaLecturaHive != null) {
            return _NpkContenido(
              lectura: _convertirHistorialADatosSensor(ultimaLecturaHive),
              usandoLecturaLocal: true,
            );
          }

          return _NpkError(mensaje: error.toString());
        },
      ),
    );
  }

  DatosSensorSuelo _convertirHistorialADatosSensor(
    LecturaHistorial lectura,
  ) {
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
}

class _NpkContenido extends StatelessWidget {
  const _NpkContenido({
    required this.lectura,
    required this.usandoLecturaLocal,
  });

  final DatosSensorSuelo lectura;
  final bool usandoLecturaLocal;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
  'Etapa: Fructificación · 2.5 ha',
  style: TextStyle(
    color: AppColores.textoSecundario,
    fontSize: 15,
    fontWeight: FontWeight.w600,
  ),
),

if (usandoLecturaLocal) ...[
  const SizedBox(height: 10),
  Container(
    padding: const EdgeInsets.all(12),
    decoration: BoxDecoration(
      color: AppColores.primariosuave,
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: AppColores.primario.withOpacity(0.20),
      ),
    ),
    child: const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          Icons.storage_rounded,
          color: AppColores.primario,
          size: 20,
        ),
        SizedBox(width: 10),
        Expanded(
          child: Text(
            'Mostrando el análisis NPK con la última lectura guardada en Hive.',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: AppColores.textoPrincipal,
              height: 1.35,
            ),
          ),
        ),
      ],
    ),
  ),
],

const SizedBox(height: 16),

        const _RangosNpkCard(),

        const SizedBox(height: 16),

        _NutrienteCard(
          simbolo: 'N',
          nombre: 'Nitrógeno',
          fuente: 'Urea (46% N)',
          valor: lectura.nitrogeno,
          unidad: 'ppm',
          minimoIdeal: RangosAgronomicos.nitrogenoFructificacion.minimo,
          maximoIdeal: RangosAgronomicos.nitrogenoFructificacion.maximo,
          valorMaximoGrafico: 180,
          color: const Color(0xFF20B486),
          fertilizante: 'Urea',
          porcentajeContenido: 46,
        ),

        const SizedBox(height: 16),

        _NutrienteCard(
          simbolo: 'P',
          nombre: 'Fósforo',
          fuente: 'Superfosfato Triple (46% P₂O₅)',
          valor: lectura.fosforo,
          unidad: 'ppm',
          minimoIdeal: RangosAgronomicos.fosforoFructificacion.minimo,
          maximoIdeal: RangosAgronomicos.fosforoFructificacion.maximo,
          valorMaximoGrafico: 100,
          color: const Color(0xFFE0A11B),
          fertilizante: 'Superfosfato Triple',
          porcentajeContenido: 46,
        ),

        const SizedBox(height: 16),

        _NutrienteCard(
          simbolo: 'K',
          nombre: 'Potasio',
          fuente: 'Cloruro de Potasio (60% K₂O)',
          valor: lectura.potasio,
          unidad: 'ppm',
          minimoIdeal: RangosAgronomicos.potasioFructificacion.minimo,
          maximoIdeal: RangosAgronomicos.potasioFructificacion.maximo,
          valorMaximoGrafico: 220,
          color: const Color(0xFFD64545),
          fertilizante: 'Cloruro de Potasio',
          porcentajeContenido: 60,
        ),

        const SizedBox(height: 16),

        _HumedadFertilizacionCard(humedad: lectura.humedadSuelo),

        const SizedBox(height: 20),

        const Text(
          'Fórmulas basadas en literatura agronómica. '
          'Dosis estimada = (objetivo - valor actual) × 2 kg/ha por ppm. '
          'El resultado se ajusta según el porcentaje de contenido del fertilizante. '
          'Los rangos deben ser validados con asesoría agronómica y pruebas piloto.',
          style: TextStyle(
            color: AppColores.textoSecundario,
            fontSize: 13,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _RangosNpkCard extends StatelessWidget {
  const _RangosNpkCard();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Rangos óptimos para fructificación',
              style: TextStyle(
                color: AppColores.textoSecundario,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 18),
            Row(
              children: [
                Expanded(
                  child: _RangoNpkItem(
                    simbolo: 'N',
                    rango:
                        '${_numero(RangosAgronomicos.nitrogenoFructificacion.minimo)}–${_numero(RangosAgronomicos.nitrogenoFructificacion.maximo)}',
                    color: const Color(0xFF20B486),
                  ),
                ),
                const _SeparadorVertical(),
                Expanded(
                  child: _RangoNpkItem(
                    simbolo: 'P',
                    rango:
                        '${_numero(RangosAgronomicos.fosforoFructificacion.minimo)}–${_numero(RangosAgronomicos.fosforoFructificacion.maximo)}',
                    color: const Color(0xFFE0A11B),
                  ),
                ),
                const _SeparadorVertical(),
                Expanded(
                  child: _RangoNpkItem(
                    simbolo: 'K',
                    rango:
                        '${_numero(RangosAgronomicos.potasioFructificacion.minimo)}–${_numero(RangosAgronomicos.potasioFructificacion.maximo)}',
                    color: const Color(0xFFD64545),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _numero(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _RangoNpkItem extends StatelessWidget {
  const _RangoNpkItem({
    required this.simbolo,
    required this.rango,
    required this.color,
  });

  final String simbolo;
  final String rango;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(
          simbolo,
          style: TextStyle(
            color: color,
            fontSize: 28,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 6),
        Text(
          rango,
          style: const TextStyle(
            fontSize: 20,
            color: AppColores.textoPrincipal,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 2),
        const Text('ppm', style: TextStyle(color: AppColores.textoSecundario)),
      ],
    );
  }
}

class _SeparadorVertical extends StatelessWidget {
  const _SeparadorVertical();

  @override
  Widget build(BuildContext context) {
    return Container(width: 1, height: 70, color: AppColores.borde);
  }
}

class _NutrienteCard extends StatelessWidget {
  const _NutrienteCard({
    required this.simbolo,
    required this.nombre,
    required this.fuente,
    required this.valor,
    required this.unidad,
    required this.minimoIdeal,
    required this.maximoIdeal,
    required this.valorMaximoGrafico,
    required this.color,
    required this.fertilizante,
    required this.porcentajeContenido,
  });

  final String simbolo;
  final String nombre;
  final String fuente;
  final double valor;
  final String unidad;
  final double minimoIdeal;
  final double maximoIdeal;
  final double valorMaximoGrafico;
  final Color color;
  final String fertilizante;
  final double porcentajeContenido;

  bool get estaOptimo => valor >= minimoIdeal && valor <= maximoIdeal;

  bool get estaBajo => valor < minimoIdeal;

  bool get estaAlto => valor > maximoIdeal;

  double get progreso {
    if (valorMaximoGrafico == 0) return 0;
    return (valor / valorMaximoGrafico).clamp(0.0, 1.0);
  }

  double get inicioIdeal {
    if (valorMaximoGrafico == 0) return 0;
    return (minimoIdeal / valorMaximoGrafico).clamp(0.0, 1.0);
  }

  double get finIdeal {
    if (valorMaximoGrafico == 0) return 0;
    return (maximoIdeal / valorMaximoGrafico).clamp(0.0, 1.0);
  }

  Color get colorEstado {
    if (estaOptimo) return AppColores.primario;
    if (estaBajo) return AppColores.critico;
    return AppColores.advertencia;
  }

  String get textoEstado {
    if (estaOptimo) return 'Óptimo';
    if (estaBajo) return 'Deficiente';
    return 'Alto';
  }

  @override
  Widget build(BuildContext context) {
    final resultado = const CalculadorNpk().calcular(
      valorActual: valor,
      minimoIdeal: minimoIdeal,
      maximoIdeal: maximoIdeal,
      porcentajeFertilizante: porcentajeContenido,
    );

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(18),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _EncabezadoNutriente(
              simbolo: simbolo,
              nombre: nombre,
              fuente: fuente,
              color: color,
              textoEstado: textoEstado,
              colorEstado: colorEstado,
            ),

            const SizedBox(height: 22),

            Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _numero(valor),
                  style: const TextStyle(
                    fontSize: 42,
                    height: 1,
                    color: AppColores.textoPrincipal,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(width: 6),
                Padding(
                  padding: const EdgeInsets.only(bottom: 5),
                  child: Text(
                    unidad,
                    style: const TextStyle(
                      color: AppColores.textoSecundario,
                      fontSize: 17,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
                const Spacer(),
                Flexible(
                  child: Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Text(
                      'óptimo: ${_numero(minimoIdeal)}–${_numero(maximoIdeal)} $unidad',
                      textAlign: TextAlign.end,
                      style: const TextStyle(
                        color: AppColores.textoSecundario,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _BarraNutriente(
              progreso: progreso,
              inicioIdeal: inicioIdeal,
              finIdeal: finIdeal,
              color: colorEstado,
            ),

            if (estaBajo && resultado.dosisFertilizante > 0) ...[
              const SizedBox(height: 18),
              _DosisRecomendadaCard(
                dosis: resultado.dosisFertilizante,
                kgNutriente: resultado.kgPorHaNutriente,
                fertilizante: fertilizante,
                porcentajeContenido: porcentajeContenido,
              ),
            ],

            if (estaAlto) ...[
              const SizedBox(height: 18),
              _NotaNutrienteCard(
                texto:
                    'El valor está por encima del rango óptimo. Se recomienda revisar el plan de fertilización antes de aplicar más insumos.',
                color: AppColores.advertencia,
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _numero(double value) {
    if (value % 1 == 0) return value.toInt().toString();
    return value.toStringAsFixed(1);
  }
}

class _EncabezadoNutriente extends StatelessWidget {
  const _EncabezadoNutriente({
    required this.simbolo,
    required this.nombre,
    required this.fuente,
    required this.color,
    required this.textoEstado,
    required this.colorEstado,
  });

  final String simbolo;
  final String nombre;
  final String fuente;
  final Color color;
  final String textoEstado;
  final Color colorEstado;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Container(
          width: 54,
          height: 54,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Center(
            child: Text(
              simbolo,
              style: TextStyle(
                color: color,
                fontSize: 26,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                nombre,
                style: const TextStyle(
                  fontSize: 19,
                  color: AppColores.textoPrincipal,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 2),
              Text(
                fuente,
                style: const TextStyle(
                  color: AppColores.textoSecundario,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
        _EstadoChip(texto: textoEstado, color: colorEstado),
      ],
    );
  }
}

class _EstadoChip extends StatelessWidget {
  const _EstadoChip({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(999),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 7,
            height: 7,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle),
          ),
          const SizedBox(width: 6),
          Text(
            texto,
            style: TextStyle(color: color, fontWeight: FontWeight.w700),
          ),
        ],
      ),
    );
  }
}

class _BarraNutriente extends StatelessWidget {
  const _BarraNutriente({
    required this.progreso,
    required this.inicioIdeal,
    required this.finIdeal,
    required this.color,
  });

  final double progreso;
  final double inicioIdeal;
  final double finIdeal;
  final Color color;

  @override
  Widget build(BuildContext context) {
    final anchoIdeal = (finIdeal - inicioIdeal).clamp(0.0, 1.0);

    return LayoutBuilder(
      builder: (context, constraints) {
        return SizedBox(
          height: 12,
          child: Stack(
            alignment: Alignment.centerLeft,
            children: [
              Container(
                height: 9,
                decoration: BoxDecoration(
                  color: AppColores.primariosuave,
                  borderRadius: BorderRadius.circular(999),
                ),
              ),
              Positioned(
                left: constraints.maxWidth * inicioIdeal,
                child: Container(
                  width: constraints.maxWidth * anchoIdeal,
                  height: 9,
                  decoration: BoxDecoration(
                    color: AppColores.primario.withValues(alpha: 0.20),
                  ),
                ),
              ),
              FractionallySizedBox(
                widthFactor: progreso,
                child: Container(
                  height: 9,
                  decoration: BoxDecoration(
                    color: color,
                    borderRadius: BorderRadius.circular(999),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}

class _DosisRecomendadaCard extends StatelessWidget {
  const _DosisRecomendadaCard({
    required this.dosis,
    required this.kgNutriente,
    required this.fertilizante,
    required this.porcentajeContenido,
  });

  final double dosis;
  final double kgNutriente;
  final String fertilizante;
  final double porcentajeContenido;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColores.primariosuave,
        borderRadius: BorderRadius.circular(16),
        border: const Border(
          left: BorderSide(color: AppColores.primario, width: 5),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Dosis recomendada',
            style: TextStyle(
              color: AppColores.primario,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '${dosis.toStringAsFixed(1)} kg/ha de $fertilizante',
            style: const TextStyle(
              color: AppColores.textoPrincipal,
              fontSize: 16,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '= ${kgNutriente.toStringAsFixed(1)} kg/ha ÷ ${porcentajeContenido.toStringAsFixed(0)}% contenido',
            style: const TextStyle(
              color: AppColores.textoSecundario,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}

class _NotaNutrienteCard extends StatelessWidget {
  const _NotaNutrienteCard({required this.texto, required this.color});

  final String texto;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.10),
        borderRadius: BorderRadius.circular(16),
        border: Border(left: BorderSide(color: color, width: 5)),
      ),
      child: Text(
        texto,
        style: TextStyle(
          color: color,
          height: 1.4,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}

class _HumedadFertilizacionCard extends StatelessWidget {
  const _HumedadFertilizacionCard({required this.humedad});

  final double humedad;

  @override
  Widget build(BuildContext context) {
    final texto = humedad < RangosAgronomicos.humedadSuelo.minimo
        ? 'Humedad baja para fertilización'
        : humedad > RangosAgronomicos.humedadSuelo.maximo
        ? 'Humedad alta; revisar drenaje antes de fertilizar'
        : 'Humedad adecuada para fertilización';

    final detalle =
        'Humedad actual: ${humedad.toStringAsFixed(1)}% · Revisar recomendaciones antes de aplicar fertilizante.';

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FF),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: const Color(0xFF9EC5FE)),
      ),
      child: Text(
        '$texto\n$detalle',
        style: const TextStyle(
          color: Color(0xFF2F5F9F),
          height: 1.5,
          fontSize: 15,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}

class _NpkLoading extends StatelessWidget {
  const _NpkLoading();

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: const [
        Text(
          'Análisis NPK',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        SizedBox(height: 16),
        Card(
          child: Padding(
            padding: EdgeInsets.all(18),
            child: Row(
              children: [
                SizedBox(
                  width: 28,
                  height: 28,
                  child: CircularProgressIndicator(strokeWidth: 3),
                ),
                SizedBox(width: 14),
                Expanded(
                  child: Text(
                    'Esperando una lectura del sensor para calcular NPK.',
                    style: TextStyle(
                      color: AppColores.textoSecundario,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

class _NpkError extends StatelessWidget {
  const _NpkError({required this.mensaje});

  final String mensaje;

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Text(
          'Análisis NPK',
          style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(18),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.error_outline, color: AppColores.critico),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    mensaje,
                    style: const TextStyle(
                      color: AppColores.textoPrincipal,
                      height: 1.4,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
void _mostrarMetodologiaNpk(BuildContext context) {
  showModalBottomSheet<void>(
    context: context,
    isScrollControlled: true,
    showDragHandle: true,
    backgroundColor: AppColores.superficie,
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(
        top: Radius.circular(28),
      ),
    ),
    builder: (context) {
      return const _MetodologiaNpkSheet();
    },
  );
}

class _MetodologiaNpkSheet extends StatelessWidget {
  const _MetodologiaNpkSheet();

  @override
  Widget build(BuildContext context) {
    return DraggableScrollableSheet(
      expand: false,
      initialChildSize: 0.82,
      minChildSize: 0.45,
      maxChildSize: 0.95,
      builder: (context, scrollController) {
        return ListView(
          controller: scrollController,
          padding: const EdgeInsets.fromLTRB(20, 8, 20, 28),
          children: const [
            Text(
              'Metodología NPK',
              style: TextStyle(
                fontSize: 24,
                fontWeight: FontWeight.w800,
                color: AppColores.textoPrincipal,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'Esta sección explica cómo la aplicación interpreta los valores de nitrógeno, fósforo y potasio para apoyar la toma de decisiones en el cultivo de fresa.',
              style: TextStyle(
                color: AppColores.textoSecundario,
                height: 1.45,
                fontWeight: FontWeight.w500,
              ),
            ),
            SizedBox(height: 20),

            _BloqueMetodologia(
              icono: Icons.eco,
              titulo: '1. Variables analizadas',
              contenido:
                  'El análisis NPK utiliza las lecturas de nitrógeno, fósforo y potasio entregadas por el sensor de suelo. Estas variables permiten observar posibles deficiencias nutricionales durante la etapa de fructificación.',
            ),

            SizedBox(height: 14),

            _BloqueMetodologia(
              icono: Icons.straighten,
              titulo: '2. Rangos de referencia',
              contenido:
                  'Para el prototipo se usan rangos ideales definidos en la clase RangosAgronomicos. Actualmente son: Nitrógeno 100–125 ppm, Fósforo 45–65 ppm y Potasio 120–160 ppm. Estos valores deben validarse con literatura agronómica, asesoría técnica o pruebas piloto.',
            ),

            SizedBox(height: 14),

            _BloqueMetodologia(
              icono: Icons.calculate,
              titulo: '3. Cálculo de déficit',
              contenido:
                  'Cuando el valor actual está por debajo del rango ideal, se calcula un objetivo promedio entre el mínimo y el máximo del rango. Luego se estima el déficit como la diferencia entre ese objetivo y el valor medido.',
            ),

            SizedBox(height: 14),

            _FormulaMetodologiaCard(),

            SizedBox(height: 14),

            _BloqueMetodologia(
              icono: Icons.science,
              titulo: '4. Fertilizante de referencia',
              contenido:
                  'La aplicación usa fertilizantes de referencia para estimar una dosis inicial: Urea para nitrógeno, Superfosfato Triple para fósforo y Cloruro de Potasio para potasio. La dosis se ajusta según el porcentaje de contenido del nutriente en cada fertilizante.',
            ),

            SizedBox(height: 14),

            _BloqueMetodologia(
              icono: Icons.warning_amber_rounded,
              titulo: '5. Importante',
              contenido:
                  'La dosis calculada es una estimación para prototipo y apoyo a la decisión. No reemplaza una recomendación agronómica profesional. Antes de aplicar fertilizantes se deben considerar análisis de suelo, etapa fenológica, clima, historial del lote y criterio técnico.',
            ),

            SizedBox(height: 14),

            _BloqueMetodologia(
              icono: Icons.psychology_alt_outlined,
              titulo: '6. Relación con HCI',
              contenido:
                  'Desde HCI, esta pantalla reduce la carga cognitiva porque no obliga al usuario a interpretar únicamente números. Presenta estados visuales, rangos, alertas y dosis estimadas en tarjetas claras, favoreciendo la comprensión y la toma rápida de decisiones.',
            ),
          ],
        );
      },
    );
  }
}

class _BloqueMetodologia extends StatelessWidget {
  const _BloqueMetodologia({
    required this.icono,
    required this.titulo,
    required this.contenido,
  });

  final IconData icono;
  final String titulo;
  final String contenido;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColores.primariosuave,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColores.borde,
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColores.superficie,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              icono,
              color: AppColores.primario,
              size: 22,
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
                    color: AppColores.textoPrincipal,
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  contenido,
                  style: const TextStyle(
                    color: AppColores.textoSecundario,
                    height: 1.45,
                    fontWeight: FontWeight.w500,
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

class _FormulaMetodologiaCard extends StatelessWidget {
  const _FormulaMetodologiaCard();

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFE3F0FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFF9EC5FE),
        ),
      ),
      child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Fórmula usada en el prototipo',
            style: TextStyle(
              color: Color(0xFF2F5F9F),
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
          SizedBox(height: 12),
          _LineaFormula(
            texto: 'objetivo = (mínimo ideal + máximo ideal) / 2',
          ),
          SizedBox(height: 8),
          _LineaFormula(
            texto: 'déficit = objetivo - valor actual',
          ),
          SizedBox(height: 8),
          _LineaFormula(
            texto: 'kg/ha nutriente = déficit × 2',
          ),
          SizedBox(height: 8),
          _LineaFormula(
            texto: 'dosis fertilizante = kg/ha nutriente ÷ concentración',
          ),
        ],
      ),
    );
  }
}

class _LineaFormula extends StatelessWidget {
  const _LineaFormula({
    required this.texto,
  });

  final String texto;

  @override
  Widget build(BuildContext context) {
    return Text(
      texto,
      style: const TextStyle(
        color: Color(0xFF2F5F9F),
        fontWeight: FontWeight.w700,
        height: 1.35,
      ),
    );
  }
}