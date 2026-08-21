import 'package:flutter_riverpod/flutter_riverpod.dart';


final fechaLecturaUsbActivaProvider = StateProvider<DateTime?>((ref) => null);

String tiempoRelativoLectura(DateTime fecha) {
  final ahora = DateTime.now();
  var diferencia = ahora.difference(fecha);


  if (diferencia.isNegative) {
    diferencia = Duration.zero;
  }

  if (diferencia.inSeconds < 60) {
    return 'hace menos de 1 min';
  }

  if (diferencia.inMinutes < 60) {
    return 'hace ${diferencia.inMinutes} min';
  }

  if (diferencia.inHours < 24) {
    return 'hace ${diferencia.inHours} h';
  }

  return 'hace ${diferencia.inDays} días';
}


bool lecturaEstaActiva(
  DateTime fecha, {
  Duration margenActivo = const Duration(minutes: 30),
}) {
  final ahora = DateTime.now();
  var diferencia = ahora.difference(fecha);

  if (diferencia.isNegative) {
    diferencia = Duration.zero;
  }

  return diferencia <= margenActivo;
}
