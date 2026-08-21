
import 'package:firebase_core/firebase_core.dart' show FirebaseOptions;
import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;


class DefaultFirebaseOptions {
  static FirebaseOptions get currentPlatform {
    if (kIsWeb) {
      return web;
    }
    switch (defaultTargetPlatform) {
      case TargetPlatform.android:
        return android;
      case TargetPlatform.iOS:
        return ios;
      case TargetPlatform.macOS:
        return macos;
      case TargetPlatform.windows:
        return windows;
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux - '
          'you can reconfigure this by running the FlutterFire CLI again.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyCg766IxImNDjUlKsEWLMT-mqTX92HQyKc',
    appId: '1:263939674464:web:9f66302e41b603478c0e05',
    messagingSenderId: '263939674464',
    projectId: 'sensores-fresa',
    authDomain: 'sensores-fresa.firebaseapp.com',
    storageBucket: 'sensores-fresa.firebasestorage.app',
  );

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyCFxH_cqrak5FGGhNEoF3c57eIoVsvvpXM',
    appId: '1:263939674464:android:9a21f39a687788618c0e05',
    messagingSenderId: '263939674464',
    projectId: 'sensores-fresa',
    storageBucket: 'sensores-fresa.firebasestorage.app',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'AIzaSyCl85a3rTlBsDw79d_FJhVbJgLHVaSHzpw',
    appId: '1:263939674464:ios:a9fccf40e2fd62618c0e05',
    messagingSenderId: '263939674464',
    projectId: 'sensores-fresa',
    storageBucket: 'sensores-fresa.firebasestorage.app',
    iosBundleId: 'com.example.fresaApp',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'AIzaSyCl85a3rTlBsDw79d_FJhVbJgLHVaSHzpw',
    appId: '1:263939674464:ios:a9fccf40e2fd62618c0e05',
    messagingSenderId: '263939674464',
    projectId: 'sensores-fresa',
    storageBucket: 'sensores-fresa.firebasestorage.app',
    iosBundleId: 'com.example.fresaApp',
  );

  static const FirebaseOptions windows = FirebaseOptions(
    apiKey: 'AIzaSyCg766IxImNDjUlKsEWLMT-mqTX92HQyKc',
    appId: '1:263939674464:web:7dc56bb94d8ea4db8c0e05',
    messagingSenderId: '263939674464',
    projectId: 'sensores-fresa',
    authDomain: 'sensores-fresa.firebaseapp.com',
    storageBucket: 'sensores-fresa.firebasestorage.app',
  );
}
