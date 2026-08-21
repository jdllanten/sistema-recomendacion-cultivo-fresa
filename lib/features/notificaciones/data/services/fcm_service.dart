import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class FcmService {
  FcmService({
    FirebaseMessaging? messaging,
    FirebaseFirestore? firestore,
  })  : _messaging = messaging ?? FirebaseMessaging.instance,
        _firestore = firestore ?? FirebaseFirestore.instance;

  final FirebaseMessaging _messaging;
  final FirebaseFirestore _firestore;

  final FlutterLocalNotificationsPlugin _localNotifications =
      FlutterLocalNotificationsPlugin();

  static const String _usuarioId = 'jdh2010';

  static const AndroidNotificationChannel _canalAlertas =
      AndroidNotificationChannel(
    'alertas_agronomicas',
    'Alertas agronómicas',
    description: 'Notificaciones críticas del cultivo de fresa',
    importance: Importance.high,
    playSound: true,
  );

  CollectionReference<Map<String, dynamic>> get _dispositivosRef {
    return _firestore
        .collection('usuarios')
        .doc(_usuarioId)
        .collection('dispositivos');
  }

  Future<void> inicializar() async {
    await _crearCanalAndroid();

    final permiso = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    debugPrint('Permiso de notificaciones: ${permiso.authorizationStatus}');

    final token = await _obtenerTokenConReintento();

    if (token == null) {
      debugPrint(
        'No se pudo obtener token FCM. Se intentará al reiniciar la app.',
      );
      return;
    }

    await _guardarToken(token);

    _messaging.onTokenRefresh.listen((nuevoToken) async {
      await _guardarToken(nuevoToken);
    });

    FirebaseMessaging.onMessage.listen((RemoteMessage message) async {
      debugPrint('Notificación recibida con app abierta');
      debugPrint('Título: ${message.notification?.title}');
      debugPrint('Cuerpo: ${message.notification?.body}');
      debugPrint('Data: ${message.data}');

      await _mostrarNotificacionLocal(message);
    });

    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      debugPrint('Usuario abrió la notificación');
      debugPrint('Data: ${message.data}');
    });
  }

  Future<void> _crearCanalAndroid() async {
    const initializationSettingsAndroid =
        AndroidInitializationSettings('@mipmap/ic_launcher');

    const initializationSettings = InitializationSettings(
      android: initializationSettingsAndroid,
    );

    await _localNotifications.initialize(settings: initializationSettings);

    final androidPlugin =
        _localNotifications.resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin>();

    await androidPlugin?.createNotificationChannel(_canalAlertas);

    try {
      await androidPlugin?.requestNotificationsPermission();
    } catch (e) {
      debugPrint('No se pudo solicitar permiso local Android: $e');
    }

    debugPrint('Canal Android creado: alertas_agronomicas');
  }

  Future<void> _mostrarNotificacionLocal(RemoteMessage message) async {
    final notification = message.notification;

    final titulo = notification?.title ?? 'Alerta agronómica';
    final cuerpo = notification?.body ?? 'Se detectó una condición crítica.';

    const androidDetails = AndroidNotificationDetails(
      'alertas_agronomicas',
      'Alertas agronómicas',
      channelDescription: 'Notificaciones críticas del cultivo de fresa',
      importance: Importance.high,
      priority: Priority.high,
      playSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
    );

    await _localNotifications.show(
      id: message.hashCode,
      title: titulo,
      body: cuerpo,
      notificationDetails: details,
      payload: message.data.toString(),
    );
  }

  Future<String?> _obtenerTokenConReintento() async {
    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Primer intento FCM falló: $e');
    }

    await Future<void>.delayed(const Duration(seconds: 3));

    try {
      return await _messaging.getToken();
    } catch (e) {
      debugPrint('Segundo intento FCM falló: $e');
      return null;
    }
  }

  Future<void> _guardarToken(String token) async {
    final dispositivoId = _crearIdSeguroDesdeToken(token);

    await _dispositivosRef.doc(dispositivoId).set(
      {
        'id': dispositivoId,
        'usuarioId': _usuarioId,
        'tokenFcm': token,
        'plataforma': 'android',
        'activo': true,
        'nombre': 'Celular Android',
        'actualizadoEn': FieldValue.serverTimestamp(),
        'creadoEn': FieldValue.serverTimestamp(),
      },
      SetOptions(merge: true),
    );

    debugPrint('Token FCM guardado en Firestore: $dispositivoId');
  }

  String _crearIdSeguroDesdeToken(String token) {
    return token
        .replaceAll('/', '_')
        .replaceAll('.', '_')
        .replaceAll('#', '_')
        .replaceAll('[', '_')
        .replaceAll(']', '_');
  }
}