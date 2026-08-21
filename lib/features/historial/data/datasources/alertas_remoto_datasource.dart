import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter/material.dart';

import '../../domain/entities/alerta_critica_historial.dart';

class AlertasRemotoDatasource {
  AlertasRemotoDatasource({
    FirebaseFirestore? firestore,
  }) : _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseFirestore _firestore;

  static const String _usuarioId = 'jdh2010';
  static const String _fincaId = 'finca_esperanza';
  static const String _loteId = 'lote_1';

  CollectionReference<Map<String, dynamic>> get _alertasRef {
    return _firestore
        .collection('usuarios')
        .doc(_usuarioId)
        .collection('fincas')
        .doc(_fincaId)
        .collection('lotes')
        .doc(_loteId)
        .collection('alertas');
  }

  Future<List<AlertaCriticaHistorial>> obtenerAlertasRecientes({
    int limite = 100,
  }) async {
    debugPrint('Descargando alertas críticas desde Firestore');
    debugPrint(
      'Ruta: usuarios/$_usuarioId/fincas/$_fincaId/lotes/$_loteId/alertas',
    );

    final snapshot = await _alertasRef.limit(limite).get();

    debugPrint('Alertas encontradas en Firestore: ${snapshot.docs.length}');

    final todasLasAlertas = <AlertaCriticaHistorial>[];

    for (final doc in snapshot.docs) {
      try {
        final data = doc.data();

        final alerta = AlertaCriticaHistorial.fromFirestore({
          ...data,
          'id': data['id'] ?? doc.id,
        });

        todasLasAlertas.add(alerta);
      } catch (e) {
        debugPrint('⚠️ No se pudo convertir alerta ${doc.id}: $e');
      }
    }

    final alertasFiltradas = _filtrarAlertasParaHistorial(todasLasAlertas);

    alertasFiltradas.sort(
      (a, b) => b.creadaEn.compareTo(a.creadaEn),
    );

    debugPrint(
      'Alertas visibles en historial: ${alertasFiltradas.length}',
    );

    return alertasFiltradas;
  }

  List<AlertaCriticaHistorial> _filtrarAlertasParaHistorial(
    List<AlertaCriticaHistorial> alertas,
  ) {
    final lecturasConResumen = <String>{};

    for (final alerta in alertas) {
      if (alerta.esAlertaResumen) {
        lecturasConResumen.add(alerta.lecturaId);
      }
    }

    final visibles = <AlertaCriticaHistorial>[];

    for (final alerta in alertas) {
      final tieneResumen = lecturasConResumen.contains(alerta.lecturaId);

      if (alerta.esAlertaResumen) {
        visibles.add(alerta);
        continue;
      }

      if (tieneResumen && alerta.esAlertaIndividualAgrupada) {
        continue;
      }

      visibles.add(alerta);
    }

    return visibles;
  }
}