import 'package:cloud_firestore/cloud_firestore.dart';

class AlertaCriticaHistorial {
  const AlertaCriticaHistorial({
    required this.id,
    required this.lecturaId,
    required this.tipo,
    required this.prioridad,
    required this.titulo,
    required this.mensaje,
    required this.enviada,
    required this.enviados,
    required this.fallidos,
    required this.creadaEn,
    required this.resumen,
    required this.agrupada,
    required this.totalAlertas,
    required this.tiposDetectados,
  });

  final String id;
  final String lecturaId;
  final String tipo;
  final String prioridad;
  final String titulo;
  final String mensaje;
  final bool enviada;
  final int enviados;
  final int fallidos;
  final DateTime creadaEn;

  final String resumen;
  final bool agrupada;
  final int totalAlertas;
  final List<String> tiposDetectados;

  factory AlertaCriticaHistorial.fromFirestore(
    Map<String, dynamic> data,
  ) {
    return AlertaCriticaHistorial(
      id: _toString(data['id']),
      lecturaId: _toString(data['lecturaId']),
      tipo: _toString(data['tipo']),
      prioridad: _toString(data['prioridad']),
      titulo: _toString(data['titulo']),
      mensaje: _toString(data['mensaje']),
      enviada: data['enviada'] == true,
      enviados: _toInt(data['enviados']),
      fallidos: _toInt(data['fallidos']),
      creadaEn: _toDateTime(data['creadaEn']),
      resumen: _toString(data['resumen']),
      agrupada: data['agrupada'] == true,
      totalAlertas: _toInt(data['totalAlertas']),
      tiposDetectados: _toStringList(data['tiposDetectados']),
    );
  }

  bool get esAlertaResumen {
    return tipo == 'multiple' || totalAlertas > 1 || id.contains('_resumen_');
  }

  bool get esAlertaIndividualAgrupada {
    return agrupada && !esAlertaResumen;
  }

  String get tituloVisible {
    if (esAlertaResumen) {
      return 'Alerta crítica múltiple';
    }

    return titulo;
  }

  String get subtituloVisible {
    if (esAlertaResumen && totalAlertas > 1) {
      return '$totalAlertas condiciones críticas detectadas';
    }

    return mensaje;
  }

  List<String> get etiquetasVisibles {
    if (tiposDetectados.isNotEmpty) {
      return tiposDetectados.map(_formatearTipo).toList();
    }

    if (tipo.isNotEmpty) {
      return [_formatearTipo(tipo)];
    }

    return [];
  }

  static String _formatearTipo(String value) {
    switch (value) {
      case 'humedad_baja':
        return 'Humedad baja';
      case 'humedad_alta':
        return 'Humedad alta';
      case 'temperatura_alta':
        return 'Temperatura alta';
      case 'ph_acido':
        return 'pH ácido';
      case 'ph_alto':
        return 'pH alto';
      case 'salinidad_alta':
        return 'Salinidad alta';
      case 'nitrogeno_bajo':
        return 'Nitrógeno bajo';
      case 'fosforo_bajo':
        return 'Fósforo bajo';
      case 'potasio_bajo':
        return 'Potasio bajo';
      case 'multiple':
        return 'Múltiple';
      default:
        return value.replaceAll('_', ' ');
    }
  }

  static String _toString(dynamic value) {
    if (value == null) return '';
    return value.toString();
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static List<String> _toStringList(dynamic value) {
    if (value is List) {
      return value.map((item) => item.toString()).toList();
    }

    return [];
  }

  static DateTime _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;

    if (value is String) {
      return DateTime.tryParse(value) ?? DateTime.now();
    }

    return DateTime.now();
  }

  String get hora {
    final h = creadaEn.hour.toString().padLeft(2, '0');
    final m = creadaEn.minute.toString().padLeft(2, '0');

    return '$h:$m';
  }

  String get fechaCorta {
    return '${creadaEn.day}/${creadaEn.month}/${creadaEn.year}';
  }
}