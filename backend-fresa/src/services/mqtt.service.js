const mqtt = require("mqtt");

const { db, FieldValue } = require("../firebase");
const {
  generarAlertasCriticas,
  generarAlertaResumen,
} = require("./alertas.service");
const { enviarNotificacionAlerta } = require("./notificaciones.service");
const {
  registrarMqttConectado,
  registrarMqttDesconectado,
  registrarUltimaLecturaMqtt,
  registrarUltimaAlerta,
  registrarErrorBackend,
} = require("./estado.service");

const USUARIO_ID = process.env.USUARIO_ID || "jdh2010";
const FINCA_ID = process.env.FINCA_ID || "finca_esperanza";
const LOTE_ID = process.env.LOTE_ID || "lote_1";
const SENSOR_ID = process.env.SENSOR_ID || "sensor_rs485_7en1_01";

const MQTT_BROKER_URL =
  process.env.MQTT_BROKER_URL || "mqtt://broker.emqx.io:1883";

const MQTT_CLIENT_ID =
  process.env.MQTT_CLIENT_ID || "fresa_app_backend_jdh2010_pc";

const MQTT_TOPIC =
  process.env.MQTT_TOPIC ||
  "fresa_app/jdh2010/finca_esperanza/lote_1/suelo";

function lecturasRef() {
  return db
    .collection("usuarios")
    .doc(USUARIO_ID)
    .collection("fincas")
    .doc(FINCA_ID)
    .collection("lotes")
    .doc(LOTE_ID)
    .collection("lecturas");
}

function alertasRef() {
  return db
    .collection("usuarios")
    .doc(USUARIO_ID)
    .collection("fincas")
    .doc(FINCA_ID)
    .collection("lotes")
    .doc(LOTE_ID)
    .collection("alertas");
}

function generarIdLectura(fecha) {
  const fechaUtc = fecha.toISOString();

  return `${SENSOR_ID}_${fechaUtc
    .replaceAll(":", "-")
    .replaceAll(".", "-")}`;
}

function convertirLecturaMqtt(payload) {
  const fechaLectura = payload.fechaLectura
    ? new Date(payload.fechaLectura)
    : new Date();

  return {
    sensorId: SENSOR_ID,
    usuarioId: USUARIO_ID,
    fincaId: FINCA_ID,
    loteId: LOTE_ID,

    cultivo: "Fresa Albión",
    etapa: "Fructificación",
    origen: "backend_mqtt",
    fuente: "mqtt_backend",

    fechaLectura,
    fechaLecturaIso: fechaLectura.toISOString(),
    fechaLecturaMs: fechaLectura.getTime(),

    humedadSuelo: Number(payload.humedadSuelo),
    temperaturaSuelo: Number(payload.temperaturaSuelo),
    conductividadElectrica: Number(payload.conductividadElectrica),
    phSuelo: Number(payload.phSuelo),
    nitrogeno: Number(payload.nitrogeno),
    fosforo: Number(payload.fosforo),
    potasio: Number(payload.potasio),

    esLecturaValida: true,
  };
}

