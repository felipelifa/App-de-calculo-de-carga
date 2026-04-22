import 'package:flutter/foundation.dart'
    show defaultTargetPlatform, kIsWeb, TargetPlatform;
import 'package:firebase_core/firebase_core.dart';

/// Firebase configuration generated manually for emulator support.
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
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for windows.',
        );
      case TargetPlatform.linux:
        throw UnsupportedError(
          'DefaultFirebaseOptions have not been configured for linux.',
        );
      default:
        throw UnsupportedError(
          'DefaultFirebaseOptions are not supported for this platform.',
        );
    }
  }

  static const FirebaseOptions web = FirebaseOptions(
    apiKey: 'AIzaSyA8Cnjhujks-BjLk7_43L8MwK0mxS2IUZA',
    appId: '1:220706619737:web:8af56698b30c668385cc48',
    messagingSenderId: '220706619737',
    projectId: 'appcalculotreino-51f23',
    authDomain: 'appcalculotreino-51f23.firebaseapp.com',
    storageBucket: 'appcalculotreino-51f23.firebasestorage.app',
    measurementId: 'G-DC3D8HCWM9',
  );

  // Dummy values for Local Emulator usage

  static const FirebaseOptions android = FirebaseOptions(
    apiKey: 'AIzaSyA8Cnjhujks-BjLk7_43L8MwK0mxS2IUZA', // Usando chave real do projeto
    appId: '1:220706619737:android:8af56698b30c668385cc48', // Placeholder aproximado (favor conferir no console)
    messagingSenderId: '220706619737',
    projectId: 'appcalculotreino-51f23',
    storageBucket: 'appcalculotreino-51f23.appspot.com',
  );

  static const FirebaseOptions ios = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:1234567890:ios:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'appcalculotreino-51f23',
    storageBucket: 'appcalculotreino-51f23.appspot.com',
    iosBundleId: 'com.felipe.app',
  );

  static const FirebaseOptions macos = FirebaseOptions(
    apiKey: 'dummy-api-key',
    appId: '1:1234567890:ios:abcdef',
    messagingSenderId: '1234567890',
    projectId: 'appcalculotreino-51f23',
    storageBucket: 'appcalculotreino-51f23.appspot.com',
    iosBundleId: 'com.felipe.app.macos',
  );
}