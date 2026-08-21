const { initializeApp, cert } = require("firebase-admin/app");
const {
  getFirestore,
  FieldValue,
} = require("firebase-admin/firestore");
const { getMessaging } = require("firebase-admin/messaging");

let serviceAccount;

if (process.env.FIREBASE_SERVICE_ACCOUNT_JSON) {
  serviceAccount = JSON.parse(process.env.FIREBASE_SERVICE_ACCOUNT_JSON);
} else {
  serviceAccount = require("../serviceAccountKey.json");
}

initializeApp({
  credential: cert(serviceAccount),
});

const db = getFirestore();
const messaging = getMessaging();

module.exports = {
  db,
  messaging,
  FieldValue,
};