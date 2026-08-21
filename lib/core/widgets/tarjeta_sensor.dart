import 'package:flutter/material.dart';
import '../tema/app_colores.dart';

// Estados posibles de un sensor
enum EstadoSensor { optimo, advertencia, critico }

// Tendencia de un sensor respecto a la lectura anterior.
enum TipoTendencia { subiendo, bajando, estable }

class TarjetaSensor extends StatelessWidget {
  const TarjetaSensor({
    super.key,
    required this.titulo,
    required this.valor,
    required this.unidad,
    required this.estado,
    required this.valorMinimo,
    required this.valorMaximo,
    required this.rangoIdealMinimo,
    required this.rangoIdealMaximo,
    this.icono,
    this.mensajeEstado,
    this.tendencia,  // NUEVO: opcional para no romper usos existentes
  });

  final String titulo;
  final double valor;
  final String unidad;
  final EstadoSensor estado;
  final double valorMinimo;
  final double valorMaximo;
  final double rangoIdealMinimo;
  final double rangoIdealMaximo;
  final IconData? icono;
  final String? mensajeEstado;
  final TipoTendencia? tendencia;  // NUEVO

  Color get colorEstado {
    switch (estado) {
      case EstadoSensor.optimo:
        return AppColores.primario;
      case EstadoSensor.advertencia:
        return AppColores.advertencia;
      case EstadoSensor.critico:
        return AppColores.critico;
    }
  }

  String get textoEstado {
    switch (estado) {
      case EstadoSensor.optimo:
        return 'Óptimo';
      case EstadoSensor.advertencia:
        return 'Advertencia';
      case EstadoSensor.critico:
        return 'Crítico';
    }
  }

  String _formatearNumero(double numero) {
    if (numero % 1 == 0) return numero.toInt().toString();
    return numero.toStringAsFixed(1);
  }

  double _calcularProgreso(double actual) {
    if (valorMaximo == valorMinimo) return 0;
    return ((actual - valorMinimo) / (valorMaximo - valorMinimo)).clamp(0.0, 1.0);
  }

  @override
  Widget build(BuildContext context) {
    final progreso = _calcularProgreso(valor);


    return Card(
      child: IntrinsicHeight(
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Container(
              width: 7,
              decoration: BoxDecoration(
                color: colorEstado,
                borderRadius: const BorderRadius.horizontal(
                  left: Radius.circular(20),
                ),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _encabezado(),
                    const SizedBox(height: 16),
                    _valorPrincipal(),
                    const SizedBox(height: 16),
                    LinearProgressIndicator(
                      value: progreso,
                      minHeight: 10,
                      borderRadius: BorderRadius.circular(999),
                      backgroundColor: AppColores.primariosuave,
                      valueColor: AlwaysStoppedAnimation<Color>(colorEstado),
                    ),
                    const SizedBox(height: 8),
                    _etiquetasRango(),
                    if (mensajeEstado != null && mensajeEstado!.isNotEmpty) ...[
                      const SizedBox(height: 10),
                      Text(
                        mensajeEstado!,
                        style: TextStyle(
                          color: colorEstado,
                          height: 1.35,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _encabezado() {
    return Row(
      children: [
        if (icono != null) ...[
          Container(
            width: 42,
            height: 42,
            decoration: BoxDecoration(
              color: AppColores.primariosuave,
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(icono, color: colorEstado),
          ),
          const SizedBox(width: 12),
        ],
        Expanded(
          child: Text(
            titulo,
            style: const TextStyle(
              fontSize: 16,
              color: AppColores.textoSecundario,
              fontWeight: FontWeight.w600,
            ),
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
          decoration: BoxDecoration(
            color: colorEstado.withValues(alpha: 0.10),
            borderRadius: BorderRadius.circular(999),
          ),
          child: Text(
            textoEstado,
            style: TextStyle(
              color: colorEstado,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
        ),
      ],
    );
  }

  Widget _valorPrincipal() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          _formatearNumero(valor),
          style: const TextStyle(
            fontSize: 42,
            height: 1,
            fontWeight: FontWeight.w700,
            color: AppColores.textoPrincipal,
          ),
        ),
        if (unidad.isNotEmpty) ...[
          const SizedBox(width: 5),
          Padding(
            padding: const EdgeInsets.only(bottom: 2),
            child: Text(
              unidad,
              style: const TextStyle(
                fontSize: 18,
                color: AppColores.textoSecundario,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
        const Spacer(),
        if (tendencia != null) _badgeTendencia(),
      ],
    );
  }

  Widget _badgeTendencia() {
    final IconData icono;
    final String texto;
    final Color color;

    switch (tendencia!) {
      case TipoTendencia.subiendo:
        icono = Icons.trending_up;
        texto = 'Subiendo';
        color = Colors.blue.shade600;
        break;
      case TipoTendencia.bajando:
        icono = Icons.trending_down;
        texto = 'Bajando';
        color = Colors.orange.shade700;
        break;
      case TipoTendencia.estable:
        icono = Icons.trending_flat;
        texto = 'Estable';
        color = AppColores.textoSecundario;
        break;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 5),
      decoration: BoxDecoration(
        color: color.withOpacity(0.10),
        borderRadius: BorderRadius.circular(99),
        border: Border.all(color: color.withOpacity(0.25)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icono, size: 15, color: color),
          const SizedBox(width: 4),
          Text(
            texto,
            style: TextStyle(
              color: color,
              fontSize: 12,
              fontWeight: FontWeight.w700,
            ),
          ),
        ],
      ),
    );
  }

  Widget _etiquetasRango() {
    return Row(
      children: [
        Text(
          '${_formatearNumero(valorMinimo)}$unidad',
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        Text(
          '${_formatearNumero(rangoIdealMinimo)}-${_formatearNumero(rangoIdealMaximo)}$unidad',
          style: const TextStyle(
            color: AppColores.primario,
            fontWeight: FontWeight.w700,
          ),
        ),
        const Spacer(),
        Text(
          '${_formatearNumero(valorMaximo)}$unidad',
          style: const TextStyle(
            color: AppColores.textoSecundario,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}