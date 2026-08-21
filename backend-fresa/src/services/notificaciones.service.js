const { db, messaging, FieldValue } = require("../firebase");

async function obtenerTokensActivos(usuarioId) {
  const snapshot = await db
    .collection("usuarios")
    .doc(usuarioId)
    .collection("dispositivos")
    .where("activo", "==", true)
    .get();

  const tokens = [];

  snapshot.forEach((doc) => {
    const data = doc.data();

    if (data.tokenFcm) {
      tokens.push({
        id: doc.id,
        token: data.tokenFcm,
      });
    }
  });

  return tokens;
}

async function enviarNotificacionAlerta({
  usuarioId,
  fincaId,
  loteId,
  lecturaId,
  alerta,
}) {
  const tokens = await obtenerTokensActivos(usuarioId);

  if (tokens.length === 0) {
    console.log("⚠️ No hay tokens activos para notificar.");
    return {
      enviados: 0,
      fallidos: 0,
    };
  }

  let enviados = 0;
  let fallidos = 0;

  for (const item of tokens) {
    try {
      const messageId = await messaging.send({
  token: item.token,
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
      });

      enviados++;
      console.log("✅ Notificación enviada a:", item.id);
      console.log("📨 FCM messageId:", messageId);
    } catch (error) {
      fallidos++;
      console.error("❌ Error enviando notificación:", error.message);

      await db
        .collection("usuarios")
        .doc(usuarioId)
        .collection("dispositivos")
        .doc(item.id)
        .set(
          {
            ultimoErrorFcm: error.message,
            actualizadoEn: FieldValue.serverTimestamp(),
          },
          { merge: true },
        );
    }
  }

  return {
    enviados,
    fallidos,
  };
}

module.exports = {
  enviarNotificacionAlerta,
};