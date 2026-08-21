function generarAlertasCriticas(lectura) {
  if (!lectura) return [];

  const alertas = [];

  const humedad = Number(lectura.humedadSuelo);
  const temperatura = Number(lectura.temperaturaSuelo);
  const ec = Number(lectura.conductividadElectrica);
  const ph = Number(lectura.phSuelo);
  const nitrogeno = Number(lectura.nitrogeno);
  const fosforo = Number(lectura.fosforo);
  const potasio = Number(lectura.potasio);

  if (humedad > 0 && humedad < 35) {
    alertas.push({
      tipo: "humedad_baja",
      prioridad: "alta",
      titulo: "Humedad baja",
      mensaje: `La humedad del suelo está en ${humedad.toFixed(
        1,
      )}%. Revisa el riego del lote 1.`,
      resumen: `humedad baja (${humedad.toFixed(1)}%)`,
    });
  }

  if (humedad > 75) {
    alertas.push({
      tipo: "humedad_alta",
      prioridad: "alta",
      titulo: "Exceso de humedad",
      mensaje: `La humedad del suelo está en ${humedad.toFixed(
        1,
      )}%. Puede existir riesgo de encharcamiento.`,
      resumen: `humedad alta (${humedad.toFixed(1)}%)`,
    });
  }

  if (temperatura > 30) {
    alertas.push({
      tipo: "temperatura_alta",
      prioridad: "alta",
      titulo: "Temperatura alta",
      mensaje: `La temperatura del suelo está en ${temperatura.toFixed(
        1,
      )} °C. Revisa condiciones de estrés térmico.`,
      resumen: `temperatura alta (${temperatura.toFixed(1)} °C)`,
    });
  }

  if (ph > 0 && ph < 5.3) {
    alertas.push({
      tipo: "ph_acido",
      prioridad: "alta",
      titulo: "pH ácido",
      mensaje: `El pH del suelo está en ${ph.toFixed(
        1,
      )}. Puede afectar la disponibilidad de nutrientes.`,
      resumen: `pH ácido (${ph.toFixed(1)})`,
    });
  }

  if (ph > 7.0) {
    alertas.push({
      tipo: "ph_alto",
      prioridad: "alta",
      titulo: "pH alto",
      mensaje: `El pH del suelo está en ${ph.toFixed(
        1,
      )}. Revisa la disponibilidad nutricional del cultivo.`,
      resumen: `pH alto (${ph.toFixed(1)})`,
    });
  }

  if (ec > 2.5) {
    alertas.push({
      tipo: "salinidad_alta",
      prioridad: "alta",
      titulo: "Salinidad alta",
      mensaje: `La conductividad eléctrica está en ${ec.toFixed(
        2,
      )} dS/m. Existe riesgo de salinidad.`,
      resumen: `salinidad alta (${ec.toFixed(2)} dS/m)`,
    });
  }

  if (nitrogeno > 0 && nitrogeno < 60) {
    alertas.push({
      tipo: "nitrogeno_bajo",
      prioridad: "alta",
      titulo: "Nitrógeno bajo",
      mensaje: `El nitrógeno está en ${nitrogeno.toFixed(
        0,
      )} ppm. Revisa el plan de fertilización.`,
      resumen: `nitrógeno bajo (${nitrogeno.toFixed(0)} ppm)`,
    });
  }

  if (fosforo > 0 && fosforo < 27) {
    alertas.push({
      tipo: "fosforo_bajo",
      prioridad: "alta",
      titulo: "Fósforo bajo",
      mensaje: `El fósforo está en ${fosforo.toFixed(
        0,
      )} ppm. Revisa la nutrición del cultivo.`,
      resumen: `fósforo bajo (${fosforo.toFixed(0)} ppm)`,
    });
  }

  if (potasio > 0 && potasio < 72) {
    alertas.push({
      tipo: "potasio_bajo",
      prioridad: "alta",
      titulo: "Potasio bajo",
      mensaje: `El potasio está en ${potasio.toFixed(
        0,
      )} ppm. Puede afectar calidad y desarrollo del fruto.`,
      resumen: `potasio bajo (${potasio.toFixed(0)} ppm)`,
    });
  }

  return alertas;
}

function generarAlertaResumen(alertas) {
  if (!alertas || alertas.length === 0) return null;

  if (alertas.length === 1) {
    const alerta = alertas[0];

    return {
      tipo: alerta.tipo,
      prioridad: alerta.prioridad,
      titulo: alerta.titulo,
      mensaje: alerta.mensaje,
    };
  }

  const resumenes = alertas.map((alerta) => alerta.resumen).join(", ");

  return {
    tipo: "multiple",
    prioridad: "alta",
    titulo: "Alerta crítica en Lote 1",
    mensaje: `Se detectaron ${alertas.length} condiciones críticas: ${resumenes}.`,
  };
}

module.exports = {
  generarAlertasCriticas,
  generarAlertaResumen,
};