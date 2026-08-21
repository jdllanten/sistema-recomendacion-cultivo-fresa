const { db, FieldValue } = require("../firebase");

const BACKEND_ID = "backend_fresa";
const SERVIDOR_NOMBRE = process.env.SERVIDOR_NOMBRE || "pc_extra";

function estadoBackendRef() {
  return db.collection("sistema").doc(BACKEND_ID);
}

async function actualizarHeartbeat() {
  await estadoBackendRef().set(
    {
      id: BACKEND_ID,
      estado: "activo",
      servidor: SERVIDOR_NOMBRE,
      ultimoHeartbeat: FieldValue.serverTimestamp(),
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Heartbeat backend actualizado");
}

async function registrarBackendIniciado() {
  await estadoBackendRef().set(
    {
      id: BACKEND_ID,
      estado: "activo",
      servidor: SERVIDOR_NOMBRE,
      iniciadoEn: FieldValue.serverTimestamp(),
      ultimoHeartbeat: FieldValue.serverTimestamp(),
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Estado backend iniciado registrado");
}

async function registrarMqttConectado() {
  await estadoBackendRef().set(
    {
      mqttConectado: true,
      ultimoEventoMqtt: "conectado",
      ultimoEventoMqttEn: FieldValue.serverTimestamp(),
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Estado MQTT conectado registrado");
}

async function registrarMqttDesconectado() {
  await estadoBackendRef().set(
    {
      mqttConectado: false,
      ultimoEventoMqtt: "desconectado",
      ultimoEventoMqttEn: FieldValue.serverTimestamp(),
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Estado MQTT desconectado registrado");
}

async function registrarUltimaLecturaMqtt({
  lecturaId,
  humedadSuelo,
  temperaturaSuelo,
  phSuelo,
  conductividadElectrica,
}) {
  await estadoBackendRef().set(
    {
      ultimaLecturaMqtt: FieldValue.serverTimestamp(),
      ultimaLecturaId: lecturaId,
      ultimaLecturaResumen: {
        humedadSuelo,
        temperaturaSuelo,
        phSuelo,
        conductividadElectrica,
      },
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Última lectura MQTT registrada en estado");
}

async function registrarUltimaAlerta({
  lecturaId,
  titulo,
  mensaje,
  totalAlertas,
}) {
  await estadoBackendRef().set(
    {
      ultimaAlertaEn: FieldValue.serverTimestamp(),
      ultimaAlerta: {
        lecturaId,
        titulo,
        mensaje,
        totalAlertas,
      },
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Última alerta registrada en estado");
}

async function registrarErrorBackend(error) {
  await estadoBackendRef().set(
    {
      ultimoError: error?.message || String(error),
      ultimoErrorEn: FieldValue.serverTimestamp(),
      actualizadoEn: FieldValue.serverTimestamp(),
    },
    { merge: true },
  );

  console.log("Error backend registrado en estado");
}

module.exports = {
  actualizarHeartbeat,
  registrarBackendIniciado,
  registrarMqttConectado,
  registrarMqttDesconectado,
  registrarUltimaLecturaMqtt,
  registrarUltimaAlerta,
  registrarErrorBackend,
};