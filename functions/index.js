/**
 * Import function triggers from their respective submodules:
 *
 * const {onCall} = require("firebase-functions/v2/https");
 * const {onDocumentWritten} = require("firebase-functions/v2/firestore");
 *
 * See a full list of supported triggers at https://firebase.google.com/docs/functions
 */


// For cost control, you can set the maximum number of containers that can be
// running at the same time. This helps mitigate the impact of unexpected
// traffic spikes by instead downgrading performance. This limit is a
// per-function limit. You can override the limit for each function using the
// `maxInstances` option in the function's options, e.g.
// `onRequest({ maxInstances: 5 }, (req, res) => { ... })`.
// NOTE: setGlobalOptions does not apply to functions using the v1 API. V1
// functions should each use functions.runWith({ maxInstances: 10 }) instead.
// In the v1 API, each function can only serve one request per container, so
// this will be the maximum concurrent request count.


// Create and deploy your first functions
// https://firebase.google.com/docs/functions/get-started

// exports.helloWorld = onRequest((request, response) => {
//   logger.info("Hello logs!", {structuredData: true});
//   response.send("Hello from Firebase!");
// });
const {onDocumentCreated} = require("firebase-functions/v2/firestore");
const admin = require("firebase-admin");

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

const USUARIO_ID = "jdh2010";

exports.notificarLecturaCritica = onDocumentCreated(
  {
    document:
      "usuarios/{usuarioId}/fincas/{fincaId}/lotes/{loteId}/lecturas/{lecturaId}",
    region: "us-central1",
  },
  async (event) => {
    const lectura = event.data.data();
    const {usuarioId, fincaId, loteId, lecturaId} = event.params;

    console.log("Nueva lectura:", {
      usuarioId,
      fincaId,
      loteId,
      lecturaId,
      lectura,
    });

    const alerta = generarAlerta(lectura);

    if (!alerta) {
      console.log("Lectura sin alerta crítica. No se envía notificación.");
      return;
    }

    const dispositivosSnapshot = await db
      .collection("usuarios")
      .doc(usuarioId || USUARIO_ID)
      .collection("dispositivos")
      .where("activo", "==", true)
      .get();

    if (dispositivosSnapshot.empty) {
      console.log("No hay dispositivos activos para notificar.");
      return;
    }

    const tokens = [];

    dispositivosSnapshot.forEach((doc) => {
      const data = doc.data();
      if (data.tokenFcm) {
        tokens.push(data.tokenFcm);
      }
    });

    if (tokens.length === 0) {
      console.log("No hay tokens FCM disponibles.");
      return;
    }

    const mensajes = tokens.map((token) => ({
      token,
      notification: {
        title: alerta.titulo,
        body: alerta.mensaje,
      },
      data: {
        tipo: alerta.tipo,
        prioridad: alerta.prioridad,
        fincaId,
        loteId,
        lecturaId,
      },
      android: {
        priority: "high",
        notification: {
          channelId: "alertas_agronomicas",
          priority: "high",
          defaultSound: true,
        },
      },
    }));

    const respuesta = await messaging.sendEach(mensajes);

    console.log("Notificaciones enviadas:", respuesta.successCount);
    console.log("Notificaciones fallidas:", respuesta.failureCount);
  },
);

function generarAlerta(lectura) {
  if (!lectura) return null;

  const humedad = Number(lectura.humedadSuelo);
  const temperatura = Number(lectura.temperaturaSuelo);
  const ec = Number(lectura.conductividadElectrica);
  const ph = Number(lectura.phSuelo);
  const nitrogeno = Number(lectura.nitrogeno);
  const fosforo = Number(lectura.fosforo);
  const potasio = Number(lectura.potasio);

  if (humedad > 0 && humedad < 35) {
    return {
      tipo: "humedad",
      prioridad: "alta",
      titulo: "Alerta de humedad baja",
      mensaje: `La humedad del suelo está en ${humedad.toFixed(
        1,
      )}%. Revisa el riego del lote.`,
    };
  }

  if (humedad > 75) {
    return {
      tipo: "humedad",
      prioridad: "alta",
      titulo: "Alerta de exceso de humedad",
      mensaje: `La humedad del suelo está en ${humedad.toFixed(
        1,
      )}%. Puede existir riesgo de encharcamiento.`,
    };
  }

  if (temperatura > 30) {
    return {
      tipo: "temperatura",
      prioridad: "alta",
      titulo: "Alerta de temperatura alta",
      mensaje: `La temperatura del suelo está en ${temperatura.toFixed(
        1,
      )} °C. Revisa condiciones de estrés térmico.`,
    };
  }

  if (ph > 0 && ph < 5.3) {
    return {
      tipo: "ph",
      prioridad: "alta",
      titulo: "Alerta de pH ácido",
      mensaje: `El pH del suelo está en ${ph.toFixed(
        1,
      )}. Puede afectar la disponibilidad de nutrientes.`,
    };
  }

  if (ph > 7.0) {
    return {
      tipo: "ph",
      prioridad: "alta",
      titulo: "Alerta de pH alto",
      mensaje: `El pH del suelo está en ${ph.toFixed(
        1,
      )}. Revisa la disponibilidad nutricional del cultivo.`,
    };
  }

  if (ec > 2.5) {
    return {
      tipo: "salinidad",
      prioridad: "alta",
      titulo: "Alerta de salinidad alta",
      mensaje: `La conductividad eléctrica está en ${ec.toFixed(
        2,
      )} dS/m. Existe riesgo de salinidad.`,
    };
  }

  if (nitrogeno > 0 && nitrogeno < 60) {
    return {
      tipo: "nitrogeno",
      prioridad: "alta",
      titulo: "Alerta de nitrógeno bajo",
      mensaje: `El nitrógeno está en ${nitrogeno.toFixed(
        0,
      )} ppm. Revisa el plan de fertilización.`,
    };
  }

  if (fosforo > 0 && fosforo < 27) {
    return {
      tipo: "fosforo",
      prioridad: "alta",
      titulo: "Alerta de fósforo bajo",
      mensaje: `El fósforo está en ${fosforo.toFixed(
        0,
      )} ppm. Revisa la nutrición del cultivo.`,
    };
  }

  if (potasio > 0 && potasio < 72) {
    return {
      tipo: "potasio",
      prioridad: "alta",
      titulo: "Alerta de potasio bajo",
      mensaje: `El potasio está en ${potasio.toFixed(
        0,
      )} ppm. Puede afectar calidad y desarrollo del fruto.`,
    };
  }

  return null;
}