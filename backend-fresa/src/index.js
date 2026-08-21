require("dotenv").config();

const express = require("express");
const cors = require("cors");


const { db, FieldValue } = require("./firebase");
const { generarAlertaCritica } = require("./services/alertas.service");
const {
  enviarNotificacionAlerta,
} = require("./services/notificaciones.service");

const { iniciarMqtt } = require("./services/mqtt.service");

const {
  actualizarHeartbeat,
  registrarBackendIniciado,
  registrarErrorBackend,
} = require("./services/estado.service");

const app = express();

app.use(cors());
app.use(express.json());

const PORT = process.env.PORT || 3000;
const USUARIO_ID = process.env.USUARIO_ID || "jdh2010";
const FINCA_ID = process.env.FINCA_ID || "finca_esperanza";
const LOTE_ID = process.env.LOTE_ID || "lote_1";

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

app.get("/health", (req, res) => {
  res.json({
    ok: true,
    servicio: "backend-fresa",
    fecha: new Date().toISOString(),
  });
});

app.get("/status", async (req, res) => {
  try {
    res.json({
      ok: true,
      servicio: "backend-fresa",
      estado: "activo",
      fechaServidor: new Date().toISOString(),
      firebase: {
        proyecto: "sensores-fresa",
        firestore: "conectado",
        fcm: "configurado",
      },
      mqtt: {
        broker: process.env.MQTT_BROKER_URL,
        topic: process.env.MQTT_TOPIC,
        clientId: process.env.MQTT_CLIENT_ID,
      },
      cultivo: {
        usuarioId: process.env.USUARIO_ID,
        fincaId: process.env.FINCA_ID,
        loteId: process.env.LOTE_ID,
        sensorId: process.env.SENSOR_ID,
        cultivo: "Fresa Albión",
        etapa: "Fructificación",
      },
    });
  } catch (error) {
    res.status(500).json({
      ok: false,
      error: error.message,
    });
  }
});

app.post("/revisar-alertas", async (req, res) => {
  try {
    const resultado = await revisarUltimaLecturaCritica();

    res.json({
      ok: true,
      resultado,
    });
  } catch (error) {
    console.error("❌ Error revisando alertas:", error);

    res.status(500).json({
      ok: false,
      error: error.message,
    });
  }
});

async function revisarUltimaLecturaCritica() {
  const snapshot = await lecturasRef()
    .orderBy("fechaLectura", "desc")
    .limit(1)
    .get();

  if (snapshot.empty) {
    console.log("ℹ️ No hay lecturas en Firestore.");
    return {
      estado: "sin_lecturas",
    };
  }

  const doc = snapshot.docs[0];
  const lecturaId = doc.id;
  const lectura = doc.data();

  console.log("📥 Última lectura encontrada:", lecturaId);
  console.log("📊 Datos de la última lectura:", lectura);
console.log("🌱 Humedad:", lectura.humedadSuelo);
console.log("🌡️ Temperatura:", lectura.temperaturaSuelo);
console.log("🧪 pH:", lectura.phSuelo);
console.log("⚡ EC:", lectura.conductividadElectrica);
console.log("🟢 N:", lectura.nitrogeno);
console.log("🟣 P:", lectura.fosforo);
console.log("🟠 K:", lectura.potasio);

  const alerta = generarAlertaCritica(lectura);

  if (!alerta) {
    console.log("✅ Última lectura sin alerta crítica:", lecturaId);
    return {
      estado: "sin_alerta",
      lecturaId,
    };
  }

  const alertaId = `${lecturaId}_${alerta.tipo}_${alerta.prioridad}`;

  const alertaDoc = await alertasRef().doc(alertaId).get();

  if (alertaDoc.exists) {
    console.log("ℹ️ Alerta ya notificada:", alertaId);
    return {
      estado: "ya_notificada",
      alertaId,
    };
  }

  const envio = await enviarNotificacionAlerta({
    usuarioId: USUARIO_ID,
    fincaId: FINCA_ID,
    loteId: LOTE_ID,
    lecturaId,
    alerta,
  });

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
    enviada: envio.enviados > 0,
    enviados: envio.enviados,
    fallidos: envio.fallidos,
    creadaEn: FieldValue.serverTimestamp(),
  });

  console.log("🚨 Alerta procesada:", alertaId);

  return {
    estado: "alerta_enviada",
    alertaId,
    envio,
  };
}

app.listen(PORT, async () => {
  console.log(`✅ Backend Fresa ejecutándose en puerto ${PORT}`);

  try {
    await registrarBackendIniciado();
    await actualizarHeartbeat();
  } catch (error) {
    console.error("❌ Error registrando estado inicial:", error.message);
  }

  setInterval(async () => {
    try {
      await actualizarHeartbeat();
    } catch (error) {
      console.error("❌ Error actualizando heartbeat:", error.message);

      try {
        await registrarErrorBackend(error);
      } catch (_) {
      }
    }
  }, 60 * 1000);

  iniciarMqtt();
});