async function asegurarDocumentosPadre() {
  const usuarioRef = db.collection("usuarios").doc(USUARIO_ID);

  const fincaRef = usuarioRef.collection("fincas").doc(FINCA_ID);

  const loteRef = fincaRef.collection("lotes").doc(LOTE_ID);

  await usuarioRef.set(
    {
      id: USUARIO_ID,
      nombre: "Usuario prueba",
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await fincaRef.set(
    {
      id: FINCA_ID,
      nombre: "La Esperanza",
      ubicacion: "Cauca, Colombia",
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  await loteRef.set(
    {
      id: LOTE_ID,
      nombre: "Lote 1",
      cultivo: "Fresa Albión",
      etapa: "Fructificación",
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );
}

async function guardarLecturaDesdeMqtt(lectura) {
  await asegurarDocumentosPadre();

  const lecturaId = generarIdLectura(lectura.fechaLectura);

  await lecturasRef().doc(lecturaId).set(
    {
      id: lecturaId,
      usuarioId: lectura.usuarioId,
      fincaId: lectura.fincaId,
      loteId: lectura.loteId,
      sensorId: lectura.sensorId,

      cultivo: lectura.cultivo,
      etapa: lectura.etapa,
      origen: lectura.origen,
      fuente: lectura.fuente,

      fechaLectura: lectura.fechaLectura,
      fechaLecturaIso: lectura.fechaLecturaIso,
      fechaLecturaMs: lectura.fechaLecturaMs,
      actualizadoEn: FieldValue.serverTimestamp(),

      humedadSuelo: lectura.humedadSuelo,
      temperaturaSuelo: lectura.temperaturaSuelo,
      conductividadElectrica: lectura.conductividadElectrica,
      phSuelo: lectura.phSuelo,
      nitrogeno: lectura.nitrogeno,
      fosforo: lectura.fosforo,
      potasio: lectura.potasio,

      esLecturaValida: lectura.esLecturaValida,
    },
    { merge: true },
  );

  return lecturaId;
}

async function procesarAlertaDeLectura(lecturaId, lectura) {
  const alertas = generarAlertasCriticas(lectura);

  if (alertas.length === 0) {
    console.log("✅ Lectura MQTT sin alerta crítica:", lecturaId);
    return;
  }

  const alertaResumen = generarAlertaResumen(alertas);

  if (!alertaResumen) {
    console.log("✅ No se generó alerta resumen:", lecturaId);
    return;
  }

  const alertaResumenId = `${lecturaId}_resumen_alta`;

  const alertaResumenDoc = await alertasRef().doc(alertaResumenId).get();

  if (alertaResumenDoc.exists) {
    console.log("ℹAlerta MQTT ya notificada:", alertaResumenId);
    return;
  }

  const envio = await enviarNotificacionAlerta({
    usuarioId: USUARIO_ID,
    fincaId: FINCA_ID,
    loteId: LOTE_ID,
    lecturaId,
    alerta: alertaResumen,
  });

  for (const alerta of alertas) {
    const alertaId = `${lecturaId}_${alerta.tipo}_${alerta.prioridad}`;

    await alertasRef().doc(alertaId).set({
      id: alertaId,
      lecturaId,
      usuarioId: USUARIO_ID,
      fincaId: FINCA_ID,
      loteId: LOTE_ID,
      tipo: alerta.tipo,
      prioridad: alerta.prioridad,
      titulo: alerta.titulo,
      mensaje: alerta.mensaje,
      resumen: alerta.resumen,
      enviada: envio.enviados > 0,
      enviados: envio.enviados,
      fallidos: envio.fallidos,
      origen: "backend_mqtt",
      agrupada: true,
      creadaEn: FieldValue.serverTimestamp(),
    });

    console.log("🚨 Alerta individual guardada:", alertaId);
  }

  await alertasRef().doc(alertaResumenId).set({
    id: alertaResumenId,
    lecturaId,
    usuarioId: USUARIO_ID,
    fincaId: FINCA_ID,
    loteId: LOTE_ID,
    tipo: alertaResumen.tipo,
    prioridad: alertaResumen.prioridad,
    titulo: alertaResumen.titulo,
    mensaje: alertaResumen.mensaje,
    enviada: envio.enviados > 0,
    enviados: envio.enviados,
    fallidos: envio.fallidos,
    origen: "backend_mqtt",
    agrupada: true,
    totalAlertas: alertas.length,
    tiposDetectados: alertas.map((alerta) => alerta.tipo),
    creadaEn: FieldValue.serverTimestamp(),
  });

  await registrarUltimaAlerta({
    lecturaId,
    titulo: alertaResumen.titulo,
    mensaje: alertaResumen.mensaje,
    totalAlertas: alertas.length,
  });

  console.log("🚨 Alerta resumen enviada:", alertaResumenId);
}

function iniciarMqtt() {
  console.log("🔌 Conectando backend a MQTT...");
  console.log("Broker:", MQTT_BROKER_URL);
  console.log("Topic:", MQTT_TOPIC);

  const client = mqtt.connect(MQTT_BROKER_URL, {
    clientId: MQTT_CLIENT_ID,
    clean: true,
    reconnectPeriod: 5000,
  });

  client.on("connect", async () => {
    console.log("✅ Backend conectado a MQTT");

    try {
      await registrarMqttConectado();
    } catch (error) {
      console.error("❌ Error registrando MQTT conectado:", error.message);
    }

    client.subscribe(MQTT_TOPIC, { qos: 1 }, (error) => {
      if (error) {
        console.error("❌ Error suscribiendo a MQTT:", error.message);
        return;
      }

      console.log("📡 Backend suscrito al topic:", MQTT_TOPIC);
    });
  });

  client.on("message", async (topic, message) => {
    try {
      console.log("📩 Mensaje MQTT recibido en backend:", topic);

      const texto = message.toString();
      const payload = JSON.parse(texto);

      const lectura = convertirLecturaMqtt(payload);

      console.log("🌱 MQTT Humedad:", lectura.humedadSuelo);
      console.log("🌡️ MQTT Temperatura:", lectura.temperaturaSuelo);
      console.log("🧪 MQTT pH:", lectura.phSuelo);
      console.log("⚡ MQTT EC:", lectura.conductividadElectrica);
      console.log("🟢 MQTT N:", lectura.nitrogeno);
      console.log("🟣 MQTT P:", lectura.fosforo);
      console.log("🟠 MQTT K:", lectura.potasio);

      const lecturaId = await guardarLecturaDesdeMqtt(lectura);

      console.log("✅ Lectura MQTT guardada en Firestore:", lecturaId);

      await registrarUltimaLecturaMqtt({
        lecturaId,
        humedadSuelo: lectura.humedadSuelo,
        temperaturaSuelo: lectura.temperaturaSuelo,
        phSuelo: lectura.phSuelo,
        conductividadElectrica: lectura.conductividadElectrica,
      });

      await procesarAlertaDeLectura(lecturaId, lectura);
    } catch (error) {
      console.error("❌ Error procesando mensaje MQTT:", error.message);

      try {
        await registrarErrorBackend(error);
      } catch (_) {
        // Evita que un error adicional tumbe el backend.
      }
    }
  });

  client.on("error", async (error) => {
    console.error("❌ Error MQTT:", error.message);

    try {
      await registrarErrorBackend(error);
    } catch (_) {
      // Evita que un error adicional tumbe el backend.
    }
  });

  client.on("reconnect", () => {
    console.log("🔄 Reintentando conexión MQTT...");
  });

  client.on("close", async () => {
    console.log("⚠️ Conexión MQTT cerrada");

    try {
      await registrarMqttDesconectado();
    } catch (error) {
      console.error("❌ Error registrando MQTT desconectado:", error.message);
    }
  });
}

module.exports = {
  iniciarMqtt,
};