class RangoAgronomico {
  const RangoAgronomico({
    required this.minimo,
    required this.maximo,
    required this.unidad,
    required this.descripcion,
  });

  final double minimo;
  final double maximo;
  final String unidad;
  final String descripcion;
}

abstract final class RangosAgronomicos {

  static const RangoAgronomico humedadSuelo = RangoAgronomico(
    minimo: 45,
    maximo: 65,
    unidad: '%',
    descripcion:
        'Rango operativo de humedad del suelo en porcentaje usado por la app.',
  );

  static const double humedadPorcentajeCriticaBaja = 35;
  static const double humedadPorcentajeAdvertenciaBaja = 45;
  static const double humedadPorcentajeIdealMin = 45;
  static const double humedadPorcentajeIdealMax = 65;
  static const double humedadPorcentajeAdvertenciaAlta = 75;

  static const RangoAgronomico humedadTensionSaturado = RangoAgronomico(
    minimo: 0,
    maximo: 10,
    unidad: 'cb/kPa',
    descripcion:
        'Suelo saturado. Puede afectar oxigenación y causar ahogamiento si persiste.',
  );

  static const RangoAgronomico humedadTensionIdeal = RangoAgronomico(
    minimo: 10,
    maximo: 30,
    unidad: 'cb/kPa',
    descripcion:
        'Capacidad de campo. Rango ideal indicado por el asesor para fresa.',
  );

  static const RangoAgronomico humedadTensionEstresLigero = RangoAgronomico(
    minimo: 30,
    maximo: 60,
    unidad: 'cb/kPa',
    descripcion:
        'Estrés ligero. Momento recomendado para iniciar riego.',
  );

  static const RangoAgronomico humedadTensionMuySeco = RangoAgronomico(
    minimo: 60,
    maximo: 80,
    unidad: 'cb/kPa',
    descripcion:
        'Suelo muy seco. Riesgo de estrés hídrico severo.',
  );

  static const RangoAgronomico humedadTensionMarchitez = RangoAgronomico(
    minimo: 80,
    maximo: double.infinity,
    unidad: 'cb/kPa',
    descripcion:
        'Punto de marchitez inminente. Riesgo de daño irreversible.',
  );


  static const RangoAgronomico temperaturaSuelo = RangoAgronomico(
    minimo: 15,
    maximo: 25,
    unidad: '°C',
    descripcion:
        'Rango operativo usado por la app para temperatura del suelo.',
  );

  static const RangoAgronomico temperaturaDiaIdeal = RangoAgronomico(
    minimo: 15,
    maximo: 18,
    unidad: '°C',
    descripcion:
        'Rango óptimo diurno indicado por el asesor para cultivo de fresa.',
  );

  static const RangoAgronomico temperaturaNocheIdeal = RangoAgronomico(
    minimo: 8,
    maximo: 10,
    unidad: '°C',
    descripcion:
        'Rango óptimo nocturno indicado por el asesor para cultivo de fresa.',
  );

  static const double temperaturaCriticaBaja = 8;
  static const double temperaturaAdvertenciaBaja = 15;
  static const double temperaturaAdvertenciaAlta = 25;
  static const double temperaturaCriticaAlta = 30;



  static const RangoAgronomico conductividadElectrica = RangoAgronomico(
    minimo: 0.8,
    maximo: 1.8,
    unidad: 'dS/m',
    descripcion:
        'Rango normal de conductividad eléctrica indicado por el asesor. No debería superar 2.0 dS/m.',
  );

  static const double conductividadMaximaRecomendada = 2.0;
  static const double conductividadCriticaAlta = 2.0;


  static const RangoAgronomico phSuelo = RangoAgronomico(
    minimo: 5.7,
    maximo: 6.5,
    unidad: 'pH',
    descripcion: 'Rango óptimo de pH para fresa indicado por el asesor.',
  );

  static const double phCriticoBajo = 5.2;
  static const double phAdvertenciaBajo = 5.7;
  static const double phAdvertenciaAlto = 6.5;
  static const double phCriticoAlto = 7.0;



  static const RangoAgronomico nitrogenoFructificacion = RangoAgronomico(
    minimo: 72,
    maximo: 129,
    unidad: 'mg/kg',
    descripcion: 'Rango de nitrógeno disponible indicado por el asesor.',
  );

  static const double nitrogenoCriticoBajo = 50;
  static const double nitrogenoAdvertenciaBajo = 72;
  static const double nitrogenoAdvertenciaAlto = 129;
  static const double nitrogenoCriticoAlto = 160;

  static const RangoAgronomico fosforoFructificacion = RangoAgronomico(
    minimo: 20,
    maximo: 40,
    unidad: 'mg/kg',
    descripcion: 'Rango de fósforo disponible indicado por el asesor.',
  );

  static const double fosforoCriticoBajo = 10;
  static const double fosforoAdvertenciaBajo = 20;
  static const double fosforoAdvertenciaAlto = 40;
  static const double fosforoCriticoAlto = 60;

  static const RangoAgronomico potasioFructificacion = RangoAgronomico(
    minimo: 82,
    maximo: 160,
    unidad: 'mg/kg',
    descripcion: 'Rango de potasio como K indicado por el asesor.',
  );

  static const double potasioCriticoBajo = 50;
  static const double potasioAdvertenciaBajo = 82;
  static const double potasioAdvertenciaAlto = 160;
  static const double potasioCriticoAlto = 220;

  static const RangoAgronomico potasioComoK2O = RangoAgronomico(
    minimo: 98.8,
    maximo: 192.8,
    unidad: 'mg/kg',
    descripcion: 'Rango equivalente de potasio expresado como K₂O.',
  );

  
  static double convertirKAK2O(double potasioComoK) {
    return potasioComoK * 1.2046;
  }

  static double convertirK2OAK(double potasioComoK2O) {
    return potasioComoK2O / 1.2046;
  }

  static double convertirMicroSiemensADsM(double microSiemensCm) {
    return microSiemensCm / 1000;
  }

  static double normalizarEcADsM(double valorSensor) {

    if (valorSensor > 20) {
      return convertirMicroSiemensADsM(valorSensor);
    }

    return valorSensor;
  }
}
