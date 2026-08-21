import 'package:cloud_firestore/cloud_firestore.dart';

class LoteCultivo {
  const LoteCultivo({
    required this.id,
    required this.nombre,
    required this.cultivo,
    required this.etapa,
    required this.activo,
    this.areaM2 = 0,
    this.numeroPlantas = 0,
    this.observaciones = '',
    this.creadoEn,
    this.actualizadoEn,
    this.pendienteSync = false,
    this.sincronizado = true,
  });

  final String id;
  final String nombre;
  final String cultivo;
  final String etapa;
  final bool activo;
  final double areaM2;
  final int numeroPlantas;
  final String observaciones;
  final DateTime? creadoEn;
  final DateTime? actualizadoEn;


  final bool pendienteSync;


  final bool sincronizado;

  LoteCultivo copyWith({
    String? id,
    String? nombre,
    String? cultivo,
    String? etapa,
    bool? activo,
    double? areaM2,
    int? numeroPlantas,
    String? observaciones,
    DateTime? creadoEn,
    DateTime? actualizadoEn,
    bool? pendienteSync,
    bool? sincronizado,
  }) {
    return LoteCultivo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      cultivo: cultivo ?? this.cultivo,
      etapa: etapa ?? this.etapa,
      activo: activo ?? this.activo,
      areaM2: areaM2 ?? this.areaM2,
      numeroPlantas: numeroPlantas ?? this.numeroPlantas,
      observaciones: observaciones ?? this.observaciones,
      creadoEn: creadoEn ?? this.creadoEn,
      actualizadoEn: actualizadoEn ?? this.actualizadoEn,
      pendienteSync: pendienteSync ?? this.pendienteSync,
      sincronizado: sincronizado ?? this.sincronizado,
    );
  }

  Map<String, dynamic> toMap() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'cultivo': cultivo,
      'etapa': etapa,
      'activo': activo,
      'areaM2': areaM2,
      'numeroPlantas': numeroPlantas,
      'observaciones': observaciones,
      'creadoEn': creadoEn?.toIso8601String(),
      'actualizadoEn': actualizadoEn?.toIso8601String(),
      'pendienteSync': pendienteSync,
      'sincronizado': sincronizado,
    };
  }

  Map<String, dynamic> toFirestoreMap() {
    return <String, dynamic>{
      'id': id,
      'nombre': nombre,
      'cultivo': cultivo,
      'etapa': etapa,
      'activo': activo,
      'areaM2': areaM2,
      'numeroPlantas': numeroPlantas,
      'observaciones': observaciones,
      'actualizadoEn': FieldValue.serverTimestamp(),
      if (creadoEn != null) 'creadoEnLocal': creadoEn!.toIso8601String(),
    };
  }

  factory LoteCultivo.fromMap(Map<String, dynamic> map) {
    return LoteCultivo(
      id: (map['id'] ?? '').toString(),
      nombre: (map['nombre'] ?? '').toString(),
      cultivo: (map['cultivo'] ?? 'Fresa Albión').toString(),
      etapa: (map['etapa'] ?? 'Fructificación').toString(),
      activo: map['activo'] is bool ? map['activo'] as bool : true,
      areaM2: _toDouble(map['areaM2']),
      numeroPlantas: _toInt(map['numeroPlantas']),
      observaciones: (map['observaciones'] ?? '').toString(),
      creadoEn: _toDateTime(map['creadoEn']),
      actualizadoEn: _toDateTime(map['actualizadoEn']),
      pendienteSync: map['pendienteSync'] is bool
          ? map['pendienteSync'] as bool
          : false,
      sincronizado: map['sincronizado'] is bool
          ? map['sincronizado'] as bool
          : true,
    );
  }

  static LoteCultivo loteInicial() {
    return const LoteCultivo(
      id: 'lote_1',
      nombre: 'Lote 1',
      cultivo: 'Fresa Albión',
      etapa: 'Fructificación',
      activo: true,
      pendienteSync: false,
      sincronizado: true,
    );
  }

  static double _toDouble(dynamic value) {
    if (value is num) return value.toDouble();
    if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
    return 0;
  }

  static int _toInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    if (value is String) return int.tryParse(value) ?? 0;
    return 0;
  }

  static DateTime? _toDateTime(dynamic value) {
    if (value is Timestamp) return value.toDate();
    if (value is DateTime) return value;
    if (value is String) return DateTime.tryParse(value);
    return null;
  }
}
