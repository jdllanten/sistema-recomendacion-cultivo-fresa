import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../historial/domain/entities/lectura_historial.dart';
import '../../../historial/presentation/providers/historial_provider.dart';
import '../../../sensores/domain/entities/datos_sensor_suelo.dart';
import '../../../sensores/presentation/providers/sensor_suelo_provider.dart';
import '../../domain/entities/plan_nutricional.dart';
import '../../domain/entities/producto_fertilizante.dart';
import '../../domain/services/calculadora_plan_nutricional_npk.dart';
import 'configuracion_plan_nutricional_provider.dart';
import 'fertilizantes_disponibles_provider.dart';
import '../../../lotes/presentation/providers/lotes_provider.dart';

final calculadoraPlanNutricionalNpkProvider =
    Provider<CalculadoraPlanNutricionalNpk>((ref) {
  return const CalculadoraPlanNutricionalNpk();
});

final lecturaUltimaPorLotePlanProvider =
    StreamProvider.autoDispose<DatosSensorSuelo?>((ref) {
  final loteId = ref.watch(loteSeleccionadoIdProvider);

  return FirebaseFirestore.instance
      .collection('usuarios')
      .doc('jdh2010')
      .collection('fincas')
      .doc('finca_esperanza')
      .collection('lotes')
      .doc(loteId)
      .collection('lecturas')
      .orderBy('fechaLectura', descending: true)
      .limit(1)
      .snapshots()
      .map((snapshot) {
    if (snapshot.docs.isEmpty) return null;

    final data = snapshot.docs.first.data();
    return _convertirFirestoreADatosSensor(data);
  });
});

final planNutricionalNpkProvider = Provider<AsyncValue<PlanNutricionalNpk>>((
  ref,
) {
  final lecturaAsync = ref.watch(lecturaSensorStreamProvider);
  final ultimaLecturaHive = ref.watch(ultimaLecturaHistorialProvider);
  final lecturaLoteAsync = ref.watch(lecturaUltimaPorLotePlanProvider);

  final calculadora = ref.watch(calculadoraPlanNutricionalNpkProvider);
  final parametros = ref.watch(configuracionPlanNutricionalProvider);
  final modoCalculo = ref.watch(modoCalculoFertilizanteProvider);
  final productos = ref.watch(productosFertilizantesProvider);
  final productosSeleccionados = ref.watch(
    productosFertilizantesSeleccionadosProvider,
  );

  final productosParaCalculo = modoCalculo == ModoCalculoFertilizante.sugerido
      ? productos
      : productosSeleccionados;

  final fertilizantesParaCalculo =
      modoCalculo == ModoCalculoFertilizante.personalizado &&
              productosSeleccionados.isEmpty
          ? <FertilizanteDisponible>[]
          : productosParaCalculo
              .where(
                (producto) =>
                    producto.n > 0 || producto.p2o5 > 0 || producto.k2o > 0,
              )
              .map(_convertirProductoAFertilizanteDisponible)
              .toList();

  PlanNutricionalNpk calcularCon(DatosSensorSuelo lectura) {
    return calculadora.calcular(
      lectura: lectura,
      parametros: parametros,
      fertilizantesDisponibles: fertilizantesParaCalculo,
    );
  }

  final lecturaLote = lecturaLoteAsync.valueOrNull;
  if (lecturaLote != null) {
    return AsyncValue.data(calcularCon(lecturaLote));
  }

  return lecturaAsync.when(
    data: (lectura) {
      return AsyncValue.data(calcularCon(lectura));
    },
    loading: () {
      if (ultimaLecturaHive != null) {
        final lectura = _convertirHistorialADatosSensor(ultimaLecturaHive);
        return AsyncValue.data(calcularCon(lectura));
      }

      return const AsyncValue.loading();
    },
    error: (error, stackTrace) {
      if (ultimaLecturaHive != null) {
        final lectura = _convertirHistorialADatosSensor(ultimaLecturaHive);
        return AsyncValue.data(calcularCon(lectura));
      }

      return AsyncValue.error(error, stackTrace);
    },
  );
});

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

DatosSensorSuelo _convertirFirestoreADatosSensor(Map<String, dynamic> data) {
  return DatosSensorSuelo(
    humedadSuelo: _double(data['humedadSuelo']),
    temperaturaSuelo: _double(data['temperaturaSuelo']),
    conductividadElectrica: _double(data['conductividadElectrica']),
    phSuelo: _double(data['phSuelo']),
    nitrogeno: _double(data['nitrogeno']),
    fosforo: _double(data['fosforo']),
    potasio: _double(data['potasio']),
    fechaLectura: _fecha(data['fechaLectura']),
  );
}

FertilizanteDisponible _convertirProductoAFertilizanteDisponible(
  ProductoFertilizante producto,
) {
  return FertilizanteDisponible(
    nombre: producto.nombre,
    concentracionN: producto.n,
    concentracionP2O5: producto.p2o5,
    concentracionK2O: producto.k2o,
    concentracionMgO: producto.mgO,
    concentracionCa: producto.ca,
    concentracionB: producto.b,
    precio: producto.precio,
  );
}


double _double(dynamic value) {
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value.replaceAll(',', '.')) ?? 0;
  return 0;
}

DateTime _fecha(dynamic value) {
  if (value is Timestamp) return value.toDate();
  if (value is DateTime) return value;
  if (value is String) return DateTime.tryParse(value) ?? DateTime.now();
  return DateTime.now();
}